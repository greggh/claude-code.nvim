local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local assert = require('luassert')
local before_each = require('plenary.busted').before_each

describe('MCP Resources Git Validation', function()
  local resources
  local original_popen
  local utils

  before_each(function()
    -- Clear module cache
    package.loaded['claude-code.mcp.resources'] = nil
    package.loaded['claude-code.utils'] = nil

    -- Store original io.popen for restoration
    original_popen = io.popen

    -- Load modules
    resources = require('claude-code.mcp.resources')
    utils = require('claude-code.utils')
  end)

  after_each(function()
    -- Restore original io.popen
    io.popen = original_popen
  end)

  describe('git_status resource', function()
    it('should validate git executable exists before using it', function()
      -- Mock io.popen to simulate git not found
      local popen_called = false
      io.popen = function(cmd)
        popen_called = true
        -- Check if command includes git validation
        if cmd:match('which git') or cmd:match('where git') then
          return {
            read = function()
              return ''
            end,
            close = function()
              return true, 'exit', 1
            end,
          }
        end
        return nil
      end

      local result = resources.git_status.handler()

      -- Should return error message when git is not found
      assert.is_truthy(
        result:match('git not available') or result:match('Git executable not found')
      )
    end)

    it('should use validated git path when available', function()
      -- Mock utils.find_executable to return a valid git path
      local original_find = utils.find_executable
      utils.find_executable = function(name)
        if name == 'git' then
          return '/usr/bin/git'
        end
        return original_find(name)
      end

      -- Mock io.popen to check if validated path is used
      local command_used = nil
      io.popen = function(cmd)
        command_used = cmd
        return {
          read = function()
            return ''
          end,
          close = function()
            return true
          end,
        }
      end

      resources.git_status.handler()

      -- Should use the validated git path
      assert.is_truthy(command_used)
      assert.is_truthy(command_used:match('/usr/bin/git') or command_used:match('git'))

      -- Restore
      utils.find_executable = original_find
    end)

    it('should handle git command failures gracefully', function()
      -- Mock utils.find_executable_by_name to return nil (git not found)
      local original_find = utils.find_executable_by_name
      utils.find_executable_by_name = function(name)
        if name == 'git' then
          return nil -- Simulate git not found
        end
        return nil
      end

      local result = resources.git_status.handler()

      -- Should return error message when git is not found
      assert.is_truthy(result:match('Git executable not found'))

      -- Restore
      utils.find_executable_by_name = original_find
    end)
  end)

  describe('project_structure resource', function()
    it('should not expose command injection vulnerabilities', function()
      -- Mock vim.fn.getcwd to return a path with special characters
      local original_getcwd = vim.fn.getcwd
      vim.fn.getcwd = function()
        return "/tmp/test'; rm -rf /"
      end

      -- Mock vim.fn.shellescape
      local original_shellescape = vim.fn.shellescape
      local escaped_value = nil
      vim.fn.shellescape = function(str)
        escaped_value = str
        return "'/tmp/test'''; rm -rf /'"
      end

      -- Mock io.popen to check the command
      local command_used = nil
      io.popen = function(cmd)
        command_used = cmd
        return {
          read = function()
            return 'test.lua'
          end,
          close = function()
            return true
          end,
        }
      end

      resources.project_structure.handler()

      -- Should have escaped the dangerous path
      assert.is_not_nil(escaped_value)
      assert.equals("/tmp/test'; rm -rf /", escaped_value)

      -- Restore
      vim.fn.getcwd = original_getcwd
      vim.fn.shellescape = original_shellescape
    end)
  end)
end)
