-- Centralized MCP mocking for tests
local M = {}

-- Mock MCP server state
local mock_server = {
  initialized = false,
  name = 'claude-code-nvim-mock',
  version = '1.0.0',
  protocol_version = '2024-11-05',
  tools = {},
  resources = {},
  pipes = {},
}

-- Mock MCP module
function M.setup_mock()
  -- Create mock MCP module
  local mock_mcp = {
    setup = function(opts)
      mock_server.initialized = true
      return true
    end,

    start = function()
      mock_server.initialized = true
      return true
    end,

    stop = function()
      mock_server.initialized = false
      -- Clean up any mock pipes
      mock_server.pipes = {}
      return true
    end,

    status = function()
      return {
        name = mock_server.name,
        version = mock_server.version,
        protocol_version = mock_server.protocol_version,
        initialized = mock_server.initialized,
        tool_count = vim.tbl_count(mock_server.tools),
        resource_count = vim.tbl_count(mock_server.resources),
      }
    end,

    generate_config = function(path, format)
      -- Mock config generation
      local config = {}
      if format == 'claude-code' then
        config = {
          mcpServers = {
            neovim = {
              command = 'mcp-server-neovim',
              args = {},
            },
          },
        }
      elseif format == 'workspace' then
        config = {
          neovim = {
            command = 'mcp-server-neovim',
            args = {},
          },
        }
      end

      -- Write mock config
      local file = io.open(path, 'w')
      if file then
        file:write(vim.json.encode(config))
        file:close()
        return true, path
      end
      return false, 'Failed to write config'
    end,

    setup_claude_integration = function(config_type)
      return true
    end,
  }

  -- Mock MCP server module
  local mock_mcp_server = {
    start = function()
      mock_server.initialized = true
      return true
    end,

    stop = function()
      mock_server.initialized = false
      mock_server.pipes = {}
    end,

    get_server_info = function()
      return mock_server
    end,
  }

  -- Override require for MCP modules
  local original_require = _G.require
  _G.require = function(modname)
    if modname == 'claude-code.mcp' then
      return mock_mcp
    elseif modname == 'claude-code.mcp.server' then
      return mock_mcp_server
    else
      return original_require(modname)
    end
  end

  return mock_mcp
end

-- Clean up mock
function M.cleanup_mock()
  -- Reset server state
  mock_server.initialized = false
  mock_server.pipes = {}
  mock_server.tools = {}
  mock_server.resources = {}

  -- Clear package cache
  package.loaded['claude-code.mcp'] = nil
  package.loaded['claude-code.mcp.server'] = nil
  package.loaded['claude-code.mcp.tools'] = nil
  package.loaded['claude-code.mcp.resources'] = nil
  package.loaded['claude-code.mcp.hub'] = nil
end

-- Get mock server state for assertions
function M.get_mock_state()
  return vim.deepcopy(mock_server)
end

return M
