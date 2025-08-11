#!/bin/bash

# Script to build Chromium package for distribution (without installing)

set -e

echo "Building Chromium package for distribution..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on Arch
if [ ! -f /etc/arch-release ]; then
    echo -e "${RED}Error: This script must be run on Arch Linux${NC}"
    exit 1
fi

# Install build dependencies if needed
echo -e "${YELLOW}Installing build dependencies...${NC}"
sudo pacman -S --needed base-devel python gn ninja clang lld gperf nodejs pipewire \
               rust rust-bindgen qt6-base java-runtime-headless git

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -f *.pkg.tar.zst
rm -f *.pkg.tar.zst.sig
rm -rf pkg/ src/

# Build package
echo -e "${YELLOW}Building package (this will take 4-8 hours)...${NC}"
echo -e "${YELLOW}The package will NOT be installed, only built.${NC}"

# Use -s to install deps, -c to clean after, -f to overwrite
makepkg -scf --noconfirm

# Check if build succeeded
if [ $? -eq 0 ]; then
    PACKAGE=$(ls -1 chromium-*.pkg.tar.zst 2>/dev/null | head -n1)
    if [ -n "$PACKAGE" ]; then
        SIZE=$(du -h "$PACKAGE" | cut -f1)
        echo -e "${GREEN}✓ Package built successfully!${NC}"
        echo -e "${GREEN}Package: $PACKAGE${NC}"
        echo -e "${GREEN}Size: $SIZE${NC}"
        echo ""
        echo "To install locally:"
        echo "  sudo pacman -U $PACKAGE"
        echo ""
        echo "To distribute:"
        echo "  1. Upload $PACKAGE to your hosting"
        echo "  2. Users install with: sudo pacman -U <url-to-package>"
        echo ""
        echo "To sign the package (recommended):"
        echo "  gpg --detach-sign $PACKAGE"
    else
        echo -e "${RED}✗ Build completed but package file not found${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi