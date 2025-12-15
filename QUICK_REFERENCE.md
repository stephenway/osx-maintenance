# Quick Reference Guide

## Quick Commands

### Start the Toolbox
```bash
./maintenance.sh
# or
./quick_start.sh
```

### Individual Tools
```bash
# Health check
./tools/health_check.sh

# Clean caches
./tools/cleanup_caches.sh

# Clean logs (older than 30 days)
./tools/cleanup_logs.sh

# Clean temp files
./tools/cleanup_temp.sh

# Clean old downloads (interactive)
./tools/cleanup_downloads.sh

# Repair permissions (requires sudo)
sudo ./tools/repair_permissions.sh

# Performance report
./tools/performance_report.sh

# Disk analysis
./tools/disk_analysis.sh

# Startup items
./tools/startup_items.sh

# Network diagnostics
./tools/network_diagnostics.sh

# Check for updates
./tools/update_check.sh

# Application management
./tools/app_analysis.sh
./tools/app_cleanup.sh
./tools/app_uninstall.sh

# Orphaned files (AppZapper-style)
./tools/find_orphaned_files.sh
./tools/cleanup_orphaned_files.sh
```

## Dry Run Mode

Preview changes without applying them:
```bash
DRY_RUN=true ./tools/cleanup_caches.sh
DRY_RUN=true ./tools/cleanup_logs.sh
```

## Common Tasks

### Weekly Maintenance
```bash
./tools/health_check.sh
./tools/cleanup_caches.sh
./tools/disk_analysis.sh
```

### Monthly Deep Clean
```bash
./tools/cleanup_caches.sh
./tools/cleanup_logs.sh
./tools/cleanup_temp.sh
./tools/cleanup_downloads.sh
./tools/app_cleanup.sh
sudo ./tools/repair_permissions.sh
```

### Application Storage Management
```bash
# Analyze what's taking up space
./tools/app_analysis.sh

# Clean app caches and logs (safe)
./tools/app_cleanup.sh

# Find unused apps to uninstall
./tools/app_uninstall.sh
```

### System Health Check
```bash
./tools/health_check.sh
./tools/performance_report.sh
./tools/network_diagnostics.sh
./tools/update_check.sh
```

## Configuration

Edit `config.conf` to customize:
- `DRY_RUN`: Preview mode (true/false)
- `VERBOSE`: Detailed output (true/false)
- `LOG_AGE_DAYS`: Days before logs are old (default: 30)
- `DOWNLOADS_AGE_DAYS`: Days before downloads are old (default: 90)

## Logs

View maintenance logs:
```bash
less maintenance.log
# or from menu: option 13
```

## Tips

1. **Always use dry run first** when trying new cleanup operations
2. **Review disk analysis** before cleaning to see what will be removed
3. **Some tools require sudo** - they will prompt you
4. **Downloads cleanup is interactive** - you'll be asked to confirm
5. **Logs are saved** to `maintenance.log` for review

## Troubleshooting

**Permission denied?**
- Some tools need sudo: `sudo ./tools/repair_permissions.sh`

**Script not found?**
- Make sure you're in the maintenance directory
- Or use full paths: `/Users/stephen/Developer/maintenance/maintenance.sh`

**Want to see what would be deleted?**
- Use `DRY_RUN=true` before the command
