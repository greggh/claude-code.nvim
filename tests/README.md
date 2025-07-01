# Rovo Dev Testing

This directory contains resources for testing the Rovo Dev plugin.

## Overview

There are two main components:

1. **Automated Tests**: Unit and integration tests using the Plenary test framework.
2. **Manual Testing**: A minimal configuration for reproducing issues and testing features.

## Test Coverage

The automated test suite covers the following components of the Rovo Dev plugin:

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

## Minimal Test Configuration

The `minimal-init.lua` file provides a minimal Neovim configuration for testing the Rovo Dev plugin in isolation. This standardized initialization file (recently renamed from `minimal_init.lua` to match conventions used across related Neovim projects) is useful for:

1. Reproducing and debugging issues
2. Testing new features in a clean environment
3. Providing minimal reproducible examples when reporting bugs

## Usage

### Option 1: Run directly from the plugin directory

```bash
# From the plugin root directory
nvim --clean -u tests/minimal-init.lua
```

### Option 2: Copy to a separate directory for testing

```bash
# Create a test directory
mkdir ~/rovo-test
cp tests/minimal-init.lua ~/rovo-test/
cd ~/rovo-test

# Run Neovim with the minimal config
nvim --clean -u minimal-init.lua
```

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
```

You'll see a summary of the test results like:

```plaintext
==== Test Results ====
Total Tests Run: 44
Successes: 44
Failures: 0
Errors: 0
=====================
```

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
```

## Troubleshooting

The minimal configuration:

- Attempts to auto-detect the plugin directory
- Sets up basic Neovim settings (no swap files, etc.)
- Prints available commands for reference
- Shows line numbers and sign column

To see error messages:

```vim
:messages
```

## Reporting Issues

When reporting issues, please include the following information:

1. Steps to reproduce the issue using this minimal config
2. Any error messages from `:messages`
3. The exact Neovim and Rovo Dev plugin versions
