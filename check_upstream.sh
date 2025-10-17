#!/bin/bash
set -euo pipefail

# check_upstream.sh - Check if upstream Chromium has a newer version
# Returns 0 if update needed, 1 if already up-to-date

# Configuration
CHROMIUM_API_URL="https://chromiumdash.appspot.com/fetch_releases?channel=Stable&platform=Linux&num=1"

echo "=== Checking for upstream Chromium updates ==="

# Check if PKGBUILD exists in current directory
if [[ ! -f "PKGBUILD" ]]; then
    echo "Error: PKGBUILD not found in current directory"
    exit 2
fi

# Fetch upstream version from official Chromium API
echo "Fetching upstream version from Chromium Dashboard..."
UPSTREAM_VERSION=$(curl -s "$CHROMIUM_API_URL" | grep -o '"version":"[^"]*' | head -1 | cut -d'"' -f4)

if [[ -z "$UPSTREAM_VERSION" ]]; then
    echo "Error: Failed to fetch upstream version"
    exit 2
fi

# Get current version from our PKGBUILD
CURRENT_VERSION=$(grep '^pkgver=' PKGBUILD | cut -d'=' -f2)

if [[ -z "$CURRENT_VERSION" ]]; then
    echo "Error: Failed to read current version from PKGBUILD"
    exit 2
fi

echo "Current version:  $CURRENT_VERSION"
echo "Upstream version: $UPSTREAM_VERSION"

# Compare versions
if [[ "$UPSTREAM_VERSION" != "$CURRENT_VERSION" ]]; then
    echo ""
    echo "✓ Update available: $CURRENT_VERSION -> $UPSTREAM_VERSION"
    exit 0
else
    echo ""
    echo "✓ Already up-to-date with upstream"
    exit 1
fi