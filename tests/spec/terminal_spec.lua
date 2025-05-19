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
        if cmd:match('terminal pushd /test/git/root && ' .. config.command .. ' && popd') then
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

  describe('buffer listing', function()
    it('should set buffer as nobuflisted when creating terminal', function()
      -- Claude Code is not running (bufnr is nil)
      claude_code.claude_code.bufnr = nil

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Check that nobuflisted command was called
      local nobuflisted_found = false
      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd == 'setlocal nobuflisted' then
          nobuflisted_found = true
          break
        end
      end

      assert.is_true(nobuflisted_found, 'setlocal nobuflisted should be called')
    end)
  end)
end)
