#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PLIST_NAME="com.user.ics-watcher.plist"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME"
LOG_FILE="$HOME/Library/Logs/ics-watcher.log"
ERROR_LOG="$HOME/Library/Logs/ics-watcher.error.log"

echo -e "${YELLOW}ICS Watcher Uninstall${NC}"
echo "================================"

if launchctl list | grep -q "com.user.ics-watcher"; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Service stopped"
else
    echo -e "${YELLOW}Service was not running${NC}"
fi

if [[ -f "$PLIST_PATH" ]]; then
    rm "$PLIST_PATH"
    echo -e "${GREEN}✓${NC} LaunchAgent removed"
else
    echo -e "${YELLOW}LaunchAgent plist not found${NC}"
fi

if [[ "$1" == "--remove-logs" ]]; then
    [[ -f "$LOG_FILE" ]] && rm "$LOG_FILE" && echo -e "${GREEN}✓${NC} Log file removed"
    [[ -f "$ERROR_LOG" ]] && rm "$ERROR_LOG" && echo -e "${GREEN}✓${NC} Error log removed"
else
    echo -e "${YELLOW}Logs preserved. Use --remove-logs to delete them.${NC}"
fi

echo ""
echo -e "${GREEN}Uninstall complete!${NC}"
echo "Source code remains at: $(dirname "$(dirname "$0")")"
