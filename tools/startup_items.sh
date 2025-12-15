#!/bin/bash

# Startup Items Management Tool
# Lists and manages login items and launch agents

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

log INFO "Analyzing Startup Items..."
echo ""

# Login Items (user)
echo "=========================================="
echo "  Login Items (User)"
echo "=========================================="
if command -v osascript &> /dev/null; then
    osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null | \
        tr ',' '\n' | sed 's/^[[:space:]]*//' | while read -r item; do
        if [[ -n "$item" ]]; then
            echo "  - $item"
        fi
    done
fi
echo ""

# Launch Agents (user)
echo "=========================================="
echo "  Launch Agents (User)"
echo "=========================================="
launch_agents_dir="$HOME/Library/LaunchAgents"
if [[ -d "$launch_agents_dir" ]]; then
    count=$(find "$launch_agents_dir" -name "*.plist" 2>/dev/null | wc -l | tr -d ' ')
    log INFO "Found $count launch agent(s)"

    find "$launch_agents_dir" -name "*.plist" 2>/dev/null | while read -r plist; do
        label=$(defaults read "$plist" Label 2>/dev/null || basename "$plist")
        echo "  - $label"
    done
else
    log INFO "No user launch agents found"
fi
echo ""

# Launch Daemons (system - requires root)
if [[ $EUID -eq 0 ]]; then
    echo "=========================================="
    echo "  Launch Daemons (System)"
    echo "=========================================="
    launch_daemons_dir="/Library/LaunchDaemons"
    if [[ -d "$launch_daemons_dir" ]]; then
        find "$launch_daemons_dir" -name "*.plist" 2>/dev/null | while read -r plist; do
            label=$(defaults read "$plist" Label 2>/dev/null || basename "$plist")
            echo "  - $label"
        done
    fi
    echo ""
fi

# Currently loaded launch agents
echo "=========================================="
echo "  Currently Loaded Launch Agents"
echo "=========================================="
launchctl list | grep -v "^-" | head -20
echo ""

# Startup applications
echo "=========================================="
echo "  Startup Applications"
echo "=========================================="
startup_apps_dir="$HOME/Library/Application Support/Microsoft/Office/Office/Startup"
if [[ -d "$startup_apps_dir" ]]; then
    log INFO "Microsoft Office startup items found"
    ls -la "$startup_apps_dir"
fi
echo ""

log SUCCESS "Startup items analysis completed!"
log INFO "To manage login items, use System Preferences > Users & Groups > Login Items"
