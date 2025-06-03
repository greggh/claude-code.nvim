#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Get the plugin directory from the script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# Switch to the plugin directory
echo "Changing to plugin directory: $PLUGIN_DIR"
cd "$PLUGIN_DIR"

# Print current directory for debugging
echo "Running tests from: $(pwd)"

# Find nvim - ignore NVIM env var if it points to a socket
if [ -n "$NVIM" ] && [ -x "$NVIM" ] && [ ! -S "$NVIM" ]; then
  # NVIM is set and is an executable file (not a socket)
  echo "Using NVIM from environment: $NVIM"
else
  # Find nvim in PATH
  if ! NVIM=$(command -v nvim); then
    echo "Error: nvim not found in PATH"
    exit 1
  fi
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

# Run tests with minimal Neovim configuration and add a timeout
# Timeout after 60 seconds to prevent hanging in CI
echo "Running tests with a 60 second timeout..."
timeout --foreground 60 $NVIM --headless --noplugin -u tests/minimal-init.lua -c "luafile tests/run_tests.lua"

# Check exit code
EXIT_CODE=$?
if [ $EXIT_CODE -eq 124 ]; then
  echo "Error: Test execution timed out after 60 seconds"
  exit 1
elif [ $EXIT_CODE -ne 0 ]; then
  echo "Error: Tests failed with exit code $EXIT_CODE"
  exit $EXIT_CODE
else
  echo "Test run completed successfully"
fi