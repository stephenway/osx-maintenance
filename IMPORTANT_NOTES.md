# Important Notes & Limitations

## What This Toolbox Does (and Doesn't Do)

### ✅ What It Does

- **Frees disk space** by cleaning caches, logs, and temporary files
- **Identifies storage usage** so you know what's taking up space
- **Helps maintain organization** by finding orphaned files
- **Monitors system health** with basic diagnostics
- **Keeps your system clean** through regular maintenance

### ❌ What It Does NOT Do

- **Make your Mac faster** - This is maintenance, not optimization
- **Fix hardware issues** - That requires hardware repair
- **Solve performance problems** - If your Mac is slow, this won't fix it
- **Replace professional IT support** - For complex issues, see a professional
- **Work miracles** - It's a toolbox, not magic

## Important Warnings

### Cache Cleaning

**Close applications before cleaning their caches!**

Some applications (especially browsers and Electron apps) can:
- Lose data if their cache is cleaned while running
- Crash or behave unexpectedly
- Require restart to function properly

The scripts will warn you about running applications, but **it's best practice to close apps first**.

**Particularly sensitive**:
- Safari (cache in Application Support)
- Chrome/Chromium browsers
- Electron apps (VS Code, Slack, Discord, etc.)
- Any app you're currently using

### Permission Repair

**macOS no longer supports traditional permission repair.**

The "Filesystem & Volume Repair" tool:
- ✅ Verifies filesystem integrity
- ✅ Repairs disk volumes
- ✅ Fixes basic user file permissions
- ❌ Does NOT repair SIP-protected system files (macOS handles this)

If you're expecting the old "repair permissions" functionality from macOS 10.10 and earlier, that's gone. Apple removed it because System Integrity Protection (SIP) now handles system file permissions automatically.

### Bash Version

**macOS ships with Bash 3.2**, not Bash 4+.

All scripts are tested and work with macOS's default Bash 3.2. You don't need to install a newer version of bash, though it works fine if you have Homebrew bash installed.

The README previously mentioned Bash 4+, but that was incorrect. Scripts are compatible with Bash 3.2+.

### Scheduling Maintenance

When using `launchd` for scheduling:

1. **Always include logging paths** (`StandardOutPath` and `StandardErrorPath`)
   - Without these, failures happen silently
   - You'll have no way to debug issues

2. **Set `RunAtLoad` appropriately**
   - `false` = Only run on schedule
   - `true` = Run immediately when loaded, then on schedule

3. **Check log files regularly**
   - Scheduled tasks can fail silently
   - Review logs to ensure they're working

See the README for complete launchd examples with proper logging.

## Best Practices

1. **Always use DRY_RUN first** when trying new operations
2. **Close applications** before cleaning their caches
3. **Review what will be deleted** before confirming
4. **Keep backups** of important data
5. **Read warnings** - they're there for a reason
6. **Check logs** if something seems wrong

## Realistic Expectations

This toolbox helps you:
- Maintain a clean system
- Free up disk space
- Identify what's using storage
- Monitor basic system health

It does **not**:
- Speed up your computer
- Fix broken software
- Solve hardware problems
- Replace system administration knowledge

Use it as a maintenance tool, not a performance solution.

## When to Seek Professional Help

If you're experiencing:
- Hardware failures
- Persistent crashes
- Data loss
- System corruption
- Complex permission issues

...this toolbox won't help. See a professional or Apple Support.

## Legal Disclaimer

This toolbox is provided as-is. Use at your own risk. The authors are not responsible for:
- Data loss
- System issues
- Application problems
- Any consequences of using these tools

Always backup important data before running maintenance operations.
