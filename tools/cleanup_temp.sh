#!/bin/bash

# Temporary Files Cleanup Tool
# Removes temporary files from various locations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

DRY_RUN=${DRY_RUN:-false}

log INFO "Starting Temporary Files Cleanup..."

# Function to clean directory
clean_temp_dir() {
    local dir=$1
    local name=$2

    if [[ ! -d "$dir" ]]; then
        return
    fi

    local size_before=$(du -sh "$dir" 2>/dev/null | awk '{print $1}' || echo "0B")
    local count=$(find "$dir" -type f 2>/dev/null | wc -l | tr -d ' ')

    if [[ $count -eq 0 ]]; then
        log INFO "$name: No temporary files found"
        return
    fi

    log INFO "$name: Found $count files ($size_before)"

    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "[DRY RUN] Would clean: $dir"
    else
        find "$dir" -type f -delete 2>/dev/null || true
        local size_after=$(du -sh "$dir" 2>/dev/null | awk '{print $1}' || echo "0B")
        log SUCCESS "$name: Cleaned (was $size_before, now $size_after)"
    fi
}

total_freed=0

# User temp directories
echo "=== User Temporary Files ==="
temp_dirs=(
    "$HOME/Downloads/.tmp"
    "$HOME/tmp"
    "$TMPDIR"
    "/tmp"
)

for temp_dir in "${temp_dirs[@]}"; do
    if [[ -d "$temp_dir" && "$temp_dir" != "$HOME" ]]; then
        size=$(du -sk "$temp_dir" 2>/dev/null | awk '{print $1}' || echo "0")
        total_freed=$((total_freed + size))
        clean_temp_dir "$temp_dir" "$(basename "$temp_dir")"
    fi
done
echo ""

# Clean old files from Downloads (older than 90 days, but keep directory structure)
if [[ -d "$HOME/Downloads" ]]; then
    echo "=== Old Downloads ==="
    old_count=$(find "$HOME/Downloads" -type f -mtime +90 2>/dev/null | wc -l | tr -d ' ')
    if [[ $old_count -gt 0 ]]; then
        old_size=$(find "$HOME/Downloads" -type f -mtime +90 -exec du -ck {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
        total_freed=$((total_freed + old_size))

        if [[ "$DRY_RUN" == "true" ]]; then
            log INFO "[DRY RUN] Would remove $old_count old files from Downloads"
        else
            find "$HOME/Downloads" -type f -mtime +90 -delete 2>/dev/null || true
            log SUCCESS "Removed $old_count old files from Downloads"
        fi
    else
        log INFO "No old files in Downloads"
    fi
    echo ""
fi

# Clean macOS specific temp files
echo "=== macOS Temporary Files ==="
macos_temp=(
    "$HOME/Library/Caches/com.apple.Safari/WebKitCache"
    "$HOME/.DS_Store"
)

# Remove .DS_Store files (user confirmation might be good, but for automation...)
if [[ "$DRY_RUN" == "true" ]]; then
    ds_store_count=$(find "$HOME" -name ".DS_Store" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [[ $ds_store_count -gt 0 ]]; then
        log INFO "[DRY RUN] Would remove $ds_store_count .DS_Store files"
    fi
else
    # Only remove .DS_Store from safe locations
    find "$HOME/Downloads" -name ".DS_Store" -type f -delete 2>/dev/null || true
    find "$HOME/Desktop" -name ".DS_Store" -type f -delete 2>/dev/null || true
fi

# Convert to human readable
if [[ $total_freed -gt 0 ]]; then
    freed_mb=$((total_freed / 1024))
    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "[DRY RUN] Would free approximately ${freed_mb}MB"
    else
        log SUCCESS "Temporary files cleanup completed! Approximately ${freed_mb}MB freed"
    fi
else
    log INFO "No significant temporary files found to clean"
fi
