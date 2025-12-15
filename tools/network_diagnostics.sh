#!/bin/bash

# Network Diagnostics Tool
# Performs various network connectivity and performance tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

log INFO "Starting Network Diagnostics..."
echo ""

# Basic connectivity
echo "=========================================="
echo "  Basic Connectivity"
echo "=========================================="
if ping -c 3 -W 1000 8.8.8.8 &> /dev/null; then
    log SUCCESS "Internet connectivity: OK"
    ping_time=$(ping -c 3 8.8.8.8 2>/dev/null | tail -1 | awk -F '/' '{print $5}')
    echo "  Average ping to 8.8.8.8: ${ping_time}ms"
else
    log ERROR "Internet connectivity: FAILED"
fi
echo ""

# DNS resolution
echo "=========================================="
echo "  DNS Resolution"
echo "=========================================="
if nslookup google.com &> /dev/null; then
    log SUCCESS "DNS resolution: OK"
    dns_server=$(scutil --dns | grep "nameserver\[0\]" | head -1 | awk '{print $3}' || echo "Unknown")
    echo "  Primary DNS: $dns_server"
else
    log ERROR "DNS resolution: FAILED"
fi
echo ""

# Network interfaces
echo "=========================================="
echo "  Network Interfaces"
echo "=========================================="
ifconfig | grep -E "^[a-z]|inet " | grep -B1 "inet " | head -20
echo ""

# Active connections
echo "=========================================="
echo "  Active Network Connections"
echo "=========================================="
netstat -an | grep ESTABLISHED | head -10
echo ""

# Routing table
echo "=========================================="
echo "  Routing Table"
echo "=========================================="
netstat -rn | head -10
echo ""

# Network speed test (if speedtest-cli is available)
if command -v speedtest-cli &> /dev/null; then
    echo "=========================================="
    echo "  Internet Speed Test"
    echo "=========================================="
    log INFO "Running speed test (this may take a minute)..."
    speedtest-cli --simple 2>/dev/null || log WARNING "Speed test failed or unavailable"
    echo ""
elif command -v networkQuality &> /dev/null; then
    echo "=========================================="
    echo "  Network Quality Test"
    echo "=========================================="
    networkQuality -v
    echo ""
fi

# Wi-Fi information (if available)
if command -v /System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport &> /dev/null; then
    echo "=========================================="
    echo "  Wi-Fi Information"
    echo "=========================================="
    /System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I
    echo ""
fi

log SUCCESS "Network diagnostics completed!"
