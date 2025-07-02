#!/bin/bash

# Debug script to identify permission issues
echo "🔍 Debugging permission issues..."

echo ""
echo "📂 Current directory permissions:"
echo "================================="
ls -la /root/

echo ""
echo "📂 Tech interview service directory:"
echo "===================================="
if [ -d "/root/tech-interview-service-de" ]; then
    ls -la /root/tech-interview-service-de/
    echo ""
    echo "📂 Assignments directory:"
    echo "========================"
    if [ -d "/root/tech-interview-service-de/assignments" ]; then
        ls -la /root/tech-interview-service-de/assignments/
    else
        echo "❌ Assignments directory not found"
    fi
else
    echo "❌ Tech interview service directory not found"
fi

echo ""
echo "👥 Current users:"
echo "================="
grep -E "(naruto|sasuke|sakura|kakashi|jiraiya|tsunade|orochimaru|itachi|madara|obito|shikamaru|choji|ino|neji|rocklee|gaara|temari|kankuro|hinata|minato|deidara|kisame|pain)" /etc/passwd | while read line; do
    username=$(echo $line | cut -d: -f1)
    echo "User: $username"
    echo "Home: $(echo $line | cut -d: -f6)"
    if [ -d "$(echo $line | cut -d: -f6)" ]; then
        echo "Home contents:"
        ls -la "$(echo $line | cut -d: -f6)/" 2>/dev/null || echo "  Cannot access home directory"
    fi
    echo ""
done

echo ""
echo "🔧 Environment check:"
echo "===================="
echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"
echo "HOME variable: $HOME"

echo ""
echo "📝 Recent deployment log (last 10 lines):"
echo "=========================================="
if [ -f "/root/deployment.log" ]; then
    tail -10 /root/deployment.log
else
    echo "❌ No deployment log found"
fi
