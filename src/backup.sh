#!/bin/bash

# Parse arguments to check for '--cron' flag
CRON=false
for arg in "$@"; do
  if [ "$arg" == "--cron" ]; then
    CRON=true
    break
  fi
done

syncthing_check() {
  if [ "$SYNCTHING" = true ]; then
    if ! is_syncthing_running; then
      echo "$LOG Syncthing is not running."
      osascript -e 'display notification "Backups are disabled since Syncthing is not running." with title "Obsidian Backup"'
      exit 0
    fi
  fi
}

check_requirements() {
  command -v git >/dev/null 2>&1 || {
    echo "$LOG git is required but not installed. Aborting."
    exit 1
  }
  command -v osascript >/dev/null 2>&1 || {
    echo "$LOG osascript is required but not installed. Aborting."
    exit 1
  }
  syncthing_check
}

init() {
  # Load configurations
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../config"

  # Load utilities
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"

  # Run initial requirements
  check_requirements

  # Init check variables
  if [ -f "$CHECK_PATH" ]; then
    read -r LAST_BACKUP_DATE LAST_BACKUP_TIME LAST_CHECK_TIME COUNT <"$CHECK_PATH"
  else
    LAST_BACKUP_DATE="N/A"
    LAST_BACKUP_TIME=0
    LAST_CHECK_TIME=0
    COUNT=0
  fi
}

check_online_status() {
  CURRENT_TIME=$(date +%s)

  if check_internet_access; then
    if [ "$REQUIRE_CONNECTIVITY_INTERVAL" = true ]; then
      # Verify if device is online for the at least 1 complete interval
      TIME_DIFF=$((CURRENT_TIME - LAST_CHECK_TIME))

      if [ "$TIME_DIFF" -ge "$AGENT_INTERVAL_SEC" ] && [ "$TIME_DIFF" -lt $((2 * AGENT_INTERVAL_SEC)) ]; then
        echo "$LOG Internet has been accessible for 1 interval cycle."
        return 0 # Online for the required interval
      else
        echo "$LOG Internet access detected, but 1 interval should be reserved for sync. Updating timestamp."
        echo "$LAST_BACKUP_DATE $LAST_BACKUP_TIME $CURRENT_TIME $COUNT" >"$CHECK_PATH"
        return 1 # Not online for the required interval
      fi
    else
      return 0 # Online, no interval requirements configured
    fi
  else
    echo "$LOG No internet access. Backups postponed."

    # Conditions for offline notification:
    # 1. Max offline notifications frequency as configured backup frequency.
    # 2. Obsidian is running.
    # 3. There are changes to commit.
    local should_notify=0
    if [ $((CURRENT_TIME - LAST_BACKUP_TIME)) -ge $MAX_BACKUP_FREQUENCY_SEC ] &&
      is_obsidian_running &&
      [ -n "$(git -C "$REPO_DIR" status --porcelain)" ]; then
      should_notify=1
    fi

    if [ "$should_notify" -eq 1 ]; then
      osascript -e 'display notification "You are offline! Obsidian may be out of sync." with title "Obsidian Backup"'
    fi

    return 1 # No internet access
  fi
}

perform_backup() {
  # Check if we have any changes to commit
  if [ -z "$(git -C "$REPO_DIR" status --porcelain)" ]; then
    echo "$LOG Backup is already up to date (no changes to commit)."
    return 2
  fi

  # Add all changes
  if ! git -C "$REPO_DIR" add .; then
    echo "$LOG Failed to add changes."
    return 1
  fi

  # Commit changes with a default message
  commit_message="Backup: $(date)"
  if ! git -C "$REPO_DIR" commit -m "$commit_message"; then
    echo "$LOG Failed to commit changes."
    return 1
  fi

  # Pull the latest changes from the remote repository and rebase
  if ! git -C "$REPO_DIR" pull --rebase; then
    echo "$LOG Failed to pull and rebase changes."
    return 1
  fi

  # Push the changes
  if ! git -C "$REPO_DIR" push origin main; then
    echo "$LOG Failed to push changes."
    return 1
  fi

  return 0
}

cron_checks() {
  # Checking online status
  if ! check_online_status; then
    echo "$LOG Conditions not met for running the backup. Exiting."
    exit 0
  fi

  # Get the current date and time
  CURRENT_DATE=$(date +%Y-%m-%d)
  CURRENT_TIME=$(date +%s)

  # Check if at least MAX_BACKUP_FREQUENCY_SEC seconds have passed since the last backup
  TIME_DIFF=$((CURRENT_TIME - LAST_BACKUP_TIME))
  if [ "$TIME_DIFF" -lt "$MAX_BACKUP_FREQUENCY_SEC" ]; then
    echo "$LOG Backup not needed yet. Last backup was taken $((TIME_DIFF / 60)) minutes ago."
    exit 0
  fi

  # Check if the script has already run the maximum number of times today
  if [ "$CURRENT_DATE" == "$LAST_BACKUP_DATE" ]; then
    if [ "$COUNT" -ge "$MAX_DAILY_BACKUPS" ]; then
      # Maximum daily backups reached
      echo "$LOG Maximum daily backups reached (Run without '--cron' to backup anyway)"
      exit 0
    fi
  else
    COUNT=1
  fi
}

# Main script execution
main() {
  init

  # Checking online status
  if ! check_internet_access; then
    echo "$LOG No internet connection. Exiting."
    exit 0
  fi

  # Run the cron checks if '--cron' was passed
  if [ "$CRON" == true ]; then
    cron_checks
  fi

  # Attempt backup and capture exit code (0 = succesful backup, 1 = unexpected error, 2 = nothing to backup)
  perform_backup
  backup_result=$?

  if [ "$backup_result" -eq 1 ]; then
    echo "$LOG Backup failed."
    osascript -e 'display notification "Remote backup failed - check the logs for more info." with title "Obsidian Backup"'
    exit 1
  elif [ "$backup_result" -eq 2 ]; then
    echo "$LOG Nothing to backup. Exiting."

    if [ "$CRON" == true ]; then
      # Update the LAST_CHECK_TIME in check file (only if '--cron' was passed)
      CURRENT_TIME=$(date +%s)
      echo "$LAST_BACKUP_DATE $LAST_BACKUP_TIME $CURRENT_TIME $COUNT" >"$CHECK_PATH"
    fi

    exit 0
  fi

  # Backup completed - update the check file (only if '--cron' was passed)
  if [ "$CRON" == true ]; then
    CURRENT_TIME=$(date +%s)
    COUNT=$((COUNT + 1))
    echo "$CURRENT_DATE $CURRENT_TIME $CURRENT_TIME $COUNT" >"$CHECK_PATH"
  fi

  echo "$LOG Remote backup is up to date."
  osascript -e 'display notification "Remote backup is up to date." with title "Obsidian Backup"'
}

main "$@"
