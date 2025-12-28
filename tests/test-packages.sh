#!/bin/bash
# Test package installation and availability
# This can be run standalone or as part of the test suite

set -e

echo "=== Package Installation Tests ==="

# Array of packages to check
PACKAGES=(
    # Base system
    "bash"
    "zsh"
    "vim"
    "nano"
    "git"
    "curl"
    "wget"
    "htop"
    "tmux"
    "tree"
    
    # X11
    "xorg-server"
    "xorg-xinit"
    "dmenu"
    
    # Emacs
    "emacs"
    
    # Display
    "picom"
    "feh"
    
    # Network
    "openssh"
    "networkmanager"
    
    # Development
    "python"
    "nodejs"
    "npm"
    "go"
    
    # Additional
    "base-devel"
)

# Check each package
echo "Checking installed packages..."
FAILED=0
SUCCESS=0

for pkg in "${PACKAGES[@]}"; do
    if pacman -Q "$pkg" &>/dev/null; then
        echo "✓ $pkg is installed"
        SUCCESS=$((SUCCESS + 1))
    else
        echo "✗ $pkg is NOT installed"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "=== Summary ==="
echo "Total packages checked: ${#PACKAGES[@]}"
echo "Successfully installed: $SUCCESS"
echo "Failed: $FAILED"

if [ $FAILED -eq 0 ]; then
    echo "All required packages are installed!"
    exit 0
else
    echo "Some packages are missing!"
    exit 1
fi
