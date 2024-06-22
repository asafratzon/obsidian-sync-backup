# Function to check if the laptop has internet access
check_internet_access() {
  if ping -c 1 8.8.8.8 &>/dev/null; then
    return 0 # Internet is accessible
  else
    return 1 # Internet is not accessible
  fi
}

# Function to check if Syncthing is running
is_syncthing_running() {
  if pgrep -x "syncthing" >/dev/null; then
    return 0 # Syncthing is running
  else
    return 1 # Syncthing is not running
  fi
}

# Function to check if the Obsidian app is running
is_obsidian_running() {
  if pgrep -x "Obsidian" >/dev/null; then
    return 0 # Obsidian is running
  else
    return 1 # Obsidian is not running
  fi
}
