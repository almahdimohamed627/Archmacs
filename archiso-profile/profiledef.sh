#!/usr/bin/env bash

iso_name="archmacs"
iso_label="ARCHMACS"
iso_version="$(date +%Y.%m.%d)"
iso_publisher="Archmacs"
iso_application="Archmacs Linux with EXWM + Spacemacs"
install_dir="arch"
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-x64.systemd-boot' 'uefi-x64.grub.esp')
arch="x86_64"
pacman_conf="/etc/pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.ssh"]="0:0:700"
  ["/root/.ssh/authorized_keys"]="0:0:600"
)
