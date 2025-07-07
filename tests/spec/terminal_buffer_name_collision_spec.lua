-- Tests for buffer name collision handling in terminal.lua
local assert = require('luassert')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it

local terminal = require('claude-code.terminal')

describe('terminal buffer name collision handling', function()
  local config
  local claude_code
  local git
  local vim_cmd_calls = {}
  local existing_buffers = {}
  local deleted_buffers = {}
  local nvim_buf_set_name_calls = {}
  local original_os_time = os.time
  
  -- Mock os.time for consistent timestamps
  os.time = function()
    return 1234567890
  end

  before_each(function()
    -- Reset tracking variables
    vim_cmd_calls = {}
    existing_buffers = {}
    deleted_buffers = {}
    nvim_buf_set_name_calls = {}

    -- Mock vim functions
    _G.vim = _G.vim or {}
    _G.vim.api = _G.vim.api or {}
    _G.vim.fn = _G.vim.fn or {}
    _G.vim.bo = _G.vim.bo or {}
    _G.vim.o = setmetatable({
      lines = 100,
      columns = 100,
      cmdheight = 1
    }, {
      __newindex = function(t, k, v)
        if k == 'lines' or k == 'columns' or k == 'cmdheight' then
          rawset(t, k, tonumber(v) or rawget(t, k) or 1)
        else
          rawset(t, k, v)
        end
      end
    })

    -- Mock vim.cmd
    _G.vim.cmd = function(cmd)
      table.insert(vim_cmd_calls, cmd)
      return true
    end

    -- Mock vim.api.nvim_buf_is_valid
    _G.vim.api.nvim_buf_is_valid = function(bufnr)
      return bufnr ~= nil and bufnr > 0 and not deleted_buffers[bufnr]
    end

    -- Mock vim.api.nvim_get_option_value (new API)
    _G.vim.api.nvim_get_option_value = function(option, opts)
      if option == 'buftype' then
        return 'terminal'  -- Always return terminal for valid buffers in tests
      end
      return ''
    end

    -- Mock vim.b for buffer variables (new API)
    _G.vim.b = setmetatable({}, {
      __index = function(t, bufnr)
        if not rawget(t, bufnr) then
          rawset(t, bufnr, {
            terminal_job_id = 12345  -- Mock job ID
          })
        end
        return rawget(t, bufnr)
      end
    })

    -- Mock vim.api.nvim_set_option_value (new API for both buffer and window options)
    _G.vim.api.nvim_set_option_value = function(option, value, opts)
      -- Just mock this to do nothing for tests
      return true
    end

    -- Mock vim.fn.jobwait
    _G.vim.fn.jobwait = function(job_ids, timeout)
      return {-1}  -- -1 means job is still running
    end

    -- Note: os.time mocking is done per test case as needed

    -- Mock vim.api.nvim_buf_delete
    _G.vim.api.nvim_buf_delete = function(bufnr, opts)
      deleted_buffers[bufnr] = true
      existing_buffers[bufnr] = nil
      return true
    end

    -- Mock vim.api.nvim_buf_set_name
    _G.vim.api.nvim_buf_set_name = function(bufnr, name)
      table.insert(nvim_buf_set_name_calls, {bufnr = bufnr, name = name})
      -- Check if buffer name already exists and throw error if it does
      for existing_bufnr, existing_name in pairs(existing_buffers) do
        if existing_name == name and existing_bufnr ~= bufnr and not deleted_buffers[existing_bufnr] then
          error('Vim:E95: Buffer with this name already exists')
        end
      end
      existing_buffers[bufnr] = name
      return true
    end

    -- Mock vim.fn.bufnr
    _G.vim.fn.bufnr = function(pattern)
      if pattern == '%' then
        return 42
      end
      -- Check if buffer with this name exists
      for bufnr, name in pairs(existing_buffers) do
        if name == pattern and not deleted_buffers[bufnr] then
          return bufnr
        end
      end
      return -1
    end

    -- Mock vim.fn.win_findbuf
    _G.vim.fn.win_findbuf = function(bufnr)
      -- For testing, assume buffers are not displayed unless specified
      return {}
    end

    -- Mock vim.fn.getcwd
    _G.vim.fn.getcwd = function()
      return '/test/current/dir'
    end

    -- Mock vim.api.nvim_get_current_buf
    _G.vim.api.nvim_get_current_buf = function()
      return 42
    end

    -- Mock vim.api.nvim_create_buf
    local buffer_counter = 100
    _G.vim.api.nvim_create_buf = function(listed, scratch)
      buffer_counter = buffer_counter + 1
      existing_buffers[buffer_counter] = nil  -- Track the buffer as existing
      return buffer_counter
    end

    -- Mock vim.api.nvim_open_win
    _G.vim.api.nvim_open_win = function(buf, enter, config)
      return 123
    end

    -- Mock vim.api.nvim_set_option_value
    _G.vim.api.nvim_set_option_value = function(option, value, opts)
      return true
    end

    -- Mock vim.api.nvim_win_set_buf
    _G.vim.api.nvim_win_set_buf = function(win_id, bufnr)
      return true
    end

    -- Mock vim.fn.termopen
    _G.vim.fn.termopen = function(cmd, opts)
      return 12345
    end

    -- Mock additional window/buffer functions
    _G.vim.api.nvim_win_is_valid = function(win_id)
      return win_id ~= nil and win_id > 0
    end

    _G.vim.api.nvim_get_current_win = function()
      return 200
    end

    _G.vim.api.nvim_win_close = function(win_id, force)
      return true
    end

    _G.vim.api.nvim_list_wins = function()
      return {200, 201, 202}
    end

    _G.vim.api.nvim_win_get_config = function(win_id)
      return {relative = ''}
    end

    -- Setup test objects
    config = {
      command = 'claude',
      window = {
        position = 'float',
        split_ratio = 0.5,
        enter_insert = true,
        start_in_normal_mode = false,
        hide_numbers = true,
        hide_signcolumn = true,
        float = {
          width = 80,
          height = 20,
          relative = 'editor',
          border = 'rounded'
        }
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

  after_each(function()
    -- Restore original os.time
    os.time = original_os_time
  end)

  describe('buffer name collision in floating window', function()
    it('should handle existing buffer with same name gracefully', function()
      -- Create a buffer with the name that would be generated
      local expected_name = 'claude-code-/test/git/root'
      local sanitized_name = expected_name:gsub('[^%w%-_]', '-')
      local existing_bufnr = 50
      existing_buffers[existing_bufnr] = sanitized_name

      -- Configure floating window
      config.window.position = 'float'
      
      -- Ensure no instances exist initially
      claude_code.claude_code.instances = {}

      -- Call toggle - this should handle the collision gracefully
      local success, error_msg = pcall(function()
        terminal.toggle(claude_code, config, git)
      end)

      -- Should succeed without throwing the E95 error
      assert.is_true(success, 'toggle should succeed when handling buffer name collision: ' .. (error_msg or ''))
      
      -- Should have deleted the existing buffer
      assert.is_true(deleted_buffers[existing_bufnr], 'existing buffer should be deleted')
      
      -- Should have created a new buffer with the same name
      local found_set_name = false
      for _, call in ipairs(nvim_buf_set_name_calls) do
        if call.name == sanitized_name then
          found_set_name = true
          break
        end
      end
      assert.is_true(found_set_name, 'new buffer should be created with the intended name')
    end)

    it('should use different name when existing buffer is displayed', function()
      -- Create a buffer with the name that would be generated
      local expected_name = 'claude-code-/test/git/root'
      local sanitized_name = expected_name:gsub('[^%w%-_]', '-')
      local existing_bufnr = 50
      existing_buffers[existing_bufnr] = sanitized_name

      -- Mock os.time for predictable timestamps in this test
      local original_time = os.time
      os.time = function()
        return 1234567890  -- Fixed timestamp for testing
      end

      -- Mock win_findbuf to return windows (buffer is displayed)
      _G.vim.fn.win_findbuf = function(bufnr)
        if bufnr == existing_bufnr then
          return {100, 101} -- Two windows displaying this buffer
        end
        return {}
      end

      -- Configure floating window
      config.window.position = 'float'
      
      -- Ensure no instances exist initially
      claude_code.claude_code.instances = {}

      -- Call toggle
      local success, error_msg = pcall(function()
        terminal.toggle(claude_code, config, git)
      end)

      -- Should succeed without throwing the E95 error
      assert.is_true(success, 'toggle should succeed when buffer is displayed: ' .. (error_msg or ''))
      
      -- Should NOT have deleted the existing buffer (it's displayed)
      assert.is_false(deleted_buffers[existing_bufnr] or false, 'displayed buffer should not be deleted')
      
      -- Should have created a new buffer with a different name (timestamped)
      -- The new format includes a random number: name-timestamp-random
      local found_timestamped_name = false
      local actual_name = nil
      for _, call in ipairs(nvim_buf_set_name_calls) do
        -- Check if the name matches the pattern: base-name-timestamp-random
        if call.name:match('^' .. vim.pesc(sanitized_name) .. '%-1234567890%-(%d+)$') then
          found_timestamped_name = true
          actual_name = call.name
          break
        end
      end
      assert.is_true(found_timestamped_name, 'new buffer should be created with timestamped name pattern: ' .. sanitized_name .. '-1234567890-XXXX, but got: ' .. (actual_name or 'none'))
      
      -- Restore original os.time
      os.time = original_time
    end)
  end)

  describe('buffer name collision in split window', function()
    it('should handle existing buffer with same name gracefully', function()
      -- Create a buffer with the name that would be generated
      local expected_name = 'claude-code-/test/git/root'
      local sanitized_name = expected_name:gsub('[^%w%-_]', '-')
      local existing_bufnr = 60
      existing_buffers[existing_bufnr] = sanitized_name

      -- Configure split window
      config.window.position = 'botright'
      
      -- Ensure no instances exist initially
      claude_code.claude_code.instances = {}

      -- Call toggle - this should handle the collision gracefully
      local success, error_msg = pcall(function()
        terminal.toggle(claude_code, config, git)
      end)

      -- Should succeed without throwing the E95 error
      assert.is_true(success, 'toggle should succeed when handling buffer name collision: ' .. (error_msg or ''))
      
      -- Should have deleted the existing buffer
      assert.is_true(deleted_buffers[existing_bufnr], 'existing buffer should be deleted')
      
      -- Should have created a new buffer with the same name using 'file' command
      local found_file_cmd = false
      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd == 'file ' .. sanitized_name then
          found_file_cmd = true
          break
        end
      end
      assert.is_true(found_file_cmd, 'file command should be called with the intended name')
    end)

    it('should use different name when existing buffer is displayed', function()
      -- Create a buffer with the name that would be generated
      local expected_name = 'claude-code-/test/git/root'
      local sanitized_name = expected_name:gsub('[^%w%-_]', '-')
      local existing_bufnr = 60
      existing_buffers[existing_bufnr] = sanitized_name

      -- Mock os.time for predictable timestamps in this test
      local original_time = os.time
      os.time = function()
        return 1234567890  -- Fixed timestamp for testing
      end

      -- Mock win_findbuf to return windows (buffer is displayed)
      _G.vim.fn.win_findbuf = function(bufnr)
        if bufnr == existing_bufnr then
          return {200, 201} -- Two windows displaying this buffer
        end
        return {}
      end

      -- Configure split window
      config.window.position = 'botright'
      
      -- Ensure no instances exist initially
      claude_code.claude_code.instances = {}

      -- Call toggle
      local success, error_msg = pcall(function()
        terminal.toggle(claude_code, config, git)
      end)

      -- Should succeed without throwing the E95 error
      assert.is_true(success, 'toggle should succeed when buffer is displayed: ' .. (error_msg or ''))
      
      -- Should NOT have deleted the existing buffer (it's displayed)
      assert.is_false(deleted_buffers[existing_bufnr] or false, 'displayed buffer should not be deleted')
      
      -- Should have created a new buffer with a different name (timestamped)
      -- The new format includes a random number: name-timestamp-random
      local found_timestamped_file_cmd = false
      local actual_cmd = nil
      for _, cmd in ipairs(vim_cmd_calls) do
        -- Check if the command matches the pattern: file base-name-timestamp-random
        if cmd:match('^file ' .. vim.pesc(sanitized_name) .. '%-1234567890%-(%d+)$') then
          found_timestamped_file_cmd = true
          actual_cmd = cmd
          break
        end
      end
      assert.is_true(found_timestamped_file_cmd, 'file command should be called with timestamped name pattern: file ' .. sanitized_name .. '-1234567890-XXXX, but got: ' .. (actual_cmd or 'none'))
      
      -- Restore original os.time
      os.time = original_time
    end)
  end)

  describe('buffer name collision edge cases', function()
    it('should handle invalid existing buffer gracefully', function()
      -- Create a buffer with the name that would be generated, but mark it as invalid
      local expected_name = 'claude-code-/test/git/root'
      local sanitized_name = expected_name:gsub('[^%w%-_]', '-')
      local existing_bufnr = 70
      existing_buffers[existing_bufnr] = sanitized_name
      deleted_buffers[existing_bufnr] = true -- Mark as deleted/invalid

      -- Configure floating window
      config.window.position = 'float'
      
      -- Ensure no instances exist initially
      claude_code.claude_code.instances = {}

      -- Call toggle
      local success, error_msg = pcall(function()
        terminal.toggle(claude_code, config, git)
      end)

      -- Should succeed without throwing the E95 error
      assert.is_true(success, 'toggle should succeed when existing buffer is invalid: ' .. (error_msg or ''))
      
      -- Should have created a new buffer with the intended name
      local found_set_name = false
      for _, call in ipairs(nvim_buf_set_name_calls) do
        if call.name == sanitized_name then
          found_set_name = true
          break
        end
      end
      assert.is_true(found_set_name, 'new buffer should be created with the intended name')
    end)

    it('should handle multiple collisions by using timestamp', function()
      -- Create a buffer with the name that would be generated
      local expected_name = 'claude-code-/test/git/root'
      local sanitized_name = expected_name:gsub('[^%w%-_]', '-')
      local existing_bufnr = 80
      existing_buffers[existing_bufnr] = sanitized_name

      -- Also create a buffer with the timestamped name (simulate second collision)
      -- Use our mocked timestamp value
      local timestamp = 1234567890
      local timestamped_name = sanitized_name .. '-' .. timestamp .. '-1234'  -- Match new format
      local existing_timestamped_bufnr = 81
      existing_buffers[existing_timestamped_bufnr] = timestamped_name

      -- Mock win_findbuf to return windows for both buffers (both are displayed)
      _G.vim.fn.win_findbuf = function(bufnr)
        if bufnr == existing_bufnr or bufnr == existing_timestamped_bufnr then
          return {300} -- One window displaying this buffer
        end
        return {}
      end

      -- Mock os.time to return predictable timestamp
      local original_time = os.time
      os.time = function()
        return timestamp
      end

      -- Configure floating window
      config.window.position = 'float'
      
      -- Ensure no instances exist initially
      claude_code.claude_code.instances = {}

      -- Call toggle
      local success, error_msg = pcall(function()
        terminal.toggle(claude_code, config, git)
      end)

      -- Restore original os.time
      os.time = original_time

      -- Should succeed without throwing the E95 error
      assert.is_true(success, 'toggle should succeed when handling multiple collisions: ' .. (error_msg or ''))
      
      -- Should NOT have deleted the existing buffers (they're displayed)
      assert.is_false(deleted_buffers[existing_bufnr] or false, 'first buffer should not be deleted')
      assert.is_false(deleted_buffers[existing_timestamped_bufnr] or false, 'timestamped buffer should not be deleted')
      
      -- Should have created a new buffer with a timestamped name
      -- The new format uses timestamp-random, and since both existing names are taken, 
      -- it will generate a fresh timestamp-random combination
      local found_timestamped_name = false
      local actual_name = nil
      
      -- Check for the new timestamp pattern
      local pattern = vim.pesc(sanitized_name) .. '%-1234567890%-(%d+)$'
      for _, call in ipairs(nvim_buf_set_name_calls) do
        if call.name:match(pattern) and call.name ~= timestamped_name then
          found_timestamped_name = true
          actual_name = call.name
          break
        end
      end
      
      assert.is_true(found_timestamped_name, 'new buffer should be created with timestamped name pattern: ' .. sanitized_name .. '-1234567890-XXXX, but got: ' .. (actual_name or 'none'))
    end)
  end)
end)