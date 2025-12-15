#!/bin/bash

# Interactive Orphaned Files Cleanup Tool
# Allows item-by-item selection with checkboxes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

DRY_RUN=${DRY_RUN:-false}

log INFO "Interactive Orphaned Files Cleanup"
echo ""

# First, run the find tool to get the list in machine-readable format
log INFO "Scanning for orphaned files..."
echo ""

# Run find tool with machine-readable output
MACHINE_READABLE=true bash "$SCRIPT_DIR/tools/find_orphaned_files.sh" > /tmp/orphaned_items.txt 2>&1

# Check if we got results
if ! grep -q "ORPHANED_ITEMS_START" /tmp/orphaned_items.txt; then
    log WARNING "No orphaned files found or scan failed"
    cat /tmp/orphaned_items.txt
    rm -f /tmp/orphaned_items.txt
    exit 1
fi

# Parse the machine-readable output
declare -a orphaned_items
declare -a item_selected  # Track which items are selected
declare -a item_paths     # Store full paths

in_items=false
while IFS= read -r line; do
    if [[ "$line" == "ORPHANED_ITEMS_START" ]]; then
        in_items=true
        continue
    fi
    if [[ "$line" == "ORPHANED_ITEMS_END" ]]; then
        break
    fi
    if [[ "$in_items" == "true" ]] && [[ -n "$line" ]]; then
        # Format: location|name|full_path|size_kb|size_mb|type
        orphaned_items+=("$line")
        item_selected+=("false")
        IFS='|' read -r loc name path size_kb size_mb type <<< "$line"
        item_paths+=("$path")
    fi
done < /tmp/orphaned_items.txt

rm -f /tmp/orphaned_items.txt

if [[ ${#orphaned_items[@]} -eq 0 ]]; then
    log SUCCESS "No orphaned files found!"
    exit 0
fi

log INFO "Found ${#orphaned_items[@]} orphaned items"
echo ""

# Function to display checklist
show_checklist() {
    clear
    echo "=========================================="
    echo "  Orphaned Files - Interactive Selection"
    echo "=========================================="
    echo ""
    echo "Instructions:"
    echo "  - Enter item number to toggle selection"
    echo "  - 'a' = select all"
    echo "  - 'n' = select none"
    echo "  - 's' = show selected items only"
    echo "  - 'r' = remove selected items"
    echo "  - 'q' = quit without removing"
    echo ""
    echo "=========================================="
    echo ""

    local idx=1
    for item in "${orphaned_items[@]}"; do
        IFS='|' read -r location name path size_kb size_mb type <<< "$item"
        local selected="${item_selected[$((idx-1))]}"
        local checkbox="[ ]"
        if [[ "$selected" == "true" ]]; then
            checkbox="[X]"
        fi

        # Format size display
        local size_display=""
        if [[ $size_mb -gt 1024 ]]; then
            local size_gb=$((size_mb / 1024))
            size_display="${size_gb}GB"
        elif [[ $size_mb -gt 0 ]]; then
            size_display="${size_mb}MB"
        else
            size_display="<1MB"
        fi

        printf "%3d. %s %-45s %8s  (%s/%s)\n" "$idx" "$checkbox" "$name" "$size_display" "$location" "$type"
        idx=$((idx + 1))
    done

    echo ""
    echo "=========================================="
    local selected_count=0
    local selected_size_kb=0
    for i in "${!item_selected[@]}"; do
        if [[ "${item_selected[$i]}" == "true" ]]; then
            selected_count=$((selected_count + 1))
            IFS='|' read -r loc name path size_kb size_mb type <<< "${orphaned_items[$i]}"
            selected_size_kb=$((selected_size_kb + size_kb))
        fi
    done
    local selected_size_mb=$((selected_size_kb / 1024))
    local selected_size_gb=$((selected_size_mb / 1024))

    if [[ $selected_size_gb -gt 0 ]]; then
        echo "Selected: $selected_count / ${#orphaned_items[@]} items (~${selected_size_gb}GB)"
    elif [[ $selected_size_mb -gt 0 ]]; then
        echo "Selected: $selected_count / ${#orphaned_items[@]} items (~${selected_size_mb}MB)"
    else
        echo "Selected: $selected_count / ${#orphaned_items[@]} items"
    fi
    echo ""
    echo -n "Command: "
}

# Function to remove selected items
remove_selected() {
    local selected_count=0
    local selected_items_list=()

    for i in "${!item_selected[@]}"; do
        if [[ "${item_selected[$i]}" == "true" ]]; then
            selected_count=$((selected_count + 1))
            selected_items_list+=("$i")
        fi
    done

    if [[ $selected_count -eq 0 ]]; then
        log WARNING "No items selected!"
        return
    fi

    echo ""
    log WARNING "About to remove $selected_count items:"
    echo ""

    local total_size_kb=0
    for idx in "${selected_items_list[@]}"; do
        IFS='|' read -r location name path size_kb size_mb type <<< "${orphaned_items[$idx]}"
        total_size_kb=$((total_size_kb + size_kb))
        local size_display=""
        if [[ $size_mb -gt 1024 ]]; then
            local size_gb=$((size_mb / 1024))
            size_display="${size_gb}GB"
        elif [[ $size_mb -gt 0 ]]; then
            size_display="${size_mb}MB"
        else
            size_display="<1MB"
        fi
        echo "  - $name ($size_display) in $location"
    done

    local total_size_mb=$((total_size_kb / 1024))
    local total_size_gb=$((total_size_mb / 1024))
    if [[ $total_size_gb -gt 0 ]]; then
        echo ""
        echo "Total size: ~${total_size_gb}GB"
    elif [[ $total_size_mb -gt 0 ]]; then
        echo ""
        echo "Total size: ~${total_size_mb}MB"
    fi

    echo ""
    echo -n "Confirm removal? (yes/NO): "
    read -r confirm

    if [[ "$confirm" != "yes" ]]; then
        log INFO "Cancelled"
        return
    fi

    log INFO "Removing selected items..."
    local removed=0
    local failed=0

    for idx in "${selected_items_list[@]}"; do
        IFS='|' read -r location name path size_kb size_mb type <<< "${orphaned_items[$idx]}"

        if [[ -z "$path" ]] || [[ ! -e "$path" ]]; then
            log WARNING "Item not found: $name (path: $path)"
            failed=$((failed + 1))
        else
            if [[ "$DRY_RUN" == "true" ]]; then
                log INFO "[DRY RUN] Would remove: $path"
            else
                if rm -rf "$path" 2>/dev/null; then
                    log SUCCESS "Removed: $name"
                    removed=$((removed + 1))
                else
                    log ERROR "Failed to remove: $name (may require admin privileges)"
                    failed=$((failed + 1))
                fi
            fi
        fi
    done

    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "[DRY RUN] Would remove $selected_count items"
    else
        log SUCCESS "Removed $removed items"
        if [[ $failed -gt 0 ]]; then
            log WARNING "$failed items failed to remove (may require admin or be in use)"
        fi
    fi
}

# Main interactive loop
while true; do
    show_checklist
    read -r command

    case $command in
        [0-9]*)
            # Toggle item selection
            item_num=$((command))
            if [[ $item_num -ge 1 ]] && [[ $item_num -le ${#orphaned_items[@]} ]]; then
                idx=$((item_num - 1))
                if [[ "${item_selected[$idx]}" == "true" ]]; then
                    item_selected[$idx]="false"
                else
                    item_selected[$idx]="true"
                fi
            else
                log WARNING "Invalid item number"
                sleep 1
            fi
            ;;
        a|A)
            # Select all
            for i in "${!item_selected[@]}"; do
                item_selected[$i]="true"
            done
            ;;
        n|N)
            # Select none
            for i in "${!item_selected[@]}"; do
                item_selected[$i]="false"
            done
            ;;
        s|S)
            # Show selected only
            clear
            echo "=========================================="
            echo "  Selected Items"
            echo "=========================================="
            echo ""
            local has_selected=false
            local total_size_kb=0
            for i in "${!orphaned_items[@]}"; do
                if [[ "${item_selected[$i]}" == "true" ]]; then
                    has_selected=true
                    IFS='|' read -r location name path size_kb size_mb type <<< "${orphaned_items[$i]}"
                    total_size_kb=$((total_size_kb + size_kb))
                    local size_display=""
                    if [[ $size_mb -gt 1024 ]]; then
                        local size_gb=$((size_mb / 1024))
                        size_display="${size_gb}GB"
                    elif [[ $size_mb -gt 0 ]]; then
                        size_display="${size_mb}MB"
                    else
                        size_display="<1MB"
                    fi
                    printf "  %-45s %8s  (%s/%s)\n" "$name" "$size_display" "$location" "$type"
                fi
            done

            if [[ "$has_selected" == "false" ]]; then
                echo "  No items selected"
            else
                local total_size_mb=$((total_size_kb / 1024))
                local total_size_gb=$((total_size_mb / 1024))
                echo ""
                if [[ $total_size_gb -gt 0 ]]; then
                    echo "Total: ~${total_size_gb}GB"
                elif [[ $total_size_mb -gt 0 ]]; then
                    echo "Total: ~${total_size_mb}MB"
                fi
            fi

            echo ""
            echo "Press Enter to continue..."
            read -r
            ;;
        r|R)
            # Remove selected
            remove_selected
            echo ""
            echo "Press Enter to continue..."
            read -r
            ;;
        q|Q)
            # Quit
            log INFO "Exiting without removing items"
            exit 0
            ;;
        *)
            log WARNING "Invalid command. Use: number, a, n, s, r, or q"
            sleep 1
            ;;
    esac
done
