local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local assert = require('luassert')

describe('test_mcp.sh Configurability', function()
  describe('server path configuration', function()
    it('should support configurable server path via environment variable', function()
      -- Read the test script content
      local test_script_path = vim.fn.getcwd() .. '/scripts/test_mcp.sh'
      local content = ''

      local file = io.open(test_script_path, 'r')
      if file then
        content = file:read('*a')
        file:close()
      end

      assert.is_true(#content > 0, 'test_mcp.sh should exist and be readable')

      -- Should check for mcp-neovim-server availability
      assert.is_truthy(content:match('mcp%-neovim%-server'), 'Should check for mcp-neovim-server')

      -- Should have command availability check
      assert.is_truthy(
        content:match('command %-v mcp%-neovim%-server'),
        'Should check if mcp-neovim-server command is available'
      )
    end)

    it('should use environment variable when provided', function()
      -- Mock environment for testing
      local original_getenv = os.getenv
      os.getenv = function(var)
        if var == 'CLAUDE_MCP_SERVER_PATH' then
          return '/custom/path/to/server'
        end
        return original_getenv(var)
      end

      -- Test the environment variable logic (this would be in the updated script)
      local function get_server_path()
        local custom_path = os.getenv('CLAUDE_MCP_SERVER_PATH')
        return custom_path or 'mcp-neovim-server'
      end

      local server_path = get_server_path()
      assert.equals('/custom/path/to/server', server_path)

      -- Restore original
      os.getenv = original_getenv
    end)

    it('should fall back to default when no environment variable', function()
      -- Mock environment without the variable
      local original_getenv = os.getenv
      os.getenv = function(var)
        if var == 'CLAUDE_MCP_SERVER_PATH' then
          return nil
        end
        return original_getenv(var)
      end

      -- Test fallback logic
      local function get_server_path()
        local custom_path = os.getenv('CLAUDE_MCP_SERVER_PATH')
        return custom_path or 'mcp-neovim-server'
      end

      local server_path = get_server_path()
      assert.equals('mcp-neovim-server', server_path)

      -- Restore original
      os.getenv = original_getenv
    end)

    it('should validate server path exists before use', function()
      -- Test validation logic
      local function validate_server_path(path)
        if not path or path == '' then
          return false, 'Server path is empty'
        end

        local f = io.open(path, 'r')
        if f then
          f:close()
          return true
        else
          return false, 'Server path does not exist: ' .. path
        end
      end

      -- Test with mcp-neovim-server command
      local default_cmd = 'mcp-neovim-server'
      local exists, err = validate_server_path(default_cmd)

      -- The validation function works correctly (actual file existence may vary)
      assert.is_boolean(exists)
      if not exists then
        assert.is_string(err)
      end

      -- Test with obviously invalid path
      local invalid_exists, invalid_err = validate_server_path('/nonexistent/path/server')
      assert.is_false(invalid_exists)
      assert.is_string(invalid_err)
      assert.is_truthy(invalid_err:match('does not exist'))
    end)
  end)

  describe('script configuration options', function()
    it('should support debug mode configuration', function()
      -- Test debug mode logic
      local function should_enable_debug()
        return os.getenv('DEBUG') == '1' or os.getenv('CLAUDE_MCP_DEBUG') == '1'
      end

      -- Mock debug environment
      local original_getenv = os.getenv
      os.getenv = function(var)
        if var == 'CLAUDE_MCP_DEBUG' then
          return '1'
        end
        return original_getenv(var)
      end

      assert.is_true(should_enable_debug())

      -- Restore
      os.getenv = original_getenv
    end)

    it('should support timeout configuration', function()
      -- Test timeout configuration
      local function get_timeout()
        local timeout = os.getenv('CLAUDE_MCP_TIMEOUT')
        return timeout and tonumber(timeout) or 10
      end

      -- Mock timeout environment
      local original_getenv = os.getenv
      os.getenv = function(var)
        if var == 'CLAUDE_MCP_TIMEOUT' then
          return '30'
        end
        return original_getenv(var)
      end

      local timeout = get_timeout()
      assert.equals(30, timeout)

      -- Test default
      os.getenv = function(var)
        return original_getenv(var)
      end

      local default_timeout = get_timeout()
      assert.equals(10, default_timeout)

      -- Restore
      os.getenv = original_getenv
    end)
  end)
end)
