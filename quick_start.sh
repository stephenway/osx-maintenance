#!/bin/bash

# Quick Start Helper
# Provides easy access to common maintenance tasks

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "macOS Maintenance Toolbox - Quick Start"
echo "======================================"
echo ""
echo "1. Run full interactive menu"
echo "2. Quick health check"
echo "3. Quick cache cleanup"
echo "4. Check for updates"
echo "5. Disk space analysis"
echo ""
echo -n "Select option (or press Enter for full menu): "
read -r choice

case $choice in
    1|"")
        "$SCRIPT_DIR/maintenance.sh"
        ;;
    2)
        "$SCRIPT_DIR/tools/health_check.sh"
        ;;
    3)
        "$SCRIPT_DIR/tools/cleanup_caches.sh"
        ;;
    4)
        "$SCRIPT_DIR/tools/update_check.sh"
        ;;
    5)
        "$SCRIPT_DIR/tools/disk_analysis.sh"
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac
