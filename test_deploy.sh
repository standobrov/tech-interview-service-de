#!/bin/bash

# Quick test script for local development
# This script simulates the deployment process for testing

set -e

echo "🧪 Starting local test deployment..."

# Check if we're running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root (use sudo)"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install docker-compose first."
    exit 1
fi

# Run the deployment script
echo "🚀 Running deployment script..."
./deploy_new.sh

echo "✅ Test deployment completed!"
echo ""
echo "📋 Quick verification commands:"
echo "curl http://localhost:3000  # Check Gitea"
echo "curl http://localhost:8080  # Check Code-Server"
echo "systemctl status code-server@* # Check Code-Server service"
echo "docker ps  # Check running containers"
echo ""
echo "📄 Check deployment info:"
echo "cat /root/deployment-info.txt"
