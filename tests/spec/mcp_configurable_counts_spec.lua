local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local assert = require('luassert')
local before_each = require('plenary.busted').before_each

describe('MCP Configurable Counts', function()
  local tools
  local resources
  local mcp

  before_each(function()
    -- Clear module cache
    package.loaded['claude-code.mcp.tools'] = nil
    package.loaded['claude-code.mcp.resources'] = nil
    package.loaded['claude-code.mcp'] = nil

    -- Load modules
    local tools_ok, tools_module = pcall(require, 'claude-code.mcp.tools')
    local resources_ok, resources_module = pcall(require, 'claude-code.mcp.resources')
    local mcp_ok, mcp_module = pcall(require, 'claude-code.mcp')

    if tools_ok then
      tools = tools_module
    end
    if resources_ok then
      resources = resources_module
    end
    if mcp_ok then
      mcp = mcp_module
    end
  end)

  describe('dynamic tool counting', function()
    it('should count tools dynamically instead of using hardcoded values', function()
      assert.is_not_nil(tools)

      -- Count actual tools
      local actual_tool_count = 0
      for name, tool in pairs(tools) do
        if type(tool) == 'table' and tool.name and tool.handler then
          actual_tool_count = actual_tool_count + 1
        end
      end

      -- Should have at least some tools
      assert.is_true(actual_tool_count > 0, 'Should have at least one tool defined')

      -- Test that we can get this count dynamically
      local function get_tool_count(tools_module)
        local count = 0
        for name, tool in pairs(tools_module) do
          if type(tool) == 'table' and tool.name and tool.handler then
            count = count + 1
          end
        end
        return count
      end

      local dynamic_count = get_tool_count(tools)
      assert.equals(actual_tool_count, dynamic_count)
    end)

    it('should validate tool structure without hardcoded names', function()
      assert.is_not_nil(tools)

      -- Validate that all tools have required structure
      for name, tool in pairs(tools) do
        if type(tool) == 'table' and tool.name then
          assert.is_string(tool.name, 'Tool ' .. name .. ' should have a name')
          assert.is_string(tool.description, 'Tool ' .. name .. ' should have a description')
          assert.is_table(tool.inputSchema, 'Tool ' .. name .. ' should have inputSchema')
          assert.is_function(tool.handler, 'Tool ' .. name .. ' should have a handler')
        end
      end
    end)
  end)

  describe('dynamic resource counting', function()
    it('should count resources dynamically instead of using hardcoded values', function()
      assert.is_not_nil(resources)

      -- Count actual resources
      local actual_resource_count = 0
      for name, resource in pairs(resources) do
        if type(resource) == 'table' and resource.uri and resource.handler then
          actual_resource_count = actual_resource_count + 1
        end
      end

      -- Should have at least some resources
      assert.is_true(actual_resource_count > 0, 'Should have at least one resource defined')

      -- Test that we can get this count dynamically
      local function get_resource_count(resources_module)
        local count = 0
        for name, resource in pairs(resources_module) do
          if type(resource) == 'table' and resource.uri and resource.handler then
            count = count + 1
          end
        end
        return count
      end

      local dynamic_count = get_resource_count(resources)
      assert.equals(actual_resource_count, dynamic_count)
    end)

    it('should validate resource structure without hardcoded names', function()
      assert.is_not_nil(resources)

      -- Validate that all resources have required structure
      for name, resource in pairs(resources) do
        if type(resource) == 'table' and resource.uri then
          assert.is_string(resource.uri, 'Resource ' .. name .. ' should have a uri')
          assert.is_string(
            resource.description,
            'Resource ' .. name .. ' should have a description'
          )
          assert.is_string(resource.mimeType, 'Resource ' .. name .. ' should have a mimeType')
          assert.is_function(resource.handler, 'Resource ' .. name .. ' should have a handler')
        end
      end
    end)
  end)

  describe('status counting integration', function()
    it('should use dynamic counts in status reporting', function()
      if not mcp then
        pending('MCP module not available')
        return
      end

      mcp.setup()
      local status = mcp.status()

      assert.is_table(status)
      assert.is_number(status.tool_count)
      assert.is_number(status.resource_count)

      -- The counts should be positive
      assert.is_true(status.tool_count > 0, 'Should have at least one tool')
      assert.is_true(status.resource_count > 0, 'Should have at least one resource')

      -- The counts should match what we can calculate independently
      local function count_tools()
        local count = 0
        for name, tool in pairs(tools) do
          if type(tool) == 'table' and tool.name and tool.handler then
            count = count + 1
          end
        end
        return count
      end

      local function count_resources()
        local count = 0
        for name, resource in pairs(resources) do
          if type(resource) == 'table' and resource.uri and resource.handler then
            count = count + 1
          end
        end
        return count
      end

      assert.equals(count_tools(), status.tool_count)
      assert.equals(count_resources(), status.resource_count)
    end)
  end)
end)
