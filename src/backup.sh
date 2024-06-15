#!/bin/bash

# Parse arguments to check for '--cron' flag
CRON=false
for arg in "$@"; do
  if [ "$arg" == "--cron" ]; then
    CRON=true
    break
  fi
done

# Load configuration
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../config"

# Load utils
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/utils.sh"

# Initial Syncthing check
if [ "$SYNCTHING" = true ]; then
  if ! is_syncthing_running; then
    echo "Syncthing is not running."
    osascript -e 'display notification "Backups are disabled since Syncthing is not running." with title "Obsidian Backup"'
    exit 0
  fi
fi

# Function to check the online status and decide if the backup should proceed
check_online_status() {
  if check_internet_access; then
    current_time=$(get_current_time)

    if [ -f "$TIMESTAMP_PATH" ]; then
      last_check_time=$(cat "$TIMESTAMP_PATH")
      time_diff=$((current_time - last_check_time))

      if [ "$time_diff" -ge "$INTERVAL" ] && [ "$time_diff" -lt $((2 * INTERVAL)) ]; then
        echo "Internet has been accessible for 1 interval cycle."
        return 0 # Online for the required interval
      else
        echo "Internet access detected, but 1 interval should be reserved for sync. Updating timestamp and exiting."
        echo "$current_time" >"$TIMESTAMP_PATH"
        return 1 # Not online for the required interval
      fi
    else
      echo "First internet access detected. Storing timestamp and exiting."
      echo "$current_time" >"$TIMESTAMP_PATH"
      return 1 # Exiting as this is the first check
    fi
  else
    echo "No internet access. Backups postponed."
    return 1 # No internet access
  fi
}

# Run the following checks only if '--cron' was passed
if [ "$CRON" == true ]; then

  # Checking online status
  if [ "$REQUIRE_TWO_ONLINE_INTERVALS" = true ]; then
    if ! check_online_status; then
      echo "Conditions not met for running the backup. Exiting."
      exit 0
    fi
  fi

  # Get the current date
  CURRENT_DATE=$(date +%Y-%m-%d)

  # Read the check file to get the last run date and count
  if [ -f "$CHECK_PATH" ]; then
    read -r LAST_RUN_DATE COUNT <"$CHECK_PATH"
  else
    LAST_RUN_DATE=""
    COUNT=0
  fi

  # Check if the script has already run the maximum number of times today
  if [ "$CURRENT_DATE" == "$LAST_RUN_DATE" ]; then
    if [ "$COUNT" -ge "$MAX_DAILY_BACKUPS" ]; then
      # Maximum daily backups reached
      echo "Maximum daily backups reached (Run without '--cron' to backup anyway)"
      exit 0
    else
      COUNT=$((COUNT + 1))
    fi
  else
    COUNT=1
  fi
fi

# Check if we have any changes to commit
if [ -z "$(git -C "$REPO_DIR" status --porcelain)" ]; then
  echo "Backup is already up to date (no changes to commit)."
  exit 0
fi

# Add all changes
git -C "$REPO_DIR" add .

# Commit changes with a default message
commit_message="Backup: $(date)"
git -C "$REPO_DIR" commit -m "$commit_message"

# Pull the latest changes from the remote repository and rebase
git -C "$REPO_DIR" pull --rebase

# Push the changes
git -C "$REPO_DIR" push origin main

# Update the check file with the current date and count (only if '--cron' was passed)
if [ "$CRON" == true ]; then
  echo "$CURRENT_DATE $COUNT" >"$CHECK_PATH"
fi

# Display a notification
osascript -e 'display notification "Backup is up to date." with title "Osidian Backup"'
