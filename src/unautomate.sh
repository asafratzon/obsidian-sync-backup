#!/bin/bash

# This script stops and uninstalls the launchd job for the Obsidian backup script.

# Load configuration
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../config"

# Path to the plist file
PLIST_FILE="$HOME/Library/LaunchAgents/com.${USERNAME}.obsidianbackup.plist"

# Unload the plist file from launchd
launchctl unload "$PLIST_FILE"

# Remove the plist file
rm -f "$PLIST_FILE"

# Remove log files
rm -f "$STDOUT_PATH" "$STDERR_PATH" "$CHECK_PATH" "$TIMESTAMP_PATH"

# Display a notification
osascript -e 'display notification "Backup automation uninstalled." with title "Obsidian Backup"'
