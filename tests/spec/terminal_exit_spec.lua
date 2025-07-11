local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local assert = require('luassert')
local before_each = require('plenary.busted').before_each

describe('Claude Code terminal exit handling', function()
  local claude_code
  local config
  local git
  local terminal

  before_each(function()
    -- Clear module cache
    package.loaded['claude-code'] = nil
    package.loaded['claude-code.config'] = nil
    package.loaded['claude-code.terminal'] = nil
    package.loaded['claude-code.git'] = nil

    -- Load modules
    claude_code = require('claude-code')
    config = require('claude-code.config')
    terminal = require('claude-code.terminal')
    git = require('claude-code.git')

    -- Initialize claude_code instance
    claude_code.claude_code = {
      instances = {},
      floating_windows = {},
      process_states = {},
    }
  end)

  it('should close buffer when Claude Code exits', function()
    -- Mock git.get_git_root to return a test path
    git.get_git_root = function()
      return '/test/project'
    end

    -- Create a test configuration
    local test_config = vim.tbl_deep_extend('force', config.default_config, {
      command = 'echo "test"',
      window = {
        position = 'botright',
      },
    })

    -- Mock vim functions to track buffer and window operations
    local created_buffers = {}
    local deleted_buffers = {}
    local closed_windows = {}
    local autocmds = {}

    -- Mock vim.fn.bufnr
    local original_bufnr = vim.fn.bufnr
    vim.fn.bufnr = function(arg)
      if arg == '%' then
        return 123 -- Mock buffer number
      end
      return original_bufnr(arg)
    end

    -- Mock vim.api.nvim_create_autocmd
    local original_create_autocmd = vim.api.nvim_create_autocmd
    vim.api.nvim_create_autocmd = function(event, opts)
      table.insert(autocmds, { event = event, opts = opts })
      return 1 -- Mock autocmd id
    end

    -- Mock vim.api.nvim_buf_delete
    local original_buf_delete = vim.api.nvim_buf_delete
    vim.api.nvim_buf_delete = function(bufnr, opts)
      table.insert(deleted_buffers, bufnr)
    end

    -- Mock vim.api.nvim_win_close
    local original_win_close = vim.api.nvim_win_close
    vim.api.nvim_win_close = function(win_id, force)
      table.insert(closed_windows, win_id)
    end

    -- Mock vim.fn.win_findbuf
    vim.fn.win_findbuf = function(bufnr)
      if bufnr == 123 then
        return { 456 } -- Mock window ID
      end
      return {}
    end

    -- Mock vim.api.nvim_win_is_valid
    vim.api.nvim_win_is_valid = function(win_id)
      return win_id == 456
    end

    -- Mock vim.api.nvim_buf_is_valid
    vim.api.nvim_buf_is_valid = function(bufnr)
      return bufnr == 123 and not vim.tbl_contains(deleted_buffers, bufnr)
    end

    -- Toggle Claude Code to create the terminal
    terminal.toggle(claude_code, test_config, git)

    -- Verify that TermClose autocmd was created
    local termclose_autocmd = nil
    for _, autocmd in ipairs(autocmds) do
      if autocmd.event == 'TermClose' and autocmd.opts.buffer == 123 then
        termclose_autocmd = autocmd
        break
      end
    end

    assert.is_not_nil(termclose_autocmd, 'TermClose autocmd should be created')
    assert.equals(
      123,
      termclose_autocmd.opts.buffer,
      'TermClose should be attached to correct buffer'
    )
    assert.is_function(termclose_autocmd.opts.callback, 'TermClose should have a callback function')

    -- Simulate terminal closing (Claude Code exits)
    -- First call the callback directly
    termclose_autocmd.opts.callback()

    -- Verify instance was cleaned up immediately
    assert.is_nil(claude_code.claude_code.instances['/test/project'], 'Instance should be removed')
    assert.is_nil(
      claude_code.claude_code.floating_windows['/test/project'],
      'Floating window tracking should be cleared'
    )

    -- Simulate the deferred function execution
    -- In real scenario, vim.defer_fn would delay this, but in tests we call it directly
    vim.defer_fn = function(fn, delay)
      fn() -- Execute immediately in test
    end

    -- Re-run the callback to trigger deferred cleanup
    termclose_autocmd.opts.callback()

    -- Verify buffer and window were closed
    assert.equals(1, #closed_windows, 'Window should be closed')
    assert.equals(456, closed_windows[1], 'Correct window should be closed')
    assert.equals(1, #deleted_buffers, 'Buffer should be deleted')
    assert.equals(123, deleted_buffers[1], 'Correct buffer should be deleted')

    -- Restore mocks
    vim.fn.bufnr = original_bufnr
    vim.api.nvim_create_autocmd = original_create_autocmd
    vim.api.nvim_buf_delete = original_buf_delete
    vim.api.nvim_win_close = original_win_close
  end)

  it('should handle multiple instances correctly', function()
    -- Test that each instance gets its own TermClose handler
    local test_config = vim.tbl_deep_extend('force', config.default_config, {
      command = 'echo "test"',
      git = {
        multi_instance = true,
      },
    })

    local autocmds = {}
    local original_create_autocmd = vim.api.nvim_create_autocmd
    vim.api.nvim_create_autocmd = function(event, opts)
      table.insert(autocmds, { event = event, opts = opts })
      return #autocmds
    end

    -- Mock different buffer numbers for different instances
    local bufnr_counter = 100
    vim.fn.bufnr = function(arg)
      if arg == '%' then
        bufnr_counter = bufnr_counter + 1
        return bufnr_counter
      end
      return -1
    end

    -- Create first instance
    git.get_git_root = function()
      return '/project1'
    end
    terminal.toggle(claude_code, test_config, git)

    -- Create second instance
    git.get_git_root = function()
      return '/project2'
    end
    terminal.toggle(claude_code, test_config, git)

    -- Verify two different TermClose autocmds were created
    local termclose_count = 0
    local buffer_ids = {}
    for _, autocmd in ipairs(autocmds) do
      if autocmd.event == 'TermClose' then
        termclose_count = termclose_count + 1
        table.insert(buffer_ids, autocmd.opts.buffer)
      end
    end

    assert.equals(2, termclose_count, 'Two TermClose autocmds should be created')
    assert.are_not.equals(
      buffer_ids[1],
      buffer_ids[2],
      'Each instance should have different buffer'
    )

    -- Restore mocks
    vim.api.nvim_create_autocmd = original_create_autocmd
  end)
end)
