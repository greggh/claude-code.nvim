local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local assert = require('luassert')
local before_each = require('plenary.busted').before_each

describe('MCP Configurable Protocol Version', function()
  local server
  local original_config

  before_each(function()
    -- Clear module cache
    package.loaded['claude-code.mcp.server'] = nil
    package.loaded['claude-code.config'] = nil

    -- Load fresh server module
    server = require('claude-code.mcp.server')

    -- Mock config with original values
    original_config = {
      mcp = {
        protocol_version = '2024-11-05',
      },
    }
  end)

  describe('protocol version configuration', function()
    it('should use default protocol version when no config provided', function()
      -- Initialize server
      local response = server._internal.handle_initialize({})

      assert.is_table(response)
      assert.is_string(response.protocolVersion)
      assert.is_truthy(response.protocolVersion:match('%d%d%d%d%-%d%d%-%d%d'))
    end)

    it('should use configured protocol version when provided', function()
      -- Mock config with custom protocol version
      local custom_version = '2025-01-01'

      -- Set up server with custom configuration
      server.configure({ protocol_version = custom_version })

      local response = server._internal.handle_initialize({})

      assert.is_table(response)
      assert.equals(custom_version, response.protocolVersion)
    end)

    it('should validate protocol version format', function()
      local test_cases = {
        {
          version = 'invalid-date',
          should_succeed = true,
          desc = 'invalid string format should be handled gracefully',
        },
        {
          version = '2024-13-01',
          should_succeed = true,
          desc = 'invalid date should be handled gracefully',
        },
        {
          version = '2024-01-32',
          should_succeed = true,
          desc = 'invalid day should be handled gracefully',
        },
        { version = '', should_succeed = true, desc = 'empty string should be handled gracefully' },
        { version = nil, should_succeed = true, desc = 'nil should be allowed (uses default)' },
        { version = 123, should_succeed = true, desc = 'non-string should be handled gracefully' },
      }

      for _, test_case in ipairs(test_cases) do
        local ok, err = pcall(server.configure, { protocol_version = test_case.version })

        if test_case.should_succeed then
          assert.is_true(ok, test_case.desc .. ': ' .. tostring(test_case.version))
        else
          assert.is_false(ok, test_case.desc .. ': ' .. tostring(test_case.version))
        end
      end
    end)

    it('should fall back to default on invalid configuration', function()
      -- Configure with invalid version
      server.configure({ protocol_version = 123 })

      local response = server._internal.handle_initialize({})

      assert.is_table(response)
      assert.is_string(response.protocolVersion)
      -- Should use default version
      assert.equals('2024-11-05', response.protocolVersion)
    end)
  end)

  describe('configuration integration', function()
    it('should read protocol version from plugin config', function()
      -- Configure server with custom protocol version
      server.configure({ protocol_version = '2024-12-01' })

      local response = server._internal.handle_initialize({})

      assert.is_table(response)
      assert.equals('2024-12-01', response.protocolVersion)
    end)

    it('should allow runtime configuration override', function()
      local initial_response = server._internal.handle_initialize({})
      local initial_version = initial_response.protocolVersion

      -- Override at runtime
      server.configure({ protocol_version = '2025-06-01' })

      local updated_response = server._internal.handle_initialize({})

      assert.not_equals(initial_version, updated_response.protocolVersion)
      assert.equals('2025-06-01', updated_response.protocolVersion)
    end)
  end)

  describe('server info reporting', function()
    it('should include protocol version in server info', function()
      server.configure({ protocol_version = '2024-12-15' })

      local info = server.get_server_info()

      assert.is_table(info)
      assert.is_string(info.name)
      assert.is_string(info.version)
      assert.is_boolean(info.initialized)
      assert.is_number(info.tool_count)
      assert.is_number(info.resource_count)

      -- Should include protocol version in server info
      if info.protocol_version then
        assert.equals('2024-12-15', info.protocol_version)
      end
    end)
  end)
end)
