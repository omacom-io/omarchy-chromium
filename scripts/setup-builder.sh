#!/bin/bash
set -euo pipefail

# Omarchy Chromium Builder Setup Script
# This script sets up a fresh Arch Linux machine for building Omarchy Chromium

echo "🔧 Omarchy Chromium Builder Setup"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Arch Linux
if ! grep -q "Arch Linux" /etc/os-release 2>/dev/null; then
    log_error "This script is designed for Arch Linux only!"
    exit 1
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    log_error "Do not run this script as root! Run as regular user with sudo access."
    exit 1
fi

# Check for sudo access
if ! sudo -n true 2>/dev/null; then
    log_info "This script requires sudo access for package installation."
    sudo -v
fi

echo ""
log_info "Setting up Omarchy Chromium builder environment..."
echo ""

# Step 1: Update system
log_info "1/8 Updating system packages..."
sudo pacman -Syu --noconfirm
log_success "System updated"

# Step 2: Install essential packages
log_info "2/8 Installing core build tools..."
sudo pacman -S --needed --noconfirm \
    base-devel git python gn ninja clang lld rust rust-bindgen \
    nodejs npm java-runtime-headless gperf pipewire qt6-base \
    curl wget unzip tar xz
log_success "Core build tools installed"

# Step 3: Install Chromium dependencies
log_info "3/8 Installing Chromium runtime dependencies..."
sudo pacman -S --needed --noconfirm \
    gtk3 gtk4 nss alsa-lib xdg-utils libxss libcups libgcrypt \
    ttf-liberation systemd dbus libpulse pciutils libva libffi \
    desktop-file-utils hicolor-icon-theme
log_success "Chromium dependencies installed"

# Step 4: Install additional libraries
log_info "4/8 Installing additional system libraries..."
sudo pacman -S --needed --noconfirm \
    fontconfig freetype2 harfbuzz libjpeg-turbo libpng libwebp \
    libxml2 libxslt opus zlib minizip brotli flac mesa \
    vulkan-mesa-layers vulkan-tools gstreamer gst-plugins-base \
    gst-plugins-good ca-certificates gnupg
log_success "Additional libraries installed"

# Step 5: Install development tools
log_info "5/8 Installing development and debugging tools..."
sudo pacman -S --needed --noconfirm \
    github-cli openssh strace gdb valgrind htop neofetch
log_success "Development tools installed"

# Step 6: Setup depot_tools
log_info "6/8 Setting up depot_tools..."
if [[ ! -d "$HOME/depot_tools" ]]; then
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "$HOME/depot_tools"
    log_success "depot_tools cloned"
else
    log_warning "depot_tools already exists, skipping clone"
fi

# Add depot_tools to PATH
SHELL_RC=""
if [[ -n "${BASH_VERSION:-}" ]]; then
    SHELL_RC="$HOME/.bashrc"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
    SHELL_RC="$HOME/.zshrc"
else
    SHELL_RC="$HOME/.profile"
fi

if ! grep -q "depot_tools" "$SHELL_RC" 2>/dev/null; then
    echo 'export PATH="$HOME/depot_tools:$PATH"' >> "$SHELL_RC"
    log_success "depot_tools added to PATH in $SHELL_RC"
else
    log_warning "depot_tools already in PATH"
fi

# Export for current session
export PATH="$HOME/depot_tools:$PATH"

# Step 7: Setup Git configuration optimizations
log_info "7/8 Configuring Git for large repositories..."
git config --global core.preloadindex true
git config --global core.fscache true
git config --global gc.auto 256
git config --global core.compression 0
git config --global protocol.version 2
git config --global fetch.parallel 8
git config --global http.postBuffer 524288000
git config --global core.packedGitLimit 512m
git config --global core.packedGitWindowSize 512m
git config --global pack.threads 0
git config --global core.commitGraph true
git config --global gc.writeCommitGraph true
git config --global fetch.writeCommitGraph true
git config --global core.untrackedCache true
git config --global feature.manyFiles true
git config --global index.threads true
git config --global index.version 4
log_success "Git optimizations configured"

# Step 8: Setup build environment variables
log_info "8/8 Setting up build environment..."
BUILD_ENV_SETUP="
# Chromium build environment
export NINJA_STATUS=\"[%f/%t (%p%%) %o/s %es] \"
export CCACHE_SLOPPINESS=\"time_macros\"
export GOMA_FALLBACK_ON_AUTH_FAILURE=true
export RUSTC_BOOTSTRAP=1
export PATH=\"\$HOME/depot_tools:\$PATH\"
"

if ! grep -q "NINJA_STATUS" "$SHELL_RC" 2>/dev/null; then
    echo "$BUILD_ENV_SETUP" >> "$SHELL_RC"
    log_success "Build environment variables added to $SHELL_RC"
else
    log_warning "Build environment already configured"
fi

# Setup system limits
log_info "Configuring system limits for large builds..."
if ! grep -q "65536" /etc/security/limits.conf 2>/dev/null; then
    echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf >/dev/null
    echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf >/dev/null
    log_success "File descriptor limits increased"
else
    log_warning "File descriptor limits already configured"
fi

if ! grep -q "vm.max_map_count" /etc/sysctl.conf 2>/dev/null; then
    echo "vm.max_map_count=2147483647" | sudo tee -a /etc/sysctl.conf >/dev/null
    log_success "Virtual memory limits configured"
else
    log_warning "Virtual memory limits already configured"
fi

# Create directory structure
log_info "Creating directory structure..."
mkdir -p "$HOME/BUILD_LAB"
log_success "Build directories created"

# Check available space
AVAILABLE_SPACE=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
if [[ $AVAILABLE_SPACE -lt 150 ]]; then
    log_warning "Only ${AVAILABLE_SPACE}GB available space. Recommended: 150GB+"
    log_warning "Consider freeing up space before building Chromium"
else
    log_success "Sufficient disk space available: ${AVAILABLE_SPACE}GB"
fi

echo ""
echo "=========================================="
log_success "🎉 Omarchy Chromium builder setup complete!"
echo "=========================================="
echo ""

echo "📋 Next steps:"
echo ""
echo "1. 🔑 Setup SSH keys:"
echo "   ssh-keygen -t ed25519 -C \"your-email@example.com\""
echo "   # Add public key to GitHub and AUR"
echo ""
echo "2. 🏗️ Clone repositories:"
echo "   git clone https://github.com/omacom-io/omarchy-chromium.git ~/omarchy-chromium"
echo "   git clone ssh://aur@aur.archlinux.org/omarchy-chromium-bin.git ~/BUILD_LAB/omarchy-chromium-bin"
echo ""
echo "3. 🔐 Authenticate with GitHub:"
echo "   gh auth login"
echo ""
echo "4. ⚡ Source your shell config to load new environment:"
echo "   source $SHELL_RC"
echo ""
echo "5. 🚀 Test the setup:"
echo "   cd ~/omarchy-chromium"
echo "   makepkg -s  # This will take 4-6 hours for first build"
echo ""

echo "📊 System info:"
echo "   Packages installed: $(pacman -Q | wc -l)"
echo "   Available space: ${AVAILABLE_SPACE}GB"
echo "   CPU cores: $(nproc)"
echo "   RAM: $(free -h | awk '/^Mem:/ {print $2}')"
echo ""

echo "📖 Documentation:"
echo "   Main README: https://github.com/omacom-io/omarchy-chromium/blob/master/README.md"
echo "   Machine prep: https://github.com/omacom-io/omarchy-chromium/blob/master/PREPARE_MACHINE.md"
echo "   Testing guide: https://github.com/omacom-io/omarchy-chromium/blob/master/TESTING.md"
echo ""

if [[ $AVAILABLE_SPACE -lt 100 ]]; then
    log_error "⚠️  WARNING: Very low disk space (${AVAILABLE_SPACE}GB). Chromium build may fail!"
    echo "   Consider adding more storage before proceeding."
fi

echo "💡 Pro tip: The first build will take 4-6 hours. Run it overnight!"
echo ""
log_success "Setup complete! Happy building! 🚀"