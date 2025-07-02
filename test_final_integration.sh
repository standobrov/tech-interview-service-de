#!/bin/bash

# Final Integration Test for Technical Interview Environment
# Tests full deployment including Gitea repository content

set -e

echo "🧪 Starting Final Integration Test..."

# Color output functions
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
blue() { echo -e "\033[34m$1\033[0m"; }

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

test_result() {
    if [ $1 -eq 0 ]; then
        green "✅ $2"
        ((TESTS_PASSED++))
    else
        red "❌ $2"
        ((TESTS_FAILED++))
    fi
}

echo ""
blue "=== Pre-deployment Setup ==="

# Clean up any previous test environment
echo "🧹 Cleaning up previous test environment..."
./cleanup.sh > /dev/null 2>&1 || true

# Kill any existing processes
killall gitea 2>/dev/null || true
killall code-server 2>/dev/null || true

# Wait for cleanup
sleep 5

echo ""
blue "=== Running Full Deployment ==="

# Run deployment
echo "🚀 Running deployment script..."
if timeout 600 ./deploy_new.sh > /tmp/deploy_test.log 2>&1; then
    green "✅ Deployment completed successfully"
else
    red "❌ Deployment failed"
    echo "Deployment log:"
    tail -50 /tmp/deploy_test.log
    exit 1
fi

echo ""
blue "=== Testing Service Status ==="

# Test Gitea service
if systemctl is-active --quiet gitea; then
    test_result 0 "Gitea service is running"
else
    test_result 1 "Gitea service is not running"
fi

# Test Gitea HTTP endpoint
if curl -s http://localhost:3000 | grep -q "Gitea"; then
    test_result 0 "Gitea web interface is accessible"
else
    test_result 1 "Gitea web interface is not accessible"
fi

# Test code-server service
if systemctl is-active --quiet code-server@interview; then
    test_result 0 "Code-server service is running"
else
    test_result 1 "Code-server service is not running"
fi

# Test code-server HTTP endpoint
if curl -s http://localhost:8080 | grep -q "code-server"; then
    test_result 0 "Code-server web interface is accessible"
else
    test_result 1 "Code-server web interface is not accessible"
fi

echo ""
blue "=== Testing Gitea Repository Content ==="

# Extract credentials from deployment info
if [ -f "/root/deployment-info.txt" ]; then
    ADMIN_USER=$(grep "Admin Username:" /root/deployment-info.txt | cut -d: -f2 | xargs)
    ADMIN_PASS=$(grep "Admin Password:" /root/deployment-info.txt | cut -d: -f2 | xargs)
    
    if [ -n "$ADMIN_USER" ] && [ -n "$ADMIN_PASS" ]; then
        green "✅ Extracted credentials: $ADMIN_USER"
    else
        red "❌ Could not extract credentials from deployment info"
        ADMIN_USER="interview"
        ADMIN_PASS="interviewpass123"
        yellow "⚠️ Using default credentials"
    fi
else
    red "❌ Deployment info file not found"
    ADMIN_USER="interview"
    ADMIN_PASS="interviewpass123"
    yellow "⚠️ Using default credentials"
fi

# Test repository exists
echo "🔍 Checking if assignments repository exists..."
REPO_INFO=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" \
    "http://localhost:3000/api/v1/repos/$ADMIN_USER/assignments" 2>/dev/null || echo "")

if echo "$REPO_INFO" | grep -q '"name":"assignments"'; then
    test_result 0 "Assignments repository exists in Gitea"
else
    test_result 1 "Assignments repository does not exist in Gitea"
    echo "Repository API response: $REPO_INFO"
fi

# Test repository contents via API
echo "🔍 Checking repository contents via API..."
REPO_CONTENTS=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" \
    "http://localhost:3000/api/v1/repos/$ADMIN_USER/assignments/contents" 2>/dev/null || echo "")

# Check if both task directories exist
if echo "$REPO_CONTENTS" | grep -q '"name":"task1"' && echo "$REPO_CONTENTS" | grep -q '"name":"task2"'; then
    test_result 0 "Both task1 and task2 directories exist in repository"
else
    test_result 1 "Task directories are missing from repository"
    echo "Repository contents: $REPO_CONTENTS"
fi

# Test task1 contents
echo "🔍 Checking task1 contents..."
TASK1_CONTENTS=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" \
    "http://localhost:3000/api/v1/repos/$ADMIN_USER/assignments/contents/task1" 2>/dev/null || echo "")

TASK1_FILES=("assignment.md" "trades.csv" "exchange_mapping.csv")
TASK1_MISSING=0

for file in "${TASK1_FILES[@]}"; do
    if echo "$TASK1_CONTENTS" | grep -q "\"name\":\"$file\""; then
        green "  ✅ task1/$file exists"
    else
        red "  ❌ task1/$file is missing"
        ((TASK1_MISSING++))
    fi
done

if [ $TASK1_MISSING -eq 0 ]; then
    test_result 0 "All task1 files are present"
else
    test_result 1 "Some task1 files are missing ($TASK1_MISSING missing)"
fi

# Test task2 contents
echo "🔍 Checking task2 contents..."
TASK2_CONTENTS=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" \
    "http://localhost:3000/api/v1/repos/$ADMIN_USER/assignments/contents/task2" 2>/dev/null || echo "")

TASK2_FILES=("assignment.md" "max_bytes.py" "test_max_bytes.py")
TASK2_MISSING=0

for file in "${TASK2_FILES[@]}"; do
    if echo "$TASK2_CONTENTS" | grep -q "\"name\":\"$file\""; then
        green "  ✅ task2/$file exists"
    else
        red "  ❌ task2/$file is missing"
        ((TASK2_MISSING++))
    fi
done

if [ $TASK2_MISSING -eq 0 ]; then
    test_result 0 "All task2 files are present"
else
    test_result 1 "Some task2 files are missing ($TASK2_MISSING missing)"
fi

echo ""
blue "=== Testing Local Repository Clone ==="

# Test if admin user has cloned assignments
if [ -d "/home/$ADMIN_USER/assignments" ]; then
    test_result 0 "Assignments directory exists in admin user home"
    
    # Check local directory contents
    if [ -d "/home/$ADMIN_USER/assignments/task1" ] && [ -d "/home/$ADMIN_USER/assignments/task2" ]; then
        test_result 0 "Local clone has both task directories"
    else
        test_result 1 "Local clone is missing task directories"
    fi
    
    # Check if it's a git repository
    if [ -d "/home/$ADMIN_USER/assignments/.git" ]; then
        test_result 0 "Local assignments is a git repository"
    else
        test_result 1 "Local assignments is not a git repository"
    fi
else
    test_result 1 "Assignments directory does not exist in admin user home"
fi

echo ""
blue "=== Testing File Content Quality ==="

# Test one file from each task to ensure content is correct
if [ -f "/home/$ADMIN_USER/assignments/task1/assignment.md" ]; then
    if grep -q "Exchange Rate Analysis" "/home/$ADMIN_USER/assignments/task1/assignment.md"; then
        test_result 0 "Task1 assignment content is correct"
    else
        test_result 1 "Task1 assignment content is incorrect"
    fi
else
    test_result 1 "Task1 assignment file not found locally"
fi

if [ -f "/home/$ADMIN_USER/assignments/task2/assignment.md" ]; then
    if grep -q "Memory Optimization Challenge" "/home/$ADMIN_USER/assignments/task2/assignment.md"; then
        test_result 0 "Task2 assignment content is correct"
    else
        test_result 1 "Task2 assignment content is incorrect"
    fi
else
    test_result 1 "Task2 assignment file not found locally"
fi

echo ""
blue "=== Test Summary ==="

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
echo "Total tests run: $TOTAL_TESTS"
green "Tests passed: $TESTS_PASSED"
red "Tests failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    green "🎉 ALL TESTS PASSED! The deployment is working correctly."
    echo ""
    green "✅ The technical interview environment is ready:"
    echo "   - Gitea is running with assignments repository"
    echo "   - All assignment files (task1 & task2) are present"
    echo "   - Code-server is accessible for candidates"
    echo "   - Local clone is available for the admin user"
    echo ""
    echo "📋 Connection Information:"
    cat /root/deployment-info.txt 2>/dev/null || echo "Deployment info not available"
    exit 0
else
    echo ""
    red "❌ Some tests failed. Please check the issues above."
    echo ""
    echo "📋 Logs for debugging:"
    echo "Deployment log: /tmp/deploy_test.log"
    echo "Service status: systemctl status gitea code-server@$ADMIN_USER"
    exit 1
fi
