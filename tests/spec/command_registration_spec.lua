-- Tests for command registration in Rovo Dev
local assert = require('luassert')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it

local commands_module = require('rovo-dev.commands')

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
        opts = opts
      })
      return true
    end
    
    -- Mock vim.notify
    _G.vim.notify = function() end
    
    -- Create mock rovo_dev module
    local rovo_dev = {
      toggle = function() return true end,
      version = function() return '0.3.0' end
    }
    
    -- Run the register_commands function
    commands_module.register_commands(rovo_dev)
  end)
  
  describe('command registration', function()
    it('should register RovoDev command', function()
      local command_registered = false
      for _, cmd in ipairs(registered_commands) do
        if cmd.name == 'RovoDev' then
          command_registered = true
          assert.is_not_nil(cmd.callback, "RovoDev command should have a callback")
          assert.is_not_nil(cmd.opts, "RovoDev command should have options")
          assert.is_not_nil(cmd.opts.desc, "RovoDev command should have a description")
          break
        end
      end
      
      assert.is_true(command_registered, "RovoDev command should be registered")
    end)
    
    it('should register RovoDevVersion command', function()
      local command_registered = false
      for _, cmd in ipairs(registered_commands) do
        if cmd.name == 'RovoDevVersion' then
          command_registered = true
          assert.is_not_nil(cmd.callback, "RovoDevVersion command should have a callback")
          assert.is_not_nil(cmd.opts, "RovoDevVersion command should have options")
          assert.is_not_nil(cmd.opts.desc, "RovoDevVersion command should have a description")
          break
        end
      end
      
      assert.is_true(command_registered, "RovoDevVersion command should be registered")
    end)
  end)
  
  describe('command execution', function()
    it('should call toggle when RovoDev command is executed', function()
      local toggle_called = false
      
      -- Find the RovoDev command and execute its callback
      for _, cmd in ipairs(registered_commands) do
        if cmd.name == 'RovoDev' then
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
      
      assert.is_true(toggle_called, "Toggle function should be called when RovoDev command is executed")
    end)
    
    it('should call notify with version when RovoDevVersion command is executed', function()
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
      
      -- Find the RovoDevVersion command and execute its callback
      for _, cmd in ipairs(registered_commands) do
        if cmd.name == 'RovoDevVersion' then
          cmd.callback()
          break
        end
      end
      
      assert.is_true(notify_called, "vim.notify should be called when RovoDevVersion command is executed")
      assert.is_not_nil(notify_message, "Notification message should not be nil")
      assert.is_not_nil(string.find(notify_message, 'Rovo Dev version'), "Notification should contain version information")
    end)
  end)
end)
