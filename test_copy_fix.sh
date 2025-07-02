#!/bin/bash

# Quick fix test - test just the problematic part
echo "🧪 Testing assignments copy fix..."

# Simulate the scenario
TEST_USER="test_user"
TEST_HOME="/tmp/test_home"

echo "Creating test user and environment..."
sudo useradd -m -d "$TEST_HOME" -s /bin/bash "$TEST_USER" 2>/dev/null || echo "User might already exist"

echo "Testing copy method..."
# Copy assignments folder to a temporary location accessible by test user
if cp -r /home/saddogalone/projects/tech-interview-service-de/assignments /tmp/assignments_temp; then
    echo "✅ Copy to temp succeeded"
    
    sudo chown -R "$TEST_USER:$TEST_USER" /tmp/assignments_temp
    echo "✅ Ownership changed"
    
    sudo -u "$TEST_USER" bash -c "
      cd $TEST_HOME
      cp -r /tmp/assignments_temp ./assignments
      echo 'Copy to user home succeeded'
      ls -la assignments/
    "
    
    echo "✅ Test completed successfully"
    
    # Cleanup
    rm -rf /tmp/assignments_temp
    sudo userdel -r "$TEST_USER" 2>/dev/null || echo "User cleanup might have failed"
    
else
    echo "❌ Copy to temp failed"
fi
