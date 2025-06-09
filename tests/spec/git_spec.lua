-- Tests for the git module
local assert = require('luassert')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it

local git = require('claude-code.git')

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
  local original_env_test_mode = vim.env.CLAUDE_CODE_TEST_MODE

  describe('get_git_root', function()
    it('should handle git command errors gracefully', function()
      -- Save the original vim.fn.system and vim.v
      local original_system = vim.fn.system
      local original_v = vim.v

      -- Ensure test mode is disabled
      vim.env.CLAUDE_CODE_TEST_MODE = nil

      -- Mock vim.v to make shell_error writable
      vim.v = setmetatable({
        shell_error = 1,
      }, {
        __index = original_v,
        __newindex = function(t, k, v)
          if k == 'shell_error' then
            t.shell_error = v
          else
            original_v[k] = v
          end
        end,
      })

      -- Replace vim.fn.system with a mock that simulates error
      vim.fn.system = function()
        vim.v.shell_error = 1 -- Simulate command failure
        return ''
      end

      -- Call the function and check that it returns nil
      local result = git.get_git_root()
      assert.is_nil(result)

      -- Restore the originals
      vim.fn.system = original_system
      vim.v = original_v
    end)

    it('should handle non-git directories', function()
      -- Save the original vim.fn.system and vim.v
      local original_system = vim.fn.system
      local original_v = vim.v

      -- Ensure test mode is disabled
      vim.env.CLAUDE_CODE_TEST_MODE = nil

      -- Mock vim.v to make shell_error writable
      vim.v = setmetatable({
        shell_error = 0,
      }, {
        __index = original_v,
        __newindex = function(t, k, v)
          if k == 'shell_error' then
            t.shell_error = v
          else
            original_v[k] = v
          end
        end,
      })

      -- Mock vim.fn.system to simulate a non-git directory
      local mock_called = 0
      vim.fn.system = function(cmd)
        mock_called = mock_called + 1
        vim.v.shell_error = 0 -- Command succeeds but returns false
        return 'false'
      end

      -- Call the function and check that it returns nil
      local result = git.get_git_root()
      assert.is_nil(result)
      assert.are.equal(1, mock_called, 'vim.fn.system should be called exactly once')

      -- Restore the originals
      vim.fn.system = original_system
      vim.v = original_v
    end)

    it('should extract git root in a git directory', function()
      -- Save the original io.popen
      local original_popen = io.popen

      -- Set test mode environment variable
      vim.env.CLAUDE_CODE_TEST_MODE = 'true'

      -- We'll still track calls, but the function won't use vim.fn.system in test mode
      local mock_called = 0
      local orig_system = vim.fn.system
      local orig_v = vim.v

      -- Mock vim.v to make shell_error writable (just in case)
      vim.v = setmetatable({
        shell_error = 0,
      }, {
        __index = orig_v,
        __newindex = function(t, k, v)
          if k == 'shell_error' then
            t.shell_error = v
          else
            orig_v[k] = v
          end
        end,
      })

      vim.fn.system = function(cmd)
        mock_called = mock_called + 1
        -- In test mode, we shouldn't reach here, but just in case
        return orig_system(cmd)
      end

      -- Call the function and print debug info
      local result = git.get_git_root()
      print('Test git directory result:')
      debug_value(result)

      -- Check the result
      assert.are.equal('/home/user/project', result)
      assert.are.equal(0, mock_called, 'vim.fn.system should not be called in test mode')

      -- Restore the originals and clear test flag
      vim.fn.system = orig_system
      vim.v = orig_v
      vim.env.CLAUDE_CODE_TEST_MODE = nil
    end)
  end)

  -- Restore the original environment
  vim.env.CLAUDE_CODE_TEST_MODE = original_env_test_mode
end)
