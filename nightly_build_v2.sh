#!/bin/bash
set -euo pipefail

# nightly_build_v2.sh - Alternative approach using zellij for nightly builds
# This version uses a simpler zellij invocation

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
if zellij list-sessions 2>/dev/null | grep -q "$SESSION_NAME"; then
    echo "Warning: Session '$SESSION_NAME' already exists!" | tee -a "$LOG_FILE"
    echo "To attach to it: zellij attach $SESSION_NAME" | tee -a "$LOG_FILE"  
    echo "To kill it: zellij kill-session $SESSION_NAME" | tee -a "$LOG_FILE"
    exit 1
fi

# Make sure we're in the right directory
cd "$SCRIPT_DIR"

echo "Creating zellij session '$SESSION_NAME'..." | tee -a "$LOG_FILE"

# Start zellij in detached mode with the command directly
# This approach avoids the wrapper script complexity
(
    export ZELLIJ_SESSION_NAME="$SESSION_NAME"
    zellij attach "$SESSION_NAME" --create -- bash -c "
        echo '========================================'
        echo 'Omarchy Chromium Nightly Build'
        echo 'Started at: \$(date +\"%Y-%m-%d %H:%M:%S\")'
        echo '========================================'
        echo ''
        
        cd /home/arch/omarchy-chromium
        
        # Run the smart update
        ./smart_update.sh
        EXIT_CODE=\$?
        
        echo ''
        echo '========================================'
        echo 'Nightly build finished at: \$(date +\"%Y-%m-%d %H:%M:%S\")'
        echo 'Exit code: '\$EXIT_CODE
        echo '========================================'
        
        # Keep session alive on failure for debugging
        if [ \$EXIT_CODE -ne 0 ]; then
            echo ''
            echo '⚠️  Build failed! Session will remain open for debugging.'
            echo 'To attach: zellij attach $SESSION_NAME'
            echo 'Press Enter to close this session...'
            read
        else
            echo ''
            echo '✅ Build completed successfully!'
            echo 'Session will close in 10 seconds...'
            sleep 10
        fi
    "
) </dev/null >/dev/null 2>&1 &

# Give zellij a moment to start
sleep 2

# Check if session was created successfully
if zellij list-sessions 2>/dev/null | grep -q "$SESSION_NAME"; then
    echo "✅ Session '$SESSION_NAME' created successfully!" | tee -a "$LOG_FILE"
    echo "To attach: zellij attach $SESSION_NAME" | tee -a "$LOG_FILE"
else
    echo "⚠️  Could not verify session creation" | tee -a "$LOG_FILE"
    echo "Try: zellij list-sessions" | tee -a "$LOG_FILE"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Nightly build session initiated" | tee -a "$LOG_FILE"