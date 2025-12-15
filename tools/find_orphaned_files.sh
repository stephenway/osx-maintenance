#!/bin/bash

# Find Orphaned Application Files
# AppZapper-style tool to find leftover files from uninstalled apps

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

DRY_RUN=${DRY_RUN:-false}
QUICK_SCAN=${QUICK_SCAN:-false}  # Skip size calculations for speed
MACHINE_READABLE=${MACHINE_READABLE:-false}  # Output in machine-readable format

log INFO "Scanning for orphaned application files..."
if [[ "$QUICK_SCAN" == "true" ]]; then
    log INFO "Quick scan mode: Skipping size calculations for faster results"
fi
if [[ "$MACHINE_READABLE" == "true" ]]; then
    # In machine-readable mode, suppress normal output
    exec 3>&1
    exec 1>/dev/null
fi
echo ""

# Get list of currently installed applications
log INFO "Building list of installed applications..."
installed_apps=()
installed_bundle_ids=()

while IFS= read -r -d '' app; do
    app_name=$(basename "$app" .app)
    installed_apps+=("$app_name")

    # Try to get bundle ID
    if [[ -f "$app/Contents/Info.plist" ]]; then
        bundle_id=$(defaults read "$app/Contents/Info.plist" CFBundleIdentifier 2>/dev/null || echo "")
        if [[ -n "$bundle_id" ]]; then
            installed_bundle_ids+=("$bundle_id")
        fi
    fi
done < <(find /Applications -maxdepth 1 -name "*.app" -type d -print0 2>/dev/null)

# Also check /Applications/Utilities
while IFS= read -r -d '' app; do
    app_name=$(basename "$app" .app)
    installed_apps+=("$app_name")

    if [[ -f "$app/Contents/Info.plist" ]]; then
        bundle_id=$(defaults read "$app/Contents/Info.plist" CFBundleIdentifier 2>/dev/null || echo "")
        if [[ -n "$bundle_id" ]]; then
            installed_bundle_ids+=("$bundle_id")
        fi
    fi
done < <(find /Applications/Utilities -maxdepth 1 -name "*.app" -type d -print0 2>/dev/null)

log INFO "Found ${#installed_apps[@]} installed applications"
echo ""

# Function to convert to lowercase (bash 3.2 compatible)
to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# System services and apps that should never be flagged as orphaned
is_system_service() {
    local item_name=$1
    local item_lower=$(to_lower "$item_name")

    # macOS system apps and services
    local system_items=(
        "mail" "music" "tv" "podcasts" "books" "news" "stocks" "maps"
        "facetime" "messages" "calendar" "contacts" "reminders" "notes"
        "photos" "preview" "safari" "finder" "dock" "controlcenter"
        "app store" "system preferences" "system settings"
        "automator" "quicktime" "calculator" "textedit" "terminal"
        "disk utility" "activity monitor" "console" "keychain access"
        "addressbook" "clouddocs" "fileprovider" "knowledge"
        "differentialprivacy" "callhistory" "screenshots" "diskimages"
        "configurationprofiles" "syncservices" "crashreporter"
        "temp" "teams" "openai" "datarecords" "datadumps"
    )

    for system_item in "${system_items[@]}"; do
        if [[ "$item_lower" == "$system_item" ]] || [[ "$item_lower" == *"$system_item"* ]]; then
            return 0
        fi
    done

    # System bundle IDs
    if [[ "$item_name" == "com.apple"* ]]; then
        return 0
    fi

    return 1
}

# Function to check if a folder/file belongs to an installed app
# OPTIMIZED: Check most common cases first
is_installed() {
    local item_name=$1
    local item_path=$2

    # OPTIMIZATION: Fast path - check system services first
    if is_system_service "$item_name"; then
        return 0
    fi

    # OPTIMIZATION: Fast path - check system folders first (most common skip)
    if [[ "$item_name" == "ByHost" ]] || \
       [[ "$item_name" == "MobileSync" ]] || \
       [[ "$item_name" == "Group Containers" ]] || \
       [[ "$item_name" == "Containers" ]]; then
        return 0
    fi

    # OPTIMIZATION: Check bundle IDs first (exact matches are faster)
    for bundle_id in "${installed_bundle_ids[@]}"; do
        if [[ "$item_name" == "$bundle_id" ]]; then
            return 0
        fi
    done

    local item_lower=$(to_lower "$item_name")

    # Check against app names (case-insensitive) - limit to first 100 for speed
    local app_count=0
    for app in "${installed_apps[@]}"; do
        app_count=$((app_count + 1))
        # Limit checks for performance
        if [[ $app_count -gt 100 ]]; then
            break
        fi

        local app_lower=$(to_lower "$app")
        # Direct match (most common)
        if [[ "$item_lower" == "$app_lower" ]] || [[ "$item_lower" == "${app_lower}.app" ]]; then
            return 0
        fi

        # Fuzzy matching for common variations
        # "Google" matches "Google Chrome", "Microsoft" matches "Microsoft Office", etc.
        if [[ "$item_lower" == *"$app_lower"* ]] || [[ "$app_lower" == *"$item_lower"* ]]; then
            # Additional check: make sure it's a meaningful match
            # Skip if item is too short (like "Mail" matching "Mail.app" is fine, but "Go" matching "Google" is not)
            if [[ ${#item_lower} -ge 3 ]] && [[ ${#app_lower} -ge 3 ]]; then
                return 0
            fi
        fi
    done

    # Check bundle ID substring matches (less common, do last)
    for bundle_id in "${installed_bundle_ids[@]}"; do
        if [[ "$item_name" == *"$bundle_id"* ]]; then
            return 0
        fi
    done

    return 1
}

# Function to normalize app name for matching
normalize_name() {
    local name=$1
    # Remove common suffixes/prefixes
    name="${name//com./}"
    name="${name//.mac/}"
    name="${name//.Mac/}"
    name="${name//.app/}"
    name="${name// /}"
    echo "$(to_lower "$name")"  # lowercase
}

# Scan Library directories for orphaned files
total_orphaned_size=0
declare -a orphaned_items

# Pre-build normalized app names for faster lookup (bash 3.2 compatible)
normalized_apps_list=()
build_app_lookup() {
    log INFO "Building app lookup table..."
    for app in "${installed_apps[@]}"; do
        normalized_app=$(normalize_name "$app")
        normalized_apps_list+=("$normalized_app")
        # Also add variations
        normalized_apps_list+=("${normalized_app}.app")
    done
    for bundle_id in "${installed_bundle_ids[@]}"; do
        normalized_apps_list+=("$(to_lower "$bundle_id")")
    done
}

# Function to check if normalized name is in lookup list (bash 3.2 compatible)
is_in_lookup() {
    local search_name=$1
    for lookup_name in "${normalized_apps_list[@]}"; do
        if [[ "$search_name" == "$lookup_name" ]]; then
            return 0
        fi
    done
    return 1
}

scan_directory() {
    local dir=$1
    local dir_name=$2

    if [[ ! -d "$dir" ]]; then
        return
    fi

    # Count items first for progress
    local total_items=$(find "$dir" -maxdepth 1 -mindepth 1 2>/dev/null | wc -l | tr -d ' ')
    if [[ $total_items -eq 0 ]]; then
        return
    fi

    log INFO "Scanning $dir_name... ($total_items items)"
    local item_count=0

    local found_count=0
    local found_size=0

    # Scan top-level items
    for item in "$dir"/*; do
        if [[ ! -e "$item" ]]; then
            continue
        fi

        item_count=$((item_count + 1))
        # Show progress every 100 items (less frequent updates = faster)
        if [[ $((item_count % 100)) -eq 0 ]]; then
            echo -ne "\r  Progress: $item_count/$total_items items checked..."
        fi

        item_name=$(basename "$item")
        item_type="file"
        [[ -d "$item" ]] && item_type="directory"

        # OPTIMIZATION: Fast path - check exact name match first (most common case)
        # Check if it's a system service (skip these)
        if is_system_service "$item_name"; then
            continue
        fi

        # Quick check: skip if it belongs to an installed app (fast path)
        if is_installed "$item_name" "$item"; then
            continue
        fi

        # OPTIMIZATION: Normalize once and reuse
        normalized_item=$(normalize_name "$item_name")

        # Fast lookup using pre-built list (exact match)
        if is_in_lookup "$normalized_item"; then
            continue
        fi

        # OPTIMIZATION: Skip substring matching for items that clearly don't match patterns
        # Only do expensive substring matching for items that look app-like
        local needs_substring_check=true
        if [[ "$item_name" =~ ^[0-9] ]] || \
           [[ "$item_name" =~ ^\. ]] || \
           [[ "$item_type" == "file" && ! "$item_name" =~ \. ]]; then
            needs_substring_check=false
        fi

        # Check substring matches (only if needed and not in list)
        if [[ "$needs_substring_check" == "true" ]]; then
            matched=false
            # OPTIMIZATION: Break early, limit iterations
            local max_checks=50  # Limit substring checks to first 50 apps
            local check_count=0
            for norm_app in "${normalized_apps_list[@]}"; do
                check_count=$((check_count + 1))
                if [[ $check_count -gt $max_checks ]]; then
                    break
                fi
                # Improved fuzzy matching with minimum length check
                if [[ "$normalized_item" == *"$norm_app"* ]] || [[ "$norm_app" == *"$normalized_item"* ]]; then
                    # Make sure match is meaningful (both parts at least 3 chars)
                    if [[ ${#normalized_item} -ge 3 ]] && [[ ${#norm_app} -ge 3 ]]; then
                        matched=true
                        break
                    fi
                fi
            done

            if [[ "$matched" == "true" ]]; then
                continue
            fi
        fi

        # Check if it looks like an app-related folder/file
        if [[ "$item_name" =~ ^[a-zA-Z] ]] && \
           ([[ "$item_name" =~ \. ]] || [[ "$item_type" == "directory" ]]); then

            # OPTIMIZATION: Use faster size estimation for files, defer du for directories
            local item_size_kb=0
            local should_report=false

            # Quick scan mode: skip all size calculations
            if [[ "$QUICK_SCAN" == "true" ]]; then
                # In quick mode, report anything that matches app patterns
                if [[ "$item_name" =~ ^com\. ]] || [[ "$item_name" =~ ^[A-Z] ]]; then
                    should_report=true
                    item_size_kb=0  # Unknown size in quick mode
                fi
            # Normal mode: calculate sizes
            elif [[ "$item_type" == "file" ]]; then
                # For files: use stat (much faster than du)
                local file_size=$(stat -f%z "$item" 2>/dev/null || echo "0")
                item_size_kb=$((file_size / 1024))

                # Report files if they match app patterns OR are >1MB
                if [[ "$item_name" =~ ^com\. ]] || [[ "$item_name" =~ ^[A-Z] ]] || [[ $item_size_kb -gt 1024 ]]; then
                    should_report=true
                fi
            else
                # For directories: only run du if it matches app patterns (defer expensive du)
                if [[ "$item_name" =~ ^com\. ]] || [[ "$item_name" =~ ^[A-Z] ]]; then
                    # This looks like an app, check size
                    item_size_kb=$(du -sk "$item" 2>/dev/null | awk '{print $1}' || echo "0")
                    should_report=true
                else
                    # For other directories, do a quick size check only if it might be large
                    # Use find to count files as a proxy (much faster than du)
                    local file_count=$(find "$item" -type f 2>/dev/null | wc -l | tr -d ' ')
                    if [[ $file_count -gt 100 ]]; then
                        # Only run du if it has many files (likely significant)
                        item_size_kb=$(du -sk "$item" 2>/dev/null | awk '{print $1}' || echo "0")
                        if [[ $item_size_kb -gt 1024 ]]; then
                            should_report=true
                        fi
                    fi
                fi
            fi

            # Only report if significant size (>1MB) or is a known app pattern
            if [[ "$should_report" == "true" ]] || [[ $item_size_kb -gt 1024 ]]; then
                item_size_mb=$((item_size_kb / 1024))
                # Store: location|name|full_path|size_kb|size_mb|type
                orphaned_items+=("$dir_name|$item_name|$item|$item_size_kb|$item_size_mb|$item_type")
                found_count=$((found_count + 1))
                found_size=$((found_size + item_size_kb))
                total_orphaned_size=$((total_orphaned_size + item_size_kb))
            fi
        fi
    done

    echo ""  # New line after progress indicator

    if [[ $found_count -gt 0 ]]; then
        found_size_mb=$((found_size / 1024))
        log WARNING "Found $found_count potentially orphaned items in $dir_name (~${found_size_mb}MB)"
    else
        log INFO "No orphaned items found in $dir_name"
    fi
}

# Build lookup table for faster matching
build_app_lookup

# Scan various Library locations
echo "=========================================="
echo "  Scanning Library Directories"
echo "=========================================="

# Application Support
scan_directory "$HOME/Library/Application Support" "Application Support"

# Preferences
scan_directory "$HOME/Library/Preferences" "Preferences"

# Caches
scan_directory "$HOME/Library/Caches" "Caches"

# Containers (sandboxed apps)
if [[ -d "$HOME/Library/Containers" ]]; then
    log INFO "Scanning Containers (sandboxed apps)..."
    for container in "$HOME/Library/Containers"/*; do
        if [[ -d "$container" ]]; then
            container_name=$(basename "$container")
            if ! is_installed "$container_name" "$container"; then
                container_size_kb=$(du -sk "$container" 2>/dev/null | awk '{print $1}' || echo "0")
                if [[ $container_size_kb -gt 1024 ]]; then
                    container_size_mb=$((container_size_kb / 1024))
                    orphaned_items+=("Containers|$container_name|$container|$container_size_kb|$container_size_mb|directory")
                    total_orphaned_size=$((total_orphaned_size + container_size_kb))
                fi
            fi
        fi
    done
fi

# Saved Application State
scan_directory "$HOME/Library/Saved Application State" "Saved Application State"

# Application Scripts
scan_directory "$HOME/Library/Application Scripts" "Application Scripts"

# Logs
scan_directory "$HOME/Library/Logs" "Logs"

# Launch Agents
if [[ -d "$HOME/Library/LaunchAgents" ]]; then
    log INFO "Scanning Launch Agents..."
    for agent in "$HOME/Library/LaunchAgents"/*.plist; do
        if [[ -f "$agent" ]]; then
            agent_name=$(basename "$agent" .plist)
            if ! is_installed "$agent_name" "$agent"; then
                # Try to get label from plist
                label=$(defaults read "$agent" Label 2>/dev/null || echo "$agent_name")
                orphaned_items+=("LaunchAgents|$label|$agent|1|0|file")
            fi
        fi
    done
fi

echo ""

# Display results
if [[ "$MACHINE_READABLE" != "true" ]]; then
    echo "=========================================="
    echo "  Orphaned Files & Folders Found"
    echo "=========================================="
fi

if [[ ${#orphaned_items[@]} -eq 0 ]]; then
    if [[ "$MACHINE_READABLE" == "true" ]]; then
        exec 1>&3
        echo "ORPHANED_ITEMS_START"
        echo "ORPHANED_ITEMS_END"
        exec 3>&-
    else
        log SUCCESS "No orphaned application files found!"
    fi
    exit 0
fi

# Sort by size
IFS=$'\n' sorted_items=($(printf '%s\n' "${orphaned_items[@]}" | sort -t'|' -k4 -rn))

# Machine-readable output
if [[ "$MACHINE_READABLE" == "true" ]]; then
    exec 1>&3
    echo "ORPHANED_ITEMS_START"
    for item in "${sorted_items[@]}"; do
        echo "$item"
    done
    echo "ORPHANED_ITEMS_END"
    exec 3>&-
    exit 0
fi

total_mb=$((total_orphaned_size / 1024))
total_gb=$((total_mb / 1024))

if [[ $total_gb -gt 0 ]]; then
    log WARNING "Found ${#orphaned_items[@]} potentially orphaned items (~${total_gb}GB total)"
else
    log WARNING "Found ${#orphaned_items[@]} potentially orphaned items (~${total_mb}MB total)"
fi
echo ""

# Group by location (bash 3.2 compatible - using arrays instead of associative arrays)
locations_list=()
for item in "${sorted_items[@]}"; do
    IFS='|' read -r location name path size_kb size_mb type <<< "$item"
    # Check if location is already in list
    found=false
    if [[ ${#locations_list[@]} -gt 0 ]]; then
        for loc in "${locations_list[@]}"; do
            if [[ "$loc" == "$location" ]]; then
                found=true
                break
            fi
        done
    fi
    if [[ "$found" == "false" ]]; then
        locations_list+=("$location")
    fi
done

# Display items grouped by location
if [[ ${#locations_list[@]} -gt 0 ]]; then
    for location in "${locations_list[@]}"; do
        echo "--- $location ---"
        for item in "${sorted_items[@]}"; do
            IFS='|' read -r loc name path size_kb size_mb type <<< "$item"
            if [[ "$loc" == "$location" ]]; then
                if [[ $size_mb -gt 0 ]]; then
                    printf "  %-50s %6sMB  [%s]\n" "$name" "$size_mb" "$type"
                else
                    printf "  %-50s %6s   [%s]\n" "$name" "<1MB" "$type"
                fi
            fi
        done
        echo ""
    done
fi

# Show largest items
echo "=========================================="
echo "  Largest Orphaned Items"
echo "=========================================="
for item in "${sorted_items[@]:0:20}"; do
    IFS='|' read -r location name path size_kb size_mb type <<< "$item"
    size_gb=$((size_mb / 1024))
    if [[ $size_gb -gt 0 ]]; then
        printf "  %-50s %6sGB  (%s/%s)\n" "$name" "$size_gb" "$location" "$type"
    else
        printf "  %-50s %6sMB  (%s/%s)\n" "$name" "$size_mb" "$location" "$type"
    fi
done
echo ""

# Cleanup options
echo "=========================================="
echo "  Cleanup Options"
echo "=========================================="
log INFO "To remove orphaned files, you can:"
echo ""
echo "1. Review each item manually before removing"
echo "2. Use the interactive cleanup tool:"
echo "   ./tools/cleanup_orphaned_files.sh"
echo ""
log WARNING "Always review before deleting - some items might be needed!"
log INFO "Use DRY_RUN=true to preview what would be removed"

log SUCCESS "Orphaned files scan completed!"
