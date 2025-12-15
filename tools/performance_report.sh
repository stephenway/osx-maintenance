#!/bin/bash

# System Performance Report Tool
# Generates a comprehensive performance report

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

log INFO "Generating Performance Report..."
echo ""

# System Information
echo "=========================================="
echo "  System Information"
echo "=========================================="
system_profiler SPHardwareDataType | grep -E "(Model Name|Model Identifier|Processor|Memory|Serial)" | head -6
echo ""

# CPU Information
echo "=========================================="
echo "  CPU Performance"
echo "=========================================="
echo "CPU Cores: $(sysctl -n hw.ncpu)"
echo "CPU Physical Cores: $(sysctl -n hw.physicalcpu)"
echo "CPU Logical Cores: $(sysctl -n hw.logicalcpu)"
echo "CPU Frequency: $(sysctl -n hw.cpufrequency_max | awk '{printf "%.2f GHz\n", $1/1000000000}')"
echo ""
echo "Load Average:"
uptime | awk -F'load averages:' '{print $2}'
echo ""

# Memory Information
echo "=========================================="
echo "  Memory Performance"
echo "=========================================="
total_mem=$(sysctl -n hw.memsize | awk '{printf "%.2f GB\n", $1/1024/1024/1024}')
echo "Total Memory: $total_mem"
echo ""
vm_stat | head -10
echo ""

# Disk I/O
echo "=========================================="
echo "  Disk Performance"
echo "=========================================="
df -h | grep -E "(Filesystem|/dev/)" | head -5
echo ""

# Top CPU Processes
echo "=========================================="
echo "  Top CPU Processes"
echo "=========================================="
ps aux | head -1
ps aux | sort -rk 3,3 | head -6 | tail -5
echo ""

# Top Memory Processes
echo "=========================================="
echo "  Top Memory Processes"
echo "=========================================="
ps aux | head -1
ps aux | sort -rk 4,4 | head -6 | tail -5
echo ""

# Network Statistics
echo "=========================================="
echo "  Network Statistics"
echo "=========================================="
ifconfig | grep -E "(inet |status)" | head -6
echo ""

# System Uptime
echo "=========================================="
echo "  System Uptime"
echo "=========================================="
uptime
echo ""

# Battery Status (if applicable)
if pmset -g batt &> /dev/null; then
    echo "=========================================="
    echo "  Power Management"
    echo "=========================================="
    pmset -g batt
    echo ""
fi

log SUCCESS "Performance report generated!"
