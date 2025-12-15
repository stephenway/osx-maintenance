# macOS Maintenance Toolbox

A comprehensive collection of maintenance scripts and utilities for macOS system maintenance, optimization, and health monitoring.

## ⚠️ Important Disclaimer

**This toolbox will not make your Mac faster. It will make it less messy.**

This is a maintenance toolbox, not a performance optimization suite. It helps you:

- Free up disk space by cleaning caches, logs, and temporary files
- Identify what's using your storage
- Keep your system organized
- Monitor system health

It will **not**:

- Speed up your Mac (though freeing space can help)
- Fix hardware issues
- Replace professional system administration
- Work miracles

Use it to maintain a clean system, not to solve performance problems.

## Features

### 🏥 System Health Check

- Disk space monitoring
- Memory usage analysis
- CPU load monitoring
- System integrity checks
- Network connectivity tests
- Process monitoring

### 🧹 Cleanup Tools

- **Cache Cleanup**: Removes system and user caches (browser, application, system)
- **Log Cleanup**: Removes old log files (configurable age)
- **Temp Files**: Cleans temporary files from various locations
- **Downloads**: Manages old files in Downloads folder

### 🔧 System Maintenance

- **Filesystem & Volume Repair**: Verifies filesystem integrity and basic permissions (note: macOS no longer supports traditional permission repair)
- **Performance Report**: Comprehensive system performance analysis
- **Disk Analysis**: Analyzes disk usage and finds large files
- **Startup Items**: Lists and manages login items and launch agents

### 🌐 Network & Updates

- **Network Diagnostics**: Connectivity tests, DNS checks, speed tests
- **Update Check**: Checks for macOS, App Store, and Homebrew updates

### 📱 Application Management

- **Application Analysis**: Analyzes Applications and Application Support folder sizes
- **Application Cleanup**: Safely cleans app caches, logs, and temporary data
- **Application Uninstall Helper**: Identifies unused apps and orphaned support data
- **Find Orphaned Files**: AppZapper-style tool to find leftover files from uninstalled apps
- **Cleanup Orphaned Files**: Interactive tool to safely remove orphaned application files

## Installation

1. Clone or download this repository:

```bash
cd ~/Developer/maintenance
```

2. Make scripts executable:

```bash
chmod +x maintenance.sh
chmod +x tools/*.sh
```

3. Run the main script:

```bash
./maintenance.sh
```

## Usage

### Interactive Mode

Run the main script to access an interactive menu:

```bash
./maintenance.sh
```

### Individual Tools

You can also run individual tools directly:

```bash
./tools/health_check.sh
./tools/cleanup_caches.sh
./tools/disk_analysis.sh
```

### Configuration

Edit `config.conf` to customize settings:

- `DRY_RUN`: Enable to preview changes without applying them
- `VERBOSE`: Enable for detailed output
- `LOG_AGE_DAYS`: Days before logs are considered old (default: 30)
- `DOWNLOADS_AGE_DAYS`: Days before downloads are considered old (default: 90)

## Tools Overview

### 1. System Health Check (`health_check.sh`)

Comprehensive system health analysis including:

- Disk space and usage
- Memory status
- CPU load
- System integrity protection status
- Update availability
- Network connectivity

### 2. Cache Cleanup (`cleanup_caches.sh`)

Safely removes:

- User caches (`~/Library/Caches`)
- Browser caches (Chrome, Safari, Firefox, Opera)
- System caches (requires admin)
- Xcode derived data
- Trash contents

### 3. Log Cleanup (`cleanup_logs.sh`)

Removes log files older than configured age:

- User logs
- System logs (requires admin)
- Application crash reports
- Diagnostic reports

### 4. Temporary Files (`cleanup_temp.sh`)

Cleans temporary files from:

- `/tmp`
- `$TMPDIR`
- Downloads temp files
- Old files in Downloads (configurable)

### 5. Downloads Cleanup (`cleanup_downloads.sh`)

Interactive tool to manage old files in Downloads folder:

- Lists files older than configured age
- Shows size and file count
- Interactive removal with confirmation

### 6. Filesystem & Volume Repair (`repair_permissions.sh`)

**Requires sudo**

**Important**: macOS 10.11+ removed traditional permission repair. This tool:

- Verifies and repairs disk volumes (filesystem integrity)
- Fixes basic user permission issues (SSH keys, etc.)
- Provides guidance for NVRAM/SMC reset

**Does NOT**: Repair SIP-protected system file permissions (macOS handles this automatically)

### 7. Performance Report (`performance_report.sh`)

Generates detailed performance report:

- System information
- CPU details and load
- Memory statistics
- Disk I/O
- Top processes (CPU and memory)
- Network statistics
- Battery status (if applicable)

### 8. Disk Analysis (`disk_analysis.sh`)

Analyzes disk usage:

- Overall disk usage
- Home directory breakdown
- Largest directories
- Large files (>100MB)
- Application sizes
- Library sizes

### 9. Startup Items (`startup_items.sh`)

Lists and analyzes startup items:

- Login items
- Launch agents (user and system)
- Currently loaded agents
- Startup applications

### 10. Network Diagnostics (`network_diagnostics.sh`)

Comprehensive network testing:

- Basic connectivity (ping tests)
- DNS resolution
- Network interfaces
- Active connections
- Routing table
- Speed/quality tests (if available)
- Wi-Fi information

### 11. Update Check (`update_check.sh`)

Checks for available updates:

- macOS system updates
- App Store updates (requires `mas`)
- Homebrew packages
- Xcode Command Line Tools

### 12. Application Analysis (`app_analysis.sh`)

Comprehensive analysis of applications and their data:

- Applications folder size breakdown
- Application Support folder analysis (identifies largest consumers)
- Browser data analysis
- Development tools analysis (Xcode, JetBrains, VS Code)
- Game platforms analysis
- Recommendations for cleanup

### 13. Application Cleanup (`app_cleanup.sh`)

Safely cleans application data without removing settings:

- Browser caches (Chrome, Safari, Firefox, etc.)
- Development tool caches and derived data (Xcode, JetBrains, VS Code)
- Application logs and crash reports
- Game platform caches (Steam, Battle.net)
- Preserves user settings and important data

### 14. Application Uninstall Helper (`app_uninstall.sh`)

Helps identify and manage unused applications:

- Lists all installed applications sorted by size
- Identifies potentially unused apps (not accessed in 90+ days)
- Finds orphaned Application Support data
- Provides guidance for safe uninstallation

### 15. Find Orphaned Files (`find_orphaned_files.sh`)

AppZapper-style tool to find leftover files from uninstalled applications:

- Scans all Library directories (Application Support, Preferences, Caches, etc.)
- Compares against currently installed applications
- Identifies orphaned files and folders by name and bundle ID
- Shows sizes and groups by location
- Lists largest items first

**Performance**: Optimized for speed with:

- Fast size estimation (uses `stat` for files instead of `du`)
- Deferred `du` calculations (only for directories that match app patterns)
- Limited substring matching (stops after first 50 apps)
- Quick scan mode available: `QUICK_SCAN=true ./tools/find_orphaned_files.sh` (skips size calculations)

### 16. Cleanup Orphaned Files (`cleanup_orphaned_files_interactive.sh`)

Interactive checklist tool to safely remove orphaned application files:

- **Full report**: Shows all orphaned items with sizes and locations
- **Item-by-item selection**: Check/uncheck each item individually
- **Batch operations**: Select all, select none, show selected only
- **Safe removal**: Confirms before removing, shows total size
- **Dry-run mode**: Preview what would be removed

**Usage**:

- Enter item number to toggle selection
- `a` = select all items
- `n` = deselect all items
- `s` = show only selected items
- `r` = remove selected items (with confirmation)
- `q` = quit without removing

## Safety Features

- **Dry Run Mode**: Preview changes before applying
- **Confirmation Prompts**: Important operations require confirmation
- **Logging**: All operations are logged
- **Error Handling**: Graceful error handling throughout
- **Root Checks**: Tools that require admin privileges check first

## Requirements

- macOS 10.11 or later
- Bash 3.2+ (macOS default) - scripts are compatible with macOS's default bash
- Some tools require admin privileges (sudo)

**Note**: macOS ships with Bash 3.2. All scripts are tested and compatible with this version. If you have Homebrew bash installed, that works too, but it's not required.

### Optional Dependencies

- `mas`: For App Store update checking (`brew install mas`)
- `speedtest-cli`: For network speed testing (`brew install speedtest-cli`)
- `networkQuality`: Built-in macOS tool (macOS 12+)

## Examples

### Quick Health Check

```bash
./tools/health_check.sh
```

### Clean All Caches (Dry Run)

```bash
DRY_RUN=true ./tools/cleanup_caches.sh
```

### Full Maintenance

```bash
./maintenance.sh
# Select option 12: Full Maintenance
```

### Check for Updates

```bash
./tools/update_check.sh
```

## Logs

All operations are logged to `maintenance.log` by default. You can:

- View logs from the main menu (option 13)
- Change log location in `config.conf`
- View logs directly: `less maintenance.log`

## Best Practices

1. **Run health checks regularly** to monitor system status
2. **Use dry run mode first** when trying new cleanup operations
3. **Review disk analysis** before cleaning to understand what will be removed
4. **Keep backups** before running permission repairs
5. **Schedule regular maintenance** using cron or launchd

## Scheduling Maintenance

### Using cron

Add to crontab (`crontab -e`):

```bash
# Weekly health check (Sundays at 2 AM)
0 2 * * 0 /Users/stephen/Developer/maintenance/tools/health_check.sh >> /Users/stephen/Developer/maintenance/cron.log 2>&1

# Monthly cleanup (1st of month at 3 AM)
0 3 1 * * /Users/stephen/Developer/maintenance/tools/cleanup_caches.sh >> /Users/stephen/Developer/maintenance/cron.log 2>&1
```

### Using launchd

Create `~/Library/LaunchAgents/com.maintenance.weekly.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.maintenance.weekly</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/stephen/Developer/maintenance/tools/health_check.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/Users/stephen/Developer/maintenance/launchd.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/stephen/Developer/maintenance/launchd.error.log</string>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
```

Then load it:

```bash
launchctl load ~/Library/LaunchAgents/com.maintenance.weekly.plist
```

**Important**: The `StandardOutPath` and `StandardErrorPath` keys ensure you can debug issues. Check these log files if scheduled tasks aren't running. `RunAtLoad` is set to `false` so it only runs on the schedule, not immediately when loaded.

## Troubleshooting

### Permission Denied

Some tools require admin privileges. Run with sudo:

```bash
sudo ./tools/repair_permissions.sh
```

### Script Not Executable

Make scripts executable:

```bash
chmod +x maintenance.sh tools/*.sh
```

### Tools Not Found

Ensure you're running from the correct directory or use absolute paths.

## Contributing

Feel free to extend this toolbox with additional tools. Each tool should:

- Be placed in the `tools/` directory
- Follow the existing script structure
- Include proper error handling
- Support DRY_RUN mode when applicable
- Use the logging functions from the main script

## License

This toolbox is provided as-is for personal use. Use at your own risk.

## Disclaimer

This toolbox performs system maintenance operations. While care has been taken to make operations safe:

- Always backup important data before running maintenance
- Review what will be deleted in dry run mode
- Some operations cannot be undone
- Use with caution on production systems

## Support

For issues or questions, review the logs in `maintenance.log` and check individual tool outputs for specific error messages.
