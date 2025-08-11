# Building Chromium with RBE (Remote Build Execution)

This branch (`rbe-build-setup`) includes modifications to build Chromium using Google's Remote Build Execution service.

## Prerequisites

1. **depot_tools**: Install Chromium's depot_tools
   ```bash
   git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
   export PATH="$PATH:/path/to/depot_tools"
   ```

2. **Authentication**: You need proper authentication for RBE access
   - Either use Application Default Credentials
   - Or provide a service account key

3. **RBE Access**: Ensure you have access to the RBE instance:
   - Project: `rbe-chromium-untrusted`
   - Instance: `projects/rbe-chromium-untrusted/instances/default_instance`

## Files Modified for RBE

1. **fetch-chromium-release-rbe**: Custom fetch script with RBE configuration in `.gclient`
2. **PKGBUILD.rbe**: Modified PKGBUILD that:
   - Uses `_manual_clone=1` to trigger gclient sync
   - Includes RBE build flags
   - Uses the custom fetch script
3. **build-with-rbe.sh**: Convenience script that sets up environment variables

## Building

### Option 1: Using the build script (Recommended)
```bash
./build-with-rbe.sh
```

### Option 2: Manual build with environment setup
```bash
# Set up RBE environment
export RBE_service="remotebuildexecution.googleapis.com:443"
export RBE_instance="projects/rbe-chromium-untrusted/instances/default_instance"
export SISO_PROJECT="rbe-chromium-untrusted"
export SISO_ENABLE=1
export NINJA_JOBS=800

# Build using the RBE PKGBUILD
makepkg -p PKGBUILD.rbe -si
```

## What's Different?

1. **gclient sync**: The build uses `gclient sync` to fetch dependencies with RBE configuration
2. **.gclient config**: Includes `rbe_instance` and `checkout_clang_tidy` in custom_vars
3. **Build flags**: Added `use_remoteexec=true`, `use_siso=true`, and RBE configuration
4. **Parallel jobs**: Can handle 800+ parallel jobs with remote execution

## Expected Build Time

With RBE properly configured:
- **With RBE**: 30-60 minutes
- **Without RBE**: 4-8 hours

## Troubleshooting

1. **Authentication errors**: Check your RBE credentials
2. **Siso not starting**: Verify SISO_PROJECT and SISO_ENABLE are set
3. **Falling back to local build**: Check RBE_instance configuration
4. **depot_tools not found**: Ensure depot_tools is in your PATH