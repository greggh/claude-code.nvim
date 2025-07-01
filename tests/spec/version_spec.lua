-- Tests for the version module
local assert = require('luassert')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it

local version = require('rovo-dev.version')

describe('version', function()
  describe('string', function()
    it('should return the correct version string', function()
      local result = version.string()
      assert.are.equal('0.4.2', result)
      assert.are.equal(
        string.format('%d.%d.%d', version.major, version.minor, version.patch),
        result
      )
    end)
  end)

  describe('version components', function()
    it('should have correct version components', function()
      assert.are.equal(0, version.major)
      assert.are.equal(4, version.minor)
      assert.are.equal(2, version.patch)
    end)
  end)

  describe('print_version', function()
    it('should call vim.notify with correct message', function()
      -- Save original vim.notify
      local original_notify = vim.notify

      -- Create a mock for vim.notify
      local was_called = false
      local message_received = nil
      local level_received = nil

      vim.notify = function(msg, level)
        was_called = true
        message_received = msg
        level_received = level
      end

      -- Call the function
      version.print_version()

      -- Restore original vim.notify
      vim.notify = original_notify

      -- Check if vim.notify was called with correct parameters
      assert.is_true(was_called, 'vim.notify should have been called')
      assert.are.equal('Rovo Dev version: ' .. version.string(), message_received)
      assert.are.equal(vim.log.levels.INFO, level_received)
    end)
  end)
end)
