-- MCP Hub Integration for Claude Code Neovim
-- Native integration approach inspired by mcphub.nvim

local M = {}

-- MCP Hub server registry
M.registry = {
  servers = {},
  loaded = false,
  config_path = vim.fn.stdpath('data') .. '/claude-code/mcp-hub',
}

-- Default MCP Hub servers
M.default_servers = {
  ['claude-code-neovim'] = {
    command = 'mcp-neovim-server',
    description = 'Official Neovim MCP server integration',
    homepage = 'https://github.com/modelcontextprotocol/servers',
    tags = { 'neovim', 'editor', 'official' },
    native = false,
  },
  ['filesystem'] = {
    command = 'npx',
    args = { '-y', '@modelcontextprotocol/server-filesystem' },
    description = 'Filesystem operations for MCP',
    tags = { 'filesystem', 'files' },
    config_schema = {
      type = 'object',
      properties = {
        allowed_directories = {
          type = 'array',
          items = { type = 'string' },
          description = 'Directories the server can access',
        },
      },
    },
  },
  ['github'] = {
    command = 'npx',
    args = { '-y', '@modelcontextprotocol/server-github' },
    description = 'GitHub API integration',
    tags = { 'github', 'git', 'vcs' },
    requires_config = true,
  },
}

-- Safe notification function
local function notify(msg, level)
  level = level or vim.log.levels.INFO
  vim.schedule(function()
    vim.notify('[MCP Hub] ' .. msg, level)
  end)
end

-- Load server registry from disk
function M.load_registry()
  -- Start with a fresh copy of default servers
  M.registry.servers = vim.deepcopy(M.default_servers)

  local registry_file = M.registry.config_path .. '/registry.json'

  if vim.fn.filereadable(registry_file) == 1 then
    local file = io.open(registry_file, 'r')
    if file then
      local content = file:read('*all')
      file:close()

      local ok, data = pcall(vim.json.decode, content)
      if ok and data then
        -- Merge saved servers into the defaults
        M.registry.servers = vim.tbl_deep_extend('force', M.registry.servers, data)
      end
    end
  end

  -- Ensure claude-code-neovim is always native
  if M.registry.servers['claude-code-neovim'] then
    M.registry.servers['claude-code-neovim'].native = true
  end

  M.registry.loaded = true
  return true
end

-- Save server registry to disk
function M.save_registry()
  -- Ensure directory exists
  vim.fn.mkdir(M.registry.config_path, 'p')

  local registry_file = M.registry.config_path .. '/registry.json'
  local file = io.open(registry_file, 'w')

  if file then
    file:write(vim.json.encode(M.registry.servers))
    file:close()
    return true
  end

  return false
end

-- Register a new MCP server
function M.register_server(name, config)
  if not name or not config then
    notify('Invalid server registration', vim.log.levels.ERROR)
    return false
  end

  -- Validate required fields
  if not config.command then
    notify('Server must have a command', vim.log.levels.ERROR)
    return false
  end

  M.registry.servers[name] = config
  M.save_registry()

  notify('Registered server: ' .. name, vim.log.levels.INFO)
  return true
end

-- Get server configuration
function M.get_server(name)
  if not M.registry.loaded then
    M.load_registry()
  end

  return M.registry.servers[name]
end

-- List all available servers
function M.list_servers()
  if not M.registry.loaded then
    M.load_registry()
  end

  local servers = {}
  for name, config in pairs(M.registry.servers) do
    table.insert(servers, {
      name = name,
      description = config.description,
      tags = config.tags or {},
      native = config.native or false,
      requires_config = config.requires_config or false,
    })
  end

  return servers
end

-- Generate MCP configuration for Claude Code
function M.generate_config(servers, output_path)
  output_path = output_path or vim.fn.getcwd() .. '/.claude.json'

  local config = {
    mcpServers = {},
  }

  -- Add requested servers to config
  for _, server_name in ipairs(servers) do
    local server = M.get_server(server_name)
    if server then
      local server_config = {
        command = server.command,
      }

      if server.args then
        server_config.args = server.args
      end

      -- Handle server-specific configuration
      if server.config then
        server_config = vim.tbl_deep_extend('force', server_config, server.config)
      end

      config.mcpServers[server_name] = server_config
    else
      notify('Server not found: ' .. server_name, vim.log.levels.WARN)
    end
  end

  -- Write configuration
  local file = io.open(output_path, 'w')
  if file then
    file:write(vim.json.encode(config))
    file:close()
    notify('Generated MCP config at: ' .. output_path, vim.log.levels.INFO)
    return true, output_path
  end

  return false
end

-- Interactive server selection
function M.select_servers(callback)
  local servers = M.list_servers()
  local items = {}

  for _, server in ipairs(servers) do
    local tags = table.concat(server.tags or {}, ', ')
    local item = string.format('%-20s %s', server.name, server.description)
    if #tags > 0 then
      item = item .. ' [' .. tags .. ']'
    end
    table.insert(items, item)
  end

  vim.ui.select(items, {
    prompt = 'Select MCP servers to enable:',
    format_item = function(item)
      return item
    end,
  }, function(choice, idx)
    if choice and callback then
      callback(servers[idx].name)
    end
  end)
end

-- Setup MCP Hub integration
function M.setup(opts)
  opts = opts or {}

  -- Load registry on setup
  M.load_registry()

  -- Create commands
  vim.api.nvim_create_user_command('MCPHubList', function()
    local servers = M.list_servers()
    vim.print('Available MCP Servers:')
    vim.print('=====================')
    for _, server in ipairs(servers) do
      local line = '• ' .. server.name
      if server.description then
        line = line .. ' - ' .. server.description
      end
      if server.native then
        line = line .. ' [NATIVE]'
      end
      vim.print(line)
    end
  end, {
    desc = 'List available MCP servers from hub',
  })

  vim.api.nvim_create_user_command('MCPHubInstall', function(cmd)
    local server_name = cmd.args
    if server_name == '' then
      M.select_servers(function(name)
        M.install_server(name)
      end)
    else
      M.install_server(server_name)
    end
  end, {
    desc = 'Install an MCP server from hub',
    nargs = '?',
    complete = function()
      local servers = M.list_servers()
      local names = {}
      for _, server in ipairs(servers) do
        table.insert(names, server.name)
      end
      return names
    end,
  })

  vim.api.nvim_create_user_command('MCPHubGenerate', function()
    -- Let user select multiple servers
    local selected = {}

    local function select_next()
      M.select_servers(function(name)
        table.insert(selected, name)
        vim.ui.select({ 'Add another server', 'Generate config' }, {
          prompt = 'Selected: ' .. table.concat(selected, ', '),
        }, function(choice)
          if choice == 'Add another server' then
            select_next()
          else
            M.generate_config(selected)
          end
        end)
      end)
    end

    select_next()
  end, {
    desc = 'Generate MCP config with selected servers',
  })

  return M
end

-- Install server (placeholder for future package management)
function M.install_server(name)
  local server = M.get_server(name)
  if not server then
    notify('Server not found: ' .. name, vim.log.levels.ERROR)
    return
  end

  if server.native then
    notify(name .. ' is a native server (already installed)', vim.log.levels.INFO)
    return
  end

  -- TODO: Implement actual installation logic
  notify('Installation of ' .. name .. ' not yet implemented', vim.log.levels.WARN)
end

-- Live test functionality
function M.live_test()
  notify('Starting MCP Hub Live Test', vim.log.levels.INFO)

  -- Test 1: Registry operations
  local test_server = {
    command = 'test-mcp-server',
    description = 'Test server for validation',
    tags = { 'test', 'validation' },
    test = true,
  }

  vim.print('\n=== MCP HUB LIVE TEST ===')
  vim.print('1. Testing server registration...')
  local success = M.register_server('test-server', test_server)
  vim.print('   Registration: ' .. (success and '✅ PASS' or '❌ FAIL'))

  -- Test 2: Server retrieval
  vim.print('\n2. Testing server retrieval...')
  local retrieved = M.get_server('test-server')
  vim.print('   Retrieval: ' .. (retrieved and retrieved.test and '✅ PASS' or '❌ FAIL'))

  -- Test 3: List servers
  vim.print('\n3. Testing server listing...')
  local servers = M.list_servers()
  local found = false
  for _, server in ipairs(servers) do
    if server.name == 'test-server' then
      found = true
      break
    end
  end
  vim.print('   Listing: ' .. (found and '✅ PASS' or '❌ FAIL'))

  -- Test 4: Generate config
  vim.print('\n4. Testing config generation...')
  local test_path = vim.fn.tempname() .. '.json'
  local gen_success = M.generate_config({ 'claude-code-neovim', 'test-server' }, test_path)
  vim.print('   Generation: ' .. (gen_success and '✅ PASS' or '❌ FAIL'))

  -- Verify generated config
  if gen_success and vim.fn.filereadable(test_path) == 1 then
    local file = io.open(test_path, 'r')
    if file then
      local content = file:read('*all')
      file:close()
      local config = vim.json.decode(content)
      vim.print('   Config contains:')
      for server_name, _ in pairs(config.mcpServers or {}) do
        vim.print('     • ' .. server_name)
      end
    end
    vim.fn.delete(test_path)
  end

  -- Cleanup test server
  M.registry.servers['test-server'] = nil
  M.save_registry()

  vim.print('\n=== TEST COMPLETE ===')
  vim.print('\nClaude Code can now use MCPHub commands:')
  vim.print('  :MCPHubList - List available servers')
  vim.print('  :MCPHubInstall <server> - Install a server')
  vim.print('  :MCPHubGenerate - Generate config with selected servers')

  return true
end

-- MCP Server Management Functions
local running_servers = {}

-- Start an MCP server
function M.start_server(server_name)
  -- For mcp-neovim-server, we don't actually start it directly
  -- It should be started by Claude Code via MCP configuration
  if server_name == 'mcp-neovim-server' then
    -- Check if mcp-neovim-server is installed
    if vim.fn.executable('mcp-neovim-server') == 0 then
      notify(
        'mcp-neovim-server is not installed. Install with: npm install -g mcp-neovim-server',
        vim.log.levels.ERROR
      )
      return false
    end

    -- Ensure we have a server socket for MCP to connect to
    local socket_path = vim.v.servername
    if socket_path == '' then
      -- Create a socket if none exists
      socket_path = vim.fn.tempname() .. '.sock'
      vim.fn.serverstart(socket_path)
      notify('Started Neovim server socket at: ' .. socket_path, vim.log.levels.INFO)
    end

    -- Generate MCP configuration
    local mcp = require('claude-code.claude_mcp')
    local success, config_path = mcp.generate_config(nil, 'claude-code')

    if success then
      running_servers[server_name] = true
      notify(
        'MCP server configured. Use "claude --mcp-config ' .. config_path .. '" to connect',
        vim.log.levels.INFO
      )
      return true
    else
      notify('Failed to configure MCP server', vim.log.levels.ERROR)
      return false
    end
  else
    notify('Unknown server: ' .. server_name, vim.log.levels.ERROR)
    return false
  end
end

-- Stop an MCP server
function M.stop_server(server_name)
  if running_servers[server_name] then
    running_servers[server_name] = nil
    notify('MCP server configuration cleared', vim.log.levels.INFO)
    return true
  else
    notify('MCP server is not configured', vim.log.levels.WARN)
    return false
  end
end

-- Get server status
function M.server_status(server_name)
  if server_name == 'mcp-neovim-server' then
    local status_parts = {}

    -- Check if server is installed
    if vim.fn.executable('mcp-neovim-server') == 1 then
      table.insert(status_parts, '✓ mcp-neovim-server is installed')
    else
      table.insert(status_parts, '✗ mcp-neovim-server is not installed')
      table.insert(status_parts, '  Install with: npm install -g mcp-neovim-server')
    end

    -- Check if configured
    if running_servers[server_name] then
      table.insert(status_parts, '✓ MCP configuration is active')
    else
      table.insert(status_parts, '✗ MCP configuration is not active')
    end

    -- Check Neovim server socket
    local socket_path = vim.v.servername
    if socket_path ~= '' then
      table.insert(status_parts, '✓ Neovim server socket: ' .. socket_path)
    else
      table.insert(status_parts, '✗ No Neovim server socket')
      table.insert(status_parts, '  Run :ClaudeCodeMCPStart to create one')
    end

    return table.concat(status_parts, '\n')
  else
    return 'Unknown server: ' .. server_name
  end
end

return M
