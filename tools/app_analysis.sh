#!/bin/bash

# Application Analysis Tool
# Analyzes Applications and Application Support folder sizes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

log INFO "Starting Application Analysis..."
echo ""

# Applications folder analysis
echo "=========================================="
echo "  Applications Folder Analysis"
echo "=========================================="
if [[ -d "/Applications" ]]; then
    total_apps_size=$(du -sk /Applications 2>/dev/null | awk '{print $1}')
    total_apps_mb=$((total_apps_size / 1024))
    total_apps_gb=$((total_apps_mb / 1024))

    if [[ $total_apps_gb -gt 0 ]]; then
        log INFO "Total Applications size: ${total_apps_gb}GB (${total_apps_mb}MB)"
    else
        log INFO "Total Applications size: ${total_apps_mb}MB"
    fi
    echo ""

    echo "Largest Applications:"
    du -h -d 1 /Applications 2>/dev/null | sort -hr | head -20 | \
        awk '{printf "  %-50s %s\n", $2, $1}'
else
    log WARNING "Applications folder not found"
fi
echo ""

# Application Support analysis
echo "=========================================="
echo "  Application Support Analysis"
echo "=========================================="
app_support="$HOME/Library/Application Support"
if [[ -d "$app_support" ]]; then
    total_support_size=$(du -sk "$app_support" 2>/dev/null | awk '{print $1}')
    total_support_mb=$((total_support_size / 1024))
    total_support_gb=$((total_support_mb / 1024))

    if [[ $total_support_gb -gt 0 ]]; then
        log INFO "Total Application Support size: ${total_support_gb}GB (${total_support_mb}MB)"
    else
        log INFO "Total Application Support size: ${total_support_mb}MB"
    fi
    echo ""

    echo "Largest Application Support folders:"
    du -h -d 1 "$app_support" 2>/dev/null | sort -hr | head -30 | \
        awk '{printf "  %-50s %s\n", $2, $1}'
else
    log WARNING "Application Support folder not found"
fi
echo ""

# Identify large app bundles
echo "=========================================="
echo "  Large Application Bundles (>500MB)"
echo "=========================================="
find /Applications -maxdepth 1 -type d -exec du -sh {} \; 2>/dev/null | \
    awk '$1 ~ /[0-9]+[GM]/ && ($1+0 > 500 || $1 ~ /G/) {print}' | \
    sort -hr | head -20 | awk '{printf "  %-50s %s\n", $2, $1}'
echo ""

# Browser-specific analysis
echo "=========================================="
echo "  Browser Data Analysis"
echo "=========================================="
browsers=(
    "Google/Chrome"
    "com.google.Chrome"
    "com.apple.Safari"
    "com.operasoftware.Opera"
    "com.mozilla.firefox"
    "com.brave.Browser"
    "com.microsoft.edgemac"
)

for browser in "${browsers[@]}"; do
    browser_path="$app_support/$browser"
    if [[ -d "$browser_path" ]]; then
        browser_size=$(du -sh "$browser_path" 2>/dev/null | awk '{print $1}')
        browser_name=$(basename "$browser_path")
        echo "  $browser_name: $browser_size"

        # Check for large cache subdirectories
        if [[ -d "$browser_path/Cache" ]]; then
            cache_size=$(du -sh "$browser_path/Cache" 2>/dev/null | awk '{print $1}')
            echo "    └─ Cache: $cache_size"
        fi
        if [[ -d "$browser_path/Default/Cache" ]]; then
            cache_size=$(du -sh "$browser_path/Default/Cache" 2>/dev/null | awk '{print $1}')
            echo "    └─ Default/Cache: $cache_size"
        fi
    fi
done
echo ""

# Development tools analysis
echo "=========================================="
echo "  Development Tools Analysis"
echo "=========================================="
dev_tools=(
    "JetBrains"
    "Code"
    "Xcode"
    "com.apple.dt.Xcode"
)

for tool in "${dev_tools[@]}"; do
    # Check in Applications
    if [[ -d "/Applications/$tool.app" ]]; then
        app_size=$(du -sh "/Applications/$tool.app" 2>/dev/null | awk '{print $1}')
        echo "  $tool.app: $app_size"
    fi

    # Check in Application Support
    tool_path="$app_support/$tool"
    if [[ -d "$tool_path" ]]; then
        support_size=$(du -sh "$tool_path" 2>/dev/null | awk '{print $1}')
        echo "    └─ Application Support: $support_size"

        # Check for derived data, caches, etc.
        if [[ -d "$tool_path/DerivedData" ]]; then
            derived_size=$(du -sh "$tool_path/DerivedData" 2>/dev/null | awk '{print $1}')
            echo "      └─ DerivedData: $derived_size"
        fi
        if [[ -d "$tool_path/Caches" ]]; then
            cache_size=$(du -sh "$tool_path/Caches" 2>/dev/null | awk '{print $1}')
            echo "      └─ Caches: $cache_size"
        fi
    fi
done
echo ""

# Game platforms analysis
echo "=========================================="
echo "  Game Platforms Analysis"
echo "=========================================="
game_platforms=(
    "Steam"
    "Battle.net"
    "Epic Games"
    "Paradox Interactive"
)

for platform in "${game_platforms[@]}"; do
    platform_path="$app_support/$platform"
    if [[ -d "$platform_path" ]]; then
        platform_size=$(du -sh "$platform_path" 2>/dev/null | awk '{print $1}')
        echo "  $platform: $platform_size"
    fi
done
echo ""

# Summary and recommendations
echo "=========================================="
echo "  Recommendations"
echo "=========================================="
log INFO "Consider cleaning:"
echo "  - Browser caches (can be safely cleared)"
echo "  - Development tool derived data and caches"
echo "  - Unused applications"
echo "  - Old application logs and crash reports"
echo ""
log INFO "Use './tools/app_cleanup.sh' for safe cleanup options"

log SUCCESS "Application analysis completed!"
