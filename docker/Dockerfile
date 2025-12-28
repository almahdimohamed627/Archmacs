FROM archlinux:latest

# Update system and install archiso with dependencies
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    archiso \
    git \
    bash \
    coreutils \
    squashfs-tools \
    qemu-headless \
    edk2-ovmf

# Create working directories
WORKDIR /build

# Copy build script
COPY docker/build-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/build-entrypoint.sh

# Copy customizations script
COPY archiso-profile/airootfs/root/customize.sh /usr/local/bin/customize.sh
RUN chmod +x /usr/local/bin/customize.sh

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/build-entrypoint.sh"]
