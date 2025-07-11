
# Claude code testing

This directory contains resources for testing the Claude Code plugin.

## Overview

There are two main components:

1. **Automated Tests**: Unit and integration tests using the Plenary test framework.
2. **Manual Testing**: A minimal configuration for reproducing issues and testing features.

## Test coverage

The automated test suite covers the following components of the Claude Code plugin:

1. **Core Functionality**
   - Plugin initialization and setup
   - Command registration and execution
   - Version reporting and management

2. **Terminal Integration**
   - Terminal window creation and toggling
   - Terminal positioning and configuration
   - Insert mode management

3. **Git Integration**
   - Git root detection and handling
   - Error handling for non-git directories

4. **Configuration**
   - Config validation for all settings
   - Default config values
   - Config merging with user-provided options

5. **Keymaps**
   - Normal mode toggle keybindings
   - Terminal mode toggle keybindings
   - Window navigation keybindings

6. **File Refresh**
   - Auto-refresh functionality
   - Timer management
   - Updatetime handling

The test suite currently contains 44 tests covering all major components of the plugin.

## Minimal test configuration

The `minimal-init.lua` file provides a minimal Neovim configuration for testing the Claude Code plugin in isolation. This standardized initialization file (recently renamed from `minimal_init.lua` to match conventions used across related Neovim projects) is useful for:

1. Reproducing and debugging issues
2. Testing new features in a clean environment
3. Providing minimal reproducible examples when reporting bugs

## Usage

### Option 1: run directly from the plugin directory

```bash

# From the plugin root directory
nvim --clean -u tests/minimal-init.lua

```text

### Option 2: copy to a separate directory for testing

```bash

# Create a test directory
mkdir ~/claude-test
cp tests/minimal-init.lua ~/claude-test/
cd ~/claude-test

# Run Neovim with the minimal config
nvim --clean -u minimal-init.lua

```text

## Automated Tests

The `spec/` directory contains automated tests for the plugin using the [plenary.busted](https://github.com/nvim-lua/plenary.nvim) framework.

### Test Structure

The test suite is organized by module and functionality:

- `command_registration_spec.lua`: Tests for command registration
- `config_spec.lua`: Tests for configuration parsing
- `config_validation_spec.lua`: Tests for configuration validation
- `core_integration_spec.lua`: Tests for core plugin integration
- `file_refresh_spec.lua`: Tests for file refresh functionality
- `git_spec.lua`: Tests for git integration
- `keymaps_spec.lua`: Tests for keybinding functionality
- `terminal_spec.lua`: Tests for terminal integration
- `version_spec.lua`: Tests for version handling

### Running Tests

Run all automated tests using:

```bash
./scripts/test.sh

```text

You'll see a summary of the test results like:

```plaintext
==== Test Results ====
Total Tests Run: 44
Successes: 44
Failures: 0
Errors: 0
=====================

```text

### Writing Tests

Test files should follow the plenary.busted structure:

```lua
local assert = require('luassert')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it

describe('module_name', function()
  describe('function_name', function()
    it('should do something', function()
      -- Test code here
      assert.are.equal(expected, actual)
    end)
  end)
end)

```text

## Troubleshooting

The minimal configuration:

- Attempts to auto-detect the plugin directory
- Sets up basic Neovim settings (no swap files, etc.)
- Prints available commands for reference
- Shows line numbers and sign column

To see error messages:

```vim
:messages

```text

## Reporting Issues

When reporting issues, please include the following information:

1. Steps to reproduce the issue using this minimal config
2. Any error messages from `:messages`
3. The exact Neovim and Claude Code plugin versions

## Legacy Tests

The `legacy/` subdirectory contains VimL-based tests for backward compatibility:

- **minimal.vim**: A minimal Neovim configuration for automated testing
- **basic_test.vim**: A simple test script that verifies the plugin loads correctly
- **config_test.vim**: Tests for the configuration validation and merging functionality

These legacy tests can be run via:

```bash
make test-legacy  # Run all legacy tests
make test-basic   # Run only basic functionality tests (legacy)
make test-config  # Run only configuration tests (legacy)

```text

## Interactive Tests

The `interactive/` subdirectory contains utilities for manual testing and comprehensive integration tests:

- **mcp_comprehensive_test.lua**: Full MCP integration test suite
- **mcp_live_test.lua**: Interactive MCP testing utilities
- **test_utils.lua**: Shared testing utilities

These provide commands like `:MCPComprehensiveTest` for interactive testing.

