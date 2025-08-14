# 🎨 Omarchy Chromium

[![AUR version](https://img.shields.io/aur/version/omarchy-chromium-bin)](https://aur.archlinux.org/packages/omarchy-chromium-bin)
[![GitHub release](https://img.shields.io/github/v/release/hjanuschka/omarchy-chromium)](https://github.com/hjanuschka/omarchy-chromium/releases)
[![License](https://img.shields.io/badge/license-BSD--3--Clause-blue)](LICENSE)

A custom build of Chromium with the **Omarchy theme patches** - providing command-line theme switching capabilities for seamless integration with your desktop environment.

## ✨ Features

- 🎨 **Dynamic Theme Switching** - Change Chromium's theme via command-line flags
- 🚀 **Built from Source** - Using Google's official Chromium source with bundled toolchain
- 📦 **AUR Package** - Easy installation for Arch Linux users
- 🔄 **Automated Updates** - Scripts to track upstream Chromium releases
- 🛠️ **Developer Friendly** - Full build automation and release pipeline

## 📥 Installation

### Option 1: Install from AUR (Recommended)
```bash
# Using yay
yay -S omarchy-chromium-bin

# Using paru
paru -S omarchy-chromium-bin
```

### Option 2: Download Pre-built Binary
Download the latest `.pkg.tar.zst` from [Releases](https://github.com/hjanuschka/omarchy-chromium/releases) and install:
```bash
sudo pacman -U omarchy-chromium-*.pkg.tar.zst
```

### Option 3: Build from Source
```bash
git clone https://github.com/hjanuschka/omarchy-chromium.git
cd omarchy-chromium
makepkg -si
```

## 🎨 Theme Usage

Launch Chromium with custom theme colors:
```bash
# Dark theme
chromium --theme-color="#1e1e2e" --theme-scheme="dark"

# Light theme with custom color
chromium --theme-color="#ffffff" --theme-scheme="light"

# System theme (follows GTK/Qt)
chromium --theme-scheme="system"
```

## 🏗️ Project Structure

The project consists of three main components:

| Directory | Purpose |
|-----------|---------|
| `~/omarchy-chromium` | **Build repository** - Contains PKGBUILD, patches, and automation scripts |
| `~/omarchy-chromium-src` | **Chromium source** - Official Chromium checkout with Omarchy patches applied (not committed) |
| `~/BUILD_LAB/omarchy-chromium-bin` | **AUR package** - Binary package metadata for AUR distribution |

## 🔧 Development

### Prerequisites

```bash
# Install build dependencies
sudo pacman -S base-devel git python gn ninja nodejs java-runtime-headless

# Install depot_tools
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git ~/depot_tools
export PATH="$HOME/depot_tools:$PATH"

# Install GitHub CLI for releases
sudo pacman -S github-cli
gh auth login
```

### Initial Setup

1. **Clone this repository:**
   ```bash
   git clone https://github.com/hjanuschka/omarchy-chromium.git ~/omarchy-chromium
   cd ~/omarchy-chromium
   ```

2. **Initialize Chromium source (first time only):**
   ```bash
   makepkg -s  # This will create ~/omarchy-chromium-src automatically
   ```

3. **Clone AUR package repository:**
   ```bash
   git clone ssh://aur@aur.archlinux.org/omarchy-chromium-bin.git ~/BUILD_LAB/omarchy-chromium-bin
   ```

## 📜 Automation Scripts

### 🚀 `do_update.sh` - Build & Release

Automates the complete release pipeline:

1. **Increments** `pkgrel` by one
2. **Builds** package using `makepkg -s`
3. **Uploads** to GitHub Releases
4. **Updates** AUR package metadata

#### Usage:
```bash
# Full build and release
./do_update.sh

# Skip build (use existing package)
SKIP_BUILD=1 ./do_update.sh
```

#### What it does:
- ✅ Auto-increments version number
- ✅ Builds Chromium package (~3-4 hours)
- ✅ Creates GitHub release with binary
- ✅ Updates AUR with new checksums
- ✅ Pushes everything automatically

---

### 🔄 `update_to_upstream.sh` - Track Upstream

Synchronizes with the latest official Chromium release:

1. **Fetches** latest version from Arch Linux's Chromium package
2. **Updates** local PKGBUILD version
3. **Stashes** local changes in Chromium checkout
4. **Checks out** new Chromium version tag
5. **Applies** Omarchy theme patches
6. **Prepares** build environment

#### Usage:
```bash
# Check and update to latest upstream
./update_to_upstream.sh

# Then build
makepkg -s
# Or release directly
./do_update.sh
```

#### What it does:
- ✅ Automatically detects new Chromium versions
- ✅ Preserves your local modifications
- ✅ Applies compatible patches only
- ✅ Sets up PGO profiles and dependencies
- ✅ Ready to build immediately

## 🔄 Typical Workflow

### Regular Update (same Chromium version)
```bash
cd ~/omarchy-chromium
./do_update.sh  # Increments pkgrel, builds, releases
```

### Update to New Chromium Version
```bash
cd ~/omarchy-chromium
./update_to_upstream.sh  # Updates to latest Chromium
./do_update.sh          # Builds and releases
```

### Quick Re-release (no rebuild)
```bash
cd ~/omarchy-chromium
SKIP_BUILD=1 ./do_update.sh  # Uses existing package
```

## 🛠️ Build Configuration

The build uses Google's bundled toolchain for maximum compatibility:

- **Clang/LLVM**: Version 21 (bundled)
- **Rust**: Bundled toolchain
- **PGO**: Profile-Guided Optimization enabled
- **CFI**: Control Flow Integrity enabled
- **Patches Applied**:
  - ✅ `omarchy-theme-switcher.patch` - Core theme functionality
  - ✅ `use-oauth2-client-switches-as-default.patch` - OAuth2 support
  - ❌ `compiler-rt-adjust-paths.patch` - Skipped (bundled toolchain)
  - ❌ `chromium-*-nodejs-version-check.patch` - Skipped (bundled Node.js)
  - ❌ `increase-fortify-level.patch` - Skipped (conflicts with bundled build)

## 📊 Build Requirements

- **Disk Space**: ~100GB (source + build artifacts)
- **RAM**: 16GB minimum, 32GB recommended
- **Build Time**: 3-4 hours on modern hardware
- **Network**: Fast connection for initial checkout (~30GB)

## 🐛 Troubleshooting

### Build Fails with Missing Headers
```bash
# Ensure partition_alloc symlink exists
cd ~/omarchy-chromium-src/src
ln -sf base/allocator/partition_allocator/src/partition_alloc partition_alloc
```

### PGO Profile Missing
```bash
# Update .gclient and sync
cd ~/omarchy-chromium-src
gclient sync --force --reset --with_branch_heads --with_tags
```

### Out of Memory During Build
```bash
# Limit parallel jobs
export NINJA_JOBS=4
makepkg -s
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request

### Testing Patches
```bash
cd ~/omarchy-chromium-src/src
# Apply your patch
patch -p1 < ~/your-patch.patch
# Test build
autoninja -C out/Release chrome
```

## 📝 License

This project is licensed under the BSD-3-Clause License - same as Chromium.

## 🙏 Credits

- **Chromium Project** - The amazing open-source browser
- **Arch Linux** - Package maintainers and build infrastructure
- **Omarchy** - Theme integration concept
- **Contributors** - Everyone who has helped improve this project

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/hjanuschka/omarchy-chromium/issues)
- **AUR Comments**: [AUR Package Page](https://aur.archlinux.org/packages/omarchy-chromium-bin)
- **Maintainer**: Helmut Januschka <helmut@januschka.com>

---

<div align="center">
Made with ❤️ for the Arch Linux community
</div>