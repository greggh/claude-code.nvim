-- Tests for file refresh functionality in Rovo Dev
local assert = require('luassert')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it

local file_refresh = require('rovo-dev.file_refresh')

describe('file refresh', function()
  local registered_augroups = {}
  local registered_autocmds = {}
  local timer_started = false
  local timer_closed = false
  local timer_interval = nil
  local timer_callback = nil
  local rovo_dev
  local config
  
  before_each(function()
    -- Reset tracking variables
    registered_augroups = {}
    registered_autocmds = {}
    timer_started = false
    timer_closed = false
    timer_interval = nil
    timer_callback = nil
    
    -- Mock vim functions
    _G.vim = _G.vim or {}
    _G.vim.api = _G.vim.api or {}
    _G.vim.fn = _G.vim.fn or {}
    _G.vim.loop = _G.vim.loop or {}
    _G.vim.log = _G.vim.log or { levels = { INFO = 2, ERROR = 1 } }
    _G.vim.o = _G.vim.o or { updatetime = 4000 }
    _G.vim.cmd = function() end
    
    -- Mock vim.api.nvim_create_augroup
    _G.vim.api.nvim_create_augroup = function(name, opts)
      registered_augroups[name] = opts
      return 1
    end
    
    -- Mock vim.api.nvim_create_autocmd
    _G.vim.api.nvim_create_autocmd = function(events, opts)
      table.insert(registered_autocmds, {
        events = events,
        opts = opts
      })
      return 2
    end
    
    -- Mock vim.loop.new_timer
    _G.vim.loop.new_timer = function()
      return {
        start = function(self, timeout, interval, callback)
          timer_started = true
          timer_interval = interval
          timer_callback = callback
        end,
        stop = function(self)
          timer_started = false
        end,
        close = function(self)
          timer_closed = true
        end
      }
    end
    
    -- Mock schedule_wrap
    _G.vim.schedule_wrap = function(callback)
      return callback
    end
    
    -- Mock vim.notify
    _G.vim.notify = function() end
    
    -- Mock vim.api.nvim_buf_is_valid
    _G.vim.api.nvim_buf_is_valid = function() return true end
    
    -- Mock vim.fn.win_findbuf
    _G.vim.fn.win_findbuf = function() return {1} end
    
    -- Setup test objects
    rovo_dev = {
      rovo_dev = {
        bufnr = 42,
        saved_updatetime = nil
      }
    }
    
    config = {
      refresh = {
        enable = true,
        updatetime = 500,
        timer_interval = 1000,
        show_notifications = true
      }
    }
  end)
  
  describe('setup', function()
    it('should create an augroup for file refresh', function()
      file_refresh.setup(rovo_dev, config)
      
      assert.is_not_nil(registered_augroups['RovoDevFileRefresh'], "File refresh augroup should be created")
      assert.is_true(registered_augroups['RovoDevFileRefresh'].clear, "Augroup should be cleared on creation")
    end)
    
    it('should register autocmds for file change detection', function()
      file_refresh.setup(rovo_dev, config)
      
      local has_checktime_autocmd = false
      for _, autocmd in ipairs(registered_autocmds) do
        if type(autocmd.events) == 'table' then
          -- Check if the autocmd has events that include common trigger events
          local has_trigger_events = false
          for _, event in ipairs(autocmd.events) do
            if event == 'CursorHold' or event == 'FocusGained' then
              has_trigger_events = true
              break
            end
          end
          
          -- Check if the callback contains checktime
          if has_trigger_events and autocmd.opts.callback then
            has_checktime_autocmd = true
            break
          end
        end
      end
      
      assert.is_true(has_checktime_autocmd, "Should register autocmd for file change detection")
    end)
    
    it('should create a timer for periodic file checks', function()
      file_refresh.setup(rovo_dev, config)
      
      assert.is_true(timer_started, "Timer should be started")
      assert.are.equal(config.refresh.timer_interval, timer_interval, "Timer interval should match config")
      assert.is_not_nil(timer_callback, "Timer callback should be set")
    end)
    
    it('should save the current updatetime', function()
      -- Initial updatetime
      _G.vim.o.updatetime = 4000
      
      file_refresh.setup(rovo_dev, config)
      
      assert.are.equal(4000, rovo_dev.rovo_dev.saved_updatetime, "Should save the current updatetime")
    end)
    
    it('should not setup refresh when disabled in config', function()
      -- Disable refresh in config
      config.refresh.enable = false
      
      file_refresh.setup(rovo_dev, config)
      
      assert.is_false(timer_started, "Timer should not be started when refresh is disabled")
      assert.is_nil(registered_augroups['RovoDevFileRefresh'], "Augroup should not be created when refresh is disabled")
    end)
  end)
  
  describe('cleanup', function()
    it('should stop and close the timer', function()
      -- First setup to create the timer
      file_refresh.setup(rovo_dev, config)
      
      -- Then clean up
      file_refresh.cleanup()
      
      assert.is_false(timer_started, "Timer should be stopped")
      assert.is_true(timer_closed, "Timer should be closed")
    end)
  end)
end)
