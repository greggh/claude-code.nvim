#!/bin/bash
set -e

# MCP Integration Test Script
# This script tests MCP functionality that can be verified in CI

echo "🧪 Running MCP Integration Tests"
echo "================================"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PLUGIN_DIR"

# Find nvim
NVIM=${NVIM:-nvim}
if ! command -v "$NVIM" >/dev/null 2>&1; then
  echo "❌ Error: nvim not found in PATH"
  exit 1
fi

echo "📍 Testing from: $(pwd)"
echo "🔧 Using Neovim: $(command -v "$NVIM")"

# Make MCP server executable
chmod +x ./bin/claude-code-mcp-server

# Test 1: MCP Server Startup
echo ""
echo "Test 1: MCP Server Startup"
echo "---------------------------"

if ./bin/claude-code-mcp-server --help >/dev/null 2>&1; then
  echo "✅ MCP server executable runs"
else
  echo "❌ MCP server executable failed"
  exit 1
fi

# Test 2: Module Loading
echo ""
echo "Test 2: Module Loading"  
echo "----------------------"

$NVIM --headless --noplugin -u tests/minimal-init.lua \
  -c "lua pcall(require, 'claude-code.mcp') and print('✅ MCP module loads') or error('❌ MCP module failed to load')" \
  -c "qa!"

$NVIM --headless --noplugin -u tests/minimal-init.lua \
  -c "lua pcall(require, 'claude-code.mcp.hub') and print('✅ MCP Hub module loads') or error('❌ MCP Hub module failed to load')" \
  -c "qa!"

$NVIM --headless --noplugin -u tests/minimal-init.lua \
  -c "lua pcall(require, 'claude-code.utils') and print('✅ Utils module loads') or error('❌ Utils module failed to load')" \
  -c "qa!"

# Test 3: Tools and Resources Count
echo ""
echo "Test 3: Tools and Resources"
echo "---------------------------"

$NVIM --headless --noplugin -u tests/minimal-init.lua \
  -c "lua local tools = require('claude-code.mcp.tools'); local count = 0; for _ in pairs(tools) do count = count + 1 end; print('Tools found: ' .. count); assert(count >= 8, 'Expected at least 8 tools')" \
  -c "qa!"

$NVIM --headless --noplugin -u tests/minimal-init.lua \
  -c "lua local resources = require('claude-code.mcp.resources'); local count = 0; for _ in pairs(resources) do count = count + 1 end; print('Resources found: ' .. count); assert(count >= 6, 'Expected at least 6 resources')" \
  -c "qa!"

# Test 4: Configuration Generation
echo ""
echo "Test 4: Configuration Generation"
echo "--------------------------------"

# Test Claude Code format
$NVIM --headless --noplugin -u tests/minimal-init.lua \
  -c "lua require('claude-code.mcp').generate_config('test-claude-config.json', 'claude-code')" \
  -c "qa!"

if [ -f "test-claude-config.json" ]; then
  echo "✅ Claude Code config generated"
  if grep -q "mcpServers" test-claude-config.json; then
    echo "✅ Config has correct Claude Code format"
  else
    echo "❌ Config missing mcpServers key"
    exit 1
  fi
  rm test-claude-config.json
else
  echo "❌ Claude Code config not generated"
  exit 1
fi

# Test workspace format
$NVIM --headless --noplugin -u tests/minimal-init.lua \
  -c "lua require('claude-code.mcp').generate_config('test-workspace-config.json', 'workspace')" \
  -c "qa!"

if [ -f "test-workspace-config.json" ]; then
  echo "✅ Workspace config generated"
  if grep -q "neovim" test-workspace-config.json && ! grep -q "mcpServers" test-workspace-config.json; then
    echo "✅ Config has correct workspace format"
  else
    echo "❌ Config has incorrect workspace format"
    exit 1
  fi
  rm test-workspace-config.json
else
  echo "❌ Workspace config not generated"
  exit 1
fi

# Test 5: MCP Hub
echo ""
echo "Test 5: MCP Hub"
echo "---------------"

$NVIM --headless --noplugin -u tests/minimal-init.lua \
  -c "lua local hub = require('claude-code.mcp.hub'); local servers = hub.list_servers(); print('Servers found: ' .. #servers); assert(#servers > 0, 'Expected at least one server')" \
  -c "qa!"

$NVIM --headless --noplugin -u tests/minimal-init.lua \
  -c "lua local hub = require('claude-code.mcp.hub'); assert(hub.get_server('claude-code-neovim'), 'Expected claude-code-neovim server')" \
  -c "qa!"

# Test 6: Live Test Script
echo ""
echo "Test 6: Live Test Script"
echo "------------------------"

$NVIM --headless --noplugin -u tests/minimal-init.lua \
  -c "lua local test = require('tests.interactive.mcp_live_test'); assert(type(test.setup_test_file) == 'function', 'Live test should have setup function')" \
  -c "qa!"

echo ""
echo "🎉 All MCP Integration Tests Passed!"
echo "====================================="
echo ""
echo "Manual tests you can run:"
echo "• :MCPComprehensiveTest - Full interactive test suite"
echo "• :MCPHubList - List available MCP servers"
echo "• :ClaudeCodeSetup - Generate MCP configuration"
echo ""