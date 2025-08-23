#!/bin/bash
set -euo pipefail

# Configuration
ARCH_PKGBUILD_URL="https://gitlab.archlinux.org/archlinux/packaging/packages/chromium/-/raw/main/PKGBUILD"
CHROMIUM_SRC_DIR="$HOME/omarchy-chromium-src"
CURRENT_DIR="$(pwd)"

echo "=== Omarchy Chromium Upstream Update Script ==="

# Step 1: Fetch upstream PKGBUILD and extract version
echo "1. Fetching upstream PKGBUILD to get latest version..."
TEMP_PKGBUILD=$(mktemp)
curl -s "$ARCH_PKGBUILD_URL" -o "$TEMP_PKGBUILD"

# Extract pkgver from upstream PKGBUILD
UPSTREAM_VERSION=$(grep '^pkgver=' "$TEMP_PKGBUILD" | cut -d'=' -f2)
echo "   Upstream version: $UPSTREAM_VERSION"

# Get current version from our PKGBUILD
CURRENT_VERSION=$(grep '^pkgver=' PKGBUILD | cut -d'=' -f2)
echo "   Current version:  $CURRENT_VERSION"

if [[ "$UPSTREAM_VERSION" == "$CURRENT_VERSION" ]]; then
    echo "   Already up to date!"
    rm -f "$TEMP_PKGBUILD"
    exit 0
fi

# Step 2: Update our PKGBUILD files
echo "2. Updating PKGBUILD files from $CURRENT_VERSION to $UPSTREAM_VERSION..."

# Update main PKGBUILD
sed -i "s/^pkgver=.*/pkgver=$UPSTREAM_VERSION/" PKGBUILD
sed -i "s/^pkgrel=.*/pkgrel=1/" PKGBUILD
echo "   PKGBUILD updated!"

# Update ARM64 PKGBUILD if it exists
if [[ -f "PKGBUILD.arm64" ]]; then
    sed -i "s/^pkgver=.*/pkgver=$UPSTREAM_VERSION/" PKGBUILD.arm64
    sed -i "s/^pkgrel=.*/pkgrel=1/" PKGBUILD.arm64
    echo "   PKGBUILD.arm64 updated!"
fi

# Step 3: Update Chromium source checkout
echo "3. Updating Chromium source checkout..."

if [[ ! -d "$CHROMIUM_SRC_DIR/src" ]]; then
    echo "   ERROR: Chromium source directory not found at $CHROMIUM_SRC_DIR/src"
    echo "   Please run 'makepkg -s' first to create the initial checkout"
    exit 1
fi

cd "$CHROMIUM_SRC_DIR/src"

# Setup depot_tools if not in PATH
if ! command -v git &> /dev/null; then
    echo "   ERROR: git not found in PATH"
    exit 1
fi

if ! command -v gclient &> /dev/null; then
    if [[ -d "$HOME/depot_tools" ]]; then
        export PATH="$HOME/depot_tools:$PATH"
    else
        echo "   ERROR: depot_tools not found. Please install depot_tools first."
        exit 1
    fi
fi

echo "   Stashing any local changes..."
git stash push -m "Auto-stash before update to $UPSTREAM_VERSION" || true

echo "   Fetching latest tags..."
git fetch --tags --depth=1 origin refs/tags/$UPSTREAM_VERSION:refs/tags/$UPSTREAM_VERSION 2>/dev/null || {
    echo "   Tag $UPSTREAM_VERSION not found, trying full fetch..."
    git fetch --tags
}

echo "   Checking out version $UPSTREAM_VERSION..."
git checkout "$UPSTREAM_VERSION"

echo "   Updating .gclient for PGO profiles..."
cd "$CHROMIUM_SRC_DIR"
cat > .gclient <<EOF
solutions = [
  {
    "name": "src",
    "url": "https://chromium.googlesource.com/chromium/src.git",
    "managed": False,
    "custom_deps": {},
    "custom_vars": {
      "checkout_pgo_profiles": True,
    },
  },
]
EOF

echo "   Syncing dependencies..."
gclient sync --nohooks --no-history --shallow --delete_unversioned_trees

cd src
echo "   Running gclient runhooks..."
gclient runhooks

echo "   Creating partition_alloc symlink..."
ln -sf base/allocator/partition_allocator/src/partition_alloc partition_alloc

# Step 4: Apply patches
echo "4. Applying compatible patches..."
cd "$CHROMIUM_SRC_DIR/src"

# List of patches to skip (same as PKGBUILD logic)
SKIP_PATCHES=(
    "compiler-rt-adjust-paths.patch"
    "chromium-138-nodejs-version-check.patch" 
    "increase-fortify-level.patch"
)

for patch in "$CURRENT_DIR"/*.patch; do
    if [[ -f "$patch" ]]; then
        patch_name=$(basename "$patch")
        
        # Check if patch should be skipped
        skip=false
        for skip_patch in "${SKIP_PATCHES[@]}"; do
            if [[ "$patch_name" == "$skip_patch" ]]; then
                echo "   Skipping $patch_name (incompatible with bundled toolchain)"
                skip=true
                break
            fi
        done
        
        if [[ "$skip" == "false" ]]; then
            echo "   Applying $patch_name..."
            if patch -Np1 -i "$patch" --dry-run &>/dev/null; then
                patch -Np1 -i "$patch"
                echo "     ✓ Applied successfully"
            else
                echo "     ⚠ Patch failed or already applied, skipping"
            fi
        fi
    fi
done

# Clean any existing build
echo "5. Cleaning previous build..."
rm -rf out/Release

# Return to original directory
cd "$CURRENT_DIR"

echo ""
echo "=== Update Complete! ==="
echo "Updated from $CURRENT_VERSION to $UPSTREAM_VERSION"
echo ""
echo "Files updated:"
echo "- PKGBUILD"
if [[ -f "PKGBUILD.arm64" ]]; then
    echo "- PKGBUILD.arm64"
fi
echo ""
echo "Next steps:"
echo "1. Review any changes: git diff"
echo "2. Build: makepkg -s" 
echo "3. Test the build"
echo ""
echo "The Chromium source is ready at: $CHROMIUM_SRC_DIR/src"

rm -f "$TEMP_PKGBUILD"