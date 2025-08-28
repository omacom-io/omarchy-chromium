#!/bin/bash

# validate.sh - Check architecture of binaries in latest .zst package files

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to get the expected architecture from filename
get_expected_arch_from_filename() {
    local filename=$1
    if [[ "$filename" == *"aarch64"* ]]; then
        echo "aarch64"
    elif [[ "$filename" == *"x86_64"* ]]; then
        echo "x86_64"
    else
        echo "unknown"
    fi
}

# Function to convert file arch to package arch format
normalize_arch() {
    local arch=$1
    case "$arch" in
        "x86-64"|"x86_64")
            echo "x86_64"
            ;;
        "aarch64"|"ARM aarch64")
            echo "aarch64"
            ;;
        *)
            echo "$arch"
            ;;
    esac
}

# Function to check architecture of a binary file
check_binary_arch() {
    local filepath=$1
    local expected_arch=$2
    
    # Check if file exists and is executable
    if [[ ! -f "$filepath" ]]; then
        return 0  # Skip non-existent files
    fi
    
    # Use file command to get architecture info
    local file_info=$(file "$filepath" 2>/dev/null || echo "unknown")
    
    # Extract architecture from file output
    local actual_arch=""
    if [[ "$file_info" == *"x86-64"* ]] || [[ "$file_info" == *"x86_64"* ]]; then
        actual_arch="x86_64"
    elif [[ "$file_info" == *"aarch64"* ]] || [[ "$file_info" == *"ARM aarch64"* ]]; then
        actual_arch="aarch64"
    elif [[ "$file_info" == *"ELF"* ]]; then
        # Try to get more specific info with readelf if available
        if command -v readelf >/dev/null 2>&1; then
            local readelf_info=$(readelf -h "$filepath" 2>/dev/null | grep "Machine:" || echo "")
            if [[ "$readelf_info" == *"X86-64"* ]] || [[ "$readelf_info" == *"Advanced Micro Devices X86-64"* ]]; then
                actual_arch="x86_64"
            elif [[ "$readelf_info" == *"AArch64"* ]]; then
                actual_arch="aarch64"
            fi
        fi
    else
        # Not an executable binary, skip
        return 0
    fi
    
    if [[ -n "$actual_arch" && "$actual_arch" != "$expected_arch" ]]; then
        print_status "$RED" "  ❌ ARCH MISMATCH: $filepath"
        print_status "$RED" "     Expected: $expected_arch, Found: $actual_arch"
        return 1
    elif [[ -n "$actual_arch" ]]; then
        print_status "$GREEN" "  ✅ $filepath ($actual_arch)"
        return 0
    fi
    
    return 0
}

# Function to validate a .zst package
validate_zst_package() {
    local zst_file=$1
    local temp_dir=$(mktemp -d)
    local validation_failed=0
    
    print_status "$YELLOW" "\n📦 Validating: $zst_file"
    
    # Get expected architecture from filename
    local expected_arch=$(get_expected_arch_from_filename "$zst_file")
    if [[ "$expected_arch" == "unknown" ]]; then
        print_status "$YELLOW" "  ⚠️  Cannot determine expected architecture from filename"
        rm -rf "$temp_dir"
        return 1
    fi
    
    print_status "$YELLOW" "  Expected architecture: $expected_arch"
    
    # Extract the package
    if ! tar -xf "$zst_file" -C "$temp_dir" 2>/dev/null; then
        print_status "$RED" "  ❌ Failed to extract $zst_file"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Find all executable files and shared libraries
    local binary_files=()
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]] && ([[ "$file" == *.so* ]] || [[ -x "$file" ]]); then
            binary_files+=("$file")
        fi
    done < <(find "$temp_dir" -type f \( -executable -o -name "*.so*" \) -print0 2>/dev/null)
    
    if [[ ${#binary_files[@]} -eq 0 ]]; then
        print_status "$YELLOW" "  ⚠️  No binary files found in package"
    else
        print_status "$YELLOW" "  Found ${#binary_files[@]} binary files to check"
        
        # Check each binary file
        for binary in "${binary_files[@]}"; do
            if ! check_binary_arch "$binary" "$expected_arch"; then
                validation_failed=1
            fi
        done
    fi
    
    # Clean up
    rm -rf "$temp_dir"
    
    if [[ $validation_failed -eq 0 ]]; then
        print_status "$GREEN" "  ✅ Package validation PASSED"
        return 0
    else
        print_status "$RED" "  ❌ Package validation FAILED"
        return 1
    fi
}

# Main function
main() {
    print_status "$YELLOW" "🔍 Starting architecture validation of .zst packages..."
    
    # Check for required tools
    if ! command -v file >/dev/null 2>&1; then
        print_status "$RED" "❌ Error: 'file' command not found. Please install file utilities."
        exit 1
    fi
    
    if ! command -v tar >/dev/null 2>&1; then
        print_status "$RED" "❌ Error: 'tar' command not found."
        exit 1
    fi
    
    # Find all .zst files in current directory
    local zst_files=()
    while IFS= read -r -d '' file; do
        zst_files+=("$file")
    done < <(find . -maxdepth 1 -name "*.pkg.tar.zst" -print0 2>/dev/null | sort -z)
    
    if [[ ${#zst_files[@]} -eq 0 ]]; then
        print_status "$YELLOW" "⚠️  No .zst package files found in current directory"
        exit 0
    fi
    
    # Get latest files (by modification time)
    print_status "$YELLOW" "Found ${#zst_files[@]} .zst package files"
    
    # Sort by modification time (newest first) and take latest ones
    local latest_files=()
    while IFS= read -r file; do
        latest_files+=("$file")
    done < <(ls -1t *.pkg.tar.zst 2>/dev/null | head -10)  # Check latest 10 files
    
    local overall_status=0
    
    # Validate each package
    for zst_file in "${latest_files[@]}"; do
        if [[ -f "$zst_file" ]]; then
            if ! validate_zst_package "$zst_file"; then
                overall_status=1
            fi
        fi
    done
    
    print_status "$YELLOW" "\n📋 Validation Summary:"
    if [[ $overall_status -eq 0 ]]; then
        print_status "$GREEN" "✅ All packages passed architecture validation!"
    else
        print_status "$RED" "❌ Some packages failed architecture validation!"
    fi
    
    exit $overall_status
}

# Run main function
main "$@"