#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PLIST_NAME="com.user.ics-watcher.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_DEST="$LAUNCH_AGENTS_DIR/$PLIST_NAME"

echo -e "${GREEN}ICS Watcher Setup${NC}"
echo "================================"

if ! xcode-select -p &>/dev/null; then
    echo -e "${RED}Error: Xcode Command Line Tools not installed${NC}"
    echo "Install with: xcode-select --install"
    exit 1
fi
echo -e "${GREEN}✓${NC} Xcode Command Line Tools found"

echo -e "${YELLOW}Building release binary...${NC}"
cd "$PROJECT_DIR"
swift build -c release

BINARY_PATH="$PROJECT_DIR/.build/release/ics-watcher"
if [[ ! -f "$BINARY_PATH" ]]; then
    echo -e "${RED}Error: Binary not found at $BINARY_PATH${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Binary built: $BINARY_PATH"

mkdir -p "$LAUNCH_AGENTS_DIR"

PLIST_TEMPLATE="$PROJECT_DIR/$PLIST_NAME"
sed -e "s|__BINARY_PATH__|$BINARY_PATH|g" \
    -e "s|__HOME__|$HOME|g" \
    -e "s|__PROJECT_DIR__|$PROJECT_DIR|g" \
    "$PLIST_TEMPLATE" > "$PLIST_DEST"
echo -e "${GREEN}✓${NC} LaunchAgent installed: $PLIST_DEST"

launchctl unload "$PLIST_DEST" 2>/dev/null || true
launchctl load "$PLIST_DEST"
echo -e "${GREEN}✓${NC} LaunchAgent loaded"

sleep 1
if launchctl list | grep -q "com.user.ics-watcher"; then
    echo -e "${GREEN}✓${NC} Service is running"
else
    echo -e "${YELLOW}Warning: Service may not be running. Check logs.${NC}"
fi

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "Useful commands:"
echo "  View logs:      tail -f ~/Library/Logs/ics-watcher.log"
echo "  View errors:    tail -f ~/Library/Logs/ics-watcher.error.log"
echo "  Check status:   launchctl list | grep ics-watcher"
echo "  Stop service:   launchctl stop com.user.ics-watcher"
echo "  Start service:  launchctl start com.user.ics-watcher"
echo "  Uninstall:      ./scripts/uninstall.sh"
