#!/bin/bash
set -euo pipefail
#set -x

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


    # Get package info from existing PKGBUILD
    PKGNAME=$(grep '^pkgname=' PKGBUILD | cut -d'=' -f2)
    PKGVER=$(grep '^pkgver=' PKGBUILD | cut -d'=' -f2)
    PKGREL=$(grep '^pkgrel=' PKGBUILD | cut -d'=' -f2)
    FULL_VERSION="${PKGVER}-${PKGREL}"
    # Try to find existing package file, or create it from built binaries
    PACKAGE_FILE="${PKGNAME}-${PKGVER}-${PKGREL}-x86_64.pkg.tar.zst"
    PACKAGE_SIZE=0
    if [[ -f "$PACKAGE_FILE" ]]; then
    PACKAGE_SIZE=$(du -h "$PACKAGE_FILE" | cut -f1)
    fi 
    
    echo "   Package: $PKGNAME"
    echo "   Version: $FULL_VERSION"

if [[ "${ONLY_RELEASE:-0}" == "0" ]]; then

# Check if we should skip build
if [[ "${SKIP_BUILD:-0}" == "1" ]]; then
    echo "SKIP_BUILD=1 detected, skipping build steps..."
    
    

    if [[ ! -f "$PACKAGE_FILE" ]]; then
        echo "Package file not found: $PACKAGE_FILE"
        echo "Attempting to create package from existing built binaries..."
        
        # Increment pkgrel first
        echo "Incrementing pkgrel..."
        CURRENT_PKGREL=$(grep '^pkgrel=' PKGBUILD | cut -d'=' -f2)
        NEW_PKGREL=$((CURRENT_PKGREL + 1))
        sed -i "s/^pkgrel=.*/pkgrel=$NEW_PKGREL/" PKGBUILD
        echo "   Updated pkgrel from $CURRENT_PKGREL to $NEW_PKGREL"
        
        # Update package info after incrementing pkgrel
        PKGREL=$NEW_PKGREL
        FULL_VERSION="${PKGVER}-${PKGREL}"
        PACKAGE_FILE="${PKGNAME}-${PKGVER}-${PKGREL}-x86_64.pkg.tar.zst"
        
        # Run makepkg with SKIP_BUILD=1 to package existing built binaries
        echo "Running: SKIP_BUILD=1 makepkg -s --noconfirm"
        rm -vfr src/ pkg/
        SKIP_BUILD=1 makepkg -s --noconfirm
        
        if [[ ! -f "$PACKAGE_FILE" ]]; then
            echo "Error: Failed to create package file: $PACKAGE_FILE"
            exit 1
        fi
        echo "✅ Package created from existing built binaries"
        
        # Also build ARM64 package if PKGBUILD.arm64 exists
        if [[ -f "PKGBUILD.arm64" ]]; then
            echo "Building ARM64 package from existing binaries..."
            PACKAGE_FILE_ARM64="${PKGNAME}-${PKGVER}-${PKGREL}-aarch64.pkg.tar.zst"
            
            # Update pkgrel in PKGBUILD.arm64 to match
            sed -i "s/^pkgrel=.*/pkgrel=$NEW_PKGREL/" PKGBUILD.arm64
            
            rm -vfr src/ pkg/
            CARCH=aarch64 CC=aarch64-linux-gnu-gcc SKIP_BUILD=1 makepkg -s --noconfirm -p PKGBUILD.arm64
            
            if [[ -f "$PACKAGE_FILE_ARM64" ]]; then
                echo "✅ ARM64 package created: $PACKAGE_FILE_ARM64"
                PACKAGE_SIZE_ARM64=$(du -h "$PACKAGE_FILE_ARM64" | cut -f1)
            fi
        fi
    fi
    
    # Also check for ARM64 package even if x86_64 exists
    if [[ -f "PKGBUILD.arm64" ]]; then
        PACKAGE_FILE_ARM64="${PKGNAME}-${PKGVER}-${PKGREL}-aarch64.pkg.tar.zst"
        
        if [[ ! -f "$PACKAGE_FILE_ARM64" ]]; then
            echo "ARM64 package not found, building from existing binaries..."
            
            # Update pkgrel in PKGBUILD.arm64 to match
            sed -i "s/^pkgrel=.*/pkgrel=$PKGREL/" PKGBUILD.arm64
            
            rm -vfr src/ pkg/
            CARCH=aarch64 CC=aarch64-linux-gnu-gcc SKIP_BUILD=1 makepkg -s --noconfirm -p PKGBUILD.arm64
        fi
        
        if [[ -f "$PACKAGE_FILE_ARM64" ]]; then
            echo "✅ ARM64 package available: $PACKAGE_FILE_ARM64"
            PACKAGE_SIZE_ARM64=$(du -h "$PACKAGE_FILE_ARM64" | cut -f1)
            echo "   ARM64 Size: $PACKAGE_SIZE_ARM64"
        fi
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
    rm -vfr src/ pkg/
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
    
    # Also build ARM64 package if PKGBUILD.arm64 exists
    if [[ -f "PKGBUILD.arm64" ]]; then
        echo "Building ARM64 package..."
        PACKAGE_FILE_ARM64="${PKGNAME}-${PKGVER}-${PKGREL}-aarch64.pkg.tar.zst"
        
        # Update pkgrel in PKGBUILD.arm64 to match
        sed -i "s/^pkgrel=.*/pkgrel=$PKGREL/" PKGBUILD.arm64
        rm -vfr src/ pkg/
        CARCH=aarch64 CC=aarch64-linux-gnu-gcc makepkg -s --noconfirm -p PKGBUILD.arm64
        
        if [[ -f "$PACKAGE_FILE_ARM64" ]]; then
            echo "✅ ARM64 package built: $PACKAGE_FILE_ARM64"
            PACKAGE_SIZE_ARM64=$(du -h "$PACKAGE_FILE_ARM64" | cut -f1)
            echo "   ARM64 Size: $PACKAGE_SIZE_ARM64"
        fi
    fi
fi

fi

# Step 3: Create GitHub release (always runs)
echo "3. Creating GitHub release..."
RELEASE_TAG="v${FULL_VERSION}"
RELEASE_TITLE="Omarchy Chromium ${FULL_VERSION}"
RELEASE_NOTES="Automated release of Omarchy Chromium ${FULL_VERSION}

Based on Chromium ${PKGVER} with Omarchy theme patches.

**Installation:**
\`\`\`bash
# x86_64 (Intel/AMD):
wget https://github.com/${GITHUB_REPO}/releases/download/${RELEASE_TAG}/${PACKAGE_FILE}
sudo pacman -U ${PACKAGE_FILE}
${PACKAGE_FILE_ARM64:+
# aarch64 (ARM64):
wget https://github.com/${GITHUB_REPO}/releases/download/${RELEASE_TAG}/${PACKAGE_FILE_ARM64}
sudo pacman -U ${PACKAGE_FILE_ARM64}
}
\`\`\`

**Changes:**
- Updated to Chromium ${PKGVER}
- Applied Omarchy theme patches
- Built with bundled toolchain for maximum compatibility

**Package Info:**
- x86_64: ${PACKAGE_SIZE}${PACKAGE_SIZE_ARM64:+
- aarch64: ${PACKAGE_SIZE_ARM64}}
- Maintainer: Helmut Januschka <helmut@januschka.com>"

# Check if release already exists
if gh release view "$RELEASE_TAG" >/dev/null 2>&1; then
    echo "   Release $RELEASE_TAG already exists, deleting..."
    gh release delete "$RELEASE_TAG" --yes
fi

echo "   Creating release $RELEASE_TAG..."
# Create release with x86_64 package
gh release create "$RELEASE_TAG" \
    --title "$RELEASE_TITLE" \
    --notes "$RELEASE_NOTES" \
    "$PACKAGE_FILE"

# Upload ARM64 package if it exists
if [[ -f "${PACKAGE_FILE_ARM64:-}" ]]; then
    echo "   Uploading ARM64 package to release..."
    gh release upload "$RELEASE_TAG" "$PACKAGE_FILE_ARM64"
    echo "   ✓ ARM64 package uploaded"
fi

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

# Get download URLs
DOWNLOAD_URL_X86="https://github.com/${GITHUB_REPO}/releases/download/${RELEASE_TAG}/${PACKAGE_FILE}"
DOWNLOAD_URL_ARM64="https://github.com/${GITHUB_REPO}/releases/download/${RELEASE_TAG}/${PACKAGE_FILE_ARM64:-${PKGNAME}-${PKGVER}-${PKGREL}-aarch64.pkg.tar.zst}"

# Calculate checksums
echo "   Calculating checksums..."
cd "$CURRENT_DIR"
SHA256SUM_X86=$(sha256sum "$PACKAGE_FILE" | cut -d' ' -f1)
if [[ -f "${PACKAGE_FILE_ARM64:-}" ]]; then
    SHA256SUM_ARM64=$(sha256sum "$PACKAGE_FILE_ARM64" | cut -d' ' -f1)
else
    SHA256SUM_ARM64="SKIP"  # Will be skipped in sha256sums array
fi
cd "$AUR_DIR"

# Create/update PKGBUILD for binary package
cat > PKGBUILD << EOF
# Maintainer: Helmut Januschka <helmut@januschka.com>

pkgname=omarchy-chromium-bin
pkgver=${PKGVER}
pkgrel=${PKGREL}
pkgdesc="A web browser built for speed, simplicity, and security, with patches for Omarchy (binary package)"
arch=('x86_64' 'aarch64')
url="https://www.chromium.org/Home"
license=('BSD-3-Clause')
depends=('gtk3' 'nss' 'alsa-lib' 'xdg-utils' 'libxss' 'libcups' 'libgcrypt'
         'ttf-liberation' 'systemd' 'dbus' 'libpulse' 'pciutils' 'libva'
         'libffi' 'desktop-file-utils' 'hicolor-icon-theme')
provides=('chromium')
conflicts=('chromium' 'omarchy-chromium')

# Architecture-specific sources
source_x86_64=("${DOWNLOAD_URL_X86}")
source_aarch64=("${DOWNLOAD_URL_ARM64}")
sha256sums_x86_64=('${SHA256SUM_X86}')
sha256sums_aarch64=('${SHA256SUM_ARM64}')

package() {
    cd "\$srcdir"
    
    # Extract the package (filename varies by architecture)
    tar -xf ${PKGNAME}-${PKGVER}-${PKGREL}-\${CARCH}.pkg.tar.zst
    
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
