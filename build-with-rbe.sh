#!/bin/bash

# Build script for Chromium with RBE (Remote Build Execution)

set -e

echo "Setting up RBE environment for Chromium build..."

# RBE Configuration
export RBE_service="remotebuildexecution.googleapis.com:443"
export RBE_instance="projects/rbe-chromium-untrusted/instances/default_instance"

# Optional: Authentication (adjust based on your setup)
# export RBE_use_application_default_credentials=true
# or
# export RBE_service_account="/path/to/service-account-key.json"

# Siso configuration
export SISO_PROJECT="rbe-chromium-untrusted"
export SISO_ENABLE=1

# Increase parallel jobs for distributed build
export NINJA_JOBS=800

# Ensure depot_tools is in PATH if not already
if ! command -v gclient &> /dev/null; then
    echo "depot_tools not found in PATH. Please install depot_tools first."
    echo "git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git"
    echo "export PATH=\"\$PATH:/path/to/depot_tools\""
    exit 1
fi

# Use the RBE-enabled PKGBUILD
echo "Building with RBE-enabled PKGBUILD..."
makepkg -p PKGBUILD.rbe -si "$@"

echo "Build complete!"