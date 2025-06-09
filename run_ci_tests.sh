#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Simulate GitHub Actions environment
export CI=true
export GITHUB_ACTIONS=true
export GITHUB_WORKFLOW="CI"
export PLUGIN_ROOT="$(pwd)"
export CLAUDE_CODE_TEST_MODE="true"
export RUNNER_OS="Linux"
export OSTYPE="linux-gnu"

echo -e "${YELLOW}=== Running Tests in CI Environment ===${NC}"
echo "CI=$CI"
echo "GITHUB_ACTIONS=$GITHUB_ACTIONS"
echo "CLAUDE_CODE_TEST_MODE=$CLAUDE_CODE_TEST_MODE"
echo ""

# Track results
PASSED_TESTS=()
FAILED_TESTS=()
TIMEOUT_TESTS=()

# Get all test files
TEST_FILES=$(find tests/spec -name "*_spec.lua" | sort)
TOTAL_TESTS=$(echo "$TEST_FILES" | wc -l | tr -d ' ')

echo "Found $TOTAL_TESTS test files"
echo ""

# Function to run a single test
run_test() {
    local test_file=$1
    local test_name=$(basename "$test_file")
    
    echo -e "${YELLOW}Running: $test_name${NC}"
    
    # Export TEST_FILE for the Lua script
    export TEST_FILE="$test_file"
    
    # Run with timeout
    if timeout 120 nvim --headless --noplugin -u tests/minimal-init.lua \
        -c "luafile scripts/run_single_test.lua" > /tmp/test_output.log 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        PASSED_TESTS+=("$test_name")
    else
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 124 ]; then
            echo -e "${RED}✗ TIMEOUT (120s)${NC}"
            TIMEOUT_TESTS+=("$test_name")
        else
            echo -e "${RED}✗ FAILED (exit code: $EXIT_CODE)${NC}"
            FAILED_TESTS+=("$test_name")
        fi
        
        # Show last 20 lines of output for failed tests
        echo "--- Last 20 lines of output ---"
        tail -20 /tmp/test_output.log
        echo "--- End of output ---"
    fi
    echo ""
}

# Run all tests
for TEST_FILE in $TEST_FILES; do
    run_test "$TEST_FILE"
done

# Summary
echo -e "${YELLOW}=== Test Summary ===${NC}"
echo -e "${GREEN}Passed: ${#PASSED_TESTS[@]}${NC}"
echo -e "${RED}Failed: ${#FAILED_TESTS[@]}${NC}"
echo -e "${RED}Timeout: ${#TIMEOUT_TESTS[@]}${NC}"
echo ""

if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo -e "${RED}Failed tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo "  - $test"
    done
    echo ""
fi

if [ ${#TIMEOUT_TESTS[@]} -gt 0 ]; then
    echo -e "${RED}Timeout tests:${NC}"
    for test in "${TIMEOUT_TESTS[@]}"; do
        echo "  - $test"
    done
    echo ""
fi

# Exit with error if any tests failed
if [ ${#FAILED_TESTS[@]} -gt 0 ] || [ ${#TIMEOUT_TESTS[@]} -gt 0 ]; then
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi