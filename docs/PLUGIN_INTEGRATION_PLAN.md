
# Claude code neovim plugin - mcp integration plan

## Current plugin architecture

The `claude-code.nvim` plugin currently:

- Provides terminal-based integration with Claude Code command-line tool
- Manages Claude instances per git repository
- Handles keymaps and commands for Claude interaction
- Uses `terminal.lua` to spawn and manage Claude command-line tool processes

## Mcp integration goals

Extend the existing plugin to:

1. **Keep existing functionality** - Terminal-based command-line tool interaction remains
2. **Add MCP server** - Expose Neovim capabilities to Claude Code
3. **Seamless experience** - Users get IDE features automatically
4. **Optional feature** - MCP can be disabled if not needed

## Integration architecture

```text
┌─────────────────────────────────────────────────────────┐
│                   claude-code.nvim                       │
├─────────────────────────────────────────────────────────┤
│  Existing Features          │   New MCP Features         │
│  ├─ terminal.lua           │   ├─ mcp/init.lua         │
│  ├─ commands.lua           │   ├─ mcp/server.lua       │
│  ├─ keymaps.lua            │   ├─ mcp/config.lua       │
│  └─ git.lua                │   └─ mcp/health.lua       │
│                            │                             │
│  Claude command-line tool ◄──────────────┼───► MCP Server             │
│     ▲                      │         ▲                   │
│     │                      │         │                   │
│     └──────────────────────┴─────────┘                   │
│              User Commands/Keymaps                       │
└─────────────────────────────────────────────────────────┘

```text

## Implementation steps

### 1. add mcp module to existing plugin

Create `lua/claude-code/mcp/` directory:

```lua
-- lua/claude-code/mcp/init.lua
local M = {}

-- Check if MCP dependencies are available
M.available = function()
  -- Check for Node.js
  local has_node = vim.fn.executable('node') == 1
  -- Check for MCP server binary
  local server_path = vim.fn.stdpath('data') .. '/claude-code/mcp-server/dist/index.js'
  local has_server = vim.fn.filereadable(server_path) == 1

  return has_node and has_server
end

-- Start MCP server for current Neovim instance
M.start = function(config)
  if not M.available() then
    return false, "MCP dependencies not available"
  end

  -- Start server with Neovim socket
  local socket = vim.fn.serverstart()
  -- ... server startup logic

  return true
end

return M

```text

### 2. extend main plugin configuration

Update `lua/claude-code/config.lua`:

```lua
-- Add to default config
mcp = {
  enabled = true,  -- Enable MCP server by default
  auto_start = true,  -- Start server when opening Claude
  server = {
    port = nil,  -- Use stdio by default
    security = {
      allowed_paths = nil,  -- Allow all by default
      require_confirmation = false,
    }
  }
}

```text

### 3. integrate mcp with terminal module

Update `lua/claude-code/terminal.lua`:

```lua
-- In toggle function, after starting Claude command-line tool
if config.mcp.enabled and config.mcp.auto_start then
  local mcp = require('claude-code.mcp')
  local ok, err = mcp.start(config.mcp)
  if ok then
    -- Configure Claude command-line tool to use MCP server
    local cmd = string.format('claude mcp add neovim-local stdio:%s', mcp.get_command())
    vim.fn.jobstart(cmd)
  end
end

```text

### 4. add mcp commands

Update `lua/claude-code/commands.lua`:

```lua
-- New MCP-specific commands
vim.api.nvim_create_user_command('ClaudeCodeMCPStart', function()
  require('claude-code.mcp').start()
end, { desc = 'Start MCP server for Claude Code' })

vim.api.nvim_create_user_command('ClaudeCodeMCPStop', function()
  require('claude-code.mcp').stop()
end, { desc = 'Stop MCP server' })

vim.api.nvim_create_user_command('ClaudeCodeMCPStatus', function()
  require('claude-code.mcp').status()
end, { desc = 'Show MCP server status' })

```text

### 5. health check integration

Create `lua/claude-code/mcp/health.lua`:

```lua
local M = {}

M.check = function()
  local health = vim.health or require('health')

  health.report_start('Claude Code MCP')

  -- Check Node.js
  if vim.fn.executable('node') == 1 then
    health.report_ok('Node.js found')
  else
    health.report_error('Node.js not found', 'Install Node.js for MCP support')
  end

  -- Check MCP server
  local server_path = vim.fn.stdpath('data') .. '/claude-code/mcp-server'
  if vim.fn.isdirectory(server_path) == 1 then
    health.report_ok('MCP server installed')
  else
    health.report_warn('MCP server not installed', 'Run :ClaudeCodeMCPInstall')
  end
end

return M

```text

### 6. installation helper

Add post-install script or command:

```lua
vim.api.nvim_create_user_command('ClaudeCodeMCPInstall', function()
  local install_path = vim.fn.stdpath('data') .. '/claude-code/mcp-server'

  vim.notify('Installing Claude Code MCP server...')

  -- Clone and build MCP server
  local cmd = string.format([[
    mkdir -p %s &&
    cd %s &&
    npm init -y &&
    npm install @modelcontextprotocol/sdk neovim &&
    cp -r %s/mcp-server/* .
  ]], install_path, install_path, vim.fn.stdpath('config') .. '/claude-code.nvim')

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code)
      if code == 0 then
        vim.notify('MCP server installed successfully!')
      else
        vim.notify('Failed to install MCP server', vim.log.levels.ERROR)
      end
    end
  })
end, { desc = 'Install MCP server for Claude Code' })

```text

## User experience

### Default experience (mcp enabled)

1. User runs `:ClaudeCode`
2. Plugin starts Claude command-line tool terminal
3. Plugin automatically starts MCP server
4. Plugin configures Claude to use the MCP server
5. User gets full IDE features without any extra steps

### Opt-out experience

```lua
require('claude-code').setup({
  mcp = {
    enabled = false  -- Disable MCP, use command-line tool only
  }
})

```text

### Manual control

```vim
:ClaudeCodeMCPStart    " Start MCP server manually
:ClaudeCodeMCPStop     " Stop MCP server
:ClaudeCodeMCPStatus   " Check server status

```text

## Benefits of this approach

1. **Non-breaking** - Existing users keep their workflow
2. **Progressive enhancement** - MCP adds features on top
3. **Single plugin** - Users install one thing, get everything
4. **Automatic setup** - MCP "just works" by default
5. **Flexible** - Can disable or manually control if needed

## Next steps

1. Create `lua/claude-code/mcp/` module structure
2. Build the MCP server in `mcp-server/` directory
3. Add installation/build scripts
4. Test integration with existing features
5. Update documentation

