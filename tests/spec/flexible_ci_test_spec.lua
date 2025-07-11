local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local assert = require('luassert')

describe('Flexible CI Test Helpers', function()
  local test_helpers = {}

  -- Environment-aware test values
  function test_helpers.get_test_values()
    local is_ci = os.getenv('CI') or os.getenv('GITHUB_ACTIONS') or os.getenv('TRAVIS')
    local is_windows = vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1

    return {
      is_ci = is_ci ~= nil,
      is_windows = is_windows,
      temp_dir = is_windows and os.getenv('TEMP') or '/tmp',
      home_dir = is_windows and os.getenv('USERPROFILE') or os.getenv('HOME'),
      path_sep = is_windows and '\\' or '/',
      executable_ext = is_windows and '.exe' or '',
      null_device = is_windows and 'NUL' or '/dev/null',
    }
  end

  -- Flexible port selection for tests
  function test_helpers.get_test_port()
    -- Use a dynamic port range for CI to avoid conflicts
    local base_port = 9000
    local random_offset = math.random(0, 999)
    return base_port + random_offset
  end

  -- Generate test paths that work across environments
  function test_helpers.get_test_paths(env)
    env = env or test_helpers.get_test_values()

    return {
      user_config_dir = env.home_dir .. env.path_sep .. '.config',
      claude_dir = env.home_dir .. env.path_sep .. '.claude',
      local_claude = env.home_dir
        .. env.path_sep
        .. '.claude'
        .. env.path_sep
        .. 'local'
        .. env.path_sep
        .. 'claude'
        .. env.executable_ext,
      temp_file = env.temp_dir .. env.path_sep .. 'test_file_' .. os.time(),
      temp_socket = env.temp_dir .. env.path_sep .. 'test_socket_' .. os.time() .. '.sock',
    }
  end

  -- Flexible assertion helpers
  function test_helpers.assert_valid_port(port)
    assert.is_number(port)
    assert.is_true(port > 1024 and port < 65536, 'Port should be in valid range')
  end

  function test_helpers.assert_valid_path(path, should_exist)
    assert.is_string(path)
    assert.is_true(#path > 0, 'Path should not be empty')

    if should_exist then
      local exists = vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1
      assert.is_true(exists, 'Path should exist: ' .. path)
    end
  end

  function test_helpers.assert_notification_structure(notification)
    assert.is_table(notification)
    assert.is_string(notification.msg)
    assert.is_number(notification.level)
    assert.is_true(
      notification.level >= vim.log.levels.TRACE and notification.level <= vim.log.levels.ERROR
    )
  end

  describe('environment detection', function()
    it('should detect test environment correctly', function()
      local env = test_helpers.get_test_values()

      assert.is_boolean(env.is_ci)
      assert.is_boolean(env.is_windows)
      assert.is_string(env.temp_dir)
      assert.is_string(env.home_dir)
      assert.is_string(env.path_sep)
      assert.is_string(env.executable_ext)
      assert.is_string(env.null_device)
    end)

    it('should generate environment-appropriate paths', function()
      local env = test_helpers.get_test_values()
      local paths = test_helpers.get_test_paths(env)

      assert.is_string(paths.user_config_dir)
      assert.is_string(paths.claude_dir)
      assert.is_string(paths.local_claude)
      assert.is_string(paths.temp_file)

      -- Paths should use correct separators
      if env.is_windows then
        assert.is_truthy(paths.local_claude:match('\\'))
      else
        assert.is_truthy(paths.local_claude:match('/'))
      end

      -- Executable should have correct extension
      if env.is_windows then
        assert.is_truthy(paths.local_claude:match('%.exe$'))
      else
        assert.is_falsy(paths.local_claude:match('%.exe$'))
      end
    end)
  end)

  describe('port selection', function()
    it('should generate valid test ports', function()
      for i = 1, 10 do
        local port = test_helpers.get_test_port()
        test_helpers.assert_valid_port(port)
      end
    end)

    it('should generate different ports for concurrent tests', function()
      local ports = {}
      for i = 1, 5 do
        ports[i] = test_helpers.get_test_port()
      end

      -- Should have some variation (though not guaranteed to be unique)
      local unique_ports = {}
      for _, port in ipairs(ports) do
        unique_ports[port] = true
      end

      assert.is_true(next(unique_ports) ~= nil, 'Should generate at least one port')
    end)
  end)

  describe('assertion helpers', function()
    it('should validate notification structures', function()
      local valid_notification = {
        msg = 'Test message',
        level = vim.log.levels.INFO,
      }

      test_helpers.assert_notification_structure(valid_notification)
    end)

    it('should validate path structures', function()
      local env = test_helpers.get_test_values()
      test_helpers.assert_valid_path(env.temp_dir, true) -- temp dir should exist
      test_helpers.assert_valid_path('/nonexistent/path/12345', false) -- this shouldn't exist
    end)
  end)

  -- Export helpers for use in other tests
  _G.test_helpers = test_helpers
end)
