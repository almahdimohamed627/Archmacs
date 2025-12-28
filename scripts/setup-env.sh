#!/bin/bash
# Environment setup script for Archmacs project
# This script checks and installs all required dependencies

set -e

echo "======================================================================"
echo "=== Archmacs Environment Setup ==="
echo "======================================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status
print_status() {
    local status="$1"
    local message="$2"
    if [ "$status" = "ok" ]; then
        echo -e "${GREEN}✓${NC} $message"
    elif [ "$status" = "warning" ]; then
        echo -e "${YELLOW}⚠${NC} $message"
    else
        echo -e "${RED}✗${NC} $message"
    fi
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Please do not run this script as root"
    exit 1
fi

# Function to install package via dnf
install_dnf() {
    local pkg="$1"
    if ! command_exists "$pkg"; then
        echo "Installing $pkg..."
        sudo dnf install -y "$pkg"
        print_status "ok" "$pkg installed successfully"
    else
        print_status "ok" "$pkg is already installed"
    fi
}

echo "Step 1: Checking Docker..."
if command_exists docker; then
    print_status "ok" "Docker is installed"
    docker --version
else
    print_status "warning" "Docker is not installed"
    echo "Installing Docker..."
    sudo dnf install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker "$USER"
    print_status "ok" "Docker installed and service started"
    print_status "warning" "Please log out and back in for Docker group to take effect"
fi

echo ""
echo "Step 2: Checking Terraform..."
if command_exists terraform; then
    print_status "ok" "Terraform is installed"
    terraform version
else
    print_status "warning" "Terraform is not installed"
    echo "Installing Terraform..."
    sudo dnf install -y terraform
    print_status "ok" "Terraform installed"
fi

echo ""
echo "Step 3: Checking KVM/Libvirt..."
if command_exists virsh; then
    print_status "ok" "KVM/Libvirt is installed"
    virsh --version
else
    print_status "warning" "KVM/Libvirt is not installed"
    echo "Installing KVM/Libvirt..."
    sudo dnf install -y @virtualization
    sudo systemctl start libvirtd
    sudo systemctl enable libvirtd
    sudo usermod -aG libvirt "$USER"
    print_status "ok" "KVM/Libvirt installed and service started"
    print_status "warning" "Please log out and back in for libvirt group to take effect"
fi

echo ""
echo "Step 4: Checking additional tools..."
for tool in bc jq git make; do
    if command_exists "$tool"; then
        print_status "ok" "$tool is available"
    else
        echo "Installing $tool..."
        sudo dnf install -y "$tool"
        print_status "ok" "$tool installed"
    fi
done

echo ""
echo "Step 5: Creating necessary directories..."
for dir in out work terraform/.terraform logs; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_status "ok" "Created directory: $dir"
    else
        print_status "ok" "Directory exists: $dir"
    fi
done

echo ""
echo "Step 6: Checking SSH keys..."
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    echo "Generating SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N ""
    print_status "ok" "SSH key pair generated"
else
    print_status "ok" "SSH key pair exists"
fi

echo ""
echo "Step 7: Setting up file permissions..."
chmod +x docker/build-entrypoint.sh
chmod +x archiso-profile/airootfs/root/customize.sh
chmod +x archiso-profile/airootfs/root/.xinitrc
chmod +x tests/*.sh
chmod +x scripts/*.sh
print_status "ok" "File permissions set"

echo ""
echo "Step 8: Checking system resources..."
echo "Checking CPU cores..."
CPU_CORES=$(nproc)
print_status "ok" "Available CPU cores: $CPU_CORES"

echo "Checking available memory..."
MEMORY=$(free -h | grep Mem | awk '{print $2}')
print_status "ok" "Available memory: $MEMORY"

echo "Checking disk space..."
DISK=$(df -h . | tail -n 1 | awk '{print $4}')
print_status "ok" "Available disk space: $DISK"

echo ""
echo "Step 9: Verifying system requirements..."

# Minimum requirements
MIN_CPU=2
MIN_MEMORY_GB=4

if [ "$CPU_CORES" -lt "$MIN_CPU" ]; then
    print_status "warning" "System has less than $MIN_CPU CPU cores (recommended for optimal performance)"
fi

MEMORY_GB=$(free -g | grep Mem | awk '{print $2}')
if [ "$MEMORY_GB" -lt "$MIN_MEMORY_GB" ]; then
    print_status "warning" "System has less than $MIN_MEMORY_GB GB RAM (recommended for optimal performance)"
fi

echo ""
echo "Step 10: Testing tools..."

# Test Docker
if command_exists docker; then
    if docker ps &>/dev/null; then
        print_status "ok" "Docker is working"
    else
        print_status "warning" "Docker may not be properly configured"
    fi
fi

# Test libvirt
if command_exists virsh; then
    if virsh version &>/dev/null; then
        print_status "ok" "Libvirt is working"
    else
        print_status "warning" "Libvirt may not be properly configured"
    fi
fi

# Test terraform
if command_exists terraform; then
    print_status "ok" "Terraform is working"
fi

echo ""
echo "======================================================================"
echo "=== Setup Complete! ==="
echo "======================================================================"
echo ""
echo "Next steps:"
echo "1. Log out and back in if new groups (docker, libvirt) were added"
echo "2. Run 'make build' to build the ISO"
echo "3. Run 'make test' to test the ISO"
echo "4. Run 'make all' to build and test (recommended)"
echo ""
echo "For more information, see README.org"
echo ""
