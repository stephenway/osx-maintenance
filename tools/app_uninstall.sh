#!/bin/bash

# Application Uninstaller Tool
# Helps identify and uninstall unused applications

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

log INFO "Application Uninstaller Tool"
echo ""

# Function to get app size
get_app_size() {
    local app_path=$1
    if [[ -d "$app_path" ]]; then
        du -sh "$app_path" 2>/dev/null | awk '{print $1}'
    else
        echo "0B"
    fi
}

# Function to get app last used date
get_last_used() {
    local app_path=$1
    if [[ -d "$app_path" ]]; then
        stat -f "%Sm" -t "%Y-%m-%d" "$app_path" 2>/dev/null || echo "Unknown"
    else
        echo "Unknown"
    fi
}

# Analyze Applications folder
echo "=========================================="
echo "  Installed Applications Analysis"
echo "=========================================="

if [[ ! -d "/Applications" ]]; then
    log ERROR "Applications folder not found"
    exit 1
fi

# Get all applications
apps=()
while IFS= read -r -d '' app; do
    apps+=("$app")
done < <(find /Applications -maxdepth 1 -name "*.app" -type d -print0 2>/dev/null)

total_apps=${#apps[@]}
log INFO "Found $total_apps applications"
echo ""

# Sort by size
echo "Applications sorted by size:"
declare -a app_sizes
for app in "${apps[@]}"; do
    app_name=$(basename "$app" .app)
    app_size=$(get_app_size "$app")
    app_sizes+=("$app_size|$app_name|$app")
done

# Sort by size (simple numeric sort for MB/GB)
printf '%s\n' "${app_sizes[@]}" | sort -t'|' -k1 -hr | head -30 | while IFS='|' read -r size name path; do
    last_used=$(get_last_used "$path")
    printf "  %-40s %8s  (last used: %s)\n" "$name" "$size" "$last_used"
done
echo ""

# Find potentially unused apps (not accessed in 90+ days)
echo "=========================================="
echo "  Potentially Unused Applications"
echo "  (Not accessed in 90+ days)"
echo "=========================================="
unused_count=0
unused_total_size=0

for app in "${apps[@]}"; do
    if [[ -d "$app" ]]; then
        last_access=$(stat -f "%m" "$app" 2>/dev/null || echo "0")
        current_time=$(date +%s)
        days_since_access=$(( (current_time - last_access) / 86400 ))

        if [[ $days_since_access -gt 90 ]]; then
            app_name=$(basename "$app" .app)
            app_size=$(get_app_size "$app")
            unused_count=$((unused_count + 1))

            # Convert size to KB for total
            size_kb=$(du -sk "$app" 2>/dev/null | awk '{print $1}' || echo "0")
            unused_total_size=$((unused_total_size + size_kb))

            printf "  %-40s %8s  (%d days ago)\n" "$app_name" "$app_size" "$days_since_access"
        fi
    fi
done

if [[ $unused_count -eq 0 ]]; then
    log INFO "No unused applications found (all accessed within 90 days)"
else
    unused_mb=$((unused_total_size / 1024))
    unused_gb=$((unused_mb / 1024))

    if [[ $unused_gb -gt 0 ]]; then
        log WARNING "Found $unused_count potentially unused apps (~${unused_gb}GB)"
    else
        log WARNING "Found $unused_count potentially unused apps (~${unused_mb}MB)"
    fi
fi
echo ""

# Check Application Support for orphaned data
echo "=========================================="
echo "  Orphaned Application Support Data"
echo "  (Support folders without corresponding apps)"
echo "=========================================="
app_support="$HOME/Library/Application Support"
orphaned_count=0

if [[ -d "$app_support" ]]; then
    for support_dir in "$app_support"/*; do
        if [[ -d "$support_dir" ]]; then
            dir_name=$(basename "$support_dir")

            # Check if corresponding app exists
            app_found=false
            for app in "${apps[@]}"; do
                app_name=$(basename "$app" .app)
                # Try various name matching patterns
                if [[ "$dir_name" == "$app_name" ]] || \
                   [[ "$dir_name" == "com.$(echo "$app_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '.').mac" ]] || \
                   [[ "$dir_name" == *"$app_name"* ]]; then
                    app_found=true
                    break
                fi
            done

            # Also check common bundle IDs
            if [[ "$dir_name" =~ ^com\. ]] && [[ "$app_found" == "false" ]]; then
                # Might be a bundle ID, check if we can find the app
                app_found=false  # Keep checking
            fi

            # Skip system and common folders
            if [[ "$dir_name" == "ByHost" ]] || \
               [[ "$dir_name" == "MobileSync" ]] || \
               [[ "$dir_name" == "com.apple"* ]]; then
                continue
            fi

            # If not found and size is significant, flag it
            if [[ "$app_found" == "false" ]]; then
                dir_size=$(du -sk "$support_dir" 2>/dev/null | awk '{print $1}' || echo "0")
                if [[ $dir_size -gt 10240 ]]; then  # More than 10MB
                    dir_size_mb=$((dir_size / 1024))
                    echo "  $dir_name: ${dir_size_mb}MB"
                    orphaned_count=$((orphaned_count + 1))
                fi
            fi
        fi
    done

    if [[ $orphaned_count -eq 0 ]]; then
        log INFO "No significant orphaned Application Support data found"
    else
        log WARNING "Found $orphaned_count potentially orphaned Application Support folders"
        log INFO "Review these folders - they may be safe to remove if apps are uninstalled"
    fi
fi
echo ""

# Interactive uninstall
echo "=========================================="
echo "  Uninstall Applications"
echo "=========================================="
log INFO "To uninstall an application:"
echo "  1. Drag it from /Applications to Trash"
echo "  2. Empty Trash"
echo "  3. Run this tool again to clean up Application Support data"
echo ""
log INFO "For App Store apps, use: mas uninstall <app_id>"
log INFO "For Homebrew casks, use: brew uninstall --cask <app_name>"
echo ""

log SUCCESS "Application analysis completed!"
