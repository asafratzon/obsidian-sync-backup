#!/bin/bash

# This script sets up a launchd job to run the Obsidian backup script at a specified interval.
# Note: be sure to update config file prior to running this script.

# Usage:
# 1. Run with: ./run.sh --install
# 2. Verify the setup worked by checking the loaded launchd jobs: ./run.sh --status
# To undo the backup automation: ./run.sh --uninstall

# Load configuration
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../config"

# Path to the plist file
PLIST_FILE="$HOME/Library/LaunchAgents/com.${USERNAME}.obsidianbackup.plist"

# Create the plist file
cat <<EOF >"$PLIST_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.${USERNAME}.obsidianbackup</string>

    <key>ServiceDescription</key>
    <string>Periodic backups of Obsidian vaults to remote github repository.</string>

    <key>ProgramArguments</key>
    <array>
      <string>${BACKUP_SCRIPT}</string>
      <string>--cron</string>
    </array>

    <key>StartInterval</key>
    <integer>${AGENT_INTERVAL_SEC}</integer>

    <key>RunAtLoad</key>
    <true/>

    <key>StandardOutPath</key>
    <string>${STDOUT_PATH}</string>
    <key>StandardErrorPath</key>
    <string>${STDERR_PATH}</string>
  </dict>
</plist>
EOF

# Load the plist file into launchd
launchctl load "$PLIST_FILE"

# Display a notification
osascript -e 'display notification "Backup automation installed." with title "Obsidian Backup"'
