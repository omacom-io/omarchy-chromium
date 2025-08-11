#!/bin/bash

# Clean build script for Chromium with RBE

set -e

echo "Cleaning up any previous build attempts..."

# Clean up makepkg directories
rm -rf src/ pkg/ chromium-build/

# Set up RBE environment
export RBE_service="remotebuildexecution.googleapis.com:443"
export RBE_instance="projects/rbe-chromium-untrusted/instances/default_instance"
export SISO_PROJECT="rbe-chromium-untrusted"
export SISO_ENABLE=1
export NINJA_JOBS=800
export PATH="$HOME/depot_tools:$PATH"

echo "Starting clean build with full RBE support..."
makepkg -p PKGBUILD.rbe-full -Ccsi

echo "Build complete!"