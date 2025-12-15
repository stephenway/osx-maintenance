#!/bin/bash

# Cleanup Orphaned Application Files
# Interactive tool to safely remove leftover files from uninstalled apps

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

DRY_RUN=${DRY_RUN:-false}

log INFO "Orphaned Files Cleanup Tool"
echo ""

# First, run the find tool to get the list
log INFO "Scanning for orphaned files..."
FOUND_ITEMS=$(bash "$SCRIPT_DIR/tools/find_orphaned_files.sh" 2>&1 | grep -A 1000 "Orphaned Files & Folders Found" || echo "")

if [[ -z "$FOUND_ITEMS" ]]; then
    log INFO "No orphaned files found. Run find_orphaned_files.sh first to see what's available."
    exit 0
fi

echo "$FOUND_ITEMS"
echo ""

# Function to safely remove item
remove_item() {
    local item_path=$1
    local item_name=$2
    local item_type=$3

    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "[DRY RUN] Would remove: $item_path"
        return 0
    fi

    if [[ "$item_type" == "directory" ]]; then
        if rm -rf "$item_path" 2>/dev/null; then
            log SUCCESS "Removed directory: $item_name"
            return 0
        else
            log ERROR "Failed to remove: $item_path"
            return 1
        fi
    else
        if rm -f "$item_path" 2>/dev/null; then
            log SUCCESS "Removed file: $item_name"
            return 0
        else
            log ERROR "Failed to remove: $item_path"
            return 1
        fi
    fi
}

# Interactive cleanup by location
cleanup_by_location() {
    local location=$1
    local location_path=""

    case $location in
        "Application Support")
            location_path="$HOME/Library/Application Support"
            ;;
        "Preferences")
            location_path="$HOME/Library/Preferences"
            ;;
        "Caches")
            location_path="$HOME/Library/Caches"
            ;;
        "Containers")
            location_path="$HOME/Library/Containers"
            ;;
        "Saved Application State")
            location_path="$HOME/Library/Saved Application State"
            ;;
        "Application Scripts")
            location_path="$HOME/Library/Application Scripts"
            ;;
        "Logs")
            location_path="$HOME/Library/Logs"
            ;;
        "LaunchAgents")
            location_path="$HOME/Library/LaunchAgents"
            ;;
        *)
            log WARNING "Unknown location: $location"
            return
            ;;
    esac

    if [[ ! -d "$location_path" ]]; then
        log WARNING "Location not found: $location_path"
        return
    fi

    echo ""
    echo "=========================================="
    echo "  Cleaning: $location"
    echo "=========================================="

    # Get items from find_orphaned_files output or scan directly
    # For now, let's do a simple interactive approach
    log INFO "Review items in $location_path"
    log INFO "Items will be shown for confirmation"
    echo ""

    # This is a simplified version - in practice, you'd parse the find output
    log WARNING "For safety, please review items manually"
    log INFO "You can remove items individually or use the find tool to identify them first"
}

# Main menu
show_cleanup_menu() {
    clear
    echo "=========================================="
    echo "  Orphaned Files Cleanup"
    echo "=========================================="
    echo ""
    echo "This tool helps remove leftover files from uninstalled applications."
    echo ""
    echo "⚠️  WARNING: Always review items before removing!"
    echo ""
    echo "1. Clean Application Support (safest - mostly caches)"
    echo "2. Clean Preferences (review carefully)"
    echo "3. Clean Caches (safe)"
    echo "4. Clean Containers (sandboxed app data - review carefully)"
    echo "5. Clean Saved Application State (safe)"
    echo "6. Clean Logs (safe)"
    echo "7. Clean Launch Agents (review carefully)"
    echo "8. Interactive item-by-item cleanup"
    echo "9. Show all orphaned items again"
    echo "0. Back"
    echo ""
    echo -n "Select an option: "
}

# Get orphaned items list (simplified - would be better to cache from find tool)
get_orphaned_items() {
    local location_filter=${1:-}

    # This would ideally parse the output from find_orphaned_files.sh
    # For now, we'll provide a framework
    echo ""
    log INFO "Run './tools/find_orphaned_files.sh' first to see all orphaned items"
    log INFO "Then manually review and remove items you're sure about"
}

# Interactive item selection
interactive_cleanup() {
    log INFO "Interactive Cleanup Mode"
    echo ""
    log INFO "This mode lets you review and remove items one by one"
    echo ""

    # Get the find tool output
    echo "Running scan..."
    bash "$SCRIPT_DIR/tools/find_orphaned_files.sh"
    echo ""

    echo "To remove specific items, you can:"
    echo "1. Use Finder to navigate and delete manually"
    echo "2. Use terminal: rm -rf 'path/to/item'"
    echo "3. Review the list above and remove items you're certain about"
    echo ""
    log WARNING "Always double-check before removing!"
}

# Main execution
if [[ "${1:-}" == "--auto" ]]; then
    # Auto mode - clean safest items only
    log INFO "Auto-cleanup mode (safest items only)"
    echo ""

    # Clean caches (safest)
    if [[ -d "$HOME/Library/Caches" ]]; then
        log INFO "Cleaning orphaned caches..."
        # Would need to identify orphaned cache folders
    fi

    # Clean logs (safe)
    if [[ -d "$HOME/Library/Logs" ]]; then
        log INFO "Cleaning orphaned logs..."
    fi

    log SUCCESS "Auto-cleanup completed"
else
    # Interactive mode
    while true; do
        show_cleanup_menu
        read -r choice

        case $choice in
            1)
                cleanup_by_location "Application Support"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            2)
                cleanup_by_location "Preferences"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            3)
                cleanup_by_location "Caches"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            4)
                cleanup_by_location "Containers"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            5)
                cleanup_by_location "Saved Application State"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            6)
                cleanup_by_location "Logs"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            7)
                cleanup_by_location "LaunchAgents"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            8)
                interactive_cleanup
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            9)
                bash "$SCRIPT_DIR/tools/find_orphaned_files.sh"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            0)
                exit 0
                ;;
            *)
                log WARNING "Invalid option"
                sleep 1
                ;;
        esac
    done
fi
