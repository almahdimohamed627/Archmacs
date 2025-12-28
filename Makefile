.PHONY: all build test clean help setup destroy

# Default target
.DEFAULT_GOAL := help

# Colors for output
GREEN := $(shell echo -e '\033[0;32m')
YELLOW := $(shell echo -e '\033[1;33m')
NC := $(shell echo -e '\033[0m')

help:
	@echo "$(GREEN)Archmacs - Fully Automated Build & Test Infrastructure$(NC)"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  setup              - Set up environment (Docker, KVM, Terraform)"
	@echo "  build              - Build ISO using Docker container (fast mode)"
	@echo "  build-full         - Build ISO using Docker container (full clean build)"
	@echo "  test               - Deploy VM with Terraform and run tests"
	@echo "  all                - build + test (fast build)"
	@echo "  all-full           - build-full + test"
	@echo "  clean              - Clean up build artifacts"
	@echo "  destroy            - Destroy Terraform resources"
	@echo "  cleanup            - Full cleanup (VMs, containers, artifacts)"
	@echo "  show-iso           - Show the built ISO file"
	@echo "  connect-vm         - Connect to test VM via SSH"
	@echo "  test-local          - Run tests locally (without Terraform)"
	@echo ""
	@echo "Quick start:"
	@echo "  1. make setup"
	@echo "  2. make all"
	@echo ""

setup:
	@echo "$(GREEN)Setting up Archmacs environment...$(NC)"
	@chmod +x scripts/*.sh
	@./scripts/setup-env.sh

docker-build:
	@echo "$(GREEN)Building Docker image...$(NC)"
	@docker build -t archmacs-builder ./docker

 build:
	@echo "$(GREEN)Building Archmacs ISO (fast mode)...$(NC)"
	@chmod +x scripts/build-iso.sh
	@BUILD_TYPE=fast ./scripts/build-iso.sh

build-full:
	@echo "$(GREEN)Building Archmacs ISO (full clean build)...$(NC)"
	@chmod +x scripts/build-iso.sh
	@BUILD_TYPE=full ./scripts/build-iso.sh

find-iso:
	@echo "$(GREEN)Finding latest ISO file...$(NC)"
	@if [ -z "$(wildcard out/*.iso)" ]; then \
		echo "No ISO files found in out/ directory"; \
		exit 1; \
	fi
	@ls -lh out/*.iso | tail -n 1

test:
	@echo "$(GREEN)Testing ISO with Terraform...$(NC)"
	@$(MAKE) find-iso
	@cd terraform && terraform init
	@cd terraform && terraform apply -auto-approve
	@echo "$(GREEN)Tests completed successfully!$(NC)"

all: build test

all-full: build-full test

clean:
	@echo "$(GREEN)Cleaning build artifacts...$(NC)"
	@rm -rf out/work
	@rm -f out/*.iso

destroy:
	@echo "$(GREEN)Destroying Terraform resources...$(NC)"
	@if [ -f terraform/.terraform/terraform.tfstate ]; then \
		cd terraform && terraform destroy -auto-approve; \
	else \
		echo "No Terraform resources to destroy"; \
	fi

cleanup: destroy clean
	@echo "$(GREEN)Running full cleanup...$(NC)"
	@chmod +x scripts/cleanup.sh
	@./scripts/cleanup.sh

show-iso:
	@$(MAKE) find-iso
	@echo "$(GREEN)ISO information:$(NC)"
	@file out/*.iso | tail -n 1
	@du -h out/*.iso | tail -n 1

connect-vm:
	@echo "$(GREEN)Connecting to test VM...$(NC)"
	@if [ ! -f terraform/terraform.tfstate ]; then \
		echo "No Terraform state found. Run 'make test' first."; \
		exit 1; \
	fi
	@IP=$$(cd terraform && terraform output -raw test_vm_ip 2>/dev/null); \
	if [ -z "$$IP" ]; then \
		echo "No VM IP found. VM may not be running."; \
		exit 1; \
	fi; \
	ssh -o StrictHostKeyChecking=no archuser@$$IP

test-local:
	@echo "$(GREEN)Running tests locally...$(NC)"
	@chmod +x tests/*.sh
	@./tests/test-packages.sh
	@./tests/test-emacs.sh

# Advanced targets

init-terraform:
	@echo "$(GREEN)Initializing Terraform...$(NC)"
	@cd terraform && terraform init

plan-terraform:
	@echo "$(GREEN)Planning Terraform changes...$(NC)"
	@cd terraform && terraform plan

apply-terraform:
	@echo "$(GREEN)Applying Terraform changes...$(NC)"
	@cd terraform && terraform apply

# Utility targets

check-env:
	@echo "$(GREEN)Checking environment...$(NC)"
	@echo "Docker: $$(which docker 2>/dev/null || echo 'Not installed')"
	@echo "Terraform: $$(which terraform 2>/dev/null || echo 'Not installed')"
	@echo "Virsh: $$(which virsh 2>/dev/null || echo 'Not installed')"
	@echo "Make: $$(which make 2>/dev/null || echo 'Not installed')"

show-resources:
	@echo "$(GREEN)Showing Docker resources...$(NC)"
	@docker ps -a
	@docker images | grep archmacs
	@echo ""
	@echo "$(GREEN)Showing Libvirt resources...$(NC)"
	@virsh list --all 2>/dev/null || echo "Libvirt not available"
	@virsh pool-list 2>/dev/null || echo "Libvirt not available"
	@virsh net-list 2>/dev/null || echo "Libvirt not available"

# CI/CD targets (for future automation)

ci-build:
	@echo "$(GREEN)CI: Building ISO...$(NC)"
	@$(MAKE) build

ci-test:
	@echo "$(GREEN)CI: Running tests...$(NC)"
	@$(MAKE) test

ci: ci-build ci-test
