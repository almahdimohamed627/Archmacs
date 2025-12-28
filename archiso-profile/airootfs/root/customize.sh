#!/bin/bash
# Customization script for Archmacs live ISO
# This script runs during ISO build

set -e

echo "=== Customizing Archmacs Live ISO ==="

# Enable SSH server
echo "[1/6] Configuring SSH server..."
systemctl enable sshd

# Create .ssh directory for root
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# Generate SSH host keys
echo "[2/6] Generating SSH host keys..."
ssh-keygen -A

# Enable NetworkManager
echo "[3/6] Enabling NetworkManager..."
systemctl enable NetworkManager

# Set up autologin for convenience in live environment
echo "[4/6] Configuring autologin..."
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I 38400 linux
EOF

# Create test user for automated testing
echo "[5/6] Creating test user..."
useradd -m -G wheel -s /bin/bash archuser
echo "archuser:archuser" | chpasswd

# Enable sudo without password for test user
echo "archuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/archuser
chmod 440 /etc/sudoers.d/archuser

# Add test user SSH directory
mkdir -p /home/archuser/.ssh
chmod 700 /home/archuser/.ssh
chown archuser:archuser /home/archuser/.ssh

# Start services on boot
echo "[6/6] Configuring services..."
systemctl enable sshd.service

echo "=== Customization Complete ==="
