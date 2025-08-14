# 🎨 Omarchy Chromium

[![AUR version](https://img.shields.io/aur/version/omarchy-chromium-bin)](https://aur.archlinux.org/packages/omarchy-chromium-bin)
[![GitHub release](https://img.shields.io/github/v/release/omacom-io/omarchy-chromium)](https://github.com/omacom-io/omarchy-chromium/releases)
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

The package is available in the AUR: https://aur.archlinux.org/packages/omarchy-chromium-bin

```bash
# Using an AUR helper (if you have one installed)
yay -S omarchy-chromium-bin
# OR
paru -S omarchy-chromium-bin

# Manual installation (without AUR helper)
git clone https://aur.archlinux.org/omarchy-chromium-bin.git
cd omarchy-chromium-bin
makepkg -si
```

### Option 2: Download Pre-built Binary
Download the latest `.pkg.tar.zst` from [Releases](https://github.com/omacom-io/omarchy-chromium/releases) and install:
```bash
sudo pacman -U omarchy-chromium-*.pkg.tar.zst
```

### Option 3: Build from Source
```bash
git clone https://github.com/omacom-io/omarchy-chromium.git
cd omarchy-chromium
makepkg -si
```

## 🎨 Theme Usage

Change Chromium's theme without opening a new window:

```bash
# Switch to dark theme
chromium --no-startup-window --set-color-scheme=dark

# Switch to light theme
chromium --no-startup-window --set-color-scheme=light

# Set custom theme color (RGB values)
chromium --no-startup-window --set-theme-color=255,100,0

# Reset to default theme
chromium --no-startup-window --set-default-theme
```

> **Note**: The `--no-startup-window` flag allows theme changes to apply to existing windows without opening a new one.

## 🏗️ Project Structure

The project consists of three main components:

| Directory | Purpose |
|-----------|---------|
| `~/omarchy-chromium` | **Build repository** - Contains PKGBUILD, patches, and automation scripts |
| `~/omarchy-chromium-src` | **Chromium source** - Official Chromium checkout with Omarchy patches applied (not committed) |
| `~/BUILD_LAB/omarchy-chromium-bin` | **AUR package** - Binary package metadata for AUR distribution |

## 🔧 Development

### Initial Setup

> besides AUR everything is meant to be done/initialized by `makepkg -s` itself

1. **Setup AUR package repository:**
   ```bash
   mkdir -p ~/BUILD_LAB
   git clone ssh://aur@aur.archlinux.org/omarchy-chromium-bin.git ~/BUILD_LAB/omarchy-chromium-bin
   
   ```

2. **Configure GitHub CLI (for releases):**
   ```bash
   gh auth login
   # Follow prompts to authenticate with GitHub
   ```

## 📜 Automation Scripts

### 🎯 `smart_update.sh` - Upstream-Aware Updates (Recommended)

**Only builds and pushes to AUR when upstream Chromium has changes!**

This is the **recommended way** to keep your package updated - it ensures you only push to AUR when there's an actual new Chromium release from Arch Linux.

#### Usage:
```bash
# Check upstream and update if needed
./smart_update.sh
```

#### What it does:
- ✅ Checks if Arch Linux has released a new Chromium version
- ✅ Only proceeds if there are upstream changes
- ✅ Automatically runs update_to_upstream.sh and do_update.sh
- ✅ Prevents unnecessary AUR updates
- ✅ Saves build time and resources

---

### 🔍 `check_upstream.sh` - Check for Updates

Checks if the upstream Arch Linux Chromium package has a newer version than ours.

#### Usage:
```bash
# Check if updates are available
./check_upstream.sh
```

#### Returns:
- Exit code 0: Update available
- Exit code 1: Already up-to-date
- Exit code 2: Error occurred

---

### 🚀 `do_update.sh` - Manual Build & Release

Use this for hotfixes, patches, or when you need to force a release regardless of upstream status.

1. **Increments** `pkgrel` by one
2. **Builds** package using `makepkg -s`
3. **Uploads** to GitHub Releases
4. **Updates** AUR package metadata

#### Usage:
```bash
# Full build and release (for patches/fixes)
./do_update.sh

# Skip build (use existing package)
SKIP_BUILD=1 ./do_update.sh
```

#### When to use:
- When you've made patches or fixes
- For emergency updates
- When smart_update.sh says no update but you need to release

---

### 🔄 `update_to_upstream.sh` - Sync with Upstream

Synchronizes with the latest official Chromium release:

1. **Fetches** latest version from Arch Linux's Chromium package
2. **Updates** local PKGBUILD version
3. **Stashes** local changes in Chromium checkout
4. **Checks out** new Chromium version tag
5. **Applies** Omarchy theme patches
6. **Prepares** build environment

#### Usage:
```bash
# Manually sync to latest upstream
./update_to_upstream.sh

# Then build
makepkg -s
```

#### What it does:
- ✅ Automatically detects new Chromium versions
- ✅ Preserves your local modifications
- ✅ Applies compatible patches only
- ✅ Ready to build immediately

## 🔄 Typical Workflow

### Recommended: Smart Update (checks upstream first)
```bash
cd ~/omarchy-chromium
./smart_update.sh  # Only builds if Arch has new Chromium
```

### Manual Update for Patches/Fixes
```bash
cd ~/omarchy-chromium
./do_update.sh  # Increments pkgrel, builds, releases
```

### Update to New Chromium Version (manual)
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

### Check if updates are available
```bash
cd ~/omarchy-chromium
./check_upstream.sh  # Shows if Arch has newer version
```

## 🤖 GitHub Actions Automation

**Automated builds using self-hosted GitHub runner (recommended approach):**

### 🌙 Nightly Builds
Runs daily at 01:00 UTC, only builds when upstream changes are detected.

**Workflow**: `.github/workflows/nightly-build.yml`

#### Features:
- ✅ **Daily Schedule**: Runs at 01:00 UTC automatically
- ✅ **Smart Detection**: Only builds when Arch has new Chromium version
- ✅ **Manual Trigger**: Can be run manually from GitHub Actions tab
- ✅ **Force Build**: Option to build even without upstream changes
- ✅ **12-hour Timeout**: Handles long build times gracefully
- ✅ **Error Handling**: Uploads logs on failure for debugging

#### How to Trigger:
**Automatic (Recommended):**
- Runs automatically every day at 01:00 UTC
- Only builds if upstream changes detected

**Manual:**
1. Go to **Actions** tab on GitHub
2. Select **"Nightly Upstream Check & Build"**  
3. Click **"Run workflow"** dropdown
4. Select branch (usually `master`)
5. Check "Force build" if you want to build without upstream changes
6. Click green **"Run workflow"** button

---

### ⚡ Quick Release Testing
For testing AUR releases without rebuilding (uses existing package files).

**Workflow**: `.github/workflows/quick-release.yml`

#### How to Trigger:
**Branch Pattern (Recommended for testing):**
```bash
# Create and push a release test branch
git checkout -b release-test/test-aur-upload
git push origin release-test/test-aur-upload
# → Automatically triggers quick release workflow
```

**Tag Pattern:**
```bash
# Create and push a quick release tag  
git tag quick-release-v1
git push origin quick-release-v1
# → Automatically triggers quick release workflow
```

**Manual Trigger:**
1. Go to **Actions** tab on GitHub
2. Select **"Quick Release (Skip Build)"**
3. Click **"Run workflow"** dropdown
4. Select branch (usually `master`)
5. Choose whether to increment pkgrel
6. Click green **"Run workflow"** button

#### Features:
- ✅ **Skip Build**: Uses `SKIP_BUILD=1` with existing package
- ✅ **Fast**: Completes in ~5 minutes vs 5-6 hours
- ✅ **Testing**: Perfect for testing AUR release process
- ✅ **Safe**: Uses existing built packages
- ✅ **Flexible**: Branch pattern or tag pattern triggers

---

### 🔍 Monitor Workflows

#### View Workflow Status:
1. Go to **Actions** tab on GitHub: `https://github.com/omacom-io/omarchy-chromium/actions`
2. See all workflow runs (running, completed, failed)
3. Click on any run to see detailed logs

#### Real-time Monitoring:
1. Click on a **running workflow** 
2. Click on the **job name** (e.g., "check-and-build")
3. Click on individual **steps** to see live logs
4. **Auto-refreshes** - no need to manually reload

#### Check Self-Hosted Runner:
1. Go to **Repository Settings**
2. Select **Actions** → **Runners**
3. Verify runner is **online** and **idle/active**

#### Troubleshooting:
```bash
# Check runner status on your machine
systemctl --user status actions.runner.omacom-io-omarchy-chromium.*

# Restart runner if needed  
systemctl --user restart actions.runner.omacom-io-omarchy-chromium.*

# View runner logs
journalctl --user -u actions.runner.omacom-io-omarchy-chromium.* -f
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

## 🔧 Patch Maintenance

### Theme Switcher Patch (IMPORTANT)

The core `omarchy-theme-switcher.patch` is based on an upstream Chromium change request:

**📎 Upstream CL**: [https://chromium-review.googlesource.com/c/chromium/src/+/6832165](https://chromium-review.googlesource.com/c/chromium/src/+/6832165)

#### If the patch fails to apply:

1. **Visit the CL** and check its merge status
2. **Fix merge conflicts** in the CL to keep it mergeable with main
3. **Download the updated diff**:
   ```bash
   # From the CL page, click "Download" and select "Patch"
   # Or use git:
   cd ~/omarchy-chromium-src/src
   git fetch https://chromium.googlesource.com/chromium/src refs/changes/65/6832165/[LATEST_PATCHSET]
   git format-patch -1 FETCH_HEAD -o ~/omarchy-chromium/
   ```
4. **Replace** `omarchy-theme-switcher.patch` with the new version
5. **Test** the build with the updated patch

> **Note**: Keeping the CL mergeable with Chromium main branch is crucial for maintaining this project. If you encounter merge conflicts, please help by updating the CL!


## 🧪 Testing

### Running Theme Service Tests

After applying the theme switcher patch, verify it works correctly:

```bash
cd ~/omarchy-chromium-src/src

# Run theme service unit tests
tools/autotest.py -C out/Release --gtest_repeat=1 chrome/browser/themes/theme_service_unittest.cc

```

Expected output:
```
[==========] Running tests from theme_service_unittest.cc
[----------] ThemeServiceTest
[ RUN      ] ThemeServiceTest.CommandLineThemeColor
[       OK ] ThemeServiceTest.CommandLineThemeColor (15 ms)
[ RUN      ] ThemeServiceTest.CommandLineThemeScheme
[       OK ] ThemeServiceTest.CommandLineThemeScheme (12 ms)
[==========] All tests passed
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly (including unit tests above)
4. Submit a pull request

### Testing Patches
```bash
cd ~/omarchy-chromium-src/src
# Apply your patch
patch -p1 < ~/your-patch.patch
# Test build
autoninja -C out/Release chrome
# Run theme tests
tools/autotest.py -C out/Release --gtest_repeat=1 chrome/browser/themes/theme_service_unittest.cc
```

## 📝 License

This project is licensed under the BSD-3-Clause License - same as Chromium.

## 🙏 Credits

- **Chromium Project** - The amazing open-source browser
- **Arch Linux** - Package maintainers and build infrastructure
- **Omarchy** - Theme integration concept
- **Contributors** - Everyone who has helped improve this project

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/omacom-io/omarchy-chromium/issues)
- **AUR Comments**: [AUR Package Page](https://aur.archlinux.org/packages/omarchy-chromium-bin)
- **Maintainer**: Helmut Januschka <helmut@januschka.com>

---

<div align="center">
Made with ❤️ for the Arch Linux community
</div>
