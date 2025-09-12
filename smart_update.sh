#!/bin/bash
set -euo pipefail

# smart_update.sh - Only builds and pushes to AUR when upstream changes are detected
# This ensures we only update the AUR package when there's a new Chromium release

echo "=== Omarchy Chromium Smart Update ==="
echo "This script only builds and releases when upstream Chromium has changes"
echo ""

# Check prerequisites
if [[ ! -f "check_upstream.sh" ]]; then
    echo "Error: check_upstream.sh not found"
    exit 1
fi

if [[ ! -f "update_to_upstream.sh" ]]; then
    echo "Error: update_to_upstream.sh not found"
    exit 1
fi

if [[ ! -f "do_update.sh" ]]; then
    echo "Error: do_update.sh not found"
    exit 1
fi

# Check for upstream changes
echo "Step 1: Checking for upstream changes..."
if ./check_upstream.sh; then
    echo ""
    echo "Step 2: Upstream changes detected, proceeding with update..."
    echo "========================================================"

    rm -vfr ~/omarchy-chromium-src/src/out/*
    
    # Update to latest upstream version
    echo ""
    echo "Running update_to_upstream.sh to sync with latest Chromium..."
    if ! ./update_to_upstream.sh; then
        echo "Error: Failed to update to upstream version"
        exit 1
    fi
    
    # Build and release
    echo ""
    echo "========================================================"
    echo "Running do_update.sh to build and release..."
    echo ""

    ./do_update.sh
    
    echo ""
    echo "=== Smart Update Complete! ==="
    echo "✓ Updated to latest upstream Chromium"
    echo "✓ Built and released new package"
    echo "✓ AUR package updated"
else
    echo ""
    echo "=== No Action Needed ==="
    echo "No upstream changes detected. Skipping build and release."
    echo ""
    echo "If you need to force a release (e.g., for patches or fixes):"
    echo "  ./do_update.sh    # This will increment pkgrel and release"
    echo ""
    echo "To check upstream status again:"
    echo "  ./check_upstream.sh"
fi
