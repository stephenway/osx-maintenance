#!/bin/bash

# System Health Check Tool
# Checks various system health indicators

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

log INFO "Starting System Health Check..."
echo ""

# Check disk space
echo "=== Disk Space ==="
df -h / | tail -1 | awk '{print "Root partition: " $4 " free of " $2 " (" $5 " used)"}'
disk_usage=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
if [[ $disk_usage -gt 90 ]]; then
    log WARNING "Disk usage is above 90%!"
elif [[ $disk_usage -gt 80 ]]; then
    log WARNING "Disk usage is above 80%"
else
    log SUCCESS "Disk usage is healthy"
fi
echo ""

# Check memory
echo "=== Memory Usage ==="
memory_pressure=$(memory_pressure 2>/dev/null | grep "System-wide memory free percentage" | awk '{print $5}' | sed 's/%//' || echo "N/A")
if [[ "$memory_pressure" != "N/A" ]]; then
    if [[ $memory_pressure -lt 10 ]]; then
        log WARNING "Low memory: ${memory_pressure}% free"
    else
        log SUCCESS "Memory: ${memory_pressure}% free"
    fi
fi
vm_stat | head -5
echo ""

# Check CPU load
echo "=== CPU Load ==="
uptime
cpu_cores=$(sysctl -n hw.ncpu)
log INFO "CPU Cores: $cpu_cores"
echo ""

# Check system integrity
echo "=== System Integrity ==="
if command -v csrutil &> /dev/null; then
    sip_status=$(csrutil status 2>&1 | grep -i "System Integrity Protection" || echo "Unknown")
    echo "SIP Status: $sip_status"
fi
echo ""

# Check for system updates
echo "=== System Updates ==="
if command -v softwareupdate &> /dev/null; then
    update_count=$(softwareupdate -l 2>&1 | grep -c "Software Update found" || echo "0")
    if [[ $update_count -gt 0 ]]; then
        log WARNING "System updates available"
    else
        log SUCCESS "System is up to date"
    fi
fi
echo ""

# Check disk health (if possible)
echo "=== Disk Health ==="
if command -v diskutil &> /dev/null; then
    diskutil verifyVolume / 2>&1 | head -3 || log INFO "Disk verification requires admin privileges"
fi
echo ""

# Check network connectivity
echo "=== Network Connectivity ==="
if ping -c 1 -W 1000 8.8.8.8 &> /dev/null; then
    log SUCCESS "Internet connectivity: OK"
else
    log WARNING "Internet connectivity: Failed"
fi
echo ""

# Check running processes
echo "=== Top Processes (CPU) ==="
ps aux | sort -rk 3,3 | head -6 | awk '{printf "%-8s %6.1f%% %s\n", $1, $3, $11}'
echo ""

# Check system uptime
echo "=== System Uptime ==="
uptime -s 2>/dev/null || uptime
echo ""

log SUCCESS "Health check completed!"
