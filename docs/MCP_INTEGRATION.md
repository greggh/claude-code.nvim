
# Mcp integration with claude code cli

## Overview

Claude Code Neovim plugin implements Model Context Protocol (MCP) server capabilities that enable seamless integration with Claude Code command-line tool. This document details the MCP integration specifics, configuration options, and usage instructions.

## Mcp server implementation

The plugin provides a pure Lua HTTP server that implements the following MCP endpoints:

- `GET /mcp/config` - Returns server metadata, available tools, and resources
- `POST /mcp/session` - Creates a new session for the Claude Code command-line tool
- `DELETE /mcp/session/{session_id}` - Terminates an active session

## Tool naming convention

All tools follow the Claude/Anthropic naming convention:

```text
mcp__{server-name}__{tool-name}

```text

For example:

- `mcp__neovim-lua__vim_buffer`
- `mcp__neovim-lua__vim_command`
- `mcp__neovim-lua__vim_edit`

This naming convention ensures that tools are properly identified and can be allowed via the `--allowedTools` command-line tool flag.

## Available tools

| Tool | Description | Schema |
|------|-------------|--------|
| `mcp__neovim-lua__vim_buffer` | Read/write buffer content | `{ "filename": "string" }` |
| `mcp__neovim-lua__vim_command` | Execute Vim commands | `{ "command": "string" }` |
| `mcp__neovim-lua__vim_status` | Get current editor status | `{}` |
| `mcp__neovim-lua__vim_edit` | Edit buffer content | `{ "filename": "string", "mode": "string", "text": "string" }` |
| `mcp__neovim-lua__vim_window` | Manage windows | `{ "action": "string", "filename": "string?" }` |
| `mcp__neovim-lua__analyze_related` | Analyze related files | `{ "filename": "string", "depth": "number?" }` |
| `mcp__neovim-lua__search_files` | Search files by pattern | `{ "pattern": "string", "content_pattern": "string?" }` |

## Available resources

| Resource URI | Description | MIME Type |
|--------------|-------------|-----------|
| `mcp__neovim-lua://current-buffer` | Contents of the current buffer | text/plain |
| `mcp__neovim-lua://buffers` | List of all open buffers | application/json |
| `mcp__neovim-lua://project` | Project structure and files | application/json |
| `mcp__neovim-lua://git-status` | Git status of current repository | application/json |
| `mcp__neovim-lua://lsp-diagnostics` | LSP diagnostics for workspace | application/json |

## Starting the mcp server

Start the MCP server using the Neovim command:

```vim
:ClaudeCodeMCPStart

```text

Or programmatically in Lua:

```lua
require('claude-code.mcp').start()

```text

The server automatically starts on `127.0.0.1:27123` by default, but can be configured through options.

## Using with claude code cli

### Basic usage

```sh
claude code --mcp-config http://localhost:27123/mcp/config -e "Describe the current buffer"

```text

### Restricting tool access

```sh
claude code --mcp-config http://localhost:27123/mcp/config --allowedTools mcp__neovim-lua__vim_buffer -e "What's in the buffer?"

```text

### Using with recent claude models

```sh
claude code --mcp-config http://localhost:27123/mcp/config --model claude-3-opus-20240229 -e "Help me refactor this Neovim plugin"

```text

## Session management

Each interaction with Claude Code command-line tool creates a unique session that can be tracked by the plugin. Sessions include:

- Session ID
- Creation timestamp
- Last activity time
- Client IP address

Sessions can be stopped manually using the DELETE endpoint or will timeout after a period of inactivity.

## Permissions model

The plugin implements a permissions model that respects the `--allowedTools` flag from the command-line tool. When specified, only the tools explicitly allowed will be executed. This provides a security boundary for sensitive operations.

## Troubleshooting

### Connection issues

If you encounter connection issues:

1. Verify the MCP server is running using `:ClaudeCodeMCPStatus`
2. Check firewall settings to ensure port 27123 is open
3. Try restarting the MCP server with `:ClaudeCodeMCPRestart`

### Permission issues

If tool execution fails due to permissions:

1. Verify the tool name matches exactly the expected format
2. Check that the tool is included in `--allowedTools` if that flag is used
3. Review the plugin logs for specific error messages

## Advanced configuration

### Custom port

```lua
require('claude-code').setup({
  mcp = {
    http_server = {
      port = 8080
    }
  }
})

```text

### Custom host

```lua
require('claude-code').setup({
  mcp = {
    http_server = {
      host = "0.0.0.0"  -- Allow external connections
    }
  }
})

```text

### Session timeout

```lua
require('claude-code').setup({
  mcp = {
    session_timeout_minutes = 60  -- Default: 30
  }
})

```text

