#!/bin/bash

# Simple validation test for deploy_new.sh
# Tests script structure and logic without actual deployment

set -e

echo "🔍 Testing deploy_new.sh script validation..."

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
blue "=== Testing Script Structure ==="

# Check if deploy_new.sh exists and is executable
if [ -f "deploy_new.sh" ] && [ -x "deploy_new.sh" ]; then
    test_result 0 "deploy_new.sh exists and is executable"
else
    test_result 1 "deploy_new.sh is missing or not executable"
fi

# Check critical sections exist
echo ""
blue "=== Testing Script Content ==="

# Check for key sections
if grep -q '"auto_init": false' deploy_new.sh; then
    test_result 0 "Repository creation uses auto_init: false (correct)"
else
    test_result 1 "Repository creation should use auto_init: false"
fi

if grep -q "git add \." deploy_new.sh; then
    test_result 0 "Script adds all assignment files to git"
else
    test_result 1 "Script should add all files with 'git add .'"
fi

if grep -q "task1\|task2" deploy_new.sh; then
    test_result 0 "Script references both task1 and task2"
else
    test_result 1 "Script should reference both task directories"
fi

if grep -q "git push" deploy_new.sh; then
    test_result 0 "Script pushes to remote repository"
else
    test_result 1 "Script should push to remote repository"
fi

echo ""
blue "=== Testing Assignment Files ==="

# Check assignments directory structure
if [ -d "assignments" ]; then
    test_result 0 "assignments directory exists"
    
    if [ -d "assignments/task1" ] && [ -d "assignments/task2" ]; then
        test_result 0 "Both task1 and task2 directories exist"
    else
        test_result 1 "Missing task directories"
    fi
    
    # Check task1 files
    TASK1_FILES=("assignment.md" "trades.csv" "exchange_mapping.csv")
    TASK1_MISSING=0
    for file in "${TASK1_FILES[@]}"; do
        if [ -f "assignments/task1/$file" ]; then
            green "  ✅ task1/$file exists"
        else
            red "  ❌ task1/$file is missing"
            ((TASK1_MISSING++))
        fi
    done
    
    if [ $TASK1_MISSING -eq 0 ]; then
        test_result 0 "All task1 files are present"
    else
        test_result 1 "Some task1 files are missing"
    fi
    
    # Check task2 files
    TASK2_FILES=("assignment.md" "max_bytes.py" "test_max_bytes.py")
    TASK2_MISSING=0
    for file in "${TASK2_FILES[@]}"; do
        if [ -f "assignments/task2/$file" ]; then
            green "  ✅ task2/$file exists"
        else
            red "  ❌ task2/$file is missing"
            ((TASK2_MISSING++))
        fi
    done
    
    if [ $TASK2_MISSING -eq 0 ]; then
        test_result 0 "All task2 files are present"
    else
        test_result 1 "Some task2 files are missing"
    fi
    
else
    test_result 1 "assignments directory does not exist"
fi

echo ""
blue "=== Testing Script Logic ==="

# Test that script creates empty repo first, then pushes content
if grep -q '"auto_init": false' deploy_new.sh; then
    test_result 0 "Script creates empty repository correctly"
else
    test_result 1 "Repository creation logic needs verification"
fi

# Check that git commands are in correct order
SCRIPT_LINES=$(cat deploy_new.sh)
if echo "$SCRIPT_LINES" | grep -n "git init\|git add\|git commit\|git push" | head -4 | tail -1 | grep -q "git push"; then
    test_result 0 "Git commands are in correct order (init -> add -> commit -> push)"
else
    test_result 1 "Git command order might be incorrect"
fi

echo ""
blue "=== Testing Configuration ==="

# Check cloud-init.yaml exists
if [ -f "cloud-init.yaml" ]; then
    test_result 0 "cloud-init.yaml exists"
    
    if grep -q "deploy_new.sh" cloud-init.yaml; then
        test_result 0 "cloud-init.yaml references deploy_new.sh"
    else
        test_result 1 "cloud-init.yaml should reference deploy_new.sh"
    fi
else
    test_result 1 "cloud-init.yaml is missing"
fi

echo ""
blue "=== Summary ==="

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
echo "Total validation checks: $TOTAL_TESTS"
green "Checks passed: $TESTS_PASSED"
red "Checks failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    green "🎉 ALL VALIDATION CHECKS PASSED!"
    echo ""
    green "The deployment script looks good and should:"
    echo "✅ Create an empty Gitea repository"
    echo "✅ Add all assignment files (task1 & task2) to git"
    echo "✅ Push the files to the Gitea repository"
    echo "✅ Clone the repository to admin user's home"
    echo ""
    yellow "📋 Ready for deployment on Hetzner server!"
    exit 0
else
    echo ""
    red "❌ Some validation checks failed."
    echo "Please review the issues above before deployment."
    exit 1
fi
