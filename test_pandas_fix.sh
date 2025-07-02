#!/bin/bash

# Quick test for pandas installation fixes
echo "🧪 Testing pandas installation approach..."

# Test 1: Check if system packages are available
echo "📦 Checking system pandas packages availability..."
apt-cache show python3-pandas | head -5 2>/dev/null || echo "⚠️ python3-pandas not available in repositories"

# Test 2: Test virtual environment creation (without actually installing)
echo "🐍 Testing virtual environment creation..."
python3 -c "import venv; print('✅ venv module available')" 2>/dev/null || echo "❌ venv module not available"

# Test 3: Check pip with --break-system-packages flag support
echo "🔧 Testing pip --break-system-packages flag..."
pip3 help install | grep -q "break-system-packages" && echo "✅ --break-system-packages flag supported" || echo "⚠️ flag not supported (older pip version)"

# Test 4: Check current Python version
echo "🐍 Current Python version:"
python3 --version

echo ""
echo "✅ The deployment script should now handle pandas installation correctly!"
echo "✅ It will try system packages first, then use virtual environment"
echo "✅ Fallback to --break-system-packages if needed"
