#!/bin/bash

# Load configuration
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/config"

case "$1" in
--backup)
  "$BACKUP_SCRIPT"
  ;;
--install)
  "$AUTOMATE_SCRIPT"
  ;;
--uninstall)
  "$UNAUTOMATE_SCRIPT"
  ;;
--status)
  STATUS=$(launchctl list | grep "com.${USERNAME}.obsidianbackup")
  if [ -n "$STATUS" ]; then
    echo "Obsidian backup service is running."
    echo "Details:"
    echo "$STATUS"
  else
    echo "Obsidian backup service is not running."
  fi
  ;;
*)
  echo "Usage: $0 {--backup|--install|--uninstall|--status}"
  exit 1
  ;;
esac
