
# Claude code neovim plugin self-test suite

This document describes the self-test functionality included with the Claude Code Neovim plugin. These tests are designed to verify that the plugin is working correctly and to demonstrate its capabilities.

## Quick start

Run all tests with:

```vim
:ClaudeCodeTestAll

```text

This will execute all tests and provide a comprehensive report on plugin functionality.

## Available commands

| Command | Description |
|---------|-------------|
| `:ClaudeCodeSelfTest` | Run general functionality tests |
| `:ClaudeCodeMCPTest` | Run MCP server-specific tests |
| `:ClaudeCodeTestAll` | Run all tests and show summary |
| `:ClaudeCodeDemo` | Show interactive demo instructions |

## What's being tested

### General functionality

The `:ClaudeCodeSelfTest` command tests:

- Buffer reading and writing capabilities
- Command execution
- Project structure awareness
- Git status information access
- LSP diagnostic information access
- Mark setting functionality
- Vim options access

### Mcp server functionality

The `:ClaudeCodeMCPTest` command tests:

- Starting the MCP server
- Checking server status
- Available MCP resources
- Available MCP tools
- Configuration file generation

## Live tests with claude

The self-test suite is particularly useful when used with Claude via the MCP interface, as it allows Claude to verify its own connectivity and capabilities within Neovim.

### Example usage scenarios

1. **Verify Installation**:
   Ask Claude to run the tests to verify that the plugin was installed correctly.

2. **Diagnose Issues**:
   If you're experiencing problems, ask Claude to run specific tests to help identify where things are going wrong.

3. **Demonstrate Capabilities**:
   Use the demo command to showcase what Claude can do with the plugin.

4. **Tutorial Mode**:
   Ask Claude to explain each test and what it's checking, as an educational tool.

### Example prompts for claude

- "Please run the self-test and explain what each test is checking."
- "Can you verify if the MCP server is working correctly?"
- "Show me a demonstration of how you can interact with Neovim through the MCP interface."
- "What features of this plugin are working properly and which ones need attention?"

## Interactive demo

The `:ClaudeCodeDemo` command displays instructions for an interactive demonstration of plugin features. This is useful for:

1. Learning how to use the plugin
2. Verifying functionality manually
3. Demonstrating the plugin to others
4. Testing specific features in isolation

## Extending the tests

The test suite is designed to be extensible. You can add your own tests by:

1. Adding new test functions to `test/self_test.lua` or `test/self_test_mcp.lua`
2. Adding new entries to the `results` table
3. Calling your new test functions in the `run_all_tests` function

## Troubleshooting

If tests are failing, check:

1. **Plugin Installation**: Verify the plugin is properly installed and loaded
2. **Dependencies**: Check that all required dependencies are installed
3. **Configuration**: Verify your plugin configuration
4. **Permissions**: Ensure file permissions allow reading/writing
5. **LSP Setup**: For LSP tests, verify that language servers are configured

For MCP-specific issues:

1. Check that the MCP server is not already running elsewhere
2. Verify network ports are available
3. Check Neovim has permissions to bind to network ports

## Using test results

The test results can be used to:

1. Verify plugin functionality after installation
2. Check for regressions after updates
3. Diagnose issues with specific features
4. Demonstrate plugin capabilities to others
5. Learn about available features

---

* This self-test suite was designed and implemented by Claude as a demonstration of the Claude Code Neovim plugin's MCP capabilities.*

