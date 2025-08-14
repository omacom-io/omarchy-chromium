#!/bin/bash
set -euo pipefail

# nightly_build.sh - Run the smart update in a zellij session for nightly builds
# This allows attaching to the session to monitor progress or fix issues

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_NAME="omarchy-nightly"
LOG_FILE="$SCRIPT_DIR/nightly_build.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting nightly build check..." | tee -a "$LOG_FILE"

# Check if zellij is installed
if ! command -v zellij &> /dev/null; then
    echo "Error: zellij is not installed. Install with: sudo pacman -S zellij" | tee -a "$LOG_FILE"
    exit 1
fi

# Check if session already exists
if zellij list-sessions 2>/dev/null | grep -q "^$SESSION_NAME"; then
    echo "Warning: Session '$SESSION_NAME' already exists!" | tee -a "$LOG_FILE"
    echo "To attach to it: zellij attach $SESSION_NAME" | tee -a "$LOG_FILE"
    echo "To kill it: zellij kill-session $SESSION_NAME" | tee -a "$LOG_FILE"
    exit 1
fi

# Make sure we're in the right directory
cd "$SCRIPT_DIR"

# Create a wrapper script that will run in the zellij session
# This ensures proper environment and logging
cat > /tmp/omarchy_nightly_wrapper.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "========================================"
echo "Omarchy Chromium Nightly Build"
echo "Started at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo ""

cd /home/arch/omarchy-chromium

# Run the smart update
./smart_update.sh

EXIT_CODE=$?
echo ""
echo "========================================"
echo "Nightly build finished at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Exit code: $EXIT_CODE"
echo "========================================"

# Keep the session alive for review
if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "⚠️  Build failed! Session will remain open for debugging."
    echo "To attach: zellij attach omarchy-nightly"
    read -p "Press Enter to close this session..."
else
    echo ""
    echo "✅ Build completed successfully!"
    echo "Session will close in 10 seconds..."
    sleep 10
fi
EOF

chmod +x /tmp/omarchy_nightly_wrapper.sh

# Create new zellij session and run the wrapper script
echo "Creating zellij session '$SESSION_NAME'..." | tee -a "$LOG_FILE"
zellij --session "$SESSION_NAME" run -- /tmp/omarchy_nightly_wrapper.sh

# Clean up wrapper script
rm -f /tmp/omarchy_nightly_wrapper.sh

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Nightly build session completed" | tee -a "$LOG_FILE"