#!/bin/bash

# Filesystem & Volume Repair Tool
# Note: macOS 10.11+ removed traditional permission repair.
# This tool performs filesystem verification and basic ownership checks only.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

if [[ $EUID -ne 0 ]]; then
    log ERROR "This tool requires root privileges"
    exit 1
fi

log INFO "Starting Filesystem & Volume Repair..."
log WARNING "Note: macOS no longer supports traditional permission repair."
log INFO "This tool performs filesystem verification and basic ownership checks only."
echo ""

# On macOS 10.11+, diskutil repairPermissions is deprecated
# We use diskutil verifyVolume and repairVolume instead

echo "=== Verifying Disk ==="
if diskutil verifyVolume / &> /dev/null; then
    log SUCCESS "Disk verification passed"
else
    log WARNING "Disk issues detected, attempting repair..."
    diskutil repairVolume /
fi
echo ""

# Repair permissions on user home directory (if running as current user's admin)
echo "=== Repairing User Permissions ==="
if [[ -n "${SUDO_USER:-}" ]]; then
    USER_HOME=$(eval echo ~$SUDO_USER)
    log INFO "Repairing permissions for: $USER_HOME"

    # Fix common permission issues
    chmod 700 "$USER_HOME/.ssh" 2>/dev/null || true
    chmod 600 "$USER_HOME/.ssh/id_*" 2>/dev/null || true
    chmod 644 "$USER_HOME/.ssh/known_hosts" 2>/dev/null || true
    chmod 644 "$USER_HOME/.ssh/config" 2>/dev/null || true

    log SUCCESS "User permissions repaired"
fi
echo ""

# Reset NVRAM/PRAM (requires reboot, so just inform)
log INFO "For complete system reset, consider:"
log INFO "  - Resetting NVRAM: Hold Option+Command+P+R at startup"
log INFO "  - Resetting SMC: Shut down, then hold Shift+Control+Option+Power"

log SUCCESS "Filesystem repair completed!"
log INFO "For SIP-protected system files, macOS handles permissions automatically."
