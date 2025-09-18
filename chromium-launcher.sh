#!/bin/bash
# Chromium launcher script for ARM64 - feature-parity with C launcher
# This script reads flags from config files and launches chromium

CHROMIUM_NAME="chromium"
CHROMIUM_BINARY="/usr/lib/chromium/chromium"
CHROMIUM_VENDOR="Arch Linux"
LAUNCHER_VERSION="v8-bash"

# Function to show help
show_help() {
    local system_flags="$1"
    local user_flags="$2"

    cat >&2 <<EOF

Chromium launcher $LAUNCHER_VERSION -- for Chromium help, see \`man $CHROMIUM_NAME\`

Custom flags are read in order from the following files:

  $system_flags
  $user_flags

Arguments included in those files are split on whitespace and shell quoting
rules apply but no further parsing is performed. Lines starting with a hash
symbol (#) are skipped. Lines with unbalanced quotes are skipped as well.

EOF

    if [ ${#ALL_FLAGS[@]} -gt 0 ]; then
        echo "Currently detected flags:" >&2
        echo >&2
        for flag in "${ALL_FLAGS[@]}"; do
            echo "  $flag" >&2
        done
        echo >&2
    fi
}

# Function to read flags from a config file
read_flags() {
    local conf_file="$1"
    local flags=()

    if [ ! -f "$conf_file" ]; then
        return
    fi

    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Parse the line with shell quoting rules
        # Using eval is necessary here to handle quoted arguments properly
        # This matches the g_shell_parse_argv behavior in the C version
        eval "local parsed_args=($line)" 2>/dev/null || continue

        # Add parsed arguments to flags array
        for arg in "${parsed_args[@]}"; do
            flags+=("$arg")
        done
    done < "$conf_file"

    echo "${flags[@]}"
}

# Determine config file paths
SYSTEM_FLAGS_CONF="/etc/${CHROMIUM_NAME}-flags.conf"

if [ -n "$XDG_CONFIG_HOME" ]; then
    USER_FLAGS_CONF="$XDG_CONFIG_HOME/${CHROMIUM_NAME}-flags.conf"
elif [ -n "$HOME" ]; then
    USER_FLAGS_CONF="$HOME/.config/${CHROMIUM_NAME}-flags.conf"
else
    USER_FLAGS_CONF=""
fi

# Read flags from config files
ALL_FLAGS=()

# Read system flags
if [ -f "$SYSTEM_FLAGS_CONF" ]; then
    system_flags=($(read_flags "$SYSTEM_FLAGS_CONF"))
    ALL_FLAGS+=("${system_flags[@]}")
fi

# Read user flags
if [ -n "$USER_FLAGS_CONF" ] && [ -f "$USER_FLAGS_CONF" ]; then
    user_flags=($(read_flags "$USER_FLAGS_CONF"))
    ALL_FLAGS+=("${user_flags[@]}")
fi

# Check for help flag
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help "$SYSTEM_FLAGS_CONF" "$USER_FLAGS_CONF"
    exit 0
fi

# Set environment variables (matching the C launcher)
export CHROME_WRAPPER="$0"
export CHROME_DESKTOP="${CHROMIUM_NAME}.desktop"
export CHROME_VERSION_EXTRA="$CHROMIUM_VENDOR"

# Build the complete command line
exec "$CHROMIUM_BINARY" "${ALL_FLAGS[@]}" "$@"