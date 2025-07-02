#!/bin/bash

# Simple verification script
echo "🔍 Checking Tech Interview Service status..."

echo ""
echo "📊 System Services:"
echo "==================="

# Check Gitea service
if systemctl is-active --quiet gitea; then
    echo "✅ Gitea service: Running"
else
    echo "❌ Gitea service: Not running"
fi

# Check if any code-server services are running
CODE_SERVER_COUNT=$(systemctl list-units --type=service --state=active | grep -c "code-server@" || echo "0")
if [ "$CODE_SERVER_COUNT" -gt 0 ]; then
    echo "✅ Code-Server service: $CODE_SERVER_COUNT instance(s) running"
else
    echo "❌ Code-Server service: Not running"
fi

echo ""
echo "🌐 Web Services:"
echo "================"

# Check Gitea web interface
if curl -s http://localhost:3000 > /dev/null; then
    echo "✅ Gitea web interface: Accessible on http://localhost:3000"
else
    echo "❌ Gitea web interface: Not accessible"
fi

# Check Code-Server web interface
if curl -s http://localhost:8080 > /dev/null; then
    echo "✅ Code-Server web interface: Accessible on http://localhost:8080"
else
    echo "❌ Code-Server web interface: Not accessible"
fi

echo ""
echo "📂 Files and Directories:"
echo "========================="

# Check if Gitea binary exists
if [ -f "/usr/local/bin/gitea" ]; then
    echo "✅ Gitea binary: Installed at /usr/local/bin/gitea"
else
    echo "❌ Gitea binary: Not found"
fi

# Check if Code-Server binary exists
if [ -f "/usr/local/bin/code-server" ]; then
    echo "✅ Code-Server binary: Installed at /usr/local/bin/code-server"
else
    echo "❌ Code-Server binary: Not found"
fi

# Check deployment info
if [ -f "/root/deployment-info.txt" ]; then
    echo "✅ Deployment info: Available at /root/deployment-info.txt"
    echo ""
    echo "📋 Quick Access Info:"
    echo "===================="
    grep -E "(Server IP|SSH Username|Gitea URL|Code-Server URL)" /root/deployment-info.txt 2>/dev/null || echo "Info parsing failed"
else
    echo "❌ Deployment info: Not found"
fi

echo ""
echo "🔧 Quick Commands:"
echo "=================="
echo "systemctl status gitea                    # Check Gitea service"
echo "systemctl status code-server@*           # Check Code-Server services"
echo "journalctl -u gitea -f                   # View Gitea logs"
echo "cat /root/deployment-info.txt            # View all credentials"
echo "curl http://localhost:3000               # Test Gitea"
echo "curl http://localhost:8080               # Test Code-Server"
