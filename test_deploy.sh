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

# Check basic requirements
if ! command -v curl &> /dev/null; then
    echo "❌ curl is not installed. Please install curl first."
    exit 1
fi

if ! command -v wget &> /dev/null; then
    echo "❌ wget is not installed. Please install wget first."
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
echo "systemctl status gitea # Check Gitea service"
echo "systemctl status code-server@* # Check Code-Server service"
echo ""
echo "📄 Check deployment info:"
echo "cat /root/deployment-info.txt"
