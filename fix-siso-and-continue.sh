#!/bin/bash

# Script to fix siso setup and continue build without re-downloading

set -e

echo "Fixing siso environment and continuing build..."

# Set up environment
export PATH="$HOME/depot_tools:$PATH"
export RBE_service="remotebuildexecution.googleapis.com:443"
export RBE_instance="projects/rbe-chromium-untrusted/instances/default_instance"
export SISO_PROJECT="rbe-chromium-untrusted"
export SISO_ENABLE=1
export NINJA_JOBS=800

# Find the chromium source directory
CHROMIUM_DIR=$(find src -maxdepth 1 -name "chromium-*" -type d | head -n1)

if [ -z "$CHROMIUM_DIR" ]; then
    echo "Error: Could not find chromium source directory"
    echo "Expected src/chromium-VERSION"
    exit 1
fi

echo "Found chromium source at: $CHROMIUM_DIR"
cd "$CHROMIUM_DIR"

# Set up siso environment
echo "Setting up siso environment..."
if [ -f "build/config/siso/chromium-rbe.star" ]; then
    echo "build/config/siso/chromium-rbe.star" > .sisoenv
else
    # Try to download siso config if missing
    echo "Downloading siso configuration..."
    gclient sync --no-history --nohooks -D
fi

# Continue the build directly
echo "Continuing build with autoninja..."
cd ../..
makepkg -p PKGBUILD.rbe -ef --noextract

echo "Build should continue from where it left off!"