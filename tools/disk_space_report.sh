#!/bin/bash

# Disk Space Analysis Report
# Analyzes what space can be freed without making any changes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

log INFO "Generating Disk Space Analysis Report..."
log INFO "This is a READ-ONLY analysis - no changes will be made"
echo ""

# Function to get size in KB
get_size_kb() {
    local path=$1
    if [[ -e "$path" ]]; then
        du -sk "$path" 2>/dev/null | awk '{print $1}' || echo "0"
    else
        echo "0"
    fi
}

# Function to format size
format_size() {
    local kb=$1
    local mb=$((kb / 1024))
    local gb=$((mb / 1024))

    if [[ $gb -gt 0 ]]; then
        echo "${gb}GB (${mb}MB)"
    elif [[ $mb -gt 0 ]]; then
        echo "${mb}MB"
    else
        echo "${kb}KB"
    fi
}

total_potential_space=0
declare -a report_sections

# Overall disk usage
echo "=========================================="
echo "  Current Disk Usage"
echo "=========================================="
df -h / | tail -1 | awk '{print "Root partition: " $4 " free of " $2 " (" $5 " used)"}'
echo ""

# 1. System Caches
echo "=========================================="
echo "  1. System & User Caches"
echo "=========================================="
cache_total=0

# User caches
user_cache_dirs=(
    "$HOME/Library/Caches"
    "$HOME/.Trash"
)

for cache_dir in "${user_cache_dirs[@]}"; do
    if [[ -d "$cache_dir" ]]; then
        size_kb=$(get_size_kb "$cache_dir")
        cache_total=$((cache_total + size_kb))
        size_display=$(format_size $size_kb)
        echo "  $cache_dir: $size_display"
    fi
done

# Browser caches
echo ""
echo "  Browser Caches:"
browser_caches=(
    "$HOME/Library/Caches/Google/Chrome"
    "$HOME/Library/Caches/com.google.Chrome"
    "$HOME/Library/Caches/com.apple.Safari"
    "$HOME/Library/Caches/com.operasoftware.Opera"
    "$HOME/Library/Caches/com.mozilla.firefox"
    "$HOME/Library/Application Support/Google/Chrome/Default/Cache"
    "$HOME/Library/Application Support/com.google.Chrome/Default/Cache"
)

for cache_dir in "${browser_caches[@]}"; do
    if [[ -d "$cache_dir" ]] || [[ -f "$cache_dir" ]]; then
        size_kb=$(get_size_kb "$cache_dir")
        if [[ -n "$size_kb" ]] && [[ "$size_kb" =~ ^[0-9]+$ ]]; then
            cache_total=$((cache_total + size_kb))
            size_display=$(format_size $size_kb)
            echo "    $(basename "$cache_dir"): $size_display"
        fi
    fi
done

total_potential_space=$((total_potential_space + cache_total))
cache_display=$(format_size $cache_total)
echo ""
echo "  Total Cache Space: $cache_display"
report_sections+=("Caches: $cache_display")
echo ""

# 2. Log Files
echo "=========================================="
echo "  2. Log Files (older than 30 days)"
echo "=========================================="
log_total=0

log_dirs=(
    "$HOME/Library/Logs"
    "$HOME/Library/Logs/DiagnosticReports"
    "$HOME/Library/Logs/CrashReporter"
)

for log_dir in "${log_dirs[@]}"; do
    if [[ -d "$log_dir" ]]; then
        # Count old logs
        old_logs=$(find "$log_dir" -type f -mtime +30 2>/dev/null | wc -l | tr -d ' ')
        if [[ $old_logs -gt 0 ]]; then
            old_size_kb=$(find "$log_dir" -type f -mtime +30 -exec du -ck {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
            log_total=$((log_total + old_size_kb))
            size_display=$(format_size $old_size_kb)
            echo "  $log_dir: $old_logs files, $size_display"
        fi
    fi
done

total_potential_space=$((total_potential_space + log_total))
log_display=$(format_size $log_total)
echo ""
echo "  Total Old Log Space: $log_display"
report_sections+=("Old Logs: $log_display")
echo ""

# 3. Temporary Files
echo "=========================================="
echo "  3. Temporary Files"
echo "=========================================="
temp_total=0

temp_dirs=(
    "$TMPDIR"
    "/tmp"
    "$HOME/tmp"
    "$HOME/Downloads/.tmp"
)

for temp_dir in "${temp_dirs[@]}"; do
    if [[ -d "$temp_dir" ]] && [[ "$temp_dir" != "$HOME" ]]; then
        size_kb=$(get_size_kb "$temp_dir")
        if [[ -n "$size_kb" ]] && [[ "$size_kb" =~ ^[0-9]+$ ]] && [[ $size_kb -gt 1024 ]]; then  # Only report if >1MB
            temp_total=$((temp_total + size_kb))
            size_display=$(format_size $size_kb)
            echo "  $temp_dir: $size_display"
        fi
    fi
done

# Old downloads
if [[ -d "$HOME/Downloads" ]]; then
    old_downloads=$(find "$HOME/Downloads" -type f -mtime +90 2>/dev/null | wc -l | tr -d ' ')
    if [[ $old_downloads -gt 0 ]]; then
        old_dl_size_kb=$(find "$HOME/Downloads" -type f -mtime +90 -exec du -ck {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
        temp_total=$((temp_total + old_dl_size_kb))
        size_display=$(format_size $old_dl_size_kb)
        echo "  Old Downloads (>90 days): $old_downloads files, $size_display"
    fi
fi

total_potential_space=$((total_potential_space + temp_total))
temp_display=$(format_size $temp_total)
echo ""
echo "  Total Temp Space: $temp_display"
report_sections+=("Temp Files: $temp_display")
echo ""

# 4. Application Caches & Derived Data
echo "=========================================="
echo "  4. Application Caches & Derived Data"
echo "=========================================="
app_cache_total=0

# Xcode DerivedData
xcode_derived="$HOME/Library/Developer/Xcode/DerivedData"
if [[ -d "$xcode_derived" ]]; then
    size_kb=$(get_size_kb "$xcode_derived")
    app_cache_total=$((app_cache_total + size_kb))
    size_display=$(format_size $size_kb)
    echo "  Xcode DerivedData: $size_display"
fi

# Xcode Archives (old)
xcode_archives="$HOME/Library/Developer/Xcode/Archives"
if [[ -d "$xcode_archives" ]]; then
    old_archives=$(find "$xcode_archives" -type d -mtime +90 2>/dev/null | wc -l | tr -d ' ')
    if [[ $old_archives -gt 0 ]]; then
        old_arch_size_kb=$(find "$xcode_archives" -type d -mtime +90 -exec du -ck {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
        app_cache_total=$((app_cache_total + old_arch_size_kb))
        size_display=$(format_size $old_arch_size_kb)
        echo "  Xcode Old Archives (>90 days): $old_archives archives, $size_display"
    fi
fi

# JetBrains caches
jetbrains_cache="$HOME/Library/Application Support/JetBrains"
if [[ -d "$jetbrains_cache" ]]; then
    for ide_dir in "$jetbrains_cache"/*; do
        if [[ -d "$ide_dir" ]]; then
            ide_name=$(basename "$ide_dir")
            if [[ -d "$ide_dir/caches" ]]; then
                size_kb=$(get_size_kb "$ide_dir/caches")
                app_cache_total=$((app_cache_total + size_kb))
                size_display=$(format_size $size_kb)
                echo "  $ide_name caches: $size_display"
            fi
            if [[ -d "$ide_dir/logs" ]]; then
                size_kb=$(get_size_kb "$ide_dir/logs")
                app_cache_total=$((app_cache_total + size_kb))
                size_display=$(format_size $size_kb)
                echo "  $ide_name logs: $size_display"
            fi
        fi
    done
fi

# VS Code caches
vscode_cache="$HOME/Library/Application Support/Code/Cache"
if [[ -d "$vscode_cache" ]]; then
    size_kb=$(get_size_kb "$vscode_cache")
    app_cache_total=$((app_cache_total + size_kb))
    size_display=$(format_size $size_kb)
    echo "  VS Code Cache: $size_display"
fi

vscode_cached="$HOME/Library/Application Support/Code/CachedData"
if [[ -d "$vscode_cached" ]]; then
    size_kb=$(get_size_kb "$vscode_cached")
    app_cache_total=$((app_cache_total + size_kb))
    size_display=$(format_size $size_kb)
    echo "  VS Code CachedData: $size_display"
fi

total_potential_space=$((total_potential_space + app_cache_total))
app_cache_display=$(format_size $app_cache_total)
echo ""
echo "  Total App Cache Space: $app_cache_display"
report_sections+=("App Caches: $app_cache_display")
echo ""

# 5. Orphaned Files (from previous scan or estimate)
echo "=========================================="
echo "  5. Orphaned Application Files"
echo "=========================================="
log INFO "Running orphaned files scan (this may take a few minutes)..."
echo ""

# Run orphaned files scan in quick mode for speed
QUICK_SCAN=true MACHINE_READABLE=true bash "$SCRIPT_DIR/tools/find_orphaned_files.sh" > /tmp/orphaned_quick.txt 2>&1

orphaned_total=0
if grep -q "ORPHANED_ITEMS_START" /tmp/orphaned_quick.txt; then
    while IFS= read -r line; do
        if [[ "$line" == "ORPHANED_ITEMS_START" ]]; then
            continue
        fi
        if [[ "$line" == "ORPHANED_ITEMS_END" ]]; then
            break
        fi
        if [[ -n "$line" ]]; then
            IFS='|' read -r location name path size_kb size_mb type <<< "$line"
            orphaned_total=$((orphaned_total + size_kb))
        fi
    done < /tmp/orphaned_quick.txt

    # Get count
    orphaned_count=$(grep -A 1000 "ORPHANED_ITEMS_START" /tmp/orphaned_quick.txt | grep -v "ORPHANED_ITEMS" | grep -v "^$" | wc -l | tr -d ' ')

    orphaned_display=$(format_size $orphaned_total)
    echo "  Found $orphaned_count potentially orphaned items"
    echo "  Estimated space: $orphaned_display"
    echo ""
    echo "  Note: Run './tools/find_orphaned_files.sh' for detailed breakdown"
else
    echo "  Could not scan orphaned files (run find_orphaned_files.sh manually)"
fi

rm -f /tmp/orphaned_quick.txt
total_potential_space=$((total_potential_space + orphaned_total))
orphaned_display=$(format_size $orphaned_total)
report_sections+=("Orphaned Files: $orphaned_display")
echo ""

# 6. Large Files Analysis
echo "=========================================="
echo "  6. Large Files (>500MB)"
echo "=========================================="
large_files_total=0
large_file_count=0

while IFS= read -r file; do
    if [[ -f "$file" ]]; then
        size_kb=$(du -sk "$file" 2>/dev/null | awk '{print $1}' || echo "0")
        if [[ $size_kb -gt 512000 ]]; then  # >500MB
            large_files_total=$((large_files_total + size_kb))
            large_file_count=$((large_file_count + 1))
            size_mb=$((size_kb / 1024))
            size_gb=$((size_mb / 1024))
            if [[ $size_gb -gt 0 ]]; then
                echo "  $file: ${size_gb}GB"
            else
                echo "  $file: ${size_mb}MB"
            fi
        fi
    fi
done < <(find "$HOME" -type f -size +500M 2>/dev/null | head -20)

if [[ $large_file_count -gt 20 ]]; then
    echo "  ... and $((large_file_count - 20)) more large files"
fi

large_files_display=$(format_size $large_files_total)
echo ""
echo "  Total Large Files: $large_file_count files, $large_files_display"
echo "  Note: Review these manually - may contain important data"
echo ""

# Summary
echo "=========================================="
echo "  SUMMARY - Potential Space to Free"
echo "=========================================="
echo ""

total_display=$(format_size $total_potential_space)
total_mb=$((total_potential_space / 1024))
total_gb=$((total_mb / 1024))

echo "Safe to Clean (Caches, Logs, Temp):"
safe_total=$((cache_total + log_total + temp_total + app_cache_total))
safe_display=$(format_size $safe_total)
echo "  Total: $safe_display"
echo ""

echo "Review Before Cleaning (Orphaned Files):"
echo "  Total: $orphaned_display"
echo ""

echo "=========================================="
echo "  TOTAL POTENTIAL SPACE: $total_display"
echo "=========================================="
echo ""

if [[ $total_gb -gt 0 ]]; then
    log SUCCESS "You could potentially free up approximately ${total_gb}GB (${total_mb}MB)"
else
    log SUCCESS "You could potentially free up approximately ${total_mb}MB"
fi

echo ""
echo "Breakdown:"
for section in "${report_sections[@]}"; do
    echo "  - $section"
done

echo ""
log INFO "To free this space, use the appropriate cleanup tools:"
echo "  - Caches: ./tools/cleanup_caches.sh"
echo "  - Logs: ./tools/cleanup_logs.sh"
echo "  - Temp: ./tools/cleanup_temp.sh"
echo "  - App Caches: ./tools/app_cleanup.sh"
echo "  - Orphaned Files: ./tools/cleanup_orphaned_files_interactive.sh"
echo ""

log SUCCESS "Report completed!"
