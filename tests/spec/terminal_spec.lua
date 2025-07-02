-- Tests for terminal integration in Rovo Dev
local assert = require('luassert')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it

local terminal = require('rovo-dev.terminal')

describe('terminal module', function()
  local config
  local rovo_dev
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
    -- Set up vim.o with numeric values that are protected from corruption
    _G.vim.o = setmetatable({
      lines = 100,
      columns = 100,
      cmdheight = 1,
    }, {
      __newindex = function(t, k, v)
        -- Ensure lines and columns are always numbers
        if k == 'lines' or k == 'columns' or k == 'cmdheight' then
          rawset(t, k, tonumber(v) or rawget(t, k) or 1)
        else
          rawset(t, k, v)
        end
      end,
    })

    -- Mock vim.cmd
    _G.vim.cmd = function(cmd)
      table.insert(vim_cmd_calls, cmd)
      return true
    end

    -- Mock vim.api.nvim_buf_is_valid
    _G.vim.api.nvim_buf_is_valid = function(bufnr)
      return bufnr ~= nil and bufnr > 0
    end

    -- Mock vim.api.nvim_buf_get_option (deprecated)
    _G.vim.api.nvim_buf_get_option = function(bufnr, option)
      if option == 'buftype' then
        return 'terminal' -- Always return terminal for valid buffers in tests
      end
      return ''
    end

    -- Mock vim.api.nvim_get_option_value (new API)
    _G.vim.api.nvim_get_option_value = function(option, opts)
      if option == 'buftype' then
        return 'terminal' -- Always return terminal for valid buffers in tests
      end
      return ''
    end

    -- Mock vim.api.nvim_buf_get_var
    _G.vim.api.nvim_buf_get_var = function(bufnr, varname)
      if varname == 'terminal_job_id' then
        return 12345 -- Return a mock job ID
      end
      error('Invalid buffer variable: ' .. varname)
    end

    -- Mock vim.b for buffer variables (new API)
    _G.vim.b = setmetatable({}, {
      __index = function(t, bufnr)
        if not rawget(t, bufnr) then
          rawset(t, bufnr, {
            terminal_job_id = 12345, -- Mock job ID
          })
        end
        return rawget(t, bufnr)
      end,
    })

    -- Mock vim.api.nvim_set_option_value (new API for both buffer and window options)
    _G.vim.api.nvim_set_option_value = function(option, value, opts)
      -- Just mock this to do nothing for tests
      return true
    end

    -- Mock vim.fn.jobwait
    _G.vim.fn.jobwait = function(job_ids, timeout)
      return { -1 } -- -1 means job is still running
    end

    -- Mock vim.fn.win_findbuf
    _G.vim.fn.win_findbuf = function(bufnr)
      -- Return a copy of win_ids to avoid iterator issues
      local copy = {}
      for i, id in ipairs(win_ids) do
        copy[i] = id
      end
      return copy
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
      command = 'rovo',
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

    rovo_dev = {
      rovo_dev = {
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
      rovo_dev.rovo_dev.instances = {}
      rovo_dev.rovo_dev.current_instance = nil

      -- Call toggle
      terminal.toggle(rovo_dev, config, git)

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
      assert.is_not_nil(rovo_dev.rovo_dev.current_instance, 'Current instance should be set')

      -- Instance should be created in instances table
      local current_instance = rovo_dev.rovo_dev.current_instance
      assert.is_not_nil(
        rovo_dev.rovo_dev.instances[current_instance],
        'Instance buffer should be set'
      )
    end)

    it('should use git root as instance identifier when use_git_root is true', function()
      -- Configure to use git root
      config.git.use_git_root = true
      config.git.multi_instance = true

      -- Call toggle
      terminal.toggle(rovo_dev, config, git)

      -- Current instance should be git root
      assert.are.equal('/test/git/root', rovo_dev.rovo_dev.current_instance)

      -- Check that git root was used in terminal command
      local git_root_cmd_found = false

      for _, cmd in ipairs(vim_cmd_calls) do
        -- The path should now be shell-escaped
        if cmd:match("terminal pushd '/test/git/root' && " .. config.command .. ' && popd') then
          git_root_cmd_found = true
          break
        end
      end

      assert.is_true(git_root_cmd_found, 'Terminal command should include git root')
    end)

    it('should use current directory as instance identifier when use_git_root is false', function()
      -- Configure to use current directory
      config.git.use_git_root = false
      config.git.multi_instance = true

      -- Call toggle
      terminal.toggle(rovo_dev, config, git)

      -- Current instance should be current directory
      assert.are.equal('/test/current/dir', rovo_dev.rovo_dev.current_instance)
    end)

    it('should close window when instance is visible', function()
      -- Setup existing instance
      local instance_id = '/test/git/root'
      rovo_dev.rovo_dev.instances[instance_id] = 42
      rovo_dev.rovo_dev.current_instance = instance_id
      win_ids = { 100, 101 } -- Windows displaying the buffer

      -- Ensure buffer 42 is always treated as valid for this test
      -- Override just for this test - buffer 42 should always be a terminal
      local original_get_option = _G.vim.api.nvim_get_option_value
      _G.vim.api.nvim_get_option_value = function(option, opts)
        if option == 'buftype' and opts and opts.buf == 42 then
          return 'terminal'
        elseif option == 'buftype' then
          return 'terminal' -- Default to terminal for tests
        end
        return ''
      end

      -- Track how many times nvim_win_close is called
      local close_count = 0

      -- Create a function to clear the win_ids array
      _G.vim.api.nvim_win_close = function(win_id, force)
        close_count = close_count + 1
        -- Remove the specific window from win_ids
        for i, id in ipairs(win_ids) do
          if id == win_id then
            table.remove(win_ids, i)
            break
          end
        end
        return true
      end

      -- Call toggle
      terminal.toggle(rovo_dev, config, git)

      -- Check that the windows were closed
      if #win_ids ~= 0 then
        error(
          'Windows not closed. Close count: ' .. close_count .. ', Remaining windows: ' .. #win_ids
        )
      end
      assert.are.equal(0, #win_ids, 'Windows should be closed')
    end)

    it('should reopen window when instance exists but is hidden', function()
      -- Setup existing instance that's not visible
      local instance_id = '/test/git/root'
      rovo_dev.rovo_dev.instances[instance_id] = 42
      rovo_dev.rovo_dev.current_instance = instance_id
      win_ids = {} -- No windows displaying the buffer

      -- Call toggle
      terminal.toggle(rovo_dev, config, git)

      -- Check that commands were called to reopen window
      local botright_cmd_found = false
      local resize_cmd_found = false
      local buffer_cmd_found = false
      local terminal_cmd_found = false

      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd == 'botright split' then
          botright_cmd_found = true
        elseif cmd:match('^resize %d+$') then
          resize_cmd_found = true
        elseif cmd:match('^buffer 42$') then
          buffer_cmd_found = true
        elseif cmd:match('^terminal ') then
          terminal_cmd_found = true
        end
      end

      assert.is_true(botright_cmd_found, 'Botright split command should be called')
      assert.is_true(resize_cmd_found, 'Resize command should be called')

      -- Either buffer reuse or new terminal creation is acceptable
      -- The key is that the window reopens
      assert.is_true(
        buffer_cmd_found or terminal_cmd_found,
        'Either buffer reuse or new terminal command should be called'
      )
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
      terminal.toggle(rovo_dev, config, git)

      -- Check that file command was called with sanitized name
      local file_cmd_found = false
      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd:match('file rovo%-dev%-.*') then
          file_cmd_found = true
          -- Extract buffer name from the file command and check it doesn't have invalid chars
          local buffer_name = cmd:match('file (.+)')
          if buffer_name then
            -- Buffer names should only contain alphanumeric, hyphen, and underscore
            assert.is_nil(
              buffer_name:match('[^%w%-_]'),
              'Buffer name should only contain [a-zA-Z0-9_-]'
            )
          end
          break
        end
      end

      assert.is_true(file_cmd_found, 'File command should be called with sanitized buffer name')
    end)

    it('should clean up invalid buffers from instances table', function()
      -- Setup invalid buffer in instances
      local instance_id = '/test/git/root'
      rovo_dev.rovo_dev.instances[instance_id] = 999 -- Invalid buffer number

      -- Mock nvim_buf_is_valid to return false for the specific invalid buffer
      local original_is_valid = _G.vim.api.nvim_buf_is_valid
      _G.vim.api.nvim_buf_is_valid = function(bufnr)
        if bufnr == 999 then
          return false -- Invalid buffer
        end
        return original_is_valid(bufnr)
      end

      -- Call toggle
      terminal.toggle(rovo_dev, config, git)

      -- Invalid buffer should be cleaned up and replaced with a new valid one
      assert.is_not_nil(rovo_dev.rovo_dev.instances[instance_id], 'Should have new valid buffer')
      assert.are_not.equal(
        999,
        rovo_dev.rovo_dev.instances[instance_id],
        'Invalid buffer should be cleaned up'
      )

      -- Restore original mock
      _G.vim.api.nvim_buf_is_valid = original_is_valid
    end)
  end)

  describe('toggle with multi-instance disabled', function()
    before_each(function()
      config.git.multi_instance = false
    end)

    it('should use global instance when multi-instance is disabled', function()
      -- Call toggle
      terminal.toggle(rovo_dev, config, git)

      -- Current instance should be "global"
      assert.are.equal('global', rovo_dev.rovo_dev.current_instance)
    end)

    it('should create single global instance', function()
      -- Call toggle
      terminal.toggle(rovo_dev, config, git)

      -- Check that global instance is created
      assert.is_not_nil(rovo_dev.rovo_dev.instances['global'], 'Global instance should be created')
    end)
  end)

  describe('git root usage', function()
    it('should use git root when configured', function()
      -- Set git config to use root
      config.git.use_git_root = true

      -- Call toggle
      terminal.toggle(rovo_dev, config, git)

      -- Check that git root was used in terminal command
      local git_root_cmd_found = false

      for _, cmd in ipairs(vim_cmd_calls) do
        -- The path should now be shell-escaped in the command
        if cmd:match('terminal pushd .*/test/git/root.* && ' .. config.command .. ' && popd') then
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
      terminal.toggle(rovo_dev, config, git)

      -- Check that custom commands were used in terminal command
      local custom_cmd_found = false

      for _, cmd in ipairs(vim_cmd_calls) do
        -- The path should now be shell-escaped in the command
        if cmd:match('terminal enter .*/test/git/root.* ; ' .. config.command .. ' ; exit') then
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
      terminal.toggle(rovo_dev, config, git)

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
      terminal.toggle(rovo_dev, config, git)

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
      local mock_rovo_dev = {
        rovo_dev = {
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
        terminal.force_insert_mode(mock_rovo_dev, mock_config)
      end)

      assert.is_true(success, 'Force insert mode function should run without error')
    end)

    it('should handle non-terminal buffers correctly', function()
      -- Setup mock with instances table but different current buffer
      local mock_rovo_dev = {
        rovo_dev = {
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
        terminal.force_insert_mode(mock_rovo_dev, mock_config)
      end)

      assert.is_true(success, 'Force insert mode function should run without error')
    end)
  end)

  describe('floating window', function()
    local nvim_open_win_called = false
    local nvim_open_win_config = nil
    local nvim_create_buf_called = false

    before_each(function()
      -- Reset tracking variables
      nvim_open_win_called = false
      nvim_open_win_config = nil
      nvim_create_buf_called = false

      -- Mock nvim_open_win to track calls
      _G.vim.api.nvim_open_win = function(buf, enter, config)
        nvim_open_win_called = true
        nvim_open_win_config = config
        return 123 -- Return a mock window ID
      end

      -- Mock nvim_create_buf for floating window
      _G.vim.api.nvim_create_buf = function(listed, scratch)
        nvim_create_buf_called = true
        return 43 -- Return a mock buffer ID
      end

      -- Mock nvim_buf_set_option
      _G.vim.api.nvim_buf_set_option = function(bufnr, option, value)
        return true
      end

      -- Mock nvim_win_set_buf
      _G.vim.api.nvim_win_set_buf = function(win_id, bufnr)
        return true
      end

      -- Mock nvim_buf_set_name
      _G.vim.api.nvim_buf_set_name = function(bufnr, name)
        return true
      end

      -- Mock nvim_win_set_option
      _G.vim.api.nvim_win_set_option = function(win_id, option, value)
        return true
      end

      -- Mock termopen
      _G.vim.fn.termopen = function(cmd)
        return 1 -- Return a mock job ID
      end

      -- Mock vim.o.columns and vim.o.lines for percentage calculations
      _G.vim.o.columns = 120
      _G.vim.o.lines = 40
      _G.vim.o.cmdheight = 1
    end)

    it('should create floating window when position is "float"', function()
      -- Rovo Dev is not running - update for multi-instance support
      rovo_dev.rovo_dev.instances = {}

      -- Configure floating window
      config.window.position = 'float'
      config.window.float = {
        width = 80,
        height = 20,
        relative = 'editor',
        border = 'rounded',
      }

      -- Call toggle
      terminal.toggle(rovo_dev, config, git)

      -- Check that nvim_open_win was called
      assert.is_true(nvim_open_win_called, 'nvim_open_win should be called for floating window')
      assert.is_not_nil(nvim_open_win_config, 'floating window config should be provided')
      assert.are.equal('editor', nvim_open_win_config.relative)
      assert.are.equal('rounded', nvim_open_win_config.border)
      assert.are.equal(80, nvim_open_win_config.width)
      assert.are.equal(20, nvim_open_win_config.height)
      -- Check calculated positions (clamped to ensure visibility)
      assert.is_true(nvim_open_win_config.row >= 0)
      assert.is_true(nvim_open_win_config.col >= 0)
      local editor_height = 40 - 1 - 1 -- lines - cmdheight - status line
      assert.is_true(nvim_open_win_config.row <= editor_height - 20) -- max_lines - height
      assert.is_true(nvim_open_win_config.col <= 120 - 80) -- max_columns - width
    end)

    it('should calculate float dimensions from percentages', function()
      -- Rovo Dev is not running - update for multi-instance support
      rovo_dev.rovo_dev.instances = {}

      -- Configure floating window with percentage dimensions
      config.window.position = 'float'
      config.window.float = {
        width = '80%',
        height = '50%',
        relative = 'editor',
        border = 'single',
      }

      -- Call toggle
      terminal.toggle(rovo_dev, config, git)

      -- Check that dimensions were calculated correctly
      assert.is_true(nvim_open_win_called, 'nvim_open_win should be called')
      local editor_height = 40 - 1 - 1 -- lines - cmdheight - status line = 38
      local expected_width = math.floor(120 * 0.8) -- 80% of 120
      local expected_height = math.floor(editor_height * 0.5) -- 50% of 38
      assert.are.equal(expected_width, nvim_open_win_config.width)
      assert.are.equal(expected_height, nvim_open_win_config.height)
      -- Verify percentage calculations match expected formula
      local mock_columns = 120
      local mock_editor_height = 38
      assert.are.equal(math.floor(mock_columns * 0.8), expected_width)
      assert.are.equal(math.floor(mock_editor_height * 0.5), expected_height)
    end)

    it('should center floating window when position is "center"', function()
      -- Rovo Dev is not running - update for multi-instance support
      rovo_dev.rovo_dev.instances = {}

      -- Configure floating window to be centered
      config.window.position = 'float'
      config.window.float = {
        width = 60,
        height = 20,
        row = 'center',
        col = 'center',
        relative = 'editor',
      }

      -- Call toggle
      terminal.toggle(rovo_dev, config, git)

      -- Check that window is centered
      assert.is_true(nvim_open_win_called, 'nvim_open_win should be called')
      local editor_height = 40 - 1 - 1 -- lines - cmdheight - status line = 38
      assert.are.equal(math.floor((editor_height - 20) / 2), nvim_open_win_config.row) -- (38-20)/2 = 9
      assert.are.equal(30, nvim_open_win_config.col) -- (120-60)/2
    end)

    it('should reuse existing buffer for floating window when toggling', function()
      -- Rovo Dev is already running - update for multi-instance support
      local instance_id = 'global' -- Single instance mode
      rovo_dev.rovo_dev.instances = { [instance_id] = 42 }
      win_ids = {} -- No windows displaying the buffer

      -- Configure floating window
      config.window.position = 'float'
      config.window.float = {
        width = 80,
        height = 20,
        relative = 'editor',
        border = 'none',
      }

      -- Call toggle
      terminal.toggle(rovo_dev, config, git)

      -- Should open floating window with existing buffer
      assert.is_true(nvim_open_win_called, 'nvim_open_win should be called')
      -- Verify floating window configuration is correct
      assert.is_not_nil(nvim_open_win_config, 'Window config should be provided')
      assert.are.equal('editor', nvim_open_win_config.relative)
      assert.are.equal('none', nvim_open_win_config.border)

      -- Verify existing buffer is reused (buffer 42 from instances)
      -- The specific buffer reuse logic is tested implicitly through the toggle function
    end)

    it('should handle out-of-bounds dimensions gracefully', function()
      -- Rovo Dev is not running
      rovo_dev.rovo_dev.bufnr = nil

      -- Configure floating window with large dimensions
      config.window.position = 'float'
      config.window.float = {
        width = '150%',
        height = '110%',
        row = '90%',
        col = '95%',
        relative = 'editor',
        border = 'rounded',
      }

      -- Call toggle
      terminal.toggle(rovo_dev, config, git)

      -- Check that window is created (even if dims are out of bounds)
      assert.is_true(nvim_open_win_called, 'nvim_open_win should be called')
      local editor_height = 40 - 1 - 1 -- lines - cmdheight - status line = 38
      assert.are.equal(math.floor(120 * 1.5), nvim_open_win_config.width)
      assert.are.equal(math.floor(editor_height * 1.1), nvim_open_win_config.height)
    end)
  end)
end)
