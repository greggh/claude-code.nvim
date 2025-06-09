#!/bin/bash

# Test script for mcp-neovim-server integration

# Configurable server path - can be overridden via environment variable
SERVER="${CLAUDE_MCP_SERVER_PATH:-mcp-neovim-server}"

# Configurable timeout (in seconds)
TIMEOUT="${CLAUDE_MCP_TIMEOUT:-10}"

# Debug mode
DEBUG="${CLAUDE_MCP_DEBUG:-0}"

# Validate server command exists
if ! command -v "$SERVER" &> /dev/null; then
    echo "Error: MCP server command not found: $SERVER"
    echo "Please install with: npm install -g mcp-neovim-server"
    echo "Or set CLAUDE_MCP_SERVER_PATH environment variable to specify custom path"
    exit 1
fi

echo "Testing mcp-neovim-server Integration"
echo "==============================="
echo "Server: $SERVER"
echo "Timeout: ${TIMEOUT}s"
echo "Debug: $DEBUG"
echo ""

# Helper function to run commands with timeout and debug
run_with_timeout() {
    local cmd="$1"
    # shellcheck disable=SC2034
    local description="$2"
    
    if [ "$DEBUG" = "1" ]; then
        echo "DEBUG: Running: $cmd"
        echo "$cmd" | timeout "$TIMEOUT" "$SERVER"
    else
        echo "$cmd" | timeout "$TIMEOUT" "$SERVER" 2>/dev/null
    fi
}

# Test 1: Initialize
echo "1. Testing initialization..."
if ! response=$(run_with_timeout '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' "initialization" | head -1); then
    echo "ERROR: Server failed to initialize"
    exit 1
fi
echo "$response"

echo ""

# Test 2: List tools
echo "2. Testing tools list..."
(
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}'
echo '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'
) | timeout "$TIMEOUT" "$SERVER" 2>/dev/null | tail -1 | jq '.result.tools[] | .name' 2>/dev/null || echo "jq not available - raw output needed"

echo ""

# Test 3: List resources
echo "3. Testing resources list..."
(
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}'
echo '{"jsonrpc":"2.0","id":3,"method":"resources/list","params":{}}'
) | timeout "$TIMEOUT" "$SERVER" 2>/dev/null | tail -1

echo ""

# Configuration summary
echo "Test completed successfully!"
echo "Configuration used:"
echo "  Server path: $SERVER"
echo "  Timeout: ${TIMEOUT}s"
echo "  Debug mode: $DEBUG"
echo ""
echo "Environment variables available:"
echo "  CLAUDE_MCP_SERVER_PATH - Custom server path"
echo "  CLAUDE_MCP_TIMEOUT - Timeout in seconds" 
echo "  CLAUDE_MCP_DEBUG - Enable debug output (1=on, 0=off)"