# ICS Watcher

A native macOS tool that monitors your Downloads folder for ICS calendar files and prompts to add them to Calendar.app.

## Features

- Watches ~/Downloads for .ics files
- Shows native macOS dialog with event details (title, date, location)
- Opens Calendar.app for import on "Add to Calendar"
- Moves files to Trash after processing
- Auto-starts on login
- Crash recovery via KeepAlive

## Requirements

- macOS 12 (Monterey) or later
- Xcode Command Line Tools

## Installation

```bash
./scripts/setup.sh
```

This will:
1. Build the release binary
2. Install the LaunchAgent
3. Start the service

## Usage

Just download ICS files to your Downloads folder. The watcher will:
1. Detect the new file
2. Parse event details
3. Show a confirmation dialog
4. Open Calendar.app if you click "Add to Calendar"
5. Move the file to Trash

## Monitoring Commands

```bash
# View real-time logs
tail -f ~/Library/Logs/ics-watcher.log

# View error logs
tail -f ~/Library/Logs/ics-watcher.error.log

# Check if running
launchctl list | grep ics-watcher

# Manual stop
launchctl stop com.user.ics-watcher

# Manual start
launchctl start com.user.ics-watcher

# Restart service
launchctl unload ~/Library/LaunchAgents/com.user.ics-watcher.plist
launchctl load ~/Library/LaunchAgents/com.user.ics-watcher.plist
```

## Uninstallation

```bash
./scripts/uninstall.sh

# To also remove logs:
./scripts/uninstall.sh --remove-logs
```

## Troubleshooting

**Dialog doesn't appear:**
- Check if service is running: `launchctl list | grep ics-watcher`
- Check error log: `cat ~/Library/Logs/ics-watcher.error.log`

**Service won't start:**
- Ensure binary exists: `ls .build/release/ics-watcher`
- Re-run setup: `./scripts/setup.sh`

**File not detected:**
- Ensure file has .ics extension
- Check logs for errors: `tail ~/Library/Logs/ics-watcher.log`
