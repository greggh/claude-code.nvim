
# Cli configuration and detection

## Overview

The claude-code.nvim plugin provides flexible configuration options for Claude command-line tool detection and usage. This document details the configuration system, detection logic, and available options.

## Cli detection order

The plugin uses a prioritized detection system to find the Claude command-line tool executable:

### 1. custom path (highest priority)

If a custom command-line tool path is specified in the configuration:

```lua
require('claude-code').setup({
  cli_path = "/custom/path/to/claude"
})

```text

### 2. local installation (preferred default)

Checks for Claude command-line tool at: `~/.claude/local/claude`

- This is the recommended installation location
- Provides user-specific Claude installations
- Avoids PATH conflicts with system installations

### 3. PATH fallback (last resort)

Falls back to `claude` command in system PATH

- Works with global installations
- Compatible with package manager installations

## Configuration options

### Basic configuration

```lua
require('claude-code').setup({
  -- Custom Claude command-line tool path (optional)
  cli_path = nil,  -- Default: auto-detect

  -- Standard Claude command-line tool command (auto-detected if not provided)
  command = "claude",  -- Default: auto-detected

  -- Other configuration options...
})

```text

### Advanced examples

#### Development environment

```lua
-- Use development build of Claude command-line tool
require('claude-code').setup({
  cli_path = "/home/user/dev/claude-code/target/debug/claude"
})

```text

#### Enterprise environment

```lua
-- Use company-specific Claude installation
require('claude-code').setup({
  cli_path = "/opt/company/tools/claude"
})

```text

#### Explicit command override

```lua
-- Override auto-detection completely
require('claude-code').setup({
  command = "/usr/local/bin/claude-beta"
})

```text

## Detection behavior

### Robust validation

The detection system performs comprehensive validation:

1. **File Readability Check** - Ensures the file exists and is readable
2. **Executable Permission Check** - Verifies the file has execute permissions
3. **Fallback Logic** - Tries next option if current fails

### User notifications

The plugin provides clear feedback about command-line tool detection:

#### Successful custom path

```text
Claude Code: Using custom command-line tool at /custom/path/claude

```text

#### Successful local installation

```text
Claude Code: Using local installation at ~/.claude/local/claude

```text

#### Path installation

```text
Claude Code: Using 'claude' from PATH

```text

#### Warning messages

```text
Claude Code: Custom command-line tool path not found: /invalid/path - falling back to default detection
Claude Code: command-line tool not found! Please install Claude Code or set config.command

```text

## Testing

### Test-driven development

The command-line tool detection feature was implemented using TDD with comprehensive test coverage:

#### Test categories

1. **Custom Path Tests** - Validate custom command-line tool path handling
2. **Default Detection Tests** - Test standard detection order
3. **Error Handling Tests** - Verify graceful failure modes
4. **Notification Tests** - Confirm user feedback messages

#### Running cli detection tests

```bash

# Run all tests
nvim --headless -c "lua require('tests.run_tests')" -c "qall"

# Run specific cli detection tests
nvim --headless -c "lua require('tests.run_tests').run_specific('cli_detection_spec')" -c "qall"

```text

### Test scenarios covered

1. **Valid Custom Path** - Custom command-line tool path exists and is executable
2. **Invalid Custom Path** - Custom path doesn't exist, falls back to defaults
3. **Local Installation Present** - Default ~/.claude/local/claude works
4. **PATH Installation Only** - Only system PATH has Claude command-line tool
5. **No command-line tool Found** - No Claude command-line tool available anywhere
6. **Permission Issues** - File exists but not executable
7. **Notification Behavior** - Correct messages for each scenario

## Troubleshooting

### Cli not found

If you see: `Claude Code: command-line tool not found! Please install Claude Code or set config.command`

**Solutions:**

1. Install Claude command-line tool: `curl -sSL https://claude.ai/install.sh | bash`
2. Set custom path: `cli_path = "/path/to/claude"`
3. Override command: `command = "/path/to/claude"`

### Custom path not working

If custom path fails to work:

1. **Check file exists:** `ls -la /your/custom/path`
2. **Verify permissions:** `chmod +x /your/custom/path`
3. **Test execution:** `/your/custom/path --version`

### Permission issues

If file exists but isn't executable:

```bash

# Make executable
chmod +x ~/.claude/local/claude

# Or for custom path
chmod +x /your/custom/path/claude

```text

## Implementation details

### Configuration validation

The plugin validates command-line tool configuration:

```lua
-- Validates cli_path if provided
if config.cli_path ~= nil and type(config.cli_path) ~= 'string' then
  return false, 'cli_path must be a string or nil'
end

```text

### Detection function

Core detection logic:

```lua
local function detect_claude_cli(custom_path)
  -- Check custom path first
  if custom_path then
    if vim.fn.filereadable(custom_path) == 1 and vim.fn.executable(custom_path) == 1 then
      return custom_path
    end
  end

  -- Check local installation
  local local_claude = vim.fn.expand("~/.claude/local/claude")
  if vim.fn.filereadable(local_claude) == 1 and vim.fn.executable(local_claude) == 1 then
    return local_claude
  end

  -- Fall back to PATH
  if vim.fn.executable("claude") == 1 then
    return "claude"
  end

  -- Nothing found
  return nil
end

```text

### Silent mode

For testing and programmatic usage:

```lua
-- Skip command-line tool detection in silent mode
local config = require('claude-code.config').parse_config({}, true)  -- silent = true

```text

## Best practices

### Recommended setup

1. **Use local installation** (`~/.claude/local/claude`) for most users
2. **Use custom path** for development or enterprise environments
3. **Avoid hardcoding command** unless necessary for specific use cases

### Enterprise deployment

```lua
-- Centralized configuration
require('claude-code').setup({
  cli_path = os.getenv("CLAUDE_CLI_PATH") or "/opt/company/claude",
  -- Fallback to company standard path
})

```text

### Development workflow

```lua
-- Switch between versions easily
local claude_version = os.getenv("CLAUDE_VERSION") or "stable"
local cli_paths = {
  stable = "~/.claude/local/claude",
  beta = "/home/user/claude-beta/claude",
  dev = "/home/user/dev/claude-code/target/debug/claude"
}

require('claude-code').setup({
  cli_path = vim.fn.expand(cli_paths[claude_version])
})

```text

## Migration guide

### From previous versions

If you were using command override:

```lua
-- Old approach
require('claude-code').setup({
  command = "/custom/path/claude"
})

-- New recommended approach
require('claude-code').setup({
  cli_path = "/custom/path/claude"  -- Preferred for custom paths
})

```text

The `command` option still works and takes precedence over auto-detection, but `cli_path` is preferred for custom installations as it provides better error handling and user feedback.

### Backward compatibility

- All existing configurations continue to work
- `command` option still overrides auto-detection
- No breaking changes to existing functionality

## Future enhancements

Potential future improvements to command-line tool configuration:

1. **Version Detection** - Automatically detect and display Claude command-line tool version
2. **Health Checks** - Built-in command-line tool health and compatibility checking
3. **Multiple command-line tool Support** - Support for multiple Claude command-line tool versions simultaneously
4. **Auto-Update Integration** - Automatic command-line tool update notifications and handling
5. **Configuration Profiles** - Named configuration profiles for different environments

