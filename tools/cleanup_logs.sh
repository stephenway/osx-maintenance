#!/bin/bash

# Log File Cleanup Tool
# Removes old log files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

DRY_RUN=${DRY_RUN:-false}
LOG_AGE_DAYS=${LOG_AGE_DAYS:-30}

log INFO "Starting Log Cleanup (removing logs older than $LOG_AGE_DAYS days)..."

# Function to clean log directory
clean_log_dir() {
    local dir=$1
    local name=$2

    if [[ ! -d "$dir" ]]; then
        return
    fi

    local size_before=$(du -sh "$dir" 2>/dev/null | awk '{print $1}' || echo "0B")
    local count_before=$(find "$dir" -type f -mtime +$LOG_AGE_DAYS 2>/dev/null | wc -l | tr -d ' ')

    if [[ $count_before -eq 0 ]]; then
        log INFO "$name: No old logs found"
        return
    fi

    log INFO "$name: Found $count_before old log files ($size_before)"

    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "[DRY RUN] Would remove $count_before log files from $dir"
    else
        find "$dir" -type f -mtime +$LOG_AGE_DAYS -delete 2>/dev/null || true
        local size_after=$(du -sh "$dir" 2>/dev/null | awk '{print $1}' || echo "0B")
        log SUCCESS "$name: Removed $count_before log files (was $size_before, now $size_after)"
    fi
}

total_freed=0

# User logs
echo "=== User Logs ==="
user_logs=(
    "$HOME/Library/Logs"
)

for log_dir in "${user_logs[@]}"; do
    if [[ -d "$log_dir" ]]; then
        size=$(du -sk "$log_dir" 2>/dev/null | awk '{print $1}' || echo "0")
        clean_log_dir "$log_dir" "$(basename "$log_dir")"
    fi
done
echo ""

# System logs (requires admin)
if [[ $EUID -eq 0 ]]; then
    echo "=== System Logs ==="
    system_logs=(
        "/var/log"
        "/Library/Logs"
    )

    for log_dir in "${system_logs[@]}"; do
        if [[ -d "$log_dir" ]]; then
            clean_log_dir "$log_dir" "$(basename "$log_dir")"
        fi
    done
    echo ""
else
    log INFO "Skipping system logs (requires root privileges)"
fi

# Application-specific logs
echo "=== Application Logs ==="
app_log_dirs=(
    "$HOME/Library/Logs/DiagnosticReports"
    "$HOME/Library/Logs/CrashReporter"
)

for log_dir in "${app_log_dirs[@]}"; do
    if [[ -d "$log_dir" ]]; then
        clean_log_dir "$log_dir" "$(basename "$log_dir")"
    fi
done
echo ""

log SUCCESS "Log cleanup completed!"
