#!/bin/bash
set -euo pipefail

# Test script to verify NVIM environment variable detection logic
# This script tests the fix for handling NVIM variable when running inside Neovim

# Get the absolute directory path of this script
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Testing NVIM environment variable detection..."

# Save original NVIM value
ORIGINAL_NVIM="$NVIM"

# Test 1: NVIM points to a socket (simulating inside Neovim)
echo "Test 1: NVIM points to a socket"
export NVIM="/tmp/test_socket"
mkfifo "$NVIM" 2>/dev/null || true  # Create a named pipe (similar to socket)
if timeout 5 bash -c "cd '$PROJECT_DIR' && ./scripts/test.sh" 2>&1 | head -10 | grep -q "Running tests with.*nvim"; then
    echo "✓ Fallback to PATH works"
else
    echo "✗ Fallback failed"
fi
rm -f "$NVIM"

# Test 2: NVIM points to valid executable
echo "Test 2: NVIM points to valid executable"
if ! NVIM=$(command -v nvim); then
  echo "Error: nvim not found in PATH"
  exit 1
fi
export NVIM
if timeout 5 bash -c "cd '$PROJECT_DIR' && ./scripts/test.sh" 2>&1 | head -10 | grep -q "Using NVIM from environment"; then
    echo "✓ Using provided NVIM works"
else
    echo "✗ Using provided NVIM failed"
fi

# Test 3: NVIM points to non-existent path
echo "Test 3: NVIM points to non-existent path"
export NVIM="/nonexistent/nvim"
if timeout 5 bash -c "cd '$PROJECT_DIR' && ./scripts/test.sh" 2>&1 | head -10 | grep -q "Running tests with.*nvim"; then
    echo "✓ Fallback from invalid path works"
else
    echo "✗ Fallback from invalid path failed"
fi

# Test 4: NVIM is unset
echo "Test 4: NVIM is unset"
unset NVIM
if timeout 5 bash -c "cd '$PROJECT_DIR' && ./scripts/test.sh" 2>&1 | head -10 | grep -q "Running tests with.*nvim"; then
    echo "✓ Unset NVIM works"
else
    echo "✗ Unset NVIM failed"
fi

# Restore original NVIM value
if [ -n "$ORIGINAL_NVIM" ]; then
  export NVIM="$ORIGINAL_NVIM"
else
  unset NVIM
fi

echo "All NVIM detection tests completed!"