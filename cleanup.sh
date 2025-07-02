#!/bin/bash

# Cleanup script for failed deployments
# Run this if deployment fails and you want to start fresh

echo "🧹 Cleaning up failed deployment..."

# Stop Gitea service
echo "Stopping Gitea service..."
systemctl stop gitea 2>/dev/null || true
systemctl disable gitea 2>/dev/null || true

# Remove Gitea files
echo "Removing Gitea installation..."
rm -f /usr/local/bin/gitea
rm -f /etc/systemd/system/gitea.service
rm -rf /var/lib/gitea
rm -rf /etc/gitea
rm -rf /home/git/gitea-repositories

# Stop code-server services
echo "Stopping code-server services..."
systemctl stop code-server@* 2>/dev/null || true
systemctl disable code-server@* 2>/dev/null || true

# Remove users (be careful!)
read -p "Remove created users? This will delete all their data! (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Find users with naruto-themed usernames
    for user in $(grep -E "(naruto|sasuke|sakura|kakashi|jiraiya|tsunade|orochimaru|itachi|madara|obito|shikamaru|choji|ino|neji|rocklee|gaara|temari|kankuro|hinata|minato|deidara|kisame|pain)" /etc/passwd | cut -d: -f1); do
        echo "Removing user: $user"
        userdel -r "$user" 2>/dev/null || true
    done
    
    # Remove service user
    userdel interview_service_user 2>/dev/null || true
    
    # Remove git user
    userdel -r git 2>/dev/null || true
fi

# Remove systemd service
rm -f /etc/systemd/system/code-server@.service
systemctl daemon-reload

# Clean up logs
rm -f /root/deployment.log
rm -f /root/deployment-info.txt

echo "🎉 Cleanup completed!"
echo "You can now run deploy_new.sh again."
