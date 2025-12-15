# Orphaned Files Cleanup Guide (AppZapper-style)

## Overview

When you uninstall applications on macOS, they often leave behind files and folders in various Library directories. These "orphaned" files can accumulate over time and consume significant disk space. This tool works like the classic AppZapper utility to find and remove these leftover files.

## What Are Orphaned Files?

Orphaned files are application-related files and folders that remain after an application has been uninstalled. They can be found in:

- **Application Support** (`~/Library/Application Support/`) - App data and settings
- **Preferences** (`~/Library/Preferences/`) - Preference files (.plist)
- **Caches** (`~/Library/Caches/`) - Cache files
- **Containers** (`~/Library/Containers/`) - Sandboxed app data
- **Saved Application State** (`~/Library/Saved Application State/`) - App state data
- **Application Scripts** (`~/Library/Application Scripts/`) - AppleScript files
- **Logs** (`~/Library/Logs/`) - Application logs
- **Launch Agents** (`~/Library/LaunchAgents/`) - Background launch items

## Tools

### 1. Find Orphaned Files (`find_orphaned_files.sh`)

**Purpose**: Scans your Library directories to find files and folders that don't belong to currently installed applications.

**What it does**:
- Scans all installed applications in `/Applications`
- Compares Library folders against installed apps
- Identifies orphaned items by name and bundle ID matching
- Shows sizes and locations
- Groups results by Library directory
- Lists largest items first

**Usage**:
```bash
./tools/find_orphaned_files.sh
```

**Output includes**:
- Total number of orphaned items found
- Total size (MB/GB)
- Items grouped by Library location
- Largest items highlighted
- File vs directory type

**Example output**:
```
Found 45 potentially orphaned items (~2.3GB total)

--- Application Support ---
  OldAppName                   125MB  [directory]
  com.oldcompany.oldapp         89MB  [directory]

--- Preferences ---
  com.oldcompany.oldapp.plist  <1MB  [file]

--- Caches ---
  com.oldcompany.oldapp        234MB  [directory]
```

### 2. Cleanup Orphaned Files (`cleanup_orphaned_files.sh`)

**Purpose**: Interactive tool to safely remove orphaned files with confirmation.

**What it does**:
- Provides interactive menu for cleanup
- Groups cleanup by Library location
- Shows items before removal
- Requires confirmation for safety

**Usage**:
```bash
# Interactive mode
./tools/cleanup_orphaned_files.sh

# Preview mode
DRY_RUN=true ./tools/cleanup_orphaned_files.sh
```

**Cleanup options**:
1. Clean Application Support (safest - mostly caches)
2. Clean Preferences (review carefully)
3. Clean Caches (safe)
4. Clean Containers (sandboxed app data - review carefully)
5. Clean Saved Application State (safe)
6. Clean Logs (safe)
7. Clean Launch Agents (review carefully)
8. Interactive item-by-item cleanup
9. Show all orphaned items again

## Recommended Workflow

### Step 1: Find Orphaned Files
```bash
./tools/find_orphaned_files.sh
```

Review the output to see:
- How many orphaned items exist
- Total size they're consuming
- Which locations have the most orphaned files
- Largest individual items

### Step 2: Review Items
Look through the list and identify:
- Apps you remember uninstalling
- Items you're certain are safe to remove
- Items you're unsure about (research first)

### Step 3: Cleanup Safely
```bash
# Start with safest locations
./tools/cleanup_orphaned_files.sh
# Select option 3: Clean Caches (safe)
# Select option 6: Clean Logs (safe)
# Select option 5: Clean Saved Application State (safe)
```

### Step 4: Review and Clean Other Locations
For Application Support, Preferences, and Containers:
- Review each item carefully
- Use option 8 (Interactive) to go through items one by one
- When in doubt, skip it

## Safety Guidelines

### ✅ Safe to Remove (Usually)

- **Caches**: Application caches are safe to remove (they rebuild)
- **Logs**: Old application logs are safe to remove
- **Saved Application State**: Safe to remove (apps recreate as needed)
- **Old crash reports**: Safe to remove

### ⚠️ Review Before Removing

- **Application Support**: May contain user data or settings
  - Check if you have the app installed
  - Look for important data before removing
  - Caches within Application Support are usually safe

- **Preferences**: Preference files (.plist)
  - Usually safe if app is uninstalled
  - But check if you might reinstall the app (you'd lose settings)

- **Containers**: Sandboxed app data
  - May contain user documents or data
  - Review contents before removing

- **Launch Agents**: Background launch items
  - Usually safe if app is uninstalled
  - But verify the app is really gone

### ❌ Be Careful With

- Items you're not 100% sure about
- Items that might belong to system components
- Items with recent modification dates (might be in use)
- Items from apps you might reinstall

## How It Works

The tool uses several methods to identify orphaned files:

1. **Name Matching**: Compares folder/file names against installed app names
2. **Bundle ID Matching**: Matches bundle identifiers (com.company.app)
3. **Normalization**: Handles variations in naming (spaces, capitalization, etc.)
4. **Size Filtering**: Only reports items larger than 1MB (configurable)
5. **Pattern Recognition**: Identifies app-like patterns (bundle IDs, app names)

## Common Scenarios

### Scenario 1: Just Uninstalled an App

**Problem**: You just uninstalled an app and want to clean up leftovers.

**Solution**:
1. Run `find_orphaned_files.sh` to see what was left behind
2. Look for the app name in the results
3. Use `cleanup_orphaned_files.sh` to remove those specific items
4. Or manually remove if you can identify them clearly

### Scenario 2: Accumulated Orphaned Files

**Problem**: Years of installing/uninstalling apps has left many orphaned files.

**Solution**:
1. Run `find_orphaned_files.sh` to see the full scope
2. Start with safe locations (Caches, Logs, Saved Application State)
3. Review Application Support items - many are just caches
4. Be more careful with Preferences and Containers
5. Clean in stages, checking disk space after each

### Scenario 3: Large Orphaned Items

**Problem**: Found a 5GB orphaned folder in Application Support.

**Solution**:
1. Check what the folder contains:
   ```bash
   ls -lah ~/Library/Application\ Support/OldAppName
   du -sh ~/Library/Application\ Support/OldAppName/*
   ```
2. If it's mostly caches or temporary data, safe to remove
3. If it contains user documents, review first
4. When confident, remove it:
   ```bash
   rm -rf ~/Library/Application\ Support/OldAppName
   ```

## Integration with Other Tools

The orphaned files tools work well with:

- **Application Analysis** (`app_analysis.sh`): See what's using space
- **Application Cleanup** (`app_cleanup.sh`): Clean caches from installed apps
- **Application Uninstall Helper** (`app_uninstall.sh`): Find unused apps to uninstall

**Recommended sequence**:
1. Run `app_analysis.sh` to see current app usage
2. Run `app_uninstall.sh` to find unused apps
3. Uninstall unused apps manually
4. Run `find_orphaned_files.sh` to find leftovers
5. Run `cleanup_orphaned_files.sh` to clean them up
6. Run `app_cleanup.sh` to clean caches from remaining apps

## Tips

1. **Use Dry Run First**: Always preview what will be removed
   ```bash
   DRY_RUN=true ./tools/find_orphaned_files.sh
   ```

2. **Clean Regularly**: Run monthly to prevent accumulation
   ```bash
   # Add to cron or launchd
   0 2 1 * * /path/to/find_orphaned_files.sh
   ```

3. **Backup Before Major Cleanup**: If removing many items, consider a backup first

4. **Research Unknown Items**: If you see an item you don't recognize:
   - Search online for the bundle ID or name
   - Check if it might be a system component
   - When in doubt, leave it

5. **Check Modification Dates**: Items with recent dates might still be in use
   ```bash
   ls -lah ~/Library/Application\ Support/ItemName
   ```

## Troubleshooting

### "Tool says item is orphaned but I think the app is installed"
- Check `/Applications` for the app
- The app might be installed in a non-standard location
- Some apps use different names in Library vs Applications
- When in doubt, don't remove it

### "I removed something and now an app doesn't work"
- Some apps share Library folders
- You might have removed data for an installed app
- Check if you can reinstall or reset the app
- Consider restoring from Time Machine if available

### "Tool isn't finding obvious orphaned files"
- The tool uses heuristics - it's not perfect
- Some items might match installed apps by coincidence
- You can manually identify and remove items
- Check file modification dates - very old items are more likely orphaned

## Comparison to AppZapper

Like the classic AppZapper utility, these tools:
- ✅ Find leftover files from uninstalled apps
- ✅ Show what will be removed
- ✅ Group by Library location
- ✅ Show sizes
- ✅ Provide safe cleanup options

Additional features:
- ✅ Works with command line (scriptable)
- ✅ Can be scheduled
- ✅ Dry run mode
- ✅ More comprehensive scanning
- ✅ Free and open

## Summary

For managing that 68.8GB Application Support folder and other Library locations:

1. **Find**: `./tools/find_orphaned_files.sh` - See what's orphaned
2. **Review**: Check the list carefully
3. **Clean**: `./tools/cleanup_orphaned_files.sh` - Remove safely
4. **Repeat**: Monthly maintenance to keep it clean

The tools are designed to be safe, but always review before removing, especially for Application Support and Preferences folders.
