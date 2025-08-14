#!/bin/bash
set -euo pipefail

# Configuration
CURRENT_DIR="$(pwd)"
AUR_DIR="$HOME/BUILD_LAB/omarchy-chromium-bin"
GITHUB_REPO="omacom-io/omarchy-chromium"

echo "=== Omarchy Chromium Automated Update & Release Script ==="

# Check prerequisites
command -v gh >/dev/null 2>&1 || { echo "Error: gh CLI not found. Install with: sudo pacman -S github-cli"; exit 1; }
command -v makepkg >/dev/null 2>&1 || { echo "Error: makepkg not found"; exit 1; }

# Check if we're in the right directory
if [[ ! -f "PKGBUILD" ]]; then
    echo "Error: PKGBUILD not found. Run this script from the package directory."
    exit 1
fi

if [[ ! -d "$AUR_DIR" ]]; then
    echo "Error: AUR directory not found at $AUR_DIR"
    echo "Please clone omarchy-chromium-bin AUR package first:"
    echo "git clone ssh://aur@aur.archlinux.org/omarchy-chromium-bin.git $AUR_DIR"
    exit 1
fi

# Check if we should skip build
if [[ "${SKIP_BUILD:-0}" == "1" ]]; then
    echo "SKIP_BUILD=1 detected, skipping build steps..."
    
    # Get package info from existing PKGBUILD
    PKGNAME=$(grep '^pkgname=' PKGBUILD | cut -d'=' -f2)
    PKGVER=$(grep '^pkgver=' PKGBUILD | cut -d'=' -f2)
    PKGREL=$(grep '^pkgrel=' PKGBUILD | cut -d'=' -f2)
    FULL_VERSION="${PKGVER}-${PKGREL}"
    
    echo "   Package: $PKGNAME"
    echo "   Version: $FULL_VERSION"
    
    # Find existing package file
    PACKAGE_FILE="${PKGNAME}-${PKGVER}-${PKGREL}-x86_64.pkg.tar.zst"
    if [[ ! -f "$PACKAGE_FILE" ]]; then
        echo "Error: Package file not found: $PACKAGE_FILE"
        echo "Please build the package first or remove SKIP_BUILD=1"
        exit 1
    fi
    
    echo "   Using existing package: $PACKAGE_FILE"
    PACKAGE_SIZE=$(du -h "$PACKAGE_FILE" | cut -f1)
    echo "   Size: $PACKAGE_SIZE"
else
    # Step 1: Increment pkgrel
    echo "1. Incrementing pkgrel..."
    CURRENT_PKGREL=$(grep '^pkgrel=' PKGBUILD | cut -d'=' -f2)
    NEW_PKGREL=$((CURRENT_PKGREL + 1))
    sed -i "s/^pkgrel=.*/pkgrel=$NEW_PKGREL/" PKGBUILD
    echo "   Updated pkgrel from $CURRENT_PKGREL to $NEW_PKGREL"
    
    # Get package info
    PKGNAME=$(grep '^pkgname=' PKGBUILD | cut -d'=' -f2)
    PKGVER=$(grep '^pkgver=' PKGBUILD | cut -d'=' -f2)
    PKGREL=$(grep '^pkgrel=' PKGBUILD | cut -d'=' -f2)
    FULL_VERSION="${PKGVER}-${PKGREL}"
    
    echo "   Package: $PKGNAME"
    echo "   Version: $FULL_VERSION"
    
    # Step 2: Build package
    echo "2. Building package..."
    makepkg -s --noconfirm
    
    # Find the built package
    PACKAGE_FILE="${PKGNAME}-${PKGVER}-${PKGREL}-x86_64.pkg.tar.zst"
    if [[ ! -f "$PACKAGE_FILE" ]]; then
        echo "Error: Built package not found: $PACKAGE_FILE"
        exit 1
    fi
    
    echo "   Built: $PACKAGE_FILE"
    PACKAGE_SIZE=$(du -h "$PACKAGE_FILE" | cut -f1)
    echo "   Size: $PACKAGE_SIZE"
fi

# Step 3: Create GitHub release (always runs)
echo "3. Creating GitHub release..."
RELEASE_TAG="v${FULL_VERSION}"
RELEASE_TITLE="Omarchy Chromium ${FULL_VERSION}"
RELEASE_NOTES="Automated release of Omarchy Chromium ${FULL_VERSION}

Based on Chromium ${PKGVER} with Omarchy theme patches.

**Installation:**
\`\`\`bash
# Download and install
wget https://github.com/${GITHUB_REPO}/releases/download/${RELEASE_TAG}/${PACKAGE_FILE}
sudo pacman -U ${PACKAGE_FILE}
\`\`\`

**Changes:**
- Updated to Chromium ${PKGVER}
- Applied Omarchy theme patches
- Built with bundled toolchain for maximum compatibility

**Package Info:**
- Size: ${PACKAGE_SIZE}
- Architecture: x86_64
- Maintainer: Helmut Januschka <helmut@januschka.com>"

# Check if release already exists
if gh release view "$RELEASE_TAG" >/dev/null 2>&1; then
    echo "   Release $RELEASE_TAG already exists, deleting..."
    gh release delete "$RELEASE_TAG" --yes
fi

echo "   Creating release $RELEASE_TAG..."
gh release create "$RELEASE_TAG" \
    --title "$RELEASE_TITLE" \
    --notes "$RELEASE_NOTES" \
    "$PACKAGE_FILE"

echo "   ✓ Release created: https://github.com/${GITHUB_REPO}/releases/tag/${RELEASE_TAG}"

# Step 4: Update AUR package (always runs)
echo "4. Updating AUR package..."
cd "$AUR_DIR"

# Make sure AUR repo is clean
if [[ -n "$(git status --porcelain)" ]]; then
    echo "   Warning: AUR directory has uncommitted changes. Stashing..."
    git stash
fi

# Pull latest changes
git pull

# Update PKGBUILD for binary package
echo "   Updating AUR PKGBUILD..."

# Get download URL
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${RELEASE_TAG}/${PACKAGE_FILE}"

# Calculate checksums
echo "   Calculating checksums..."
cd "$CURRENT_DIR"
SHA256SUM=$(sha256sum "$PACKAGE_FILE" | cut -d' ' -f1)
cd "$AUR_DIR"

# Create/update PKGBUILD for binary package
cat > PKGBUILD << EOF
# Maintainer: Helmut Januschka <helmut@januschka.com>

pkgname=omarchy-chromium-bin
pkgver=${PKGVER}
pkgrel=${PKGREL}
pkgdesc="A web browser built for speed, simplicity, and security, with patches for Omarchy (binary package)"
arch=('x86_64')
url="https://www.chromium.org/Home"
license=('BSD-3-Clause')
depends=('gtk3' 'nss' 'alsa-lib' 'xdg-utils' 'libxss' 'libcups' 'libgcrypt'
         'ttf-liberation' 'systemd' 'dbus' 'libpulse' 'pciutils' 'libva'
         'libffi' 'desktop-file-utils' 'hicolor-icon-theme')
provides=('chromium')
conflicts=('chromium' 'omarchy-chromium')
source=("${DOWNLOAD_URL}")
sha256sums=('${SHA256SUM}')

package() {
    cd "\$srcdir"
    
    # Extract the package
    tar -xf "${PACKAGE_FILE}"
    
    # Copy everything to the target directory
    cp -r usr "\$pkgdir/"
}
EOF

# Update .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# Commit and push to AUR
echo "   Committing to AUR..."
git add PKGBUILD .SRCINFO
git commit -m "Update to ${FULL_VERSION}

- Updated to Chromium ${PKGVER}
- Binary package from https://github.com/${GITHUB_REPO}/releases/tag/${RELEASE_TAG}
- Package size: ${PACKAGE_SIZE}"

echo "   Pushing to AUR..."
git push

echo "   ✓ AUR package updated"

# Return to original directory
cd "$CURRENT_DIR"

echo ""
echo "=== Update Complete! ==="
echo "✓ Package built: $PACKAGE_FILE"
echo "✓ GitHub release: https://github.com/${GITHUB_REPO}/releases/tag/${RELEASE_TAG}"
echo "✓ AUR package updated: https://aur.archlinux.org/packages/omarchy-chromium-bin"
echo ""
echo "Users can now install with:"
echo "  yay -S omarchy-chromium-bin"
echo "or download directly from GitHub releases."
