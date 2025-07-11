#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Get the plugin directory from the script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# Switch to the plugin directory
echo "Changing to plugin directory: $PLUGIN_DIR"
cd "$PLUGIN_DIR"

# Print current directory for debugging
echo "Running tests with coverage from: $(pwd)"

# Find nvim 
NVIM=${NVIM:-$(which nvim)}

if [ -z "$NVIM" ]; then
  echo "Error: nvim not found in PATH"
  exit 1
fi

echo "Running tests with $NVIM"

# Check if plenary.nvim is installed
PLENARY_DIR=~/.local/share/nvim/site/pack/vendor/start/plenary.nvim
if [ ! -d "$PLENARY_DIR" ]; then
  echo "Plenary.nvim not found at $PLENARY_DIR"
  echo "Installing plenary.nvim..."
  mkdir -p ~/.local/share/nvim/site/pack/vendor/start
  git clone --depth 1 https://github.com/nvim-lua/plenary.nvim "$PLENARY_DIR"
fi

# Clean up previous coverage data
rm -f luacov.stats.out luacov.report.out

# Run tests with minimal Neovim configuration and coverage enabled
echo "Running tests with coverage (120 second timeout)..."
# Set LUA_PATH to include luacov from multiple possible locations
export LUA_PATH="$HOME/.luarocks/share/lua/5.1/?.lua;$HOME/.luarocks/share/lua/5.1/?/init.lua;/usr/local/share/lua/5.1/?.lua;/usr/share/lua/5.1/?.lua;./?.lua;$LUA_PATH"
export LUA_CPATH="$HOME/.luarocks/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/?.so;/usr/lib/lua/5.1/?.so;./?.so;$LUA_CPATH"

# Check if luacov is available before running
if command -v lua &> /dev/null; then
  lua -e "require('luacov')" 2>/dev/null || echo "Warning: LuaCov not available in standalone lua environment"
fi

# Run tests - if coverage fails, still run tests normally
timeout --foreground 120 "$NVIM" --headless --noplugin -u tests/minimal-init.lua \
  -c "luafile tests/run_tests_coverage.lua" || {
    echo "Coverage test run failed, trying without coverage..."
    timeout --foreground 120 "$NVIM" --headless --noplugin -u tests/minimal-init.lua \
      -c "luafile tests/run_tests.lua"
  }

# Check exit code
EXIT_CODE=$?
if [ $EXIT_CODE -eq 124 ]; then
  echo "Error: Test execution timed out after 120 seconds"
  exit 1
elif [ $EXIT_CODE -ne 0 ]; then
  echo "Error: Tests failed with exit code $EXIT_CODE"
  exit $EXIT_CODE
else
  echo "Test run completed successfully"
fi

# Generate coverage report if luacov stats were created
if [ -f "luacov.stats.out" ]; then
  echo "Generating coverage report..."
  
  # Try to find luacov command
  if command -v luacov &> /dev/null; then
    luacov
  elif [ -f "/usr/local/bin/luacov" ]; then
    /usr/local/bin/luacov
  else
    # Try to run luacov as a lua script
    if command -v lua &> /dev/null; then
      lua -e "require('luacov.runner').run()"
    else
      echo "Warning: luacov command not found, skipping report generation"
    fi
  fi
  
  # Display summary
  if [ -f "luacov.report.out" ]; then
    echo ""
    echo "Coverage Summary:"
    echo "================="
    tail -20 luacov.report.out
  fi
else
  echo "Warning: No coverage data generated"
fi