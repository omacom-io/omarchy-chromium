# WIP/Alpha Release Workflow

This document describes how to create WIP (Work In Progress) builds for beta testing.

## Quick Start

```bash
# 1. Prepare clean source with all patches
./wip_release.sh --prepare

# 2. Make your manual changes
cd ~/omarchy-chromium-src/src
# edit files...

# 3. Build and release WIP
./wip_release.sh policy-accent-fix
```

## Commands

### Prepare Source (`--prepare`)

Resets the Chromium source to a clean state and applies all patches:

```bash
./wip_release.sh --prepare
```

This will:
1. Reset `~/omarchy-chromium-src/src` to HEAD
2. Clean untracked files
3. Checkout the version tag matching PKGBUILD's `pkgver`
4. Apply patches 001-004 in order

After running, you have a clean working directory with all standard patches applied.

### Build & Release WIP

Build from current source state and publish as pre-release:

```bash
# With auto-generated date suffix
./wip_release.sh
# Creates: v143.0.7499.109-wip-20251216

# With custom suffix
./wip_release.sh theme-fix
# Creates: v143.0.7499.109-wip-theme-fix

./wip_release.sh policy-accent
# Creates: v143.0.7499.109-wip-policy-accent
```

### Skip Build (`--skip-build`)

Use an existing build without recompiling:

```bash
./wip_release.sh --skip-build test2
```

Useful when you've already built and just want to publish.

### Dry Run (`--dry-run`)

Preview what would happen without making changes:

```bash
./wip_release.sh --dry-run theme-fix
```

## Typical Workflow

### Testing a New Patch

```bash
# 1. Start fresh
./wip_release.sh --prepare

# 2. Make your changes
cd ~/omarchy-chromium-src/src
# Edit browser_widget.cc, theme_service.cc, etc.

# 3. Build and release for testing
./wip_release.sh my-new-feature

# 4. Test it, get feedback...

# 5. If it works, create a proper patch
cd ~/omarchy-chromium-src/src
git diff > ~/omarchy-chromium/005-my-new-feature.patch

# 6. Add to PKGBUILD patch list for future builds
```

### Quick Iteration

```bash
# Already have source prepared, made some changes
# Build and release:
./wip_release.sh iteration-2

# Made more changes, rebuild:
./wip_release.sh iteration-3
```

### Re-releasing Without Rebuild

```bash
# Built successfully but want different release name
./wip_release.sh --skip-build better-name
```

## Version Format

WIP releases use this format:
```
{chromium_version}-wip-{suffix}
```

Examples:
- `143.0.7499.109-wip-20251216` (date-based, default)
- `143.0.7499.109-wip-theme-fix` (custom suffix)
- `143.0.7499.109-wip-policy-accent` (descriptive)

## GitHub Release

WIP releases are automatically:
- Tagged as **pre-release** (not shown as latest)
- Titled with "WIP:" prefix
- Include warning about beta status

Example release:
```
Tag: v143.0.7499.109-wip-theme-fix
Title: WIP: Omarchy Chromium 143.0.7499.109-wip-theme-fix

Body includes:
- Warning about beta status
- What's being tested
- Installation instructions
- Link to report issues
```

## Key Differences from Production Releases

| Feature | Production (`do_update.sh`) | WIP (`wip_release.sh`) |
|---------|----------------------------|------------------------|
| Source handling | Resets and checks out tag | Preserves current state |
| Architectures | x86_64 + ARM64 | x86_64 only |
| GitHub release | Latest release | Pre-release |
| AUR update | Yes | No |
| Version increment | pkgrel++ | Custom suffix |

## Notes

- WIP builds are **x86_64 only** for faster iteration
- WIP builds do **not** update AUR - they stay on GitHub only
- Manual changes are preserved between builds (no reset)
- Use `--prepare` to get a fresh start when needed
