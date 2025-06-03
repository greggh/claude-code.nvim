-- Tests for terminal integration in Claude Code
local assert = require('luassert')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it

local terminal = require('claude-code.terminal')

describe('terminal module', function()
  local config
  local claude_code
  local git
  local vim_cmd_calls = {}
  local win_ids = {}

  before_each(function()
    -- Reset tracking variables
    vim_cmd_calls = {}
    win_ids = {}

    -- Mock vim functions
    _G.vim = _G.vim or {}
    _G.vim.api = _G.vim.api or {}
    _G.vim.fn = _G.vim.fn or {}
    _G.vim.bo = _G.vim.bo or {}
    _G.vim.o = _G.vim.o or { lines = 100 }

    -- Mock vim.cmd
    _G.vim.cmd = function(cmd)
      table.insert(vim_cmd_calls, cmd)
      return true
    end

    -- Mock vim.api.nvim_buf_is_valid
    _G.vim.api.nvim_buf_is_valid = function(bufnr)
      return bufnr ~= nil
    end

    -- Mock vim.fn.win_findbuf
    _G.vim.fn.win_findbuf = function(bufnr)
      return win_ids
    end

    -- Mock vim.fn.bufnr
    _G.vim.fn.bufnr = function(pattern)
      if pattern == '%' then
        return 42
      end
      return 42
    end

    -- Mock vim.fn.getcwd
    _G.vim.fn.getcwd = function()
      return '/test/current/dir'
    end

    -- Mock vim.api.nvim_win_close
    _G.vim.api.nvim_win_close = function(win_id, force)
      -- Remove the window from win_ids
      for i, id in ipairs(win_ids) do
        if id == win_id then
          table.remove(win_ids, i)
          break
        end
      end
      return true
    end

    -- Mock vim.api.nvim_get_mode
    _G.vim.api.nvim_get_mode = function()
      return { mode = 'n' }
    end

    -- Setup test objects
    config = {
      command = 'claude',
      window = {
        position = 'botright',
        split_ratio = 0.5,
        enter_insert = true,
        start_in_normal_mode = false,
        hide_numbers = true,
        hide_signcolumn = true,
      },
      git = {
        use_git_root = true,
        multi_instance = true,
      },
      shell = {
        separator = '&&',
        pushd_cmd = 'pushd',
        popd_cmd = 'popd',
      },
    }

    claude_code = {
      claude_code = {
        instances = {},
        current_instance = nil,
        saved_updatetime = nil,
      },
    }

    git = {
      get_git_root = function()
        return '/test/git/root'
      end,
    }
  end)

  describe('toggle with multi-instance enabled', function()
    it('should create new instance when none exists', function()
      -- No instances exist
      claude_code.claude_code.instances = {}
      claude_code.claude_code.current_instance = nil

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Check that commands were called to create window
      local botright_cmd_found = false
      local resize_cmd_found = false
      local terminal_cmd_found = false

      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd == 'botright split' then
          botright_cmd_found = true
        elseif cmd:match('^resize %d+$') then
          resize_cmd_found = true
        elseif cmd:match('^terminal') then
          terminal_cmd_found = true
        end
      end

      assert.is_true(botright_cmd_found, 'Botright split command should be called')
      assert.is_true(resize_cmd_found, 'Resize command should be called')
      assert.is_true(terminal_cmd_found, 'Terminal command should be called')

      -- Current instance should be set
      assert.is_not_nil(claude_code.claude_code.current_instance, 'Current instance should be set')

      -- Instance should be created in instances table
      local current_instance = claude_code.claude_code.current_instance
      assert.is_not_nil(claude_code.claude_code.instances[current_instance], 'Instance buffer should be set')
    end)

    it('should use git root as instance identifier when use_git_root is true', function()
      -- Configure to use git root
      config.git.use_git_root = true
      config.git.multi_instance = true

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Current instance should be git root
      assert.are.equal('/test/git/root', claude_code.claude_code.current_instance)
    end)

    it('should use current directory as instance identifier when use_git_root is false', function()
      -- Configure to use current directory
      config.git.use_git_root = false
      config.git.multi_instance = true

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Current instance should be current directory
      assert.are.equal('/test/current/dir', claude_code.claude_code.current_instance)
    end)

    it('should close window when instance is visible', function()
      -- Setup existing instance
      local instance_id = '/test/git/root'
      claude_code.claude_code.instances[instance_id] = 42
      claude_code.claude_code.current_instance = instance_id
      win_ids = { 100, 101 } -- Windows displaying the buffer

      -- Create a function to clear the win_ids array
      _G.vim.api.nvim_win_close = function(win_id, force)
        -- Remove all windows from win_ids
        win_ids = {}
        return true
      end

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Check that the windows were closed
      assert.are.equal(0, #win_ids, 'Windows should be closed')
    end)

    it('should reopen window when instance exists but is hidden', function()
      -- Setup existing instance that's not visible
      local instance_id = '/test/git/root'
      claude_code.claude_code.instances[instance_id] = 42
      claude_code.claude_code.current_instance = instance_id
      win_ids = {} -- No windows displaying the buffer

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Check that commands were called to reopen window
      local botright_cmd_found = false
      local resize_cmd_found = false
      local buffer_cmd_found = false

      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd == 'botright split' then
          botright_cmd_found = true
        elseif cmd:match('^resize %d+$') then
          resize_cmd_found = true
        elseif cmd:match('^buffer 42$') then
          buffer_cmd_found = true
        end
      end

      assert.is_true(botright_cmd_found, 'Botright split command should be called')
      assert.is_true(resize_cmd_found, 'Resize command should be called')
      assert.is_true(buffer_cmd_found, 'Buffer command should be called with correct buffer number')
    end)

    it('should create buffer with sanitized name for multi-instance', function()
      -- Use an instance ID with special characters
      config.git.use_git_root = false
      config.git.multi_instance = true

      -- Mock getcwd to return path with special characters
      _G.vim.fn.getcwd = function()
        return '/test/path with spaces/and-symbols!'
      end

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Check that file command was called with sanitized name
      local file_cmd_found = false
      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd:match('file claude%-code%-.*') then
          file_cmd_found = true
          -- Ensure no special characters remain
          assert.is_nil(cmd:match('[^%w%-_]'), 'Buffer name should not contain special characters')
          break
        end
      end

      assert.is_true(file_cmd_found, 'File command should be called with sanitized buffer name')
    end)

    it('should clean up invalid buffers from instances table', function()
      -- Setup invalid buffer in instances
      local instance_id = '/test/git/root'
      claude_code.claude_code.instances[instance_id] = 999 -- Invalid buffer number

      -- Mock nvim_buf_is_valid to return false for this buffer
      _G.vim.api.nvim_buf_is_valid = function(bufnr)
        return bufnr ~= 999
      end

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Invalid buffer should be cleaned up
      assert.is_nil(claude_code.claude_code.instances[instance_id], 'Invalid buffer should be cleaned up')
    end)
  end)

  describe('toggle with multi-instance disabled', function()
    before_each(function()
      config.git.multi_instance = false
    end)

    it('should use global instance when multi-instance is disabled', function()
      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Current instance should be "global"
      assert.are.equal('global', claude_code.claude_code.current_instance)
    end)

    it('should create single global instance', function()
      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Check that global instance is created
      assert.is_not_nil(claude_code.claude_code.instances['global'], 'Global instance should be created')
    end)
  end)

  describe('git root usage', function()
    it('should use git root when configured', function()
      -- Set git config to use root
      config.git.use_git_root = true

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Check that git root was used in terminal command
      local git_root_cmd_found = false

      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd:match('terminal pushd /test/git/root && ' .. config.command .. ' && popd') then
          git_root_cmd_found = true
          break
        end
      end

      assert.is_true(git_root_cmd_found, 'Terminal command should include git root')
    end)

    it('should use custom pushd/popd commands when configured', function()
      -- Set git config to use root
      config.git.use_git_root = true
      -- Configure custom directory commands for nushell
      config.shell.pushd_cmd = 'enter'
      config.shell.popd_cmd = 'exit'
      config.shell.separator = ';'

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Check that custom commands were used in terminal command
      local custom_cmd_found = false

      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd:match('terminal enter /test/git/root ; ' .. config.command .. ' ; exit') then
          custom_cmd_found = true
          break
        end
      end

      assert.is_true(custom_cmd_found, 'Terminal command should use custom directory commands')
    end)
  end)

  describe('start_in_normal_mode option', function()
    it('should not enter insert mode when start_in_normal_mode is true', function()
      -- Set start_in_normal_mode to true
      config.window.start_in_normal_mode = true

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Check if startinsert was NOT called
      local startinsert_found = false
      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd == 'startinsert' then
          startinsert_found = true
          break
        end
      end

      assert.is_false(
        startinsert_found,
        'startinsert should not be called when start_in_normal_mode is true'
      )
    end)

    it('should enter insert mode when start_in_normal_mode is false', function()
      -- Set start_in_normal_mode to false
      config.window.start_in_normal_mode = false

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Check if startinsert was called
      local startinsert_found = false
      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd == 'startinsert' then
          startinsert_found = true
          break
        end
      end

      assert.is_true(
        startinsert_found,
        'startinsert should be called when start_in_normal_mode is false'
      )
    end)
  end)

  describe('force_insert_mode', function()
    it('should check insert mode conditions in terminal buffer', function()
      -- Setup mock with instances table
      local mock_claude_code = {
        claude_code = {
          instances = {
            ['/test/instance'] = 1,
          },
          current_instance = '/test/instance',
        },
      }
      local mock_config = {
        window = {
          start_in_normal_mode = false,
        },
      }

      -- For this test, we'll just verify that the function can be called without error
      local success, _ = pcall(function()
        terminal.force_insert_mode(mock_claude_code, mock_config)
      end)

      assert.is_true(success, 'Force insert mode function should run without error')
    end)

    it('should handle non-terminal buffers correctly', function()
      -- Setup mock with instances table but different current buffer
      local mock_claude_code = {
        claude_code = {
          instances = {
            ['/test/instance'] = 2,
          },
          current_instance = '/test/instance',
        },
      }
      local mock_config = {
        window = {
          start_in_normal_mode = false,
        },
      }

      -- Mock bufnr to return different buffer
      _G.vim.fn.bufnr = function(pattern)
        if pattern == '%' then
          return 1 -- Different from instances buffer
        end
        return 1
      end

      -- For this test, we'll just verify that the function can be called without error
      local success, _ = pcall(function()
        terminal.force_insert_mode(mock_claude_code, mock_config)
      end)

      assert.is_true(success, 'Force insert mode function should run without error')
    end)
  end)
end)