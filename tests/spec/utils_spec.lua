local assert = require('luassert')

describe('Utils Module', function()
  local utils

  before_each(function()
    package.loaded['claude-code.utils'] = nil
    utils = require('claude-code.utils')
  end)

  describe('Module Loading', function()
    it('should load utils module', function()
      assert.is_not_nil(utils)
      assert.is_table(utils)
    end)

    it('should have required functions', function()
      assert.is_function(utils.notify)
      assert.is_function(utils.cprint)
      assert.is_function(utils.color)
      assert.is_function(utils.get_working_directory)
      assert.is_function(utils.find_executable)
      assert.is_function(utils.is_headless)
      assert.is_function(utils.ensure_directory)
    end)

    it('should have color constants', function()
      assert.is_table(utils.colors)
      assert.is_string(utils.colors.red)
      assert.is_string(utils.colors.green)
      assert.is_string(utils.colors.yellow)
      assert.is_string(utils.colors.reset)
    end)
  end)

  describe('Color Functions', function()
    it('should colorize text', function()
      local colored = utils.color('red', 'test')
      assert.is_string(colored)
      -- Use plain text search to avoid pattern issues with escape sequences
      assert.is_true(colored:find(utils.colors.red, 1, true) == 1)
      assert.is_true(colored:find(utils.colors.reset, 1, true) > 1)
      assert.is_true(colored:find('test', 1, true) > 1)
    end)

    it('should handle invalid colors gracefully', function()
      local colored = utils.color('invalid', 'test')
      assert.is_string(colored)
      -- Should still contain the text even if color is invalid
      assert.is_true(colored:find('test') > 0)
    end)
  end)

  describe('File System Functions', function()
    it('should find executable files', function()
      -- Test with a command that should exist
      local found = utils.find_executable({ '/bin/sh', '/usr/bin/sh' })
      assert.is_string(found)
    end)

    it('should return nil for non-existent executables', function()
      local found = utils.find_executable({ '/non/existent/path' })
      assert.is_nil(found)
    end)

    it('should create directories', function()
      local temp_dir = vim.fn.tempname()
      local success = utils.ensure_directory(temp_dir)

      assert.is_true(success)
      assert.equals(1, vim.fn.isdirectory(temp_dir))

      -- Cleanup
      vim.fn.delete(temp_dir, 'd')
    end)

    it('should handle existing directories', function()
      local temp_dir = vim.fn.tempname()
      vim.fn.mkdir(temp_dir, 'p')

      local success = utils.ensure_directory(temp_dir)
      assert.is_true(success)

      -- Cleanup
      vim.fn.delete(temp_dir, 'd')
    end)
  end)

  describe('Working Directory', function()
    it('should return working directory', function()
      -- Mock git module for this test
      local mock_git = {
        get_git_root = function()
          return nil
        end,
      }
      local dir = utils.get_working_directory(mock_git)
      assert.is_string(dir)
      assert.is_true(#dir > 0)
      -- Should fall back to getcwd when git returns nil
      assert.equals(vim.fn.getcwd(), dir)
    end)

    it('should work with mock git module', function()
      local mock_git = {
        get_git_root = function()
          return '/mock/git/root'
        end,
      }
      local dir = utils.get_working_directory(mock_git)
      assert.equals('/mock/git/root', dir)
    end)

    it('should fallback when git returns nil', function()
      local mock_git = {
        get_git_root = function()
          return nil
        end,
      }
      local dir = utils.get_working_directory(mock_git)
      assert.equals(vim.fn.getcwd(), dir)
    end)
  end)

  describe('Headless Detection', function()
    it('should detect headless mode correctly', function()
      local is_headless = utils.is_headless()
      assert.is_boolean(is_headless)
      -- In test environment, we're likely in headless mode
      assert.is_true(is_headless)
    end)
  end)

  describe('Notification', function()
    it('should handle notification in headless mode', function()
      -- This test just ensures the function doesn't error
      local success = pcall(utils.notify, 'test message')
      assert.is_true(success)
    end)

    it('should handle notification with options', function()
      local success = pcall(utils.notify, 'test', vim.log.levels.INFO, {
        prefix = 'TEST',
        force_stderr = true,
      })
      assert.is_true(success)
    end)
  end)
end)
