#!/bin/bash

# Disk Space Analysis Tool
# Analyzes disk usage and finds large files/directories

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

log INFO "Starting Disk Space Analysis..."
echo ""

# Overall disk usage
echo "=========================================="
echo "  Overall Disk Usage"
echo "=========================================="
df -h | grep -E "(Filesystem|/dev/)" | head -5
echo ""

# Home directory analysis
echo "=========================================="
echo "  Home Directory Analysis"
echo "=========================================="
if [[ -d "$HOME" ]]; then
    home_size=$(du -sh "$HOME" 2>/dev/null | awk '{print $1}')
    log INFO "Home directory size: $home_size"
    echo ""

    echo "Largest directories in home:"
    du -h -d 1 "$HOME" 2>/dev/null | sort -hr | head -10 | awk '{printf "  %-50s %s\n", $2, $1}'
fi
echo ""

# System directory analysis (if root)
if [[ $EUID -eq 0 ]]; then
    echo "=========================================="
    echo "  System Directory Analysis"
    echo "=========================================="
    echo "Largest directories in /:"
    du -h -d 1 / 2>/dev/null | sort -hr | head -10 | awk '{printf "  %-50s %s\n", $2, $1}'
    echo ""
fi

# Find large files
echo "=========================================="
echo "  Large Files (>100MB)"
echo "=========================================="
find "$HOME" -type f -size +100M -exec ls -lh {} \; 2>/dev/null | \
    awk '{print $9, "(" $5 ")"}' | head -20

large_count=$(find "$HOME" -type f -size +100M 2>/dev/null | wc -l | tr -d ' ')
if [[ $large_count -gt 20 ]]; then
    echo "... and $((large_count - 20)) more large files"
fi
echo ""

# Application sizes
echo "=========================================="
echo "  Application Sizes"
echo "=========================================="
if [[ -d "/Applications" ]]; then
    du -h -d 1 /Applications 2>/dev/null | sort -hr | head -10 | \
        awk '{printf "  %-50s %s\n", $2, $1}'
fi
echo ""

# Library sizes
echo "=========================================="
echo "  Library Sizes"
echo "=========================================="
if [[ -d "$HOME/Library" ]]; then
    du -h -d 1 "$HOME/Library" 2>/dev/null | sort -hr | head -10 | \
        awk '{printf "  %-50s %s\n", $2, $1}'
fi
echo ""

log SUCCESS "Disk analysis completed!"
