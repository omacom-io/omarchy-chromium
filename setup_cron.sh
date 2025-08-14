#!/bin/bash
set -euo pipefail

# setup_cron.sh - Helper script to set up the nightly build cron job

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIGHTLY_SCRIPT="$SCRIPT_DIR/nightly_build.sh"
CRON_LOG="$SCRIPT_DIR/cron.log"

echo "=== Omarchy Chromium Nightly Build Cron Setup ==="
echo ""

# Check if nightly_build.sh exists and is executable
if [[ ! -f "$NIGHTLY_SCRIPT" ]]; then
    echo "Error: nightly_build.sh not found at $NIGHTLY_SCRIPT"
    exit 1
fi

if [[ ! -x "$NIGHTLY_SCRIPT" ]]; then
    echo "Making nightly_build.sh executable..."
    chmod +x "$NIGHTLY_SCRIPT"
fi

# Check if zellij is installed
if ! command -v zellij &> /dev/null; then
    echo "Error: zellij is not installed"
    echo "Please install it first: sudo pacman -S zellij"
    exit 1
fi

# Define the cron job
CRON_CMD="0 1 * * * $NIGHTLY_SCRIPT >> $CRON_LOG 2>&1"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "nightly_build.sh"; then
    echo "⚠️  Cron job already exists:"
    crontab -l | grep "nightly_build.sh"
    echo ""
    read -p "Do you want to replace it? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing cron job."
        exit 0
    fi
    echo "Removing existing cron job..."
    (crontab -l 2>/dev/null | grep -v "nightly_build.sh") | crontab -
fi

# Add the cron job
echo "Adding cron job to run at 01:00 daily..."
(crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -

echo ""
echo "✅ Cron job successfully added!"
echo ""
echo "Current cron configuration:"
crontab -l | grep "nightly_build.sh" || true
echo ""
echo "The nightly build will:"
echo "  • Run daily at 01:00"
echo "  • Check for upstream changes"
echo "  • Only build if Arch has new Chromium version"
echo "  • Create a zellij session named 'omarchy-nightly'"
echo "  • Log output to: $CRON_LOG"
echo ""
echo "Useful commands:"
echo "  • Attach to running build: zellij attach omarchy-nightly"
echo "  • View cron logs: tail -f $CRON_LOG"
echo "  • View build logs: tail -f $SCRIPT_DIR/nightly_build.log"
echo "  • List zellij sessions: zellij list-sessions"
echo "  • Kill stuck session: zellij kill-session omarchy-nightly"
echo "  • Remove cron job: crontab -l | grep -v nightly_build.sh | crontab -"
echo ""
echo "To test the setup now (without waiting for 01:00):"
echo "  ./nightly_build.sh"