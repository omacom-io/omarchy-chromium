# 🤖 GitHub Actions Automation

**Automated builds using self-hosted GitHub runner (recommended approach):**

## 🌙 Nightly Builds
Runs daily at 01:00 UTC, only builds when upstream changes are detected.

**Workflow**: `.github/workflows/nightly-build.yml`

### Features:
- ✅ **Daily Schedule**: Runs at 01:00 UTC automatically
- ✅ **Smart Detection**: Only builds when Arch has new Chromium version
- ✅ **Manual Trigger**: Can be run manually from GitHub Actions tab
- ✅ **Force Build**: Option to build even without upstream changes
- ✅ **12-hour Timeout**: Handles long build times gracefully
- ✅ **Error Handling**: Uploads logs on failure for debugging

### How to Trigger:
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

## 🔨 Manual Full Build
For complete rebuilds from Chromium source when needed (manual trigger only).

**Workflow**: `.github/workflows/manual-build.yml`

### How to Trigger:
**Manual Trigger Only:**
1. Go to **Actions** tab on GitHub
2. Select **"Manual Full Build"**
3. Click **"Run workflow"** dropdown
4. Select branch (usually `master`)
5. Optionally enter reason for build
6. Click green **"Run workflow"** button

### Features:
- ⚠️ **Full Rebuild**: Complete 5-6 hour build from Chromium source
- ✅ **Manual Only**: Never runs automatically (prevents accidental long builds)
- ✅ **Custom Reason**: Add description for why you're doing manual build
- ✅ **Complete Pipeline**: Build → GitHub release → AUR update → commit back
- ✅ **Error Handling**: Uploads build logs on failure for debugging

### When to Use:
- When you've modified build configuration or patches
- For testing major changes before they go live
- When you need a fresh rebuild for any reason
- Emergency builds when automation isn't working

---

## 🎨 Test Theme Patch
For testing theme patches with clean Chromium source (manual trigger only).

**Workflow**: `.github/workflows/test-theme-patch.yml`

### How to Trigger:
**Manual Trigger Only:**
1. Go to **Actions** tab on GitHub
2. Select **"Test Theme Patch"**
3. Click **"Run workflow"** dropdown
4. Select branch (usually `master`)
5. Optionally specify patch file (defaults to `omarchy-theme-switcher.patch`)
6. Optionally enter reason for test
7. Click green **"Run workflow"** button

### What It Does:
1. **Stashes current state** - Preserves any work in Chromium source
2. **Checks out PKGBUILD version** - Uses exact version from your PKGBUILD
3. **Applies theme patch** - Tests patch against clean source
4. **Full build** - Complete 5-6 hour build with patch applied
5. **Restores state** - Returns Chromium source to previous state

### Features:
- 🎯 **Isolated testing** - Clean environment for patch validation
- 🔄 **State preservation** - Automatically stashes and restores your work
- 🎨 **Theme focus** - Designed specifically for theme patch testing
- ✅ **Complete pipeline** - Build → GitHub release → AUR update → commit back
- 🛡️ **Safe restoration** - Always restores Chromium source afterward

### When to Use:
- Testing new theme patch versions
- Validating patch compatibility with specific Chromium versions
- Debugging theme patch issues
- Before merging theme patch changes

---

## ⚡ Quick Release Testing
For testing AUR releases without rebuilding (uses existing package files).

**Workflow**: `.github/workflows/quick-release.yml`

### How to Trigger:
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

### Features:
- ✅ **Skip Build**: Uses `SKIP_BUILD=1` with existing package
- ✅ **Fast**: Completes in ~5 minutes vs 5-6 hours
- ✅ **Testing**: Perfect for testing AUR release process
- ✅ **Safe**: Uses existing built packages
- ✅ **Flexible**: Branch pattern or tag pattern triggers

---

## 🔍 Monitor Workflows

### View Workflow Status:
1. Go to **Actions** tab on GitHub: `https://github.com/omacom-io/omarchy-chromium/actions`
2. See all workflow runs (running, completed, failed)
3. Click on any run to see detailed logs

### Real-time Monitoring:
1. Click on a **running workflow** 
2. Click on the **job name** (e.g., "check-and-build")
3. Click on individual **steps** to see live logs
4. **Auto-refreshes** - no need to manually reload

### Check Self-Hosted Runner:
1. Go to **Repository Settings**
2. Select **Actions** → **Runners**
3. Verify runner is **online** and **idle/active**

### Troubleshooting:
```bash
# Check runner status on your machine
systemctl --user status actions.runner.omacom-io-omarchy-chromium.*

# Restart runner if needed  
systemctl --user restart actions.runner.omacom-io-omarchy-chromium.*

# View runner logs
journalctl --user -u actions.runner.omacom-io-omarchy-chromium.* -f
```

## 📝 Workflow Files

All workflow files are located in `.github/workflows/`:
- `nightly-build.yml` - Daily automated builds
- `manual-build.yml` - Manual full rebuilds
- `test-theme-patch.yml` - Theme patch testing
- `quick-release.yml` - Fast AUR release testing

## 🛠️ Self-Hosted Runner Setup

For setting up your own self-hosted runner:

1. Go to repository **Settings** → **Actions** → **Runners**
2. Click **"New self-hosted runner"**
3. Follow the setup instructions for Linux
4. Configure as a service for automatic startup

### Runner Requirements:
- **OS**: Arch Linux (for package compatibility)
- **Disk**: 150GB+ free space
- **RAM**: 16GB minimum, 32GB recommended
- **CPU**: Multi-core recommended (8+ cores ideal)
- **Network**: Fast connection for source downloads

---

💡 **Pro Tip**: The nightly build workflow is the recommended way to keep your package updated automatically while only building when necessary!