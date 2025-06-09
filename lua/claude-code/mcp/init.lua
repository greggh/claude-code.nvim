local server = require('claude-code.mcp.server')
local tools = require('claude-code.mcp.tools')
local resources = require('claude-code.mcp.resources')
local utils = require('claude-code.utils')

local M = {}

-- Use shared notification utility
local function notify(msg, level)
  utils.notify(msg, level, { prefix = 'MCP' })
end

-- Default MCP configuration
local default_config = {
  mcpServers = {
    neovim = {
      command = nil, -- Will be auto-detected
    },
  },
}

-- Register all tools
local function register_tools()
  for name, tool in pairs(tools) do
    server.register_tool(tool.name, tool.description, tool.inputSchema, tool.handler)
  end
end

-- Register all resources
local function register_resources()
  for name, resource in pairs(resources) do
    server.register_resource(
      name,
      resource.uri,
      resource.description,
      resource.mimeType,
      resource.handler
    )
  end
end

-- Initialize MCP server
function M.setup(config)
  register_tools()
  register_resources()

  -- Only show MCP initialization message if startup notifications are enabled
  if config and config.startup_notification and config.startup_notification.enabled then
    notify('Claude Code MCP server initialized', vim.log.levels.INFO)
  end
end

-- Start MCP server
function M.start()
  if not server.start() then
    notify('Failed to start Claude Code MCP server', vim.log.levels.ERROR)
    return false
  end

  notify('Claude Code MCP server started', vim.log.levels.INFO)
  return true
end

-- Stop MCP server
function M.stop()
  server.stop()
  notify('Claude Code MCP server stopped', vim.log.levels.INFO)
end

-- Get server status
function M.status()
  return server.get_server_info()
end

-- Command to start server in standalone mode
function M.start_standalone()
  -- This function can be called from a shell script
  M.setup()
  return M.start()
end

-- Generate Claude Code MCP configuration
function M.generate_config(output_path, config_type)
  -- Default to workspace-specific MCP config (VS Code standard)
  config_type = config_type or 'workspace'

  if config_type == 'workspace' then
    output_path = output_path or vim.fn.getcwd() .. '/.vscode/mcp.json'
  elseif config_type == 'claude-code' then
    output_path = output_path or vim.fn.getcwd() .. '/.claude.json'
  else
    output_path = output_path or vim.fn.getcwd() .. '/mcp-config.json'
  end

  -- Use mcp-neovim-server (should be installed globally via npm)
  local mcp_server_command = 'mcp-neovim-server'

  -- Check if the server is installed
  if vim.fn.executable(mcp_server_command) == 0 and not os.getenv('CLAUDE_CODE_TEST_MODE') then
    notify(
      'mcp-neovim-server not found. Install with: npm install -g mcp-neovim-server',
      vim.log.levels.ERROR
    )
    return false
  end

  local config
  if config_type == 'claude-code' then
    -- Claude Code CLI format
    config = {
      mcpServers = {
        neovim = {
          command = mcp_server_command,
        },
      },
    }
  else
    -- VS Code workspace format (default)
    config = {
      neovim = {
        command = mcp_server_command,
      },
    }
  end

  -- Ensure output directory exists
  local output_dir = vim.fn.fnamemodify(output_path, ':h')
  if vim.fn.isdirectory(output_dir) == 0 then
    vim.fn.mkdir(output_dir, 'p')
  end

  local json_str = vim.json.encode(config)

  -- Write to file
  local file = io.open(output_path, 'w')
  if not file then
    notify('Failed to create MCP config at: ' .. output_path, vim.log.levels.ERROR)
    return false
  end

  file:write(json_str)
  file:close()

  notify('MCP config generated at: ' .. output_path, vim.log.levels.INFO)
  return true, output_path
end

-- Setup Claude Code integration helper
function M.setup_claude_integration(config_type)
  config_type = config_type or 'claude-code'
  local success, path = M.generate_config(nil, config_type)

  if success then
    local usage_instruction
    if config_type == 'claude-code' then
      usage_instruction = 'claude --mcp-config '
        .. path
        .. ' --allowedTools "mcp__neovim__*" "Your prompt here"'
    elseif config_type == 'workspace' then
      usage_instruction = 'VS Code: Install MCP extension and reload workspace'
    else
      usage_instruction = 'Use with your MCP-compatible client: ' .. path
    end

    notify([[
MCP configuration created at: ]] .. path .. [[

Usage:
  ]] .. usage_instruction .. [[

Available tools:
  mcp__neovim__vim_buffer    - Read/write buffer contents
  mcp__neovim__vim_command   - Execute Vim commands
  mcp__neovim__vim_edit      - Edit text in buffers
  mcp__neovim__vim_status    - Get editor status
  mcp__neovim__vim_window    - Manage windows
  mcp__neovim__vim_mark      - Manage marks
  mcp__neovim__vim_register  - Access registers
  mcp__neovim__vim_visual    - Visual selections
  mcp__neovim__get_selection - Get current/last visual selection

Available resources:
  mcp__neovim__current_buffer - Current buffer content
  mcp__neovim__buffer_list    - List of open buffers
  mcp__neovim__project_structure - Project file tree
  mcp__neovim__git_status     - Git repository status
  mcp__neovim__lsp_diagnostics - LSP diagnostics
  mcp__neovim__vim_options    - Vim configuration options
  mcp__neovim__visual_selection - Current visual selection
]], vim.log.levels.INFO)
  end

  return success
end

return M
