# Application Management Guide

## Overview

The Application Management tools help you identify and manage applications and their data that consume significant disk space. Based on your system analysis showing Application Support at 68.8GB, these tools are essential for maintaining a clean system.

## Tools

### 1. Application Analysis (`app_analysis.sh`)

**Purpose**: Identify which applications and their support data are consuming the most space.

**What it shows**:
- Total size of Applications folder
- Largest applications sorted by size
- Application Support folder breakdown (the 68.8GB you're seeing)
- Browser-specific data analysis
- Development tools analysis (Xcode, JetBrains, VS Code)
- Game platforms analysis

**Usage**:
```bash
./tools/app_analysis.sh
```

**Example output highlights**:
- Shows which apps in Application Support are largest
- Identifies browser caches that can be safely cleared
- Shows development tool derived data and caches
- Lists game platform data sizes

### 2. Application Cleanup (`app_cleanup.sh`)

**Purpose**: Safely clean application caches, logs, and temporary data without removing settings or user data.

**What it cleans** (safely):
- ✅ Browser caches (Chrome, Safari, Firefox, Opera, Brave, Edge)
- ✅ Xcode DerivedData and old Archives
- ✅ JetBrains IDE caches and logs
- ✅ VS Code caches
- ✅ Application crash reports (older than 30 days)
- ✅ Application logs (older than 30 days)
- ✅ Game platform caches (Steam, Battle.net)

**What it preserves**:
- ✅ Application settings
- ✅ User data and preferences
- ✅ Saved files and documents
- ✅ Application configurations

**Usage**:
```bash
# Preview what would be cleaned
DRY_RUN=true ./tools/app_cleanup.sh

# Actually clean
./tools/app_cleanup.sh
```

**Expected results**:
- Can free several GB of space from caches alone
- Browser caches are typically the largest (can be 1-5GB+)
- Development tool caches can be 2-10GB+
- Safe to run regularly (weekly/monthly)

### 3. Application Uninstall Helper (`app_uninstall.sh`)

**Purpose**: Identify unused applications and orphaned Application Support data.

**What it shows**:
- All installed applications sorted by size
- Applications not accessed in 90+ days
- Orphaned Application Support folders (data without apps)
- Last access dates for apps

**Usage**:
```bash
./tools/app_uninstall.sh
```

**What to do with the results**:
1. Review unused applications
2. Uninstall apps you no longer need
3. Clean up orphaned Application Support data after uninstalling

## Recommended Workflow

### Initial Analysis
```bash
# 1. See what's taking up space
./tools/app_analysis.sh

# 2. Check for unused apps
./tools/app_uninstall.sh
```

### Regular Maintenance (Weekly/Monthly)
```bash
# Clean app caches and logs (safe, preserves settings)
./tools/app_cleanup.sh
```

### Deep Clean (Quarterly)
```bash
# 1. Analyze current state
./tools/app_analysis.sh

# 2. Clean all caches
./tools/app_cleanup.sh

# 3. Review and uninstall unused apps
./tools/app_uninstall.sh

# 4. After uninstalling, run cleanup again to remove orphaned data
./tools/app_cleanup.sh
```

## Common Scenarios

### Scenario 1: Application Support is 68.8GB

**Problem**: Application Support folder is very large.

**Solution**:
1. Run `app_analysis.sh` to see breakdown
2. Run `app_cleanup.sh` to clean caches and logs
3. Check for specific large apps (browsers, development tools, games)
4. Review if you need all that data

**Expected reduction**: 10-30GB depending on what's there

### Scenario 2: Browser Taking Too Much Space

**Problem**: Chrome/Safari/Arc using several GB.

**Solution**:
```bash
# Clean browser caches
./tools/app_cleanup.sh
```

**Note**: Browser caches are safe to clean. They'll rebuild as you browse.

### Scenario 3: Development Tools Using Space

**Problem**: Xcode, JetBrains, or VS Code using lots of space.

**Solution**:
```bash
# Clean derived data and caches
./tools/app_cleanup.sh
```

**What gets cleaned**:
- Xcode DerivedData (build artifacts)
- Xcode Archives older than 90 days
- JetBrains caches and logs
- VS Code caches

**What's preserved**:
- Your projects
- Settings and preferences
- Installed plugins

### Scenario 4: Unused Applications

**Problem**: Many apps installed but not used.

**Solution**:
1. Run `app_uninstall.sh` to see unused apps
2. Manually uninstall apps you don't need:
   - Drag from /Applications to Trash
   - Or use: `brew uninstall --cask <app>` for Homebrew apps
   - Or use: `mas uninstall <id>` for App Store apps
3. Run `app_cleanup.sh` to clean orphaned support data

## Best Practices

### 1. Use Dry Run First
Always preview what will be cleaned:
```bash
DRY_RUN=true ./tools/app_cleanup.sh
```

### 2. Clean Regularly
- **Weekly**: Run `app_cleanup.sh` for browser and app caches
- **Monthly**: Full analysis with `app_analysis.sh`
- **Quarterly**: Review and uninstall unused apps

### 3. Before Uninstalling
1. Check if app data is important
2. Backup settings if needed
3. Note which Application Support folders belong to the app
4. Uninstall the app
5. Run cleanup to remove orphaned data

### 4. Monitor Large Apps
Keep an eye on:
- Browsers (can grow to 5-10GB+ with heavy use)
- Development tools (Xcode can be 10-20GB+)
- Game platforms (Steam, Battle.net can be 10-50GB+)
- Communication apps (Slack, Discord cache can grow)

### 5. Safe to Clean Regularly
These are always safe to clean:
- Browser caches
- Application logs (older than 30 days)
- Crash reports (older than 30 days)
- Development tool derived data
- Temporary application data

## Understanding Application Support

The `~/Library/Application Support` folder contains:
- **Settings and preferences** (preserved by cleanup)
- **User data** (preserved by cleanup)
- **Caches** (cleaned by app_cleanup.sh)
- **Logs** (cleaned if older than 30 days)
- **Temporary data** (cleaned by app_cleanup.sh)

**Important**: The cleanup tool is designed to only remove caches, logs, and temporary data. Your settings and important data are preserved.

## Troubleshooting

### "Application Support is still large after cleanup"
- Some apps store legitimate data (games, media apps, etc.)
- Check `app_analysis.sh` to see what's left
- Consider if you need all that data
- Some apps allow you to clear data from within the app

### "I'm not sure if I should clean something"
- Use `DRY_RUN=true` to preview
- Check the app's documentation
- Most caches are safe to clean (they rebuild)
- When in doubt, skip that specific item

### "I uninstalled an app but support data remains"
- Run `app_uninstall.sh` to identify orphaned folders
- Manually review and remove if safe
- Some folders may be shared by multiple apps

## Integration with Full Maintenance

The app management tools are integrated into the full maintenance suite:

```bash
./maintenance.sh
# Select option 15: Full Maintenance
```

This runs all safe operations including application cleanup.

## Summary

For your 68.8GB Application Support folder:
1. **Start with analysis**: `./tools/app_analysis.sh`
2. **Clean caches**: `./tools/app_cleanup.sh` (can free 10-30GB)
3. **Review unused apps**: `./tools/app_uninstall.sh`
4. **Repeat monthly** to keep it under control

The tools are designed to be safe and preserve your important data while cleaning up space-consuming caches and temporary files.
