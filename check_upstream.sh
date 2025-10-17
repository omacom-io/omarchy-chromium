#!/bin/bash
set -euo pipefail

# check_upstream.sh - Check if GitHub release exists for latest Chromium version
# If not, update PKGBUILD files with new version
# Returns 0 if update needed, 1 if already up-to-date

# Configuration
CHROMIUM_API_URL="https://chromiumdash.appspot.com/fetch_releases?channel=Stable&platform=Linux&num=1"
GITHUB_REPO="omacom-io/omarchy-chromium"

echo "=== Checking for upstream Chromium updates ==="

# Fetch upstream version from official Chromium API
echo "Fetching latest Chromium version from Chromium Dashboard..."
UPSTREAM_VERSION=$(curl -s "$CHROMIUM_API_URL" | grep -o '"version":"[^"]*' | head -1 | cut -d'"' -f4)

if [[ -z "$UPSTREAM_VERSION" ]]; then
    echo "Error: Failed to fetch upstream Chromium version"
    exit 2
fi

echo "Latest Chromium version: $UPSTREAM_VERSION"

# Check if we have a GitHub release for this version
# The release tag format is v{version}-{pkgrel}, we'll check for any release starting with v{version}
echo "Checking GitHub releases for version $UPSTREAM_VERSION..."
EXISTING_RELEASE=$(gh release list -R "$GITHUB_REPO" --limit 100 | grep -o "v${UPSTREAM_VERSION}-[0-9]*" | head -1 || true)

if [[ -n "$EXISTING_RELEASE" ]]; then
    echo "✓ GitHub release found: $EXISTING_RELEASE"
    echo "✓ Already up-to-date with upstream"
    exit 1
fi

echo ""
echo "⚠ No GitHub release found for Chromium $UPSTREAM_VERSION"
echo "Updating PKGBUILD files..."

# Get current version from local PKGBUILD
CURRENT_VERSION=$(grep '^pkgver=' PKGBUILD | cut -d'=' -f2)
echo "Current PKGBUILD version: $CURRENT_VERSION"

# Update PKGBUILD
sed -i "s/^pkgver=.*/pkgver=$UPSTREAM_VERSION/" PKGBUILD
echo "✓ Updated PKGBUILD: $CURRENT_VERSION -> $UPSTREAM_VERSION"

# Update PKGBUILD.arm64 if it exists
if [[ -f "PKGBUILD.arm64" ]]; then
    sed -i "s/^pkgver=.*/pkgver=$UPSTREAM_VERSION/" PKGBUILD.arm64
    echo "✓ Updated PKGBUILD.arm64: $CURRENT_VERSION -> $UPSTREAM_VERSION"
fi

echo ""
echo "✓ PKGBUILD files updated to version $UPSTREAM_VERSION"
echo "  Next: Build and release packages"
exit 0