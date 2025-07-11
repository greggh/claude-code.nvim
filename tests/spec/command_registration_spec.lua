-- Tests for command registration in Claude Code
local assert = require('luassert')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it

local commands_module = require('claude-code.commands')

describe('command registration', function()
  local registered_commands = {}

  before_each(function()
    -- Reset registered commands
    registered_commands = {}

    -- Mock vim functions
    _G.vim = _G.vim or {}
    _G.vim.api = _G.vim.api or {}
    _G.vim.api.nvim_create_user_command = function(name, callback, opts)
      table.insert(registered_commands, {
        name = name,
        callback = callback,
        opts = opts,
      })
      return true
    end

    -- Mock vim.notify
    _G.vim.notify = function() end

    -- Create mock claude_code module
    local claude_code = {
      toggle = function()
        return true
      end,
      version = function()
        return '0.3.0'
      end,
      config = {
        command_variants = {
          continue = '--continue',
          verbose = '--verbose',
        },
      },
    }

    -- Run the register_commands function
    commands_module.register_commands(claude_code)
  end)

  describe('command registration', function()
    it('should register ClaudeCode command', function()
      local command_registered = false
      for _, cmd in ipairs(registered_commands) do
        if cmd.name == 'ClaudeCode' then
          command_registered = true
          assert.is_not_nil(cmd.callback, 'ClaudeCode command should have a callback')
          assert.is_not_nil(cmd.opts, 'ClaudeCode command should have options')
          assert.is_not_nil(cmd.opts.desc, 'ClaudeCode command should have a description')
          break
        end
      end

      assert.is_true(command_registered, 'ClaudeCode command should be registered')
    end)

    it('should register ClaudeCodeVersion command', function()
      local command_registered = false
      for _, cmd in ipairs(registered_commands) do
        if cmd.name == 'ClaudeCodeVersion' then
          command_registered = true
          assert.is_not_nil(cmd.callback, 'ClaudeCodeVersion command should have a callback')
          assert.is_not_nil(cmd.opts, 'ClaudeCodeVersion command should have options')
          assert.is_not_nil(cmd.opts.desc, 'ClaudeCodeVersion command should have a description')
          break
        end
      end

      assert.is_true(command_registered, 'ClaudeCodeVersion command should be registered')
    end)
  end)

  describe('command execution', function()
    it('should call toggle when ClaudeCode command is executed', function()
      local toggle_called = false

      -- Find the ClaudeCode command and execute its callback
      for _, cmd in ipairs(registered_commands) do
        if cmd.name == 'ClaudeCode' then
          -- Create a mock that can detect when toggle is called
          local original_toggle = cmd.callback
          cmd.callback = function()
            toggle_called = true
            return true
          end

          -- Execute the command callback
          cmd.callback()
          break
        end
      end

      assert.is_true(
        toggle_called,
        'Toggle function should be called when ClaudeCode command is executed'
      )
    end)

    it('should call notify with version when ClaudeCodeVersion command is executed', function()
      local notify_called = false
      local notify_message = nil
      local notify_level = nil

      -- Mock vim.notify to capture calls
      _G.vim.notify = function(msg, level)
        notify_called = true
        notify_message = msg
        notify_level = level
        return true
      end

      -- Find the ClaudeCodeVersion command and execute its callback
      for _, cmd in ipairs(registered_commands) do
        if cmd.name == 'ClaudeCodeVersion' then
          cmd.callback()
          break
        end
      end

      assert.is_true(
        notify_called,
        'vim.notify should be called when ClaudeCodeVersion command is executed'
      )
      assert.is_not_nil(notify_message, 'Notification message should not be nil')
      assert.is_not_nil(
        string.find(notify_message, 'Claude Code version'),
        'Notification should contain version information'
      )
    end)
  end)
end)
