#!/bin/bash
# ISO build wrapper script
# This script wraps the Docker-based build process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BUILD_TYPE="${BUILD_TYPE:-fast}"
KEEP_ALIVE="${KEEP_ALIVE:-false}"
CONTAINER_NAME="archmacs-builder"

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

# Function to print header
print_header() {
    local title="$1"
    echo ""
    echo "======================================================================"
    echo "$title"
    echo "======================================================================"
}

# Check if Docker is available
if ! command -v docker &>/dev/null; then
    print_status "error" "Docker is not installed"
    echo "Please run 'make setup' first"
    exit 1
fi

# Check if archiso-profile exists
if [ ! -d "archiso-profile" ]; then
    print_status "error" "archiso-profile directory not found"
    exit 1
fi

# Check if Docker image exists
if ! docker images | grep -q "archmacs-builder"; then
    print_header "Building Docker Image"
    docker build -t archmacs-builder ./docker
    print_status "ok" "Docker image built successfully"
fi

# Create necessary directories
mkdir -p out work

# Print build information
print_header "Archmacs ISO Build"
echo "Build type: $BUILD_TYPE"
echo "Keep alive: $KEEP_ALIVE"
echo "Output directory: $(pwd)/out"
echo "Work directory: $(pwd)/work"
echo ""

# Check if Docker is running
if ! docker ps &>/dev/null; then
    print_status "warning" "Docker may not be running"
    echo "Attempting to start Docker..."
    sudo systemctl start docker || true
fi

# Build the ISO
print_header "Building ISO"
print_status "info" "Starting container and build process..."

DOCKER_ARGS=(
    run
    --rm
    --privileged
    --name "$CONTAINER_NAME"
    -v "$(pwd)/archiso-profile:/build/archiso-profile"
    -v "$(pwd)/out:/build/out"
    -v "$(pwd)/work:/build/work"
    -e "BUILD_TYPE=$BUILD_TYPE"
    -e "KEEP_ALIVE=$KEEP_ALIVE"
)

if [ "$KEEP_ALIVE" = "true" ]; then
    DOCKER_ARGS+=(--interactive --tty)
fi

docker "${DOCKER_ARGS[@]}" archmacs-builder

# Check if build succeeded
if [ "$KEEP_ALIVE" = "true" ]; then
    print_status "ok" "Container kept alive for inspection"
    echo "Press Ctrl+C to exit the container"
else
    # Check if ISO was created
    if ls out/*.iso &>/dev/null; then
        print_header "Build Successful"
        echo "ISO files:"
        ls -lh out/*.iso
        echo ""
        
        # Calculate checksums
        print_status "info" "Calculating checksums..."
        cd out
        for iso in *.iso; do
            if [ -f "$iso" ]; then
                echo "SHA256: $iso"
                sha256sum "$iso" > "${iso}.sha256"
                cat "${iso}.sha256"
                echo ""
                
                echo "SHA512: $iso"
                sha512sum "$iso" > "${iso}.sha512"
                cat "${iso}.sha512"
                echo ""
            fi
        done
        cd ..
        
        print_status "ok" "Build complete!"
    else
        print_status "error" "Build failed - no ISO found"
        exit 1
    fi
fi

# Print summary
print_header "Summary"
echo "Build type: $BUILD_TYPE"
echo "ISO location: $(pwd)/out/"
if ls out/*.iso &>/dev/null; then
    echo "Latest ISO: $(ls -t out/*.iso | head -n 1)"
fi
echo "Logs: $(pwd)/work/"
