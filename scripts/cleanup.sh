#!/bin/bash
# Cleanup script for Archmacs project
# This script cleans up temporary files and resources

set -e

echo "=== Archmacs Cleanup ==="

# Function to confirm destructive action
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local reply
    
    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n] "
    else
        prompt="$prompt [y/N] "
    fi
    
    read -r -p "$prompt" reply
    case "$reply" in
        Y*|y*) return 0 ;;
        N*|n*) return 1 ;;
        *) [ "$default" = "y" ] && return 0 || return 1 ;;
    esac
}

# Clean Docker containers
echo "Checking for Docker containers..."
if command -v docker &>/dev/null; then
    CONTAINERS=$(docker ps -a -q)
    if [ -n "$CONTAINERS" ]; then
        echo "Found Docker containers:"
        docker ps -a
        if confirm "Remove all Docker containers?"; then
            docker rm -f $CONTAINERS
            echo "Docker containers removed"
        fi
    else
        echo "No Docker containers found"
    fi
fi

# Clean Docker images
echo "Checking for Docker images..."
if command -v docker &>/dev/null; then
    IMAGES=$(docker images -q archmacs-builder)
    if [ -n "$IMAGES" ]; then
        echo "Found archmacs-builder Docker images:"
        docker images | grep archmacs-builder
        if confirm "Remove archmacs-builder Docker images?"; then
            docker rmi -f $IMAGES
            echo "Docker images removed"
        fi
    else
        echo "No archmacs-builder Docker images found"
    fi
fi

# Clean build artifacts
echo "Checking for build artifacts..."
if [ -d "out" ] && [ "$(ls -A out)" ]; then
    echo "Found files in out/:"
    ls -lh out/
    if confirm "Remove all files in out/ directory?"; then
        rm -rf out/*
        echo "Build artifacts removed"
    fi
else
    echo "No build artifacts found"
fi

if [ -d "work" ] && [ "$(ls -A work)" ]; then
    echo "Found files in work/:"
    ls -lh work/
    if confirm "Remove all files in work/ directory?"; then
        rm -rf work/*
        echo "Work artifacts removed"
    fi
else
    echo "No work artifacts found"
fi

# Clean Terraform state
echo "Checking for Terraform resources..."
if [ -f "terraform/.terraform/terraform.tfstate" ]; then
    echo "Found Terraform state"
    if confirm "Destroy Terraform resources? (WARNING: This will destroy VMs)"; then
        cd terraform && terraform destroy -auto-approve
        echo "Terraform resources destroyed"
    fi
else
    echo "No Terraform resources found"
fi

# Clean Terraform cache
if [ -d "terraform/.terraform" ]; then
    echo "Found Terraform cache directory"
    if confirm "Remove Terraform cache?"; then
        rm -rf terraform/.terraform
        echo "Terraform cache removed"
    fi
fi

# Clean libvirt volumes
echo "Checking for libvirt volumes..."
if command -v virsh &>/dev/null; then
    POOLS=$(virsh pool-list --name 2>/dev/null | grep -E '(archmacs-iso|archmacs-vm)')
    if [ -n "$POOLS" ]; then
        echo "Found libvirt pools:"
        echo "$POOLS"
        if confirm "Remove archmacs libvirt pools and volumes?"; then
            for pool in $POOLS; do
                echo "Destroying pool: $pool"
                virsh pool-destroy "$pool" 2>/dev/null || true
                virsh pool-undefine "$pool" 2>/dev/null || true
                echo "Pool removed: $pool"
            done
        fi
    else
        echo "No archmacs libvirt pools found"
    fi
fi

# Clean libvirt networks
echo "Checking for libvirt networks..."
if command -v virsh &>/dev/null; then
    NETWORKS=$(virsh net-list --name 2>/dev/null | grep archmacs-test)
    if [ -n "$NETWORKS" ]; then
        echo "Found libvirt networks:"
        echo "$NETWORKS"
        if confirm "Remove archmacs libvirt networks?"; then
            for net in $NETWORKS; do
                echo "Destroying network: $net"
                virsh net-destroy "$net" 2>/dev/null || true
                virsh net-undefine "$net" 2>/dev/null || true
                echo "Network removed: $net"
            done
        fi
    else
        echo "No archmacs libvirt networks found"
    fi
fi

# Clean libvirt domains
echo "Checking for libvirt domains..."
if command -v virsh &>/dev/null; then
    DOMAINS=$(virsh list --name 2>/dev/null | grep archmacs)
    if [ -n "$DOMAINS" ]; then
        echo "Found libvirt domains:"
        echo "$DOMAINS"
        if confirm "Remove archmacs libvirt domains?"; then
            for dom in $DOMAINS; do
                echo "Destroying domain: $dom"
                virsh destroy "$dom" 2>/dev/null || true
                virsh undefine "$dom" 2>/dev/null || true
                echo "Domain removed: $dom"
            done
        fi
    else
        echo "No archmacs libvirt domains found"
    fi
fi

# Clean log files
echo "Checking for log files..."
if [ -d "logs" ] && [ "$(ls -A logs)" ]; then
    echo "Found log files:"
    ls -lh logs/
    if confirm "Remove all log files?"; then
        rm -rf logs/*
        echo "Log files removed"
    fi
else
    echo "No log files found"
fi

# Clean temporary files
echo "Checking for temporary files..."
TEMP_FILES=$(find . -name "*.tmp" -o -name "*.temp" -o -name "*.log" -o -name ".terraform.lock.hcl" 2>/dev/null | grep -v -E '(^./terraform|^.git)')
if [ -n "$TEMP_FILES" ]; then
    echo "Found temporary files:"
    echo "$TEMP_FILES"
    if confirm "Remove all temporary files?"; then
        find . -name "*.tmp" -delete 2>/dev/null || true
        find . -name "*.temp" -delete 2>/dev/null || true
        find . -name "*.log" -delete 2>/dev/null || true
        find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true
        echo "Temporary files removed"
    fi
else
    echo "No temporary files found"
fi

echo ""
echo "=== Cleanup Complete ==="
echo "Some resources may require manual cleanup:"
echo "1. Docker images not created by archmacs-builder"
echo "2. Libvirt resources not tagged with 'archmacs'"
echo "3. System-level packages if you want to uninstall them"
