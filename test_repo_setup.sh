#!/bin/bash

# Test script for repository setup specifically
echo "🧪 Testing repository setup..."

# Mock variables for testing
ADMIN_USER="test_user"
ADMIN_PASS="test_pass"

echo "📝 This script will test the repository setup logic"
echo "Variables:"
echo "  ADMIN_USER: $ADMIN_USER"
echo "  ADMIN_PASS: $ADMIN_PASS"
echo ""

echo "📂 Checking assignments directory structure..."
if [ -d "assignments" ]; then
    echo "✅ Assignments directory exists"
    echo "Contents:"
    find assignments -type f | head -10
    echo ""
else
    echo "❌ Assignments directory not found"
    echo "Creating from task directories..."
    mkdir -p assignments/task1 assignments/task2
    cp -r task1/* assignments/task1/ 2>/dev/null || echo "No task1 files to copy"
    cp -r task2/* assignments/task2/ 2>/dev/null || echo "No task2 files to copy"
    echo "✅ Assignments directory created"
fi

echo "📊 Assignment files summary:"
echo "Task1 files: $(find assignments/task1 -type f 2>/dev/null | wc -l)"
echo "Task2 files: $(find assignments/task2 -type f 2>/dev/null | wc -l)"

if [ -f "assignments/task1/assignment.md" ]; then
    echo "✅ Task1 assignment.md exists"
else
    echo "❌ Task1 assignment.md missing"
fi

if [ -f "assignments/task2/assignment.md" ]; then
    echo "✅ Task2 assignment.md exists"
else
    echo "❌ Task2 assignment.md missing"
fi

echo ""
echo "💡 To test full repository setup:"
echo "1. Start a local Gitea instance"
echo "2. Create a test user and repository"
echo "3. Run the repository setup logic from deploy_new.sh"
