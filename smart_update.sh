#!/bin/bash
set -euo pipefail

export PATH=~/depot_tools/:$PATH
export SISO_CREDENTIAL_HELPER=gcloud

# smart_update.sh - Only builds and pushes to AUR when upstream changes are detected
# This ensures we only update the AUR package when there's a new Chromium release

# Webhook URL for n8n notifications (set via environment variable)
WEBHOOK_URL="${N8N_WEBHOOK_URL:-}"

# Function to send failure notification
send_failure_notification() {
    local error_message="$1"
    local step="$2"

    if [[ -n "$WEBHOOK_URL" ]]; then
        curl -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"status\":\"failed\",\"step\":\"$step\",\"error\":\"$error_message\",\"timestamp\":\"$(date -Iseconds)\"}" \
            2>/dev/null || true
    fi
}

# Trap errors and send notifications
trap 'send_failure_notification "Script failed at line $LINENO" "unknown"' ERR

send_failure_notification "AHAHAHAHAH" "UNKOWN"
exit

echo "=== Omarchy Chromium Smart Update ==="
echo "This script only builds and releases when upstream Chromium has changes"
echo ""

# Check prerequisites
if [[ ! -f "check_upstream.sh" ]]; then
    error_msg="check_upstream.sh not found"
    echo "Error: $error_msg"
    send_failure_notification "$error_msg" "prerequisites"
    exit 1
fi

if [[ ! -f "update_to_upstream.sh" ]]; then
    error_msg="update_to_upstream.sh not found"
    echo "Error: $error_msg"
    send_failure_notification "$error_msg" "prerequisites"
    exit 1
fi

if [[ ! -f "do_update.sh" ]]; then
    error_msg="do_update.sh not found"
    echo "Error: $error_msg"
    send_failure_notification "$error_msg" "prerequisites"
    exit 1
fi

# Check for upstream changes
echo "Step 1: Checking for upstream changes..."
if ./check_upstream.sh; then
    echo ""
    echo "Step 2: Upstream changes detected, proceeding with update..."
    echo "========================================================"

    rm -vfr ~/omarchy-chromium-src/src/out/*

    # Update to latest upstream version
    echo ""
    echo "Running update_to_upstream.sh to sync with latest Chromium..."
    if ! ./update_to_upstream.sh; then
        error_msg="Failed to update to upstream version"
        echo "Error: $error_msg"
        send_failure_notification "$error_msg" "update_to_upstream"
        exit 1
    fi

    # Build and release
    echo ""
    echo "========================================================"
    echo "Running do_update.sh to build and release..."
    echo ""

    if ! ./do_update.sh; then
        error_msg="Failed to build and release"
        echo "Error: $error_msg"
        send_failure_notification "$error_msg" "do_update"
        exit 1
    fi

    echo ""
    echo "=== Smart Update Complete! ==="
    echo "✓ Updated to latest upstream Chromium"
    echo "✓ Built and released new package"
    echo "✓ AUR package updated"
else
    echo ""
    echo "=== No Action Needed ==="
    echo "No upstream changes detected. Skipping build and release."
    echo ""
    echo "If you need to force a release (e.g., for patches or fixes):"
    echo "  ./do_update.sh    # This will increment pkgrel and release"
    echo ""
    echo "To check upstream status again:"
    echo "  ./check_upstream.sh"
fi
