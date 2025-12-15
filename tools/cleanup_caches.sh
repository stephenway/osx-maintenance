#!/bin/bash

# System Cache Cleanup Tool
# Safely removes system and user caches

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

DRY_RUN=${DRY_RUN:-false}

log INFO "Starting Cache Cleanup..."
log WARNING "⚠️  Some apps (browsers, Electron apps) may need to be closed before cleaning their caches."
log WARNING "The script will warn you about running apps, but it's best to close them first."
echo ""

# Function to check if a process is running
is_process_running() {
    local process_name=$1
    pgrep -f "$process_name" > /dev/null 2>&1
}

# Function to warn about running apps
check_running_apps() {
    local cache_name=$1
    local app_process=$2

    if is_process_running "$app_process"; then
        log WARNING "$cache_name: Application is currently running!"
        log WARNING "Close $cache_name before cleaning its cache to avoid issues."
        echo ""
        echo -n "Continue anyway? (y/N): "
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    return 0
}

# Function to calculate directory size
get_size() {
    local dir=$1
    if [[ -d "$dir" ]]; then
        du -sh "$dir" 2>/dev/null | awk '{print $1}' || echo "0B"
    else
        echo "0B"
    fi
}

# Function to clean directory
clean_dir() {
    local dir=$1
    local name=$2
    local skip_check=${3:-false}

    if [[ ! -d "$dir" ]]; then
        log INFO "$name: Directory does not exist, skipping"
        return
    fi

    local size_before=$(get_size "$dir")
    log INFO "$name: $size_before before cleanup"

    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "[DRY RUN] Would clean: $dir"
    else
        # Remove contents but keep directory structure
        find "$dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
        local size_after=$(get_size "$dir")
        log SUCCESS "$name: Cleaned (was $size_before)"
    fi
}

total_freed=0

# User caches
echo "=== User Caches ==="
user_caches=(
    "$HOME/Library/Caches"
    "$HOME/Library/Application Support/CrashReporter"
    "$HOME/.Trash"
)

for cache_dir in "${user_caches[@]}"; do
    if [[ -d "$cache_dir" ]]; then
        size=$(du -sk "$cache_dir" 2>/dev/null | awk '{print $1}' || echo "0")
        total_freed=$((total_freed + size))
        clean_dir "$cache_dir" "$(basename "$cache_dir")"
    fi
done
echo ""

# Browser caches
echo "=== Browser Caches ==="
log WARNING "⚠️  Close browsers before cleaning their caches to avoid data loss or crashes!"

browser_caches=(
    "$HOME/Library/Caches/Google/Chrome|Google Chrome|Google Chrome"
    "$HOME/Library/Caches/com.google.Chrome|Google Chrome|Google Chrome"
    "$HOME/Library/Caches/com.apple.Safari|Safari|Safari"
    "$HOME/Library/Caches/com.operasoftware.Opera|Opera|Opera"
    "$HOME/Library/Caches/com.mozilla.firefox|Firefox|firefox"
)

for cache_entry in "${browser_caches[@]}"; do
    IFS='|' read -r cache_dir cache_name process_name <<< "$cache_entry"
    if [[ -d "$cache_dir" ]]; then
        # Check if app is running (non-interactive if DRY_RUN)
        if [[ "$DRY_RUN" != "true" ]]; then
            if ! check_running_apps "$cache_name" "$process_name"; then
                log INFO "Skipping $cache_name cache (user cancelled)"
                continue
            fi
        else
            if is_process_running "$process_name"; then
                log WARNING "[DRY RUN] $cache_name is running - close it before cleaning in real mode"
            fi
        fi

        size=$(du -sk "$cache_dir" 2>/dev/null | awk '{print $1}' || echo "0")
        total_freed=$((total_freed + size))
        clean_dir "$cache_dir" "$cache_name"
    fi
done
echo ""

# System caches (requires admin)
if [[ $EUID -eq 0 ]]; then
    echo "=== System Caches ==="
    system_caches=(
        "/Library/Caches"
        "/System/Library/Caches"
        "/private/var/folders"
    )

    for cache_dir in "${system_caches[@]}"; do
        if [[ -d "$cache_dir" ]]; then
            size=$(du -sk "$cache_dir" 2>/dev/null | awk '{print $1}' || echo "0")
            total_freed=$((total_freed + size))
            clean_dir "$cache_dir" "$(basename "$cache_dir")"
        fi
    done
    echo ""
else
    log INFO "Skipping system caches (requires root privileges)"
fi

# Xcode derived data (if exists)
if [[ -d "$HOME/Library/Developer/Xcode/DerivedData" ]]; then
    echo "=== Xcode Derived Data ==="
    size=$(du -sk "$HOME/Library/Developer/Xcode/DerivedData" 2>/dev/null | awk '{print $1}' || echo "0")
    total_freed=$((total_freed + size))
    clean_dir "$HOME/Library/Developer/Xcode/DerivedData" "Xcode DerivedData"
    echo ""
fi

# Convert to human readable
if [[ $total_freed -gt 0 ]]; then
    freed_mb=$((total_freed / 1024))
    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "[DRY RUN] Would free approximately ${freed_mb}MB"
    else
        log SUCCESS "Cache cleanup completed! Approximately ${freed_mb}MB freed"
    fi
else
    log INFO "No significant caches found to clean"
fi
