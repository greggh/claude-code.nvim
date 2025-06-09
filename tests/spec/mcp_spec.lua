local assert = require('luassert')

describe('MCP Integration', function()
  local mcp

  before_each(function()
    -- Reset package loaded state
    package.loaded['claude-code.mcp'] = nil
    package.loaded['claude-code.mcp.init'] = nil
    package.loaded['claude-code.mcp.tools'] = nil
    package.loaded['claude-code.mcp.resources'] = nil
    package.loaded['claude-code.mcp.server'] = nil
    package.loaded['claude-code.mcp.hub'] = nil

    -- Load the MCP module
    local ok, module = pcall(require, 'claude-code.mcp')
    if ok then
      mcp = module
    end
  end)

  describe('Module Loading', function()
    it('should load MCP module without errors', function()
      assert.is_not_nil(mcp)
      assert.is_table(mcp)
    end)

    it('should have required functions', function()
      assert.is_function(mcp.setup)
      assert.is_function(mcp.start)
      assert.is_function(mcp.stop)
      assert.is_function(mcp.status)
      assert.is_function(mcp.generate_config)
      assert.is_function(mcp.setup_claude_integration)
    end)
  end)

  describe('Configuration Generation', function()
    it('should generate claude-code config format', function()
      local temp_file = vim.fn.tempname() .. '.json'
      local success, path = mcp.generate_config(temp_file, 'claude-code')

      assert.is_true(success)
      assert.equals(temp_file, path)
      assert.equals(1, vim.fn.filereadable(temp_file))

      -- Verify JSON structure
      local file = io.open(temp_file, 'r')
      local content = file:read('*all')
      file:close()

      local config = vim.json.decode(content)
      assert.is_table(config.mcpServers)
      assert.is_table(config.mcpServers.neovim)
      assert.is_string(config.mcpServers.neovim.command)

      -- Cleanup
      vim.fn.delete(temp_file)
    end)

    it('should generate workspace config format', function()
      local temp_file = vim.fn.tempname() .. '.json'
      local success, path = mcp.generate_config(temp_file, 'workspace')

      assert.is_true(success)

      local file = io.open(temp_file, 'r')
      local content = file:read('*all')
      file:close()

      local config = vim.json.decode(content)
      assert.is_table(config.neovim)
      assert.is_string(config.neovim.command)

      -- Cleanup
      vim.fn.delete(temp_file)
    end)
  end)

  describe('Server Management', function()
    it('should initialize without errors', function()
      local success = pcall(mcp.setup)
      assert.is_true(success)
    end)

    it('should return server status', function()
      mcp.setup()
      local status = mcp.status()

      assert.is_table(status)
      assert.is_string(status.name)
      assert.is_string(status.version)
      assert.is_boolean(status.initialized)
      assert.is_number(status.tool_count)
      assert.is_number(status.resource_count)
    end)
  end)
end)

describe('MCP Tools', function()
  local tools

  before_each(function()
    package.loaded['claude-code.mcp.tools'] = nil
    local ok, module = pcall(require, 'claude-code.mcp.tools')
    if ok then
      tools = module
    end
  end)

  it('should load tools module', function()
    assert.is_not_nil(tools)
    assert.is_table(tools)
  end)

  it('should have expected tools', function()
    -- Count actual tools and validate their structure
    local tool_count = 0
    local tool_names = {}

    for name, tool in pairs(tools) do
      if type(tool) == 'table' and tool.name and tool.handler then
        tool_count = tool_count + 1
        table.insert(tool_names, name)

        assert.is_string(tool.name, 'Tool ' .. name .. ' should have a name')
        assert.is_string(tool.description, 'Tool ' .. name .. ' should have a description')
        assert.is_table(tool.inputSchema, 'Tool ' .. name .. ' should have inputSchema')
        assert.is_function(tool.handler, 'Tool ' .. name .. ' should have a handler')
      end
    end

    -- Should have at least some tools (flexible count)
    assert.is_true(tool_count > 0, 'Should have at least one tool defined')

    -- Verify we have some expected core tools (but not exhaustive)
    local has_buffer_tool = false
    local has_command_tool = false

    for _, name in ipairs(tool_names) do
      if name:match('buffer') then
        has_buffer_tool = true
      end
      if name:match('command') then
        has_command_tool = true
      end
    end

    assert.is_true(has_buffer_tool, 'Should have at least one buffer-related tool')
    assert.is_true(has_command_tool, 'Should have at least one command-related tool')
  end)

  it('should have valid tool schemas', function()
    for tool_name, tool in pairs(tools) do
      assert.is_table(tool.inputSchema)
      assert.equals('object', tool.inputSchema.type)
      assert.is_table(tool.inputSchema.properties)
    end
  end)
end)

describe('MCP Resources', function()
  local resources

  before_each(function()
    package.loaded['claude-code.mcp.resources'] = nil
    local ok, module = pcall(require, 'claude-code.mcp.resources')
    if ok then
      resources = module
    end
  end)

  it('should load resources module', function()
    assert.is_not_nil(resources)
    assert.is_table(resources)
  end)

  it('should have expected resources', function()
    -- Count actual resources and validate their structure
    local resource_count = 0
    local resource_names = {}

    for name, resource in pairs(resources) do
      if type(resource) == 'table' and resource.uri and resource.handler then
        resource_count = resource_count + 1
        table.insert(resource_names, name)

        assert.is_string(resource.uri, 'Resource ' .. name .. ' should have a uri')
        assert.is_string(resource.description, 'Resource ' .. name .. ' should have a description')
        assert.is_string(resource.mimeType, 'Resource ' .. name .. ' should have a mimeType')
        assert.is_function(resource.handler, 'Resource ' .. name .. ' should have a handler')
      end
    end

    -- Should have at least some resources (flexible count)
    assert.is_true(resource_count > 0, 'Should have at least one resource defined')

    -- Verify we have some expected core resources (but not exhaustive)
    local has_buffer_resource = false
    local has_git_resource = false

    for _, name in ipairs(resource_names) do
      if name:match('buffer') then
        has_buffer_resource = true
      end
      if name:match('git') then
        has_git_resource = true
      end
    end

    assert.is_true(has_buffer_resource, 'Should have at least one buffer-related resource')
    assert.is_true(has_git_resource, 'Should have at least one git-related resource')
  end)
end)

describe('MCP Hub', function()
  local hub

  before_each(function()
    package.loaded['claude-code.mcp.hub'] = nil
    local ok, module = pcall(require, 'claude-code.mcp.hub')
    if ok then
      hub = module
    end
  end)

  it('should load hub module', function()
    assert.is_not_nil(hub)
    assert.is_table(hub)
  end)

  it('should have required functions', function()
    assert.is_function(hub.setup)
    assert.is_function(hub.register_server)
    assert.is_function(hub.get_server)
    assert.is_function(hub.list_servers)
    assert.is_function(hub.generate_config)
  end)

  it('should list default servers', function()
    local servers = hub.list_servers()
    assert.is_table(servers)
    assert.is_true(#servers > 0)

    -- Check for claude-code-neovim server
    local found_native = false
    for _, server in ipairs(servers) do
      if server.name == 'claude-code-neovim' then
        found_native = true
        assert.is_true(server.native)
        break
      end
    end
    assert.is_true(found_native, 'Should have claude-code-neovim server')
  end)

  it('should register and retrieve servers', function()
    local test_server = {
      command = 'test-command',
      description = 'Test server',
      tags = { 'test' },
    }

    local success = hub.register_server('test-server', test_server)
    assert.is_true(success)

    local retrieved = hub.get_server('test-server')
    assert.is_table(retrieved)
    assert.equals('test-command', retrieved.command)
    assert.equals('Test server', retrieved.description)
  end)
end)
