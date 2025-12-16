#!/bin/bash

# macOS Ultimate Maintenance Toolbox
# Main orchestrator script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$SCRIPT_DIR/tools"
CONFIG_FILE="$SCRIPT_DIR/config.conf"

# Load configuration
if [[ -f "$CONFIG_FILE" ]]; then
    # Export SCRIPT_DIR for config file
    export SCRIPT_DIR
    source "$CONFIG_FILE"
fi

# Default settings
DRY_RUN=${DRY_RUN:-false}
VERBOSE=${VERBOSE:-false}
LOG_FILE=${LOG_FILE:-"$SCRIPT_DIR/maintenance.log"}

# Load shared functions
LIB_DIR="$SCRIPT_DIR/lib"
if [[ -f "$LIB_DIR/functions.sh" ]]; then
    source "$LIB_DIR/functions.sh"
else
    # Fallback logging function if lib not found
    log() {
        local level=$1
        shift
        local message="$*"
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

        case $level in
            INFO)
                echo -e "${BLUE}[INFO]${NC} $message"
                ;;
            SUCCESS)
                echo -e "${GREEN}[SUCCESS]${NC} $message"
                ;;
            WARNING)
                echo -e "${YELLOW}[WARNING]${NC} $message"
                ;;
            ERROR)
                echo -e "${RED}[ERROR]${NC} $message" >&2
                ;;
        esac

        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    }
fi

# Check if running as root when needed
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log ERROR "This operation requires root privileges. Please run with sudo."
        return 1
    fi
}

# Display menu
show_menu() {
    clear
    echo "=========================================="
    echo "  macOS Ultimate Maintenance Toolbox"
    echo "=========================================="
    echo ""
    echo "1.  System Health Check"
    echo "2.  Clean System Caches"
    echo "3.  Clean Log Files"
    echo "4.  Clean Temporary Files"
    echo "5.  Clean Downloads Folder (old files)"
    echo "6.  Filesystem & Volume Repair"
    echo "7.  System Performance Report"
    echo "8.  Disk Space Analysis"
    echo "8a. Disk Space Report (What Can Be Freed)"
    echo "9.  Startup Items Management"
    echo "10. Network Diagnostics"
    echo "11. System Update Check"
    echo "12. Application Analysis"
    echo "13. Application Cleanup (Safe)"
    echo "14. Application Uninstall Helper"
    echo "15. Find Orphaned Files (AppZapper-style)"
    echo "16. Cleanup Orphaned Files (Interactive Checklist)"
    echo "17. Full Maintenance (All Safe Operations)"
    echo "18. View Logs"
    echo "19. Configure Settings"
    echo "0.  Exit"
    echo ""
    echo -n "Select an option: "
}

# Run tool script
run_tool() {
    local tool=$1
    shift
    local tool_path="$TOOLS_DIR/$tool.sh"

    if [[ ! -f "$tool_path" ]]; then
        log ERROR "Tool '$tool' not found!"
        return 1
    fi

    if [[ "$VERBOSE" == "true" ]]; then
        log INFO "Running: $tool $*"
    fi

    bash "$tool_path" "$@"
}

# Main execution
main() {
    # Create tools directory if it doesn't exist
    mkdir -p "$TOOLS_DIR"

    # Initialize log file
    touch "$LOG_FILE"

    log INFO "Maintenance Toolbox initialized"

    while true; do
        show_menu
        read -r choice

        case $choice in
            1)
                run_tool "health_check"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            2)
                run_tool "cleanup_caches"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            3)
                run_tool "cleanup_logs"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            4)
                run_tool "cleanup_temp"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            5)
                run_tool "cleanup_downloads"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            6)
                if check_root; then
                    run_tool "repair_permissions"
                fi
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            7)
                run_tool "performance_report"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            8)
                run_tool "disk_analysis"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            8a|8A)
                run_tool "disk_space_report"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            9)
                run_tool "startup_items"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            10)
                run_tool "network_diagnostics"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            11)
                run_tool "update_check"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            12)
                run_tool "app_analysis"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            13)
                run_tool "app_cleanup"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            14)
                run_tool "app_uninstall"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            15)
                run_tool "find_orphaned_files"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            16)
                run_tool "cleanup_orphaned_files_interactive"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            17)
                log INFO "Running full maintenance..."
                run_tool "health_check"
                run_tool "cleanup_caches"
                run_tool "cleanup_logs"
                run_tool "cleanup_temp"
                run_tool "disk_analysis"
                run_tool "app_cleanup"
                log SUCCESS "Full maintenance completed!"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            18)
                if [[ -f "$LOG_FILE" ]]; then
                    less "$LOG_FILE"
                else
                    log WARNING "No log file found"
                fi
                ;;
            19)
                configure_settings
                ;;
            0)
                log INFO "Exiting Maintenance Toolbox"
                exit 0
                ;;
            *)
                log WARNING "Invalid option. Please try again."
                sleep 1
                ;;
        esac
    done
}

# Configure settings
configure_settings() {
    clear
    echo "=========================================="
    echo "  Configuration"
    echo "=========================================="
    echo ""
    echo "Current settings:"
    echo "  DRY_RUN: ${DRY_RUN:-false}"
    echo "  VERBOSE: ${VERBOSE:-false}"
    echo "  LOG_FILE: $LOG_FILE"
    echo ""
    echo "1. Toggle DRY_RUN mode"
    echo "2. Toggle VERBOSE mode"
    echo "3. Change log file location"
    echo "0. Back to main menu"
    echo ""
    echo -n "Select an option: "
    read -r config_choice

    case $config_choice in
        1)
            if [[ "${DRY_RUN:-false}" == "true" ]]; then
                export DRY_RUN=false
                log INFO "DRY_RUN mode disabled"
            else
                export DRY_RUN=true
                log INFO "DRY_RUN mode enabled"
            fi
            ;;
        2)
            if [[ "${VERBOSE:-false}" == "true" ]]; then
                export VERBOSE=false
                log INFO "VERBOSE mode disabled"
            else
                export VERBOSE=true
                log INFO "VERBOSE mode enabled"
            fi
            ;;
        3)
            echo -n "Enter new log file path: "
            read -r new_log
            export LOG_FILE="$new_log"
            log INFO "Log file set to: $LOG_FILE"
            ;;
    esac

    echo ""
    echo "Press Enter to continue..."
    read -r
}

# Run main function
main "$@"
