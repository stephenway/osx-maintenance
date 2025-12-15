#!/bin/bash

# Downloads Folder Cleanup Tool
# Manages old files in Downloads folder

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

DRY_RUN=${DRY_RUN:-false}
DOWNLOADS_AGE_DAYS=${DOWNLOADS_AGE_DAYS:-90}

log INFO "Starting Downloads Cleanup (files older than $DOWNLOADS_AGE_DAYS days)..."

DOWNLOADS_DIR="$HOME/Downloads"

if [[ ! -d "$DOWNLOADS_DIR" ]]; then
    log WARNING "Downloads directory not found: $DOWNLOADS_DIR"
    exit 0
fi

# Analyze Downloads folder
echo "=== Downloads Folder Analysis ==="
total_size=$(du -sh "$DOWNLOADS_DIR" 2>/dev/null | awk '{print $1}')
file_count=$(find "$DOWNLOADS_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
old_count=$(find "$DOWNLOADS_DIR" -type f -mtime +$DOWNLOADS_AGE_DAYS 2>/dev/null | wc -l | tr -d ' ')

log INFO "Total size: $total_size"
log INFO "Total files: $file_count"
log INFO "Files older than $DOWNLOADS_AGE_DAYS days: $old_count"
echo ""

if [[ $old_count -eq 0 ]]; then
    log SUCCESS "No old files to clean in Downloads"
    exit 0
fi

# Show old files
echo "=== Old Files (older than $DOWNLOADS_AGE_DAYS days) ==="
find "$DOWNLOADS_DIR" -type f -mtime +$DOWNLOADS_AGE_DAYS -exec ls -lh {} \; 2>/dev/null | \
    awk '{print $9, "(" $5 ")"}' | head -20

if [[ $old_count -gt 20 ]]; then
    echo "... and $((old_count - 20)) more files"
fi
echo ""

# Calculate space that would be freed
old_size_kb=$(find "$DOWNLOADS_DIR" -type f -mtime +$DOWNLOADS_AGE_DAYS -exec du -ck {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
old_size_mb=$((old_size_kb / 1024))

if [[ "$DRY_RUN" == "true" ]]; then
    log INFO "[DRY RUN] Would remove $old_count files (~${old_size_mb}MB)"
    echo ""
    echo "To actually remove these files, run without DRY_RUN mode"
else
    echo -n "Remove these $old_count old files? (y/N): "
    read -r confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        find "$DOWNLOADS_DIR" -type f -mtime +$DOWNLOADS_AGE_DAYS -delete 2>/dev/null || true
        log SUCCESS "Removed $old_count old files (~${old_size_mb}MB freed)"
    else
        log INFO "Cleanup cancelled"
    fi
fi
