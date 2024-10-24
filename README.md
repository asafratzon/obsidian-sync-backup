# Obsidian Sync Backup

Automated backup solution for Obsidian vaults, designed for users utilizing free Sync options.

This solution uses a Launch Agent to automate the backups of your Obsidian vaults. A Launch Agent is a type of launch daemon in macOS that automatically launches and manages processes.

## Introduction

For the optimal sync and backup solution, consider opting for Obsidian's official Sync feature as it supports ongoing development. Visit Obsidian's [official website](https://obsidian.md) to learn why it's awesome.

This repository provides an automated backup solution tailored for Obsidian users, especially those utilizing free synchronization methods like Syncthing. It ensures periodic backups to safeguard against data loss, complementing a setup that includes Obsidian for note-taking and Syncthing for cross-device synchronization.

### Prerequisites / Limitations / Notes

- GitHub backups are designed to function independently and do not require any additional plugins from the Obsidian plugins community.
- This repository is intended for use on macOS (Apple) personal computers or laptops. It is not compatible with Windows and should not be used on mobile devices.
- It is recommended to set up this backup solution on only one machine to minimize the risk of conflicting backups. If you use multiple personal computers or laptops, consider setting it up on the one you use most frequently. Remember, this repository is focused solely on daily backups; syncing should be managed separately.

## Recommended Setup from Scratch

My recommended setup for a fully synced and backed-up open-source notes solution involves:

1. **Syncthing**: For syncing notes across devices securely and freely, see [official website](https://syncthing.net).
2. **Obsidian**: For its powerful note-taking capabilities, see [official website](https://obsidian.md).
3. **This repository**: For automated backups, ensuring your notes are always safe and recoverable.
4. Consider [Importer Community Plugin](obsidian://show-plugin?id=obsidian-importer) for importing existing notes.

If you've already got an existing/different setup in place, may the force be with you.

### Objective Overview

Assuming you have multiple devices including mobile device/s and laptop/s and/or PC/s, our goal is to sync Obsidian notes across all devices. One device, referred to as the "main laptop", will be responsible for periodic backups of your notes.

1. **Setup Syncthing on Your Main Laptop**

   - Install and configure Syncthing. By default, this will create a Sync directory in your home directory:
     ```
     /Users/yourusername/Sync
     ```

2. **Setup Syncthing on Other Devices**

   - Install Syncthing on all other devices and ensure they sync to the same Sync directory.
   - Verify synchronization by adding a simple text file and confirming it syncs across devices within 5-10 seconds.

3. **Setup Obsidian on Your Main Laptop**

   - Install Obsidian only on your main laptop.
   - Configure Obsidian to set the vaults root directory inside the Sync directory. Example path:
     ```
     /Users/username/Sync/Obsidian
     ```
   - Create your first vault within this directory. For example, create a vault named "vault":
     ```
     /Users/username/Sync/Obsidian/vault
     ```

4. **Setup Obsidian on Other Devices**

   - With Syncthing set up, you should now see the Obsidian directory synced across your devices.
   - Install Obsidian on the rest of your devices and open the vault(s) you set up in the previous step.

5. **Periodic Backup Setup**
   - Now that you are all set up with synced Obsidian across devices - it's time to set up your automated backup solution.

## Periodic Backup Setup

1. **Fork this Repository**

   - Go to the [GitHub repository page](https://github.com/asafratzon/obsidian-sync-backup).
   - Click on the "Fork" button in the upper right corner to create a copy of this repository under your own GitHub account.

2. **Clone Your Forked Repository**

   ```bash
   # Navigate to your Obsidian vaults root directory on your main laptop
   cd /Users/yourusername/Sync/Obsidian

   # Clone your forked repository into your Obsidian directory
   git clone https://github.com/yourgithubusername/obsidian-sync-backup.git .
   ```

3. **Review and Update Config File**

   ```bash
   # Open the config file located in the cloned repository
   vi /Users/yourusername/Sync/Obsidian/config

   # Update your username, optionally modify backup settings as needed and save the file
   ```

4. **Install Automation**

   ```bash
   # Navigate to the repository root
   cd /Users/yourusername/Sync/Obsidian/

   # Run the automation installation script
   ./run.sh --install

   # Verify the backup service is running
   ./run.sh --status
   ```

By following these steps, you should have a complete setup for syncing Obsidian across all your devices and setting up periodic backups on your main laptop.

### Manual Backups

You may trigger manual backups:

```bash
# Navigate to the repository root
cd /Users/yourusername/Sync/Obsidian/

# Run the backup script
./run.sh --backup
```

### Troubleshooting

You should see a notification stating Obsidian backup automation was installed / uninstalled, and a "Backup is up to date" notification when a backup is taken. If you don't see these notifications, ensure that you are not in "Focus" or "Do Not Disturb" mode, as these modes can prevent notifications from appearing.

### Uninstall Backup Automation

If you want to cancel the automatic backups run the following.
Don't worry—it won't delete any of your notes or previous backups; it simply stops the automation of new backups.

```bash
# Navigate to the repository root
cd /Users/yourusername/Sync/Obsidian

# Run the uninstallation script
./run.sh --uninstall
```

### Solved: "fatal: the remote end hung up unexpectedly"
If you encounter this issue, update your local git repository settings with:

```bash
# Run the following from within repository root directory
git config http.postBuffer 10g
```

### Free and Open Source

This repository is freely available for anyone to use, fork or modify under the GNU General Public License v3. I wish everyone much love and all the best on their journey with Obsidian and beyond.
