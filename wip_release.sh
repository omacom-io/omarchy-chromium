#!/bin/bash
set -euo pipefail

# WIP Release Script for Omarchy Chromium
# Builds from current patched source without resetting

# Configuration
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHROMIUM_SRC="$HOME/omarchy-chromium-src/src"
GITHUB_REPO="omacom-io/omarchy-chromium"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
step() { echo -e "${BLUE}[STEP]${NC} $*"; }

usage() {
    cat << EOF
WIP Release Script for Omarchy Chromium

Usage:
  $(basename "$0") [options] [suffix]

Options:
  --prepare       Reset source, checkout tag, apply all patches
  --skip-build    Use existing build, just publish release
  --dry-run       Show what would happen without doing it
  -h, --help      Show this help

Examples:
  $(basename "$0") --prepare              # Get clean slate with all patches
  $(basename "$0")                        # Build and release as wip-YYYYMMDD
  $(basename "$0") theme-fix              # Build and release as wip-theme-fix
  $(basename "$0") --skip-build test1     # Publish existing build as wip-test1

Workflow:
  1. $(basename "$0") --prepare           # Reset and apply patches
  2. # Make manual changes to ~/omarchy-chromium-src/src
  3. $(basename "$0") my-feature          # Build and release WIP

See WIP_WORKFLOW.md for detailed documentation.
EOF
    exit 0
}

# Parse arguments
PREPARE=0
SKIP_BUILD=0
DRY_RUN=0
SUFFIX=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prepare)
            PREPARE=1
            shift
            ;;
        --skip-build)
            SKIP_BUILD=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            error "Unknown option: $1"
            usage
            ;;
        *)
            SUFFIX="$1"
            shift
            ;;
    esac
done

# Check prerequisites
check_prereqs() {
    local missing=()
    command -v gh >/dev/null 2>&1 || missing+=("gh (github-cli)")
    command -v autoninja >/dev/null 2>&1 || missing+=("autoninja (depot_tools)")

    if [[ ! -f "$CURRENT_DIR/PKGBUILD" ]]; then
        error "PKGBUILD not found in $CURRENT_DIR"
        exit 1
    fi

    if [[ ! -d "$CHROMIUM_SRC" ]]; then
        error "Chromium source not found at $CHROMIUM_SRC"
        exit 1
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required tools: ${missing[*]}"
        exit 1
    fi
}

# Get version from PKGBUILD
get_version() {
    PKGNAME=$(grep '^pkgname=' "$CURRENT_DIR/PKGBUILD" | cut -d'=' -f2)
    PKGVER=$(grep '^pkgver=' "$CURRENT_DIR/PKGBUILD" | cut -d'=' -f2)

    # Generate WIP version
    if [[ -z "$SUFFIX" ]]; then
        SUFFIX=$(date +%Y%m%d)
    fi
    WIP_VERSION="${PKGVER}-wip-${SUFFIX}"
    RELEASE_TAG="v${WIP_VERSION}"
}

# Prepare mode: reset source and apply patches
do_prepare() {
    step "Preparing clean source with all patches..."

    cd "$CHROMIUM_SRC"

    info "Resetting source to HEAD..."
    if [[ "$DRY_RUN" == "1" ]]; then
        echo "  [DRY-RUN] git reset --hard HEAD"
        echo "  [DRY-RUN] git clean -fd"
    else
        git reset --hard HEAD
        git clean -fd
    fi

    info "Checking out version tag: $PKGVER"
    if [[ "$DRY_RUN" == "1" ]]; then
        echo "  [DRY-RUN] git checkout tags/$PKGVER"
    else
        git checkout "tags/$PKGVER" 2>/dev/null || {
            warn "Tag $PKGVER not found, staying on current HEAD"
        }
    fi

    info "Applying patches..."
    cd "$CURRENT_DIR"

    local patches=(
        "001-omarchy-theme-switcher.patch"
        "002-omarchy-policy-reload.patch"
        "003-policy-theme-fixes.patch"
        "004-policy-theme-accent.patch"
    )

    for patch in "${patches[@]}"; do
        if [[ -f "$patch" ]]; then
            info "Applying $patch..."
            if [[ "$DRY_RUN" == "1" ]]; then
                echo "  [DRY-RUN] git apply $patch"
            else
                cd "$CHROMIUM_SRC"
                # Handle patch 002 which has git format-patch header
                if [[ "$patch" == "002-omarchy-policy-reload.patch" ]]; then
                    tail -n +11 "$CURRENT_DIR/$patch" | git apply || {
                        warn "Failed to apply $patch (may already be applied)"
                    }
                else
                    git apply "$CURRENT_DIR/$patch" || {
                        warn "Failed to apply $patch (may already be applied)"
                    }
                fi
                cd "$CURRENT_DIR"
            fi
        else
            warn "Patch not found: $patch"
        fi
    done

    echo ""
    info "Source prepared successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Make your manual changes to: $CHROMIUM_SRC"
    echo "  2. Build and release with: ./wip_release.sh [suffix]"
    echo ""
}

# Build chromium
do_build() {
    step "Building Chromium (x86_64 only)..."

    cd "$CHROMIUM_SRC"

    if [[ "$DRY_RUN" == "1" ]]; then
        echo "  [DRY-RUN] autoninja -C out/Release chrome chrome_sandbox chromedriver"
        return
    fi

    # Check if out/Release exists with args.gn
    if [[ ! -f "out/Release/args.gn" ]]; then
        info "Setting up build directory..."
        mkdir -p out/Release
        cp "$CURRENT_DIR/chromium.args.gn" out/Release/args.gn
        gn gen out/Release
    fi

    info "Running autoninja..."
    autoninja -C out/Release chrome chrome_sandbox chromedriver

    info "Build complete!"
}

# Package the build
do_package() {
    step "Packaging build as $WIP_VERSION..."

    cd "$CURRENT_DIR"

    # Use makepkg with SKIP_BUILD to package existing binaries
    # But we need to temporarily modify version
    local PACKAGE_FILE="${PKGNAME}-${WIP_VERSION}-x86_64.pkg.tar.zst"

    if [[ "$DRY_RUN" == "1" ]]; then
        echo "  [DRY-RUN] Would create package: $PACKAGE_FILE"
        return
    fi

    # Create a temporary PKGBUILD.wip with WIP version
    info "Creating temporary PKGBUILD for WIP version..."
    cp PKGBUILD PKGBUILD.wip.tmp

    # Update version in temp PKGBUILD
    sed -i "s/^pkgver=.*/pkgver=${PKGVER}/" PKGBUILD.wip.tmp
    sed -i "s/^pkgrel=.*/pkgrel=wip.${SUFFIX}/" PKGBUILD.wip.tmp

    # Clean previous build artifacts
    rm -rf src/ pkg/

    # Run makepkg with SKIP_BUILD
    info "Running makepkg (using existing binaries)..."
    SKIP_BUILD=1 makepkg -p PKGBUILD.wip.tmp --noconfirm || {
        error "Package creation failed"
        rm -f PKGBUILD.wip.tmp
        exit 1
    }

    # Clean up temp PKGBUILD
    rm -f PKGBUILD.wip.tmp

    # Find the created package (name might vary slightly)
    PACKAGE_FILE=$(ls -1 ${PKGNAME}-*-x86_64.pkg.tar.zst 2>/dev/null | head -1)

    if [[ -z "$PACKAGE_FILE" || ! -f "$PACKAGE_FILE" ]]; then
        error "Package file not found after build"
        exit 1
    fi

    # Rename to WIP version if needed
    local EXPECTED_FILE="${PKGNAME}-${WIP_VERSION}-x86_64.pkg.tar.zst"
    if [[ "$PACKAGE_FILE" != "$EXPECTED_FILE" ]]; then
        mv "$PACKAGE_FILE" "$EXPECTED_FILE"
        PACKAGE_FILE="$EXPECTED_FILE"
    fi

    PACKAGE_SIZE=$(du -h "$PACKAGE_FILE" | cut -f1)
    info "Package created: $PACKAGE_FILE ($PACKAGE_SIZE)"
}

# Create GitHub pre-release
do_release() {
    step "Creating GitHub pre-release..."

    cd "$CURRENT_DIR"

    # Find the package file
    PACKAGE_FILE=$(ls -1 ${PKGNAME}-*wip*-x86_64.pkg.tar.zst 2>/dev/null | head -1)

    if [[ -z "$PACKAGE_FILE" || ! -f "$PACKAGE_FILE" ]]; then
        # Try standard naming
        PACKAGE_FILE="${PKGNAME}-${WIP_VERSION}-x86_64.pkg.tar.zst"
    fi

    if [[ ! -f "$PACKAGE_FILE" ]]; then
        error "Package file not found: $PACKAGE_FILE"
        error "Run without --skip-build to create it first"
        exit 1
    fi

    PACKAGE_SIZE=$(du -h "$PACKAGE_FILE" | cut -f1)

    local RELEASE_TITLE="WIP: Omarchy Chromium ${WIP_VERSION}"
    local RELEASE_NOTES="## WIP/Beta Release

> **Warning**: This is a work-in-progress release for testing purposes only.
> It may contain bugs or incomplete features.

### Version
- Base: Chromium ${PKGVER}
- WIP Tag: ${SUFFIX}

### Installation (Testing Only)
\`\`\`bash
# Download and install
wget https://github.com/${GITHUB_REPO}/releases/download/${RELEASE_TAG}/${PACKAGE_FILE}
sudo pacman -U ${PACKAGE_FILE}
\`\`\`

### Package Info
- Architecture: x86_64
- Size: ${PACKAGE_SIZE}

### Feedback
Please report issues at: https://github.com/${GITHUB_REPO}/issues

---
*Built from local source with manual patches*"

    if [[ "$DRY_RUN" == "1" ]]; then
        echo "  [DRY-RUN] Would create release:"
        echo "    Tag: $RELEASE_TAG"
        echo "    Title: $RELEASE_TITLE"
        echo "    Package: $PACKAGE_FILE ($PACKAGE_SIZE)"
        echo "    Pre-release: yes"
        return
    fi

    # Delete existing release if it exists
    if gh release view "$RELEASE_TAG" >/dev/null 2>&1; then
        warn "Release $RELEASE_TAG already exists, deleting..."
        gh release delete "$RELEASE_TAG" --yes
    fi

    info "Creating pre-release: $RELEASE_TAG"
    gh release create "$RELEASE_TAG" \
        --prerelease \
        --title "$RELEASE_TITLE" \
        --notes "$RELEASE_NOTES" \
        "$PACKAGE_FILE"

    echo ""
    info "WIP release created!"
    echo "  URL: https://github.com/${GITHUB_REPO}/releases/tag/${RELEASE_TAG}"
    echo ""
}

# Main
main() {
    echo "=== Omarchy Chromium WIP Release ==="
    echo ""

    check_prereqs
    get_version

    info "Package: $PKGNAME"
    info "Base version: $PKGVER"
    info "WIP version: $WIP_VERSION"
    info "Release tag: $RELEASE_TAG"
    echo ""

    if [[ "$PREPARE" == "1" ]]; then
        do_prepare
        exit 0
    fi

    if [[ "$SKIP_BUILD" == "0" ]]; then
        do_build
        do_package
    else
        info "Skipping build (--skip-build)"
    fi

    do_release

    echo ""
    echo "=== WIP Release Complete ==="
    if [[ "$DRY_RUN" == "0" ]]; then
        echo ""
        echo "Users can test with:"
        echo "  wget https://github.com/${GITHUB_REPO}/releases/download/${RELEASE_TAG}/${PKGNAME}-${WIP_VERSION}-x86_64.pkg.tar.zst"
        echo "  sudo pacman -U ${PKGNAME}-${WIP_VERSION}-x86_64.pkg.tar.zst"
    fi
}

main "$@"
