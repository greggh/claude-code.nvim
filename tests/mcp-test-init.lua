-- Minimal configuration for MCP testing only
-- Used specifically for MCP integration tests

-- Basic settings
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undofile = false
vim.opt.hidden = true

-- Detect the plugin directory
local function get_plugin_path()
  local debug_info = debug.getinfo(1, 'S')
  local source = debug_info.source

  if string.sub(source, 1, 1) == '@' then
    source = string.sub(source, 2)
    if string.find(source, '/tests/mcp%-test%-init%.lua$') then
      local plugin_dir = string.gsub(source, '/tests/mcp%-test%-init%.lua$', '')
      return plugin_dir
    else
      return vim.fn.getcwd()
    end
  end
  return vim.fn.getcwd()
end

local plugin_dir = get_plugin_path()

-- Add the plugin directory to runtimepath
vim.opt.runtimepath:append(plugin_dir)

-- Set environment variable for development path
vim.env.CLAUDE_CODE_DEV_PATH = plugin_dir

-- Set test mode to skip mcp-neovim-server check
vim.fn.setenv('CLAUDE_CODE_TEST_MODE', '1')

print('MCP test environment loaded from: ' .. plugin_dir)
