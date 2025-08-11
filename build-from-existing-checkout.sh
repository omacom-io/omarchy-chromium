#!/bin/bash

# Build Chromium package using existing checkout at ~/chromium/src

set -e

# Configuration
CHROMIUM_SRC="$HOME/chromium/src"
CHROMIUM_VERSION="139.0.7258.66"
PACKAGE_DIR="$PWD"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Building Chromium from existing checkout at $CHROMIUM_SRC${NC}"

# Verify checkout exists
if [ ! -d "$CHROMIUM_SRC" ]; then
    echo "Error: Chromium checkout not found at $CHROMIUM_SRC"
    exit 1
fi

# Set up environment
export PATH="$HOME/depot_tools:$PATH"
export RBE_service="remotebuildexecution.googleapis.com:443"
export RBE_instance="projects/rbe-chromium-untrusted/instances/default_instance"
export SISO_PROJECT="rbe-chromium-untrusted"
export SISO_ENABLE=1

cd "$CHROMIUM_SRC"

# Reset to clean state and checkout version
echo -e "${YELLOW}Resetting to version $CHROMIUM_VERSION...${NC}"
git fetch --depth=1 origin tag $CHROMIUM_VERSION
git checkout -f $CHROMIUM_VERSION
git clean -fd

# Apply patches
echo -e "${YELLOW}Applying patches...${NC}"

# Apply all patches from PKGBUILD
echo "Applying chromium-138-nodejs-version-check.patch..."
patch -Np1 -i "$PACKAGE_DIR/chromium-138-nodejs-version-check.patch"

echo "Applying compiler-rt-adjust-paths.patch..."
patch -Np1 -i "$PACKAGE_DIR/compiler-rt-adjust-paths.patch"

echo "Applying increase-fortify-level.patch..."
patch -Np1 -i "$PACKAGE_DIR/increase-fortify-level.patch"

echo "Applying use-oauth2-client-switches-as-default.patch..."
patch -Np1 -i "$PACKAGE_DIR/use-oauth2-client-switches-as-default.patch"

echo "Applying omarchy-theme-switcher.patch..."
patch -Np1 -i "$PACKAGE_DIR/omarchy-theme-switcher.patch"

# Apply sed fixes from PKGBUILD
echo -e "${YELLOW}Applying additional fixes...${NC}"

# Allow building against system libraries in official builds
sed -i 's/OFFICIAL_BUILD/GOOGLE_CHROME_BUILD/' \
    tools/generate_shim_headers/generate_shim_headers.py

# https://crbug.com/893950
sed -i -e 's/\<xmlMalloc\>/malloc/' -e 's/\<xmlFree\>/free/' \
       -e '1i #include <cstdlib>' \
    third_party/blink/renderer/core/xml/*.cc \
    third_party/blink/renderer/core/xml/parser/xml_document_parser.cc \
    third_party/libxml/chromium/*.cc

# Sync dependencies
echo -e "${YELLOW}Running gclient sync...${NC}"
cd ..
gclient sync --no-history --with_branch_heads --with_tags
cd src

# Create GN args for Release build
echo -e "${YELLOW}Configuring build with GN...${NC}"
mkdir -p out/Release
cat > out/Release/args.gn << 'EOF'
# Build arguments for Arch Linux Chromium package
is_official_build = true
symbol_level = 0
treat_warnings_as_errors = false
fatal_linker_warnings = false
disable_fieldtrial_testing_config = true
blink_enable_generated_code_formatting = false
ffmpeg_branding = "Chrome"
proprietary_codecs = true
rtc_use_pipewire = true
link_pulseaudio = true
use_custom_libcxx = true
use_sysroot = false
use_system_libffi = true
enable_hangout_services_extension = true
enable_widevine = true
enable_nacl = false
use_qt6 = true
google_api_key = "AIzaSyDwr302FpOSkGRpLlUpPThNTDPbXcIn_FM"

# RBE configuration
use_remoteexec = true
use_siso = true
rbe_cfg = "instance=projects/rbe-chromium-untrusted/instances/default_instance"

# System libraries
use_system_libxml = true
use_system_fontconfig = true
use_system_libpng = true
use_system_harfbuzz = true
use_system_libjpeg = true
use_system_freetype = true
use_system_brotli = true
use_system_flac = true
use_system_opus = true
use_system_libwebp = true

# Clang configuration
clang_base_path = "/usr"
clang_use_chrome_plugins = false
rust_sysroot_absolute = "/usr"
rust_bindgen_root = "/usr"
EOF

# Generate build files
gn gen out/Release

# Build
echo -e "${YELLOW}Building with autoninja...${NC}"
autoninja -C out/Release chrome chrome_sandbox chromedriver.unstripped

# Create package structure
echo -e "${YELLOW}Creating Arch package...${NC}"
cd "$PACKAGE_DIR"
mkdir -p pkg/chromium-rbe/usr/lib/chromium
mkdir -p pkg/chromium-rbe/usr/bin
mkdir -p pkg/chromium-rbe/usr/share/{applications,man/man1,licenses/chromium,icons/hicolor}

# Copy binaries
cp "$CHROMIUM_SRC/out/Release/chrome" pkg/chromium-rbe/usr/lib/chromium/chromium
cp "$CHROMIUM_SRC/out/Release/chromedriver.unstripped" pkg/chromium-rbe/usr/bin/chromedriver
install -m4755 "$CHROMIUM_SRC/out/Release/chrome_sandbox" pkg/chromium-rbe/usr/lib/chromium/chrome-sandbox

# Copy resources
cp "$CHROMIUM_SRC/out/Release/"*.pak pkg/chromium-rbe/usr/lib/chromium/
cp "$CHROMIUM_SRC/out/Release/"*.so pkg/chromium-rbe/usr/lib/chromium/ 2>/dev/null || true
cp "$CHROMIUM_SRC/out/Release/"*.so.* pkg/chromium-rbe/usr/lib/chromium/ 2>/dev/null || true
cp "$CHROMIUM_SRC/out/Release/chrome_crashpad_handler" pkg/chromium-rbe/usr/lib/chromium/
cp "$CHROMIUM_SRC/out/Release/v8_context_snapshot.bin" pkg/chromium-rbe/usr/lib/chromium/
cp "$CHROMIUM_SRC/out/Release/icudtl.dat" pkg/chromium-rbe/usr/lib/chromium/
cp "$CHROMIUM_SRC/out/Release/vk_swiftshader_icd.json" pkg/chromium-rbe/usr/lib/chromium/

# Copy locales
mkdir -p pkg/chromium-rbe/usr/lib/chromium/locales
cp "$CHROMIUM_SRC/out/Release/locales/"*.pak pkg/chromium-rbe/usr/lib/chromium/locales/

# Desktop file
cp "$CHROMIUM_SRC/chrome/installer/linux/common/desktop.template" \
   pkg/chromium-rbe/usr/share/applications/chromium.desktop
sed -i -e 's/@@MENUNAME@@/Chromium/g' \
       -e 's/@@PACKAGE@@/chromium/g' \
       -e 's/@@USR_BIN_SYMLINK_NAME@@/chromium/g' \
       pkg/chromium-rbe/usr/share/applications/chromium.desktop

# Icons
for size in 24 48 64 128 256; do
    mkdir -p "pkg/chromium-rbe/usr/share/icons/hicolor/${size}x${size}/apps"
    cp "$CHROMIUM_SRC/chrome/app/theme/chromium/product_logo_$size.png" \
       "pkg/chromium-rbe/usr/share/icons/hicolor/${size}x${size}/apps/chromium.png"
done

# License
cp "$CHROMIUM_SRC/LICENSE" pkg/chromium-rbe/usr/share/licenses/chromium/

# Create launcher symlink
ln -sf /usr/lib/chromium/chromium pkg/chromium-rbe/usr/bin/chromium

# Create package
echo -e "${YELLOW}Creating package archive...${NC}"
cd pkg/chromium-rbe
tar -cf - * | zstd -c -T0 > ../../chromium-rbe-${CHROMIUM_VERSION}-1-x86_64.pkg.tar.zst
cd ../..

echo -e "${GREEN}✓ Package created: chromium-rbe-${CHROMIUM_VERSION}-1-x86_64.pkg.tar.zst${NC}"
echo -e "${GREEN}Install with: sudo pacman -U chromium-rbe-${CHROMIUM_VERSION}-1-x86_64.pkg.tar.zst${NC}"