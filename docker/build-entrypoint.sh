#!/bin/bash
set -e

BUILD_TYPE=${BUILD_TYPE:-fast}

echo "=== Building Archmacs ISO ==="
echo "Build type: $BUILD_TYPE"

# Determine build command based on type
if [ "$BUILD_TYPE" = "full" ]; then
    echo "Performing full clean build..."
    rm -rf /build/work/*
    BUILD_CMD="mkarchiso -v -w /build/work -o /build/out ."
else
    echo "Performing fast build (with caching)..."
    BUILD_CMD="mkarchiso -v -w /build/work -o /build/out ."
fi

# Build the ISO
cd /build/archiso-profile
$BUILD_CMD

echo "=== ISO Build Complete ==="
echo "Output: $(ls -lh /build/out/*.iso 2>/dev/null || echo 'No ISO found')"

# Display build summary
ISO_FILES=$(ls /build/out/*.iso 2>/dev/null)
if [ -n "$ISO_FILES" ]; then
    echo "ISO file created successfully!"
    du -h /build/out/*.iso
else
    echo "ERROR: ISO file not found!"
    exit 1
fi

# Keep container running for inspection if needed
if [ "$KEEP_ALIVE" = "true" ]; then
    echo "Container kept alive. Press Ctrl+C to exit."
    sleep infinity
fi
