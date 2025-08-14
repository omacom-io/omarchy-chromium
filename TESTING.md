# 🧪 Testing Omarchy Chromium

This document covers testing procedures for the Omarchy Chromium theme patches and build system.

## 🎨 Theme Functionality Testing

### Running Theme Command Line Handler Tests

After applying the theme switcher patch, verify the command-line theme handling works correctly:

```bash
cd ~/omarchy-chromium-src/src

# Build test target if not already built
autoninja -C out/Release chrome/browser/themes:unit_tests

# Run theme command line handler unit tests
tools/autotest.py -C out/Release --gtest_repeat=1 chrome/browser/themes/theme_command_line_handler_unittest.cc

# For debug build (if you have one)
tools/autotest.py -C out/Default --gtest_repeat=1 chrome/browser/themes/theme_command_line_handler_unittest.cc
```

### Expected Test Output:

```
[==========] Running tests from theme_command_line_handler_unittest.cc
[----------] Global test environment set-up.
[----------] ThemeCommandLineHandlerTest
[ RUN      ] ThemeCommandLineHandlerTest.SetUserColorValid
[       OK ] ThemeCommandLineHandlerTest.SetUserColorValid (12 ms)
[ RUN      ] ThemeCommandLineHandlerTest.SetUserColorInvalid
[       OK ] ThemeCommandLineHandlerTest.SetUserColorInvalid (8 ms)
[ RUN      ] ThemeCommandLineHandlerTest.SetColorSchemeDark
[       OK ] ThemeCommandLineHandlerTest.SetColorSchemeDark (10 ms)
[ RUN      ] ThemeCommandLineHandlerTest.SetColorSchemeLight
[       OK ] ThemeCommandLineHandlerTest.SetColorSchemeLight (9 ms)
[ RUN      ] ThemeCommandLineHandlerTest.SetColorVariantVibrant
[       OK ] ThemeCommandLineHandlerTest.SetColorVariantVibrant (11 ms)
[ RUN      ] ThemeCommandLineHandlerTest.SetGrayscaleTheme
[       OK ] ThemeCommandLineHandlerTest.SetGrayscaleTheme (13 ms)
[ RUN      ] ThemeCommandLineHandlerTest.SetDefaultTheme
[       OK ] ThemeCommandLineHandlerTest.SetDefaultTheme (7 ms)
[----------] 7 tests from ThemeCommandLineHandlerTest (70 ms total)
[----------] Global test environment tear-down
[==========] 7 tests from 1 test suite ran. (75 ms total)
[  PASSED  ] 7 tests.
```

### Individual Test Cases:

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| `SetUserColorValid` | Tests setting valid RGB color values | ✅ PASS |
| `SetUserColorInvalid` | Tests handling of invalid color input | ✅ PASS |
| `SetColorSchemeDark` | Tests dark theme activation | ✅ PASS |
| `SetColorSchemeLight` | Tests light theme activation | ✅ PASS |
| `SetColorVariantVibrant` | Tests vibrant color variant | ✅ PASS |
| `SetGrayscaleTheme` | Tests grayscale theme mode | ✅ PASS |
| `SetDefaultTheme` | Tests theme reset functionality | ✅ PASS |

## 🔧 Manual Theme Testing

### Test All Theme Switches

After building, test the actual command-line functionality:

```bash
# Build Chromium first
cd ~/omarchy-chromium-src/src
autoninja -C out/Release chrome

# Test all GM3-compliant switches
out/Release/chrome --no-startup-window --set-user-color="28,32,39" &
sleep 2

out/Release/chrome --no-startup-window --set-color-scheme="dark" &
sleep 2

out/Release/chrome --no-startup-window --set-color-scheme="light" &
sleep 2

out/Release/chrome --no-startup-window --set-color-variant="vibrant" &
sleep 2

out/Release/chrome --no-startup-window --set-grayscale-theme="true" &
sleep 2

out/Release/chrome --no-startup-window --set-default-theme &
```

### Visual Verification Checklist:

- [ ] **User Color**: Custom RGB color applied to browser theme
- [ ] **Dark Scheme**: Browser switches to dark mode
- [ ] **Light Scheme**: Browser switches to light mode  
- [ ] **Vibrant Variant**: Enhanced color saturation visible
- [ ] **Grayscale Theme**: All colors converted to grayscale
- [ ] **Default Theme**: Theme resets to system default

## 🛠️ Build Testing

### Test Build Configuration

```bash
cd ~/omarchy-chromium-src/src

# Test args.gn configuration
gn check out/Release

# Verify GN arguments
gn args out/Release --list | grep -E "(dcheck|theme|color)"

# Test specific build targets
autoninja -C out/Release chrome/browser/themes:theme_service
autoninja -C out/Release chrome/browser/ui:ui
```

### Test Patch Application

```bash
cd ~/omarchy-chromium-src/src

# Check if patches applied correctly
git status --porcelain | head -10

# Verify theme-related files were modified
git diff --name-only | grep -i theme

# Check for any compilation warnings related to theme code
autoninja -C out/Release chrome 2>&1 | grep -i theme | head -5
```

## 🔄 Integration Testing

### Full Build Test

```bash
cd ~/omarchy-chromium

# Test complete build process
makepkg -s --noconfirm

# Verify package contents
tar -tf omarchy-chromium-*.pkg.tar.zst | grep -E "(chromium|chrome)" | head -5

# Test package installation (in clean environment)
sudo pacman -U omarchy-chromium-*.pkg.tar.zst --noconfirm
```

### AUR Package Testing

```bash
# Test AUR package creation
cd ~/BUILD_LAB/omarchy-chromium-bin

# Verify PKGBUILD syntax
namcap PKGBUILD

# Test source download
makepkg --verifysource

# Test package build (should use pre-built binary)
makepkg -si --noconfirm
```

## 🚀 Release Testing

### GitHub Release Test

```bash
cd ~/omarchy-chromium

# Test quick release (no build)
SKIP_BUILD=1 ./do_update.sh

# Verify release was created
gh release list | head -3

# Test release download
LATEST_TAG=$(gh release list --limit 1 | cut -f1)
gh release download "$LATEST_TAG" --pattern "*.pkg.tar.zst"
```

### Automation Script Testing

```bash
cd ~/omarchy-chromium

# Test upstream checking
./check_upstream.sh
echo "Exit code: $?"

# Test update detection
./update_to_upstream.sh --dry-run  # If supported

# Test smart update
./smart_update.sh --dry-run  # If supported
```

## 🐛 Debug Testing

### Debug Build Testing

```bash
cd ~/omarchy-chromium-src/src

# Create debug build configuration
mkdir -p out/Debug
cp out/Release/args.gn out/Debug/
echo "is_debug = true" >> out/Debug/args.gn
echo "symbol_level = 2" >> out/Debug/args.gn

# Generate debug build
gn gen out/Debug

# Build with debug symbols
autoninja -C out/Debug chrome

# Run tests with debug build
tools/autotest.py -C out/Debug --gtest_repeat=1 chrome/browser/themes/theme_command_line_handler_unittest.cc
```

### Memory Testing

```bash
cd ~/omarchy-chromium-src/src

# Test for memory leaks (requires debug build)
valgrind --tool=memcheck --leak-check=full out/Debug/chrome --no-startup-window --set-default-theme --headless --disable-gpu --no-sandbox
```

## 📊 Performance Testing

### Build Performance

```bash
cd ~/omarchy-chromium-src/src

# Time the build process
time autoninja -C out/Release chrome

# Monitor resource usage during build
htop &  # In another terminal
autoninja -C out/Release chrome
```

### Theme Switch Performance

```bash
# Test theme switch speed
time (out/Release/chrome --no-startup-window --set-color-scheme="dark" & sleep 1; killall chrome)
time (out/Release/chrome --no-startup-window --set-color-scheme="light" & sleep 1; killall chrome)
```

## 🔍 Continuous Testing

### Pre-Commit Testing

```bash
# Before committing patches, run:
cd ~/omarchy-chromium-src/src

# 1. Unit tests
tools/autotest.py -C out/Release --gtest_repeat=1 chrome/browser/themes/theme_command_line_handler_unittest.cc

# 2. Build test
autoninja -C out/Release chrome

# 3. Manual smoke test
out/Release/chrome --no-startup-window --set-default-theme
```

### Post-Build Testing

```bash
# After successful build:
cd ~/omarchy-chromium

# 1. Package integrity
namcap omarchy-chromium-*.pkg.tar.zst

# 2. Installation test
sudo pacman -U omarchy-chromium-*.pkg.tar.zst

# 3. Functionality test
chromium --no-startup-window --set-color-scheme="dark"
```

## 📋 Test Checklist

Use this checklist for comprehensive testing:

### ✅ Unit Tests
- [ ] `theme_command_line_handler_unittest.cc` passes
- [ ] All 7 test cases pass individually
- [ ] No memory leaks in debug build
- [ ] Tests pass with `--gtest_repeat=10`

### ✅ Integration Tests  
- [ ] Full build completes successfully
- [ ] All theme switches work manually
- [ ] Package builds without errors
- [ ] AUR package updates correctly

### ✅ Regression Tests
- [ ] No existing functionality broken
- [ ] Performance not degraded
- [ ] Memory usage within normal limits
- [ ] No new compiler warnings

### ✅ Release Tests
- [ ] GitHub release created successfully
- [ ] Package download and install works
- [ ] AUR package metadata correct
- [ ] Version numbers consistent

## 🚨 Troubleshooting Test Failures

### Test Compilation Fails
```bash
# Clean and rebuild test targets
cd ~/omarchy-chromium-src/src
rm -rf out/Release/obj/chrome/browser/themes
autoninja -C out/Release chrome/browser/themes:unit_tests
```

### Tests Crash or Hang
```bash
# Run with debugging
tools/autotest.py -C out/Release --gtest_repeat=1 --gtest_break_on_failure chrome/browser/themes/theme_command_line_handler_unittest.cc
```

### Theme Switches Don't Work
```bash
# Check if patch applied correctly
cd ~/omarchy-chromium-src/src
git log --oneline -n 5 | grep -i theme
git diff HEAD~1 | grep -A5 -B5 "set-user-color"
```

---

💡 **Testing Tips**: Always test in a clean environment when possible, and run the full test suite before any release!