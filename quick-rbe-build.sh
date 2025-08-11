#!/bin/bash

# Quick build using existing chromium checkout

set -e

# Go to your chromium checkout
cd ~/chromium/src

# Set up RBE environment
export PATH="$HOME/depot_tools:$PATH"
export RBE_service="remotebuildexecution.googleapis.com:443"
export RBE_instance="projects/rbe-chromium-untrusted/instances/default_instance"
export SISO_PROJECT="rbe-chromium-untrusted"
export SISO_ENABLE=1

# Reset and checkout version
git checkout -f 139.0.7258.66

# Apply patches from this directory
PATCH_DIR="$(dirname "$0")"

# Apply all patches from PKGBUILD
echo "Applying patches..."
patch -Np1 -i "$PATCH_DIR/chromium-138-nodejs-version-check.patch"
patch -Np1 -i "$PATCH_DIR/compiler-rt-adjust-paths.patch"
patch -Np1 -i "$PATCH_DIR/increase-fortify-level.patch"
patch -Np1 -i "$PATCH_DIR/use-oauth2-client-switches-as-default.patch"
patch -Np1 -i "$PATCH_DIR/omarchy-theme-switcher.patch"

# Sync
cd ..
gclient sync --no-history --nohooks -D
cd src

# Configure (you can modify args.gn manually if needed)
gn gen out/Release --args='is_official_build=true use_remoteexec=true use_siso=true rbe_cfg="instance=projects/rbe-chromium-untrusted/instances/default_instance"'

# Build
autoninja -C out/Release chrome

echo "Build complete! Binaries in ~/chromium/src/out/Release/"