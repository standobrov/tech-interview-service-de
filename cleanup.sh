#!/bin/bash

# Cleanup script for failed deployments
# Run this if deployment fails and you want to start fresh

echo "🧹 Cleaning up failed deployment..."

# Stop and remove containers
echo "Stopping containers..."
docker stop gitea 2>/dev/null || true
docker rm gitea 2>/dev/null || true
docker stop gitea_db_1 2>/dev/null || true
docker rm gitea_db_1 2>/dev/null || true

# Remove Docker compose
if [ -d "/opt/gitea" ]; then
    echo "Removing Gitea setup..."
    cd /opt/gitea
    docker-compose down 2>/dev/null || true
    cd /
    rm -rf /opt/gitea
fi

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
fi

# Remove systemd service
rm -f /etc/systemd/system/code-server@.service
systemctl daemon-reload

# Clean up logs
rm -f /root/deployment.log
rm -f /root/deployment-info.txt

# Remove Docker images (optional)
read -p "Remove Docker images to save space? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker rmi gitea/gitea:1.21.4 2>/dev/null || true
    docker rmi postgres:14 2>/dev/null || true
    docker rmi hello-world 2>/dev/null || true
    docker system prune -f 2>/dev/null || true
fi

echo "🎉 Cleanup completed!"
echo "You can now run deploy_new.sh again."
