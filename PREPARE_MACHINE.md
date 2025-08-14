# 🔧 Prepare Machine for Omarchy Chromium Development

This guide will help you set up a fresh Arch Linux machine for building Omarchy Chromium.

## 📋 Prerequisites

- Fresh Arch Linux installation
- Internet connection
- Root access for package installation
- At least 16GB RAM (32GB recommended)
- At least 150GB free disk space

## 🚀 Quick Setup Script

For a fully automated setup, run this single command:

```bash
curl -fsSL https://raw.githubusercontent.com/omacom-io/omarchy-chromium/master/scripts/setup-builder.sh | bash
```

Or follow the manual steps below for full control.

## 📦 Package Installation

### Core System Packages

```bash
# Update system first
sudo pacman -Syu

# Essential build tools and development packages
sudo pacman -S --needed \
  base-devel git python gn ninja clang lld rust rust-bindgen \
  nodejs npm java-runtime-headless gperf pipewire qt6-base \
  curl wget unzip tar xz

# Chromium runtime dependencies
sudo pacman -S --needed \
  gtk3 gtk4 nss alsa-lib xdg-utils libxss libcups libgcrypt \
  ttf-liberation systemd dbus libpulse pciutils libva libffi \
  desktop-file-utils hicolor-icon-theme

# Additional system libraries
sudo pacman -S --needed \
  fontconfig freetype2 harfbuzz libjpeg-turbo libpng libwebp \
  libxml2 libxslt opus zlib minizip brotli flac

# Development and debugging tools
sudo pacman -S --needed \
  github-cli openssh strace gdb valgrind htop neofetch

# Multimedia and graphics
sudo pacman -S --needed \
  mesa vulkan-mesa-layers vulkan-tools \
  gstreamer gst-plugins-base gst-plugins-good

# Network and security
sudo pacman -S --needed \
  ca-certificates gnupg
```

### Complete Package List

<details>
<summary>Click to expand full package list (457 packages)</summary>

```bash
# This is the complete package manifest from a working builder machine
# You can install all at once with:
sudo pacman -S --needed \\
  acl adwaita-cursors adwaita-fonts adwaita-icon-theme \\
  adwaita-icon-theme-legacy alsa-lib alsa-topology-conf \\
  alsa-ucm-conf aom archlinux-keyring at-spi2-core attr \\
  audit autoconf automake avahi base base-devel bash \\
  binutils bison brotli bzip2 ca-certificates cairo \\
  cantarell-fonts clang cmake coreutils cryptsetup curl \\
  dav1d dbus desktop-file-utils diffutils e2fsprogs \\
  expat fakeroot file filesystem findutils flac flex \\
  fontconfig freetype2 fribidi gawk gcc gcc-libs gdbm \\
  gettext glib2 glibc gmp gn gnupg gnutls gpgme grep \\
  groff gst-plugins-base gst-plugins-good gstreamer \\
  gtk3 gtk4 gzip harfbuzz hicolor-icon-theme java-runtime-headless \\
  keyutils krb5 ldd less libarchive libasyncns libcap \\
  libcups libcurl libdaemon libdrm libepoxy libevdev \\
  libffi libgcrypt libgpg-error libidn2 libjpeg-turbo \\
  libnghttp2 libnsl libpng libpsl libpulse libssh2 \\
  libsysprof-capture libtasn1 libtiff libtirpc libunistring \\
  libva libvdpau libwebp libx11 libxau libxcb libxcomposite \\
  libxcursor libxdamage libxdmcp libxext libxfixes libxft \\
  libxi libxinerama libxkbcommon libxml2 libxrandr libxrender \\
  libxss libxt libxtst libxv libxxf86vm licenses linux-api-headers \\
  lld llvm llvm-libs lz4 m4 make mesa ncurses nettle \\
  ninja nodejs npm nss openssl opus p11-kit pacman \\
  pam pango pciutils pcre2 pipewire pixman pkgconf \\
  python qt6-base readline rust rust-bindgen sed \\
  shared-mime-info sqlite systemd systemd-libs tar \\
  ttf-liberation tzdata util-linux vulkan-mesa-layers \\
  vulkan-tools wayland which xdg-utils xz zlib zstd
```

</details>

## 🔑 SSH Key Setup

### Generate SSH Key

```bash
# Generate new SSH key
ssh-keygen -t ed25519 -C "your-email@example.com"

# Start SSH agent
eval "$(ssh-agent -s)"

# Add key to SSH agent
ssh-add ~/.ssh/id_ed25519

# Copy public key to clipboard
cat ~/.ssh/id_ed25519.pub
```

### Add to GitHub

1. Go to GitHub Settings → SSH and GPG keys
2. Click "New SSH key"
3. Paste your public key
4. Test connection: `ssh -T git@github.com`

### Add to AUR

1. Go to [AUR Account Settings](https://aur.archlinux.org/account/)
2. Paste your public key in "SSH Public Key" section
3. Test connection: `ssh aur@aur.archlinux.org`

## 🛠️ Development Tools Setup

### depot_tools (Google's Chromium Tools)

```bash
# Clone depot_tools
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git ~/depot_tools

# Add to shell profile
echo 'export PATH="$HOME/depot_tools:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
which gclient
```

### GitHub CLI Authentication

```bash
# Authenticate with GitHub
gh auth login

# Follow the prompts to authenticate via browser
```

## 📁 Directory Structure Setup

```bash
# Create the standard directory structure
mkdir -p ~/BUILD_LAB
mkdir -p ~/omarchy-chromium
mkdir -p ~/omarchy-chromium-src

# Clone the main repository
git clone https://github.com/omacom-io/omarchy-chromium.git ~/omarchy-chromium
cd ~/omarchy-chromium

# Clone AUR package repository (requires AUR SSH access)
git clone ssh://aur@aur.archlinux.org/omarchy-chromium-bin.git ~/BUILD_LAB/omarchy-chromium-bin
```

## ⚙️ System Configuration

### Git Configuration

```bash
# Set global Git config
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"

# Git performance optimizations for large repos
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
```

### System Limits

```bash
# Increase file descriptor limits for large builds
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Increase virtual memory for linking
echo "vm.max_map_count=2147483647" | sudo tee -a /etc/sysctl.conf
```

### Build Environment

```bash
# Set environment variables for builds
cat >> ~/.bashrc << 'EOF'
# Chromium build environment
export NINJA_STATUS="[%f/%t (%p%%) %o/s %es] "
export CCACHE_SLOPPINESS="time_macros"
export GOMA_FALLBACK_ON_AUTH_FAILURE=true

# Rust environment
export RUSTC_BOOTSTRAP=1

# depot_tools
export PATH="$HOME/depot_tools:$PATH"
EOF

source ~/.bashrc
```

## 🏗️ Initial Build Test

### Test the Setup

```bash
cd ~/omarchy-chromium

# This should work without errors
makepkg -s --noconfirm

# The first run will:
# 1. Download Chromium source (~30GB)
# 2. Download build dependencies
# 3. Build Chromium (~4-6 hours)
# 4. Create package file
```

### Verify Everything Works

```bash
# Test automation scripts
./check_upstream.sh
./update_to_upstream.sh
./do_update.sh

# Test GitHub integration
gh release list

# Test AUR access
cd ~/BUILD_LAB/omarchy-chromium-bin
git status
```

## 💾 Storage Requirements

- **Chromium source**: ~30GB
- **Build artifacts**: ~40GB
- **Dependencies cache**: ~10GB
- **Package files**: ~500MB per version
- **Total recommended**: 150GB+ free space

## 🚀 Performance Tips

### For Faster Builds

```bash
# Use all CPU cores
export NINJA_JOBS=$(nproc)

# Use ccache if available
sudo pacman -S ccache
export USE_CCACHE=1
export CCACHE_DIR="$HOME/.ccache"
ccache -M 20G  # Set cache size
```

### For Memory-Constrained Systems

```bash
# Limit parallel jobs to avoid OOM
export NINJA_JOBS=4

# Use swap if needed (not recommended for SSDs)
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## 🔍 Verification

Run this checklist to verify your setup:

```bash
# Check essential tools
command -v git && echo "✅ Git installed"
command -v clang && echo "✅ Clang installed"
command -v rust && echo "✅ Rust installed"
command -v gn && echo "✅ GN installed"
command -v ninja && echo "✅ Ninja installed"
command -v gh && echo "✅ GitHub CLI installed"
command -v gclient && echo "✅ depot_tools installed"

# Check SSH access
ssh -T git@github.com 2>&1 | grep -q "successfully authenticated" && echo "✅ GitHub SSH works"
ssh aur@aur.archlinux.org 2>&1 | grep -q "interactive shell" && echo "✅ AUR SSH works"

# Check directories
[[ -d ~/omarchy-chromium ]] && echo "✅ Main repo cloned"
[[ -d ~/BUILD_LAB/omarchy-chromium-bin ]] && echo "✅ AUR repo cloned"

# Check disk space
df -h ~ | awk 'NR==2 {print "💾 Available space: " $4}'
```

## 🎯 Next Steps

Once everything is set up:

1. **Test build**: `cd ~/omarchy-chromium && makepkg -s`
2. **Set up automation**: Configure any needed cron jobs or GitHub Actions
3. **Monitor resources**: Keep an eye on disk space and memory usage
4. **Update regularly**: Run `./smart_update.sh` to stay current

## 📞 Troubleshooting

### Common Issues

**Build fails with "No space left on device":**
```bash
# Check disk usage
df -h
du -sh ~/omarchy-chromium-src
```

**SSH authentication fails:**
```bash
# Test connections
ssh -vT git@github.com
ssh -vT aur@aur.archlinux.org
```

**Out of memory during build:**
```bash
# Reduce parallel jobs
export NINJA_JOBS=2
makepkg -s
```

### Getting Help

- **Issues**: [GitHub Issues](https://github.com/omacom-io/omarchy-chromium/issues)
- **AUR Comments**: [AUR Package Page](https://aur.archlinux.org/packages/omarchy-chromium-bin)
- **Documentation**: [Main README](README.md)

---

💡 **Pro Tip**: This setup will take several hours for the first build. Consider running it overnight or while you're away from your computer.