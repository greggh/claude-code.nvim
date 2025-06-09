#!/bin/bash

# Simulate GitHub Actions environment variables
export CI=true
export GITHUB_ACTIONS=true
export GITHUB_WORKFLOW="CI"
export GITHUB_RUN_ID="12345678"
export GITHUB_RUN_NUMBER="1"
export GITHUB_SHA="$(git rev-parse HEAD)"
export GITHUB_REF="refs/heads/$(git branch --show-current)"
export RUNNER_OS="Linux"
export RUNNER_TEMP="/tmp"

# Plugin-specific test variables
export PLUGIN_ROOT="$(pwd)"
export CLAUDE_CODE_TEST_MODE="true"

# GitHub Actions uses Ubuntu, so simulate that
export OSTYPE="linux-gnu"

echo "=== CI Environment Setup ==="
echo "CI=$CI"
echo "GITHUB_ACTIONS=$GITHUB_ACTIONS"
echo "CLAUDE_CODE_TEST_MODE=$CLAUDE_CODE_TEST_MODE"
echo "PLUGIN_ROOT=$PLUGIN_ROOT"
echo "Current directory: $(pwd)"
echo "Git branch: $(git branch --show-current)"
echo "==========================="

# Run the tests the same way CI does
echo "Running tests with CI environment..."

# First, let's run a single test to see if it works
TEST_FILE="tests/spec/config_spec.lua"
echo "Testing single file: $TEST_FILE"

nvim --headless --noplugin -u tests/minimal-init.lua \
  -c "lua require('plenary.test_harness').test_file('$TEST_FILE')" \
  -c "qa!"

# Now let's run all tests like CI does
echo ""
echo "=== Running all tests ==="

# Get all test files
TEST_FILES=$(find tests/spec -name "*_spec.lua" | sort)

# Run each test individually with timeout like CI
for TEST_FILE in $TEST_FILES; do
    echo ""
    echo "Running: $TEST_FILE"
    
    # Export TEST_FILE for the Lua script
    export TEST_FILE="$TEST_FILE"
    
    # Use timeout to match CI (120 seconds)
    timeout 120 nvim --headless --noplugin -u tests/minimal-init.lua \
        -c "luafile scripts/run_single_test.lua" || {
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 124 ]; then
            echo "ERROR: Test $TEST_FILE timed out after 120 seconds"
        else
            echo "ERROR: Test $TEST_FILE failed with exit code $EXIT_CODE"
        fi
    }
done