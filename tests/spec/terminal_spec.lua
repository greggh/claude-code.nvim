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
      return bufnr ~= nil and bufnr > 0
    end
    
    -- Mock vim.api.nvim_buf_get_option
    _G.vim.api.nvim_buf_get_option = function(bufnr, option)
      if option == 'buftype' then
        return 'terminal'  -- Always return terminal for valid buffers in tests
      end
      return ''
    end
    
    -- Mock vim.api.nvim_buf_get_var
    _G.vim.api.nvim_buf_get_var = function(bufnr, varname)
      if varname == 'terminal_job_id' then
        return 12345  -- Return a mock job ID
      end
      error('Invalid buffer variable: ' .. varname)
    end
    
    -- Mock vim.fn.jobwait
    _G.vim.fn.jobwait = function(job_ids, timeout)
      return {-1}  -- -1 means job is still running
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
      },
    }

    claude_code = {
      claude_code = {
        bufnr = nil,
        saved_updatetime = nil,
      },
    }

    git = {
      get_git_root = function()
        return '/test/git/root'
      end,
    }
  end)

  describe('toggle', function()
    it('should open terminal window when Claude Code is not running', function()
      -- Claude Code is not running (bufnr is nil)
      claude_code.claude_code.bufnr = nil

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

      -- Buffer number should be set
      assert.is_not_nil(claude_code.claude_code.bufnr, 'Claude Code buffer number should be set')
    end)

    it('should use git root when configured', function()
      -- Claude Code is not running (bufnr is nil)
      claude_code.claude_code.bufnr = nil

      -- Set git config to use root
      config.git.use_git_root = true

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Check that git root was used in terminal command
      local git_root_cmd_found = false

      for _, cmd in ipairs(vim_cmd_calls) do
        -- The path should now be shell-escaped
        if cmd:match("terminal pushd '/test/git/root' && " .. config.command .. " && popd") then
          git_root_cmd_found = true
          break
        end
      end

      assert.is_true(git_root_cmd_found, 'Terminal command should include git root')
    end)

    it('should close window when Claude Code is visible', function()
      -- Claude Code is running and visible
      claude_code.claude_code.bufnr = 42
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

    it('should reopen window when Claude Code exists but is hidden', function()
      -- Claude Code is running but not visible
      claude_code.claude_code.bufnr = 42
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
  end)

  describe('start_in_normal_mode option', function()
    it('should not enter insert mode when start_in_normal_mode is true', function()
      -- Claude Code is not running (bufnr is nil)
      claude_code.claude_code.bufnr = nil

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
      -- Claude Code is not running (bufnr is nil)
      claude_code.claude_code.bufnr = nil

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
      -- For this test, we'll just verify that the function can be called without error
      local success, _ = pcall(function()
        -- Setup minimal mock
        local mock_claude_code = {
          claude_code = {
            bufnr = 1,
          },
        }
        local mock_config = {
          window = {
            start_in_normal_mode = false,
          },
        }
        terminal.force_insert_mode(mock_claude_code, mock_config)
      end)

      assert.is_true(success, 'Force insert mode function should run without error')
    end)

    it('should handle non-terminal buffers correctly', function()
      -- For this test, we'll just verify that the function can be called without error
      local success, _ = pcall(function()
        -- Setup minimal mock that's different from terminal buffer
        local mock_claude_code = {
          claude_code = {
            bufnr = 2,
          },
        }
        local mock_config = {
          window = {
            start_in_normal_mode = false,
          },
        }
        terminal.force_insert_mode(mock_claude_code, mock_config)
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
      _G.vim.o = _G.vim.o or {}
      _G.vim.o.columns = 120
      _G.vim.o.lines = 40
    end)

    it('should create floating window when position is "float"', function()
      -- Claude Code is not running
      claude_code.claude_code.bufnr = nil
      
      -- Configure floating window
      config.window.position = 'float'
      config.window.float = {
        width = 80,
        height = 20,
        relative = 'editor',
        border = 'rounded'
      }

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Check that nvim_open_win was called
      assert.is_true(nvim_open_win_called, 'nvim_open_win should be called for floating window')
      assert.is_not_nil(nvim_open_win_config, 'floating window config should be provided')
      assert.are.equal('editor', nvim_open_win_config.relative)
      assert.are.equal('rounded', nvim_open_win_config.border)
      assert.are.equal(80, nvim_open_win_config.width)
      assert.are.equal(20, nvim_open_win_config.height)
      assert.are.equal(0, nvim_open_win_config.row)
      assert.are.equal(0, nvim_open_win_config.col)
    end)

    it('should calculate float dimensions from percentages', function()
      -- Claude Code is not running
      claude_code.claude_code.bufnr = nil
      
      -- Configure floating window with percentage dimensions
      config.window.position = 'float'
      config.window.float = {
        width = '80%',
        height = '50%',
        relative = 'editor',
        border = 'single'
      }

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Check that dimensions were calculated correctly
      assert.is_true(nvim_open_win_called, 'nvim_open_win should be called')
      assert.are.equal(math.floor(120 * 0.8), nvim_open_win_config.width) -- 80% of 120
      assert.are.equal(math.floor(40 * 0.5), nvim_open_win_config.height) -- 50% of 40
    end)

    it('should center floating window when position is "center"', function()
      -- Claude Code is not running
      claude_code.claude_code.bufnr = nil
      
      -- Configure floating window to be centered
      config.window.position = 'float'
      config.window.float = {
        width = 60,
        height = 20,
        row = 'center',
        col = 'center',
        relative = 'editor'
      }

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Check that window is centered
      assert.is_true(nvim_open_win_called, 'nvim_open_win should be called')
      assert.are.equal(10, nvim_open_win_config.row) -- (40-20)/2
      assert.are.equal(30, nvim_open_win_config.col) -- (120-60)/2
    end)

    it('should reuse existing buffer for floating window when toggling', function()
      -- Claude Code is already running
      claude_code.claude_code.bufnr = 42
      win_ids = {} -- No windows displaying the buffer
      
      -- Configure floating window
      config.window.position = 'float'
      config.window.float = {
        width = 80,
        height = 20,
        relative = 'editor',
        border = 'none'
      }

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Should open floating window with existing buffer
      assert.is_true(nvim_open_win_called, 'nvim_open_win should be called')
      assert.is_false(nvim_create_buf_called, 'should not create new buffer')
    end)

    it('should handle out-of-bounds dimensions gracefully', function()
      -- Claude Code is not running
      claude_code.claude_code.bufnr = nil
      
      -- Configure floating window with large dimensions
      config.window.position = 'float'
      config.window.float = {
        width = '150%',
        height = '110%',
        row = '90%',
        col = '95%',
        relative = 'editor',
        border = 'rounded'
      }

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Check that window is created (even if dims are out of bounds)
      assert.is_true(nvim_open_win_called, 'nvim_open_win should be called')
      assert.are.equal(math.floor(120 * 1.5), nvim_open_win_config.width)
      assert.are.equal(math.floor(40 * 1.1), nvim_open_win_config.height)
    end)
  end)
end)
