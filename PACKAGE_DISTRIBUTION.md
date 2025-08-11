# Distributing Chromium Arch Package

## Building the Package (on your Arch build machine)

### For standard build:
```bash
# Clone and build
git clone https://github.com/hjanuschka/omarchy-chromium.git
cd omarchy-chromium
git checkout add-theme-command-line-patch

# Build package without installing (-s installs deps, -c cleans after)
makepkg -sc

# This creates: chromium-139.0.7258.66-2-x86_64.pkg.tar.zst
```

### For RBE build (faster):
```bash
git checkout rbe-build-setup
./build-with-rbe.sh --noinstall

# Or manually:
makepkg -p PKGBUILD.rbe -sc
# Creates: chromium-rbe-139.0.7258.66-1-x86_64.pkg.tar.zst
```

## Distributing the Package

### Option 1: Direct file sharing
```bash
# The package file is created in the current directory
ls *.pkg.tar.zst
# chromium-139.0.7258.66-2-x86_64.pkg.tar.zst

# Upload to your preferred hosting:
# - GitHub Releases
# - Google Drive
# - Dropbox
# - Your own server
```

### Option 2: Create a custom repository
```bash
# Create repo directory
mkdir -p ~/chromium-repo

# Copy package
cp chromium-*.pkg.tar.zst ~/chromium-repo/

# Create repository database
cd ~/chromium-repo
repo-add chromium-repo.db.tar.gz chromium-*.pkg.tar.zst

# Host this directory on a web server
```

### Option 3: GitHub Releases (Recommended)
```bash
# Install GitHub CLI if needed
sudo pacman -S github-cli

# Create release and upload package
gh release create v139.0.7258.66-2 \
  --title "Chromium with Theme Switcher" \
  --notes "Chromium build with command-line theme switching support" \
  chromium-139.0.7258.66-2-x86_64.pkg.tar.zst
```

## Installing the Package

Users can install your package with:

### From file:
```bash
# Download the package
wget https://your-host/chromium-139.0.7258.66-2-x86_64.pkg.tar.zst

# Install with pacman
sudo pacman -U chromium-139.0.7258.66-2-x86_64.pkg.tar.zst
```

### From custom repository:
```bash
# Add to /etc/pacman.conf
echo "[chromium-custom]
Server = https://your-repo-url" | sudo tee -a /etc/pacman.conf

# Update and install
sudo pacman -Sy chromium
```

## Package Contents

The package includes:
- Chromium binary with theme switcher patch
- All required libraries and resources
- Desktop files and icons
- Man pages

## Theme Switcher Usage

After installation, users can use:
```bash
# Change theme color
chromium --set-theme-color=255,100,50

# Set dark mode
chromium --set-color-scheme=dark

# Reset to default
chromium --set-default-theme
```

## Signature (Optional but Recommended)

For trusted distribution:
```bash
# Sign the package
gpg --detach-sign chromium-139.0.7258.66-2-x86_64.pkg.tar.zst

# Users verify with
gpg --verify chromium-139.0.7258.66-2-x86_64.pkg.tar.zst.sig
```

## File Size Warning

Chromium packages are large (~150-200MB compressed). Consider:
- Using a CDN or reliable hosting
- Providing torrent/magnet links for large-scale distribution
- Setting up mirrors if many users