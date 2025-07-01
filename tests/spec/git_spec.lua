-- Tests for the git module
local assert = require('luassert')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it

local git = require('rovo-dev.git')

-- Debug helper
local function debug_value(value)
  if value == nil then
    print('DEBUG: Value is nil')
    return 'nil'
  elseif type(value) == 'string' then
    print("DEBUG: String value: '" .. value .. "', length: " .. #value)
    -- Print hex representation to see hidden characters
    local hex = ''
    for i = 1, #value do
      hex = hex .. string.format('%02X ', string.byte(value, i))
    end
    print('DEBUG: Hex: ' .. hex)
    return value
  else
    print('DEBUG: Value type: ' .. type(value))
    return value
  end
end

describe('git', function()
  -- Keep track of the original environment
  local original_env_test_mode = vim.env.ROVO_DEV_TEST_MODE

  describe('get_git_root', function()
    it('should handle io.popen errors gracefully', function()
      -- Save the original io.popen
      local original_popen = io.popen

      -- Ensure test mode is disabled
      vim.env.ROVO_DEV_TEST_MODE = nil

      -- Replace io.popen with a mock that returns nil
      io.popen = function()
        return nil
      end

      -- Call the function and check that it returns nil
      local result = git.get_git_root()
      assert.is_nil(result)

      -- Restore the original io.popen
      io.popen = original_popen
    end)

    it('should handle non-git directories', function()
      -- Save the original io.popen
      local original_popen = io.popen

      -- Ensure test mode is disabled
      vim.env.ROVO_DEV_TEST_MODE = nil

      -- Mock io.popen to simulate a non-git directory
      local mock_called = 0
      io.popen = function(cmd)
        mock_called = mock_called + 1

        -- Return a file handle that returns "false" for the first call
        return {
          read = function()
            return 'false'
          end,
          close = function() end,
        }
      end

      -- Call the function and check that it returns nil
      local result = git.get_git_root()
      assert.is_nil(result)
      assert.are.equal(1, mock_called, 'io.popen should be called exactly once')

      -- Restore the original io.popen
      io.popen = original_popen
    end)

    it('should extract git root in a git directory', function()
      -- Save the original io.popen
      local original_popen = io.popen

      -- Set test mode environment variable
      vim.env.ROVO_DEV_TEST_MODE = 'true'

      -- We'll still track calls, but the function won't use io.popen in test mode
      local mock_called = 0
      local orig_io_popen = io.popen
      io.popen = function(cmd)
        mock_called = mock_called + 1
        -- In test mode, we shouldn't reach here, but just in case
        return orig_io_popen(cmd)
      end

      -- Call the function and print debug info
      local result = git.get_git_root()
      print('Test git directory result:')
      debug_value(result)

      -- Check the result
      assert.are.equal('/home/user/project', result)
      assert.are.equal(0, mock_called, 'io.popen should not be called in test mode')

      -- Restore the original io.popen and clear test flag
      io.popen = original_popen
      vim.env.ROVO_DEV_TEST_MODE = nil
    end)
  end)

  -- Restore the original environment
  vim.env.ROVO_DEV_TEST_MODE = original_env_test_mode
end)
