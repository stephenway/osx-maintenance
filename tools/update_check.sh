#!/bin/bash

# System Update Check Tool
# Checks for available system and app updates

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

log INFO "Checking for system updates..."
echo ""

# macOS System Updates
echo "=========================================="
echo "  macOS System Updates"
echo "=========================================="
if command -v softwareupdate &> /dev/null; then
    if [[ $EUID -eq 0 ]]; then
        log INFO "Checking for available updates..."
        softwareupdate -l 2>&1 | head -30

        update_count=$(softwareupdate -l 2>&1 | grep -c "Software Update found" || echo "0")
        if [[ $update_count -gt 0 ]]; then
            echo ""
            log WARNING "System updates are available!"
            echo "To install updates, run: sudo softwareupdate -i -a"
        else
            log SUCCESS "System is up to date"
        fi
    else
        log INFO "Checking for available updates (limited without admin privileges)..."
        softwareupdate -l 2>&1 | head -20
        log INFO "For full update management, run with sudo"
    fi
else
    log WARNING "softwareupdate command not available"
fi
echo ""

# App Store Updates
echo "=========================================="
echo "  App Store Updates"
echo "=========================================="
if command -v mas &> /dev/null; then
    log INFO "Checking App Store updates..."
    outdated_count=$(mas outdated 2>/dev/null | wc -l | tr -d ' ')
    if [[ $outdated_count -gt 0 ]]; then
        log WARNING "$outdated_count App Store app(s) have updates available"
        mas outdated
        echo ""
        echo "To update all: mas upgrade"
    else
        log SUCCESS "All App Store apps are up to date"
    fi
else
    log INFO "mas (Mac App Store command line) not installed"
    log INFO "Install with: brew install mas"
fi
echo ""

# Homebrew Updates (if installed)
echo "=========================================="
echo "  Homebrew Updates"
echo "=========================================="
if command -v brew &> /dev/null; then
    log INFO "Checking Homebrew updates..."
    outdated=$(brew outdated 2>/dev/null | wc -l | tr -d ' ')
    if [[ $outdated -gt 0 ]]; then
        log WARNING "$outdated Homebrew package(s) have updates available"
        brew outdated | head -20
        echo ""
        echo "To update all: brew upgrade"
    else
        log SUCCESS "All Homebrew packages are up to date"
    fi

    # Check for Homebrew itself
    if brew update &> /dev/null; then
        log INFO "Homebrew is up to date"
    fi
else
    log INFO "Homebrew not installed"
fi
echo ""

# Xcode Command Line Tools
echo "=========================================="
echo "  Xcode Command Line Tools"
echo "=========================================="
if xcode-select -p &> /dev/null; then
    log SUCCESS "Xcode Command Line Tools are installed"
    xcode-select -p
else
    log WARNING "Xcode Command Line Tools not installed"
    log INFO "Install with: xcode-select --install"
fi
echo ""

log SUCCESS "Update check completed!"
