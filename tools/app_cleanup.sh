#!/bin/bash

# Application Cleanup Tool
# Safely cleans application data, caches, and unused apps

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

DRY_RUN=${DRY_RUN:-false}

log INFO "Starting Application Cleanup..."
echo ""

# Function to clean directory
clean_dir() {
    local dir=$1
    local name=$2
    local safe=${3:-true}

    if [[ ! -d "$dir" ]]; then
        return
    fi

    local size_before=$(du -sh "$dir" 2>/dev/null | awk '{print $1}' || echo "0B")
    local count=$(find "$dir" -type f 2>/dev/null | wc -l | tr -d ' ')

    if [[ $count -eq 0 ]]; then
        return
    fi

    log INFO "$name: $size_before ($count files)"

    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "[DRY RUN] Would clean: $dir"
    else
        if [[ "$safe" == "true" ]]; then
            find "$dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
            local size_after=$(du -sh "$dir" 2>/dev/null | awk '{print $1}' || echo "0B")
            log SUCCESS "$name: Cleaned (was $size_before, now $size_after)"
        else
            log WARNING "Skipping unsafe directory: $dir"
        fi
    fi
}

total_freed=0

# Browser caches (safe to clean)
echo "=========================================="
echo "  Browser Caches (Safe to Clean)"
echo "=========================================="
log WARNING "⚠️  Close browsers before cleaning their caches!"
echo ""
app_support="$HOME/Library/Application Support"

browser_caches=(
    "$app_support/Google/Chrome/Default/Cache"
    "$app_support/Google/Chrome/Default/Code Cache"
    "$app_support/com.google.Chrome/Default/Cache"
    "$app_support/com.google.Chrome/Default/Code Cache"
    "$app_support/com.apple.Safari/Cache.db"
    "$app_support/com.operasoftware.Opera/Cache"
    "$app_support/com.mozilla.firefox/Cache"
    "$app_support/com.brave.Browser/Default/Cache"
    "$app_support/com.microsoft.edgemac/Default/Cache"
)

for cache_dir in "${browser_caches[@]}"; do
    if [[ -d "$cache_dir" ]] || [[ -f "$cache_dir" ]]; then
        size=$(du -sk "$cache_dir" 2>/dev/null | awk '{print $1}' || echo "0")
        total_freed=$((total_freed + size))
        clean_dir "$cache_dir" "$(basename "$(dirname "$cache_dir")") Cache" true
    fi
done
echo ""

# Development tool caches and derived data
echo "=========================================="
echo "  Development Tool Cleanup"
echo "=========================================="

# Xcode Derived Data
xcode_derived="$HOME/Library/Developer/Xcode/DerivedData"
if [[ -d "$xcode_derived" ]]; then
    size=$(du -sk "$xcode_derived" 2>/dev/null | awk '{print $1}' || echo "0")
    total_freed=$((total_freed + size))
    clean_dir "$xcode_derived" "Xcode DerivedData" true
fi

# Xcode Archives (old builds)
xcode_archives="$HOME/Library/Developer/Xcode/Archives"
if [[ -d "$xcode_archives" ]]; then
    # Only clean archives older than 90 days
    old_archives=$(find "$xcode_archives" -type d -mtime +90 2>/dev/null | wc -l | tr -d ' ')
    if [[ $old_archives -gt 0 ]]; then
        old_size=$(find "$xcode_archives" -type d -mtime +90 -exec du -ck {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
        total_freed=$((total_freed + old_size))

        if [[ "$DRY_RUN" == "true" ]]; then
            log INFO "[DRY RUN] Would remove $old_archives old Xcode archives"
        else
            find "$xcode_archives" -type d -mtime +90 -exec rm -rf {} + 2>/dev/null || true
            log SUCCESS "Removed $old_archives old Xcode archives"
        fi
    fi
fi

# JetBrains caches
jetbrains_cache="$app_support/JetBrains"
if [[ -d "$jetbrains_cache" ]]; then
    # Clean caches but keep settings
    for ide_dir in "$jetbrains_cache"/*; do
        if [[ -d "$ide_dir" ]]; then
            ide_name=$(basename "$ide_dir")
            if [[ -d "$ide_dir/caches" ]]; then
                size=$(du -sk "$ide_dir/caches" 2>/dev/null | awk '{print $1}' || echo "0")
                total_freed=$((total_freed + size))
                clean_dir "$ide_dir/caches" "$ide_name caches" true
            fi
            if [[ -d "$ide_dir/logs" ]]; then
                size=$(du -sk "$ide_dir/logs" 2>/dev/null | awk '{print $1}' || echo "0")
                total_freed=$((total_freed + size))
                clean_dir "$ide_dir/logs" "$ide_name logs" true
            fi
        fi
    done
fi

# VS Code caches
vscode_cache="$app_support/Code/Cache"
if [[ -d "$vscode_cache" ]]; then
    size=$(du -sk "$vscode_cache" 2>/dev/null | awk '{print $1}' || echo "0")
    total_freed=$((total_freed + size))
    clean_dir "$vscode_cache" "VS Code Cache" true
fi

# VS Code CachedData
vscode_cached="$app_support/Code/CachedData"
if [[ -d "$vscode_cached" ]]; then
    size=$(du -sk "$vscode_cached" 2>/dev/null | awk '{print $1}' || echo "0")
    total_freed=$((total_freed + size))
    clean_dir "$vscode_cached" "VS Code CachedData" true
fi
echo ""

# Application crash reports and logs
echo "=========================================="
echo "  Application Logs & Crash Reports"
echo "=========================================="
crash_reports="$HOME/Library/Logs/DiagnosticReports"
if [[ -d "$crash_reports" ]]; then
    # Clean crash reports older than 30 days
    old_crashes=$(find "$crash_reports" -type f -mtime +30 2>/dev/null | wc -l | tr -d ' ')
    if [[ $old_crashes -gt 0 ]]; then
        old_size=$(find "$crash_reports" -type f -mtime +30 -exec du -ck {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
        total_freed=$((total_freed + old_size))

        if [[ "$DRY_RUN" == "true" ]]; then
            log INFO "[DRY RUN] Would remove $old_crashes old crash reports"
        else
            find "$crash_reports" -type f -mtime +30 -delete 2>/dev/null || true
            log SUCCESS "Removed $old_crashes old crash reports"
        fi
    fi
fi

# Application-specific logs
app_logs="$HOME/Library/Logs"
if [[ -d "$app_logs" ]]; then
    # Clean logs older than 30 days from app-specific folders
    for log_dir in "$app_logs"/*; do
        if [[ -d "$log_dir" ]]; then
            app_name=$(basename "$log_dir")
            old_logs=$(find "$log_dir" -type f -mtime +30 2>/dev/null | wc -l | tr -d ' ')
            if [[ $old_logs -gt 0 ]]; then
                old_size=$(find "$log_dir" -type f -mtime +30 -exec du -ck {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
                total_freed=$((total_freed + old_size))

                if [[ "$DRY_RUN" == "true" ]]; then
                    log INFO "[DRY RUN] Would remove $old_logs old logs from $app_name"
                else
                    find "$log_dir" -type f -mtime +30 -delete 2>/dev/null || true
                    log SUCCESS "Removed $old_logs old logs from $app_name"
                fi
            fi
        fi
    done
fi
echo ""

# Steam download cache (safe to clean)
echo "=========================================="
echo "  Game Platform Cleanup"
echo "=========================================="
steam_cache="$app_support/Steam/appcache"
if [[ -d "$steam_cache" ]]; then
    size=$(du -sk "$steam_cache" 2>/dev/null | awk '{print $1}' || echo "0")
    total_freed=$((total_freed + size))
    clean_dir "$steam_cache" "Steam appcache" true
fi

# Battle.net cache
battlenet_cache="$app_support/Battle.net/Cache"
if [[ -d "$battlenet_cache" ]]; then
    size=$(du -sk "$battlenet_cache" 2>/dev/null | awk '{print $1}' || echo "0")
    total_freed=$((total_freed + size))
    clean_dir "$battlenet_cache" "Battle.net Cache" true
fi
echo ""

# Convert to human readable
if [[ $total_freed -gt 0 ]]; then
    freed_mb=$((total_freed / 1024))
    freed_gb=$((freed_mb / 1024))

    if [[ $freed_gb -gt 0 ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log INFO "[DRY RUN] Would free approximately ${freed_gb}GB (${freed_mb}MB)"
        else
            log SUCCESS "Application cleanup completed! Approximately ${freed_gb}GB (${freed_mb}MB) freed"
        fi
    else
        if [[ "$DRY_RUN" == "true" ]]; then
            log INFO "[DRY RUN] Would free approximately ${freed_mb}MB"
        else
            log SUCCESS "Application cleanup completed! Approximately ${freed_mb}MB freed"
        fi
    fi
else
    log INFO "No significant application data found to clean"
fi

echo ""
log INFO "Note: Application settings and user data were preserved"
log INFO "Only caches, logs, and temporary data were cleaned"
