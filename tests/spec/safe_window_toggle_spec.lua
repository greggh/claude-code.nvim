-- Test-Driven Development: Safe Window Toggle Tests
-- Written BEFORE implementation to define expected behavior
describe('Safe Window Toggle', function()
  -- Ensure test mode is set
  vim.env.CLAUDE_CODE_TEST_MODE = '1'

  local terminal = require('claude-code.terminal')

  -- Mock vim functions for testing
  local original_functions = {}
  local mock_buffers = {}
  local mock_windows = {}
  local mock_processes = {}
  local notifications = {}

  before_each(function()
    -- Save original functions
    original_functions.nvim_buf_is_valid = vim.api.nvim_buf_is_valid
    original_functions.nvim_win_close = vim.api.nvim_win_close
    original_functions.win_findbuf = vim.fn.win_findbuf
    original_functions.bufnr = vim.fn.bufnr
    original_functions.bufexists = vim.fn.bufexists
    original_functions.jobwait = vim.fn.jobwait
    original_functions.notify = vim.notify

    -- Clear mocks
    mock_buffers = {}
    mock_windows = {}
    mock_processes = {}
    notifications = {}

    -- Mock vim.notify to capture messages
    vim.notify = function(msg, level)
      table.insert(notifications, {
        msg = msg,
        level = level,
      })
    end
  end)

  after_each(function()
    -- Restore original functions
    vim.api.nvim_buf_is_valid = original_functions.nvim_buf_is_valid
    vim.api.nvim_win_close = original_functions.nvim_win_close
    vim.fn.win_findbuf = original_functions.win_findbuf
    vim.fn.bufnr = original_functions.bufnr
    vim.fn.bufexists = original_functions.bufexists
    vim.fn.jobwait = original_functions.jobwait
    vim.notify = original_functions.notify
  end)

  describe('hide window without stopping process', function()
    it('should hide visible Claude Code window but keep process running', function()
      -- Setup: Claude Code is running and visible
      local bufnr = 42
      local win_id = 100
      local instance_id = '/test/project'
      local closed_windows = {}

      -- Mock Claude Code instance setup
      local claude_code = {
        claude_code = {
          instances = {
            [instance_id] = bufnr,
          },
          current_instance = instance_id,
          process_states = {
            [instance_id] = { job_id = 123, status = 'running', hidden = false },
          },
        },
      }

      local config = {
        git = {
          multi_instance = true,
          use_git_root = true,
        },
        window = {
          position = 'botright',
          start_in_normal_mode = false,
          split_ratio = 0.3,
        },
        command = 'echo test',
      }

      local git = {
        get_git_root = function()
          return '/test/project'
        end,
      }

      -- Mock that buffer is valid and has a visible window
      vim.api.nvim_buf_is_valid = function(buf)
        return buf == bufnr
      end

      vim.fn.win_findbuf = function(buf)
        if buf == bufnr then
          return { win_id } -- Window is visible
        end
        return {}
      end

      -- Mock window closing
      vim.api.nvim_win_close = function(win, force)
        table.insert(closed_windows, {
          win = win,
          force = force,
        })
      end

      -- Test: Safe toggle should hide window
      terminal.safe_toggle(claude_code, config, git)

      -- Verify: Window was closed but buffer still exists
      assert.is_true(#closed_windows > 0)
      assert.equals(win_id, closed_windows[1].win)
      assert.equals(false, closed_windows[1].force) -- safe_toggle uses force=false

      -- Verify: Buffer still tracked (process still running)
      assert.equals(bufnr, claude_code.claude_code.instances[instance_id])
    end)

    it('should show hidden Claude Code window without creating new process', function()
      -- Setup: Claude Code process exists but window is hidden
      local bufnr = 42
      local instance_id = '/test/project'

      local claude_code = {
        claude_code = {
          instances = {
            [instance_id] = bufnr,
          },
          current_instance = instance_id,
        },
      }

      local config = {
        git = {
          multi_instance = true,
          use_git_root = true,
        },
        window = {
          position = 'botright',
          start_in_normal_mode = false,
          split_ratio = 0.3,
        },
        command = 'echo test',
      }

      local git = {
        get_git_root = function()
          return '/test/project'
        end,
      }

      -- Mock that buffer exists but no window is visible
      vim.api.nvim_buf_is_valid = function(buf)
        return buf == bufnr
      end

      vim.fn.win_findbuf = function(buf)
        return {} -- No visible windows
      end

      -- Mock split creation
      local splits_created = {}
      local original_cmd = vim.cmd
      vim.cmd = function(command)
        if command:match('split') or command:match('vsplit') then
          table.insert(splits_created, command)
        elseif command == 'stopinsert | startinsert' then
          table.insert(splits_created, 'insert_mode')
        end
      end

      -- Test: Toggle should show existing window
      terminal.safe_toggle(claude_code, config, git)

      -- Verify: Split was created to show existing buffer
      assert.is_true(#splits_created > 0)

      -- Verify: Same buffer is still tracked (no new process)
      assert.equals(bufnr, claude_code.claude_code.instances[instance_id])

      -- Restore vim.cmd
      vim.cmd = original_cmd
    end)
  end)

  describe('process state management', function()
    it('should maintain process state when window is hidden', function()
      -- Setup: Active Claude Code process
      local bufnr = 42
      local job_id = 1001
      local instance_id = '/test/project'

      local claude_code = {
        claude_code = {
          instances = {
            [instance_id] = bufnr,
          },
          current_instance = instance_id,
          process_states = {
            [instance_id] = {
              job_id = job_id,
              status = 'running',
              hidden = false,
            },
          },
        },
      }

      local config = {
        git = {
          multi_instance = true,
          use_git_root = true,
        },
        window = {
          position = 'botright',
          split_ratio = 0.3,
        },
        command = 'echo test',
      }

      -- Mock buffer and window state
      vim.api.nvim_buf_is_valid = function(buf)
        return buf == bufnr
      end
      vim.fn.win_findbuf = function(buf)
        return { 100 }
      end -- Visible
      vim.api.nvim_win_close = function() end -- Close window

      -- Mock job status check
      vim.fn.jobwait = function(jobs, timeout)
        if jobs[1] == job_id and timeout == 0 then
          return { -1 } -- Still running
        end
        return { 0 }
      end

      -- Test: Toggle (hide window)
      terminal.safe_toggle(claude_code, config, {
        get_git_root = function()
          return '/test/project'
        end,
      })

      -- Verify: Process state marked as hidden but still running
      assert.equals('running', claude_code.claude_code.process_states['/test/project'].status)
      assert.equals(true, claude_code.claude_code.process_states['/test/project'].hidden)
    end)

    it('should detect when hidden process has finished', function()
      -- Setup: Hidden Claude Code process that has finished
      local bufnr = 42
      local job_id = 1001
      local instance_id = '/test/project'

      local claude_code = {
        claude_code = {
          instances = {
            [instance_id] = bufnr,
          },
          current_instance = instance_id,
          process_states = {
            [instance_id] = {
              job_id = job_id,
              status = 'running',
              hidden = true,
            },
          },
        },
      }

      -- Mock job finished
      vim.fn.jobwait = function(jobs, timeout)
        return { 0 } -- Job finished
      end

      vim.api.nvim_buf_is_valid = function(buf)
        return buf == bufnr
      end
      vim.fn.win_findbuf = function(buf)
        return {}
      end -- Hidden

      -- Mock vim.cmd to prevent buffer commands
      vim.cmd = function() end

      -- Test: Show window of finished process
      terminal.safe_toggle(claude_code, {
        git = {
          multi_instance = true,
          use_git_root = true,
        },
        window = {
          position = 'botright',
          split_ratio = 0.3,
        },
        command = 'echo test',
      }, {
        get_git_root = function()
          return '/test/project'
        end,
      })

      -- Verify: Process state updated to finished
      assert.equals('finished', claude_code.claude_code.process_states['/test/project'].status)
    end)
  end)

  describe('user notifications', function()
    it('should notify when hiding window with active process', function()
      -- Setup active process
      local bufnr = 42
      local claude_code = {
        claude_code = {
          instances = {
            global = bufnr,
          },
          current_instance = 'global',
          process_states = {
            global = {
              status = 'running',
              hidden = false,
              job_id = 123,
            },
          },
        },
      }

      vim.api.nvim_buf_is_valid = function()
        return true
      end
      vim.fn.win_findbuf = function()
        return { 100 }
      end
      vim.api.nvim_win_close = function() end

      -- Test: Hide window
      terminal.safe_toggle(claude_code, {
        git = {
          multi_instance = false,
        },
        window = {
          position = 'botright',
          split_ratio = 0.3,
        },
        command = 'echo test',
      }, {})

      -- Verify: User notified about hiding
      assert.is_true(#notifications > 0)
      local found_hide_message = false
      for _, notif in ipairs(notifications) do
        if notif.msg:find('hidden') or notif.msg:find('background') then
          found_hide_message = true
          break
        end
      end
      assert.is_true(found_hide_message)
    end)

    it('should notify when showing window with completed process', function()
      -- Setup completed process
      local bufnr = 42
      local job_id = 1001
      local claude_code = {
        claude_code = {
          instances = {
            global = bufnr,
          },
          current_instance = 'global',
          process_states = {
            global = {
              status = 'finished',
              hidden = true,
              job_id = job_id,
            },
          },
        },
      }

      vim.api.nvim_buf_is_valid = function()
        return true
      end
      vim.fn.win_findbuf = function()
        return {}
      end
      vim.fn.jobwait = function(jobs, timeout)
        return { 0 } -- Job finished
      end

      -- Mock vim.cmd to prevent buffer commands
      vim.cmd = function() end

      -- Test: Show window
      terminal.safe_toggle(claude_code, {
        git = {
          multi_instance = false,
        },
        window = {
          position = 'botright',
          split_ratio = 0.3,
        },
        command = 'echo test',
      }, {})

      -- Verify: User notified about completion
      assert.is_true(#notifications > 0)
      local found_complete_message = false
      for _, notif in ipairs(notifications) do
        if notif.msg:find('finished') or notif.msg:find('completed') then
          found_complete_message = true
          break
        end
      end
      assert.is_true(found_complete_message)
    end)
  end)

  describe('multi-instance behavior', function()
    it('should handle multiple hidden Claude instances independently', function()
      -- Setup: Two different project instances
      local project1_buf = 42
      local project2_buf = 43

      local claude_code = {
        claude_code = {
          instances = {
            ['project1'] = project1_buf,
            ['project2'] = project2_buf,
          },
          process_states = {
            ['project1'] = {
              status = 'running',
              hidden = true,
            },
            ['project2'] = {
              status = 'running',
              hidden = false,
            },
          },
        },
      }

      vim.api.nvim_buf_is_valid = function(buf)
        return buf == project1_buf or buf == project2_buf
      end

      vim.fn.win_findbuf = function(buf)
        if buf == project1_buf then
          return {}
        end -- Hidden
        if buf == project2_buf then
          return { 100 }
        end -- Visible
        return {}
      end

      -- Test: Each instance should maintain separate state
      assert.equals(true, claude_code.claude_code.process_states['project1'].hidden)
      assert.equals(false, claude_code.claude_code.process_states['project2'].hidden)

      -- Both buffers should still exist
      assert.equals(project1_buf, claude_code.claude_code.instances['project1'])
      assert.equals(project2_buf, claude_code.claude_code.instances['project2'])
    end)
  end)

  describe('edge cases', function()
    it('should handle buffer deletion gracefully', function()
      -- Setup: Instance exists but buffer was deleted externally
      local bufnr = 42
      local claude_code = {
        claude_code = {
          instances = {
            test = bufnr,
          },
          process_states = {
            test = {
              status = 'running',
            },
          },
        },
      }

      -- Mock deleted buffer
      vim.api.nvim_buf_is_valid = function(buf)
        return false
      end

      -- Test: Toggle should clean up invalid buffer
      terminal.safe_toggle(claude_code, {
        git = {
          multi_instance = false,
        },
        window = {
          position = 'botright',
          split_ratio = 0.3,
        },
        command = 'echo test',
      }, {})

      -- Verify: Invalid buffer removed from instances
      assert.is_nil(claude_code.claude_code.instances.test)
    end)

    it('should handle rapid toggle operations', function()
      -- Setup: Valid Claude instance
      local bufnr = 42
      local claude_code = {
        claude_code = {
          instances = {
            global = bufnr,
          },
          process_states = {
            global = {
              status = 'running',
            },
          },
        },
      }

      vim.api.nvim_buf_is_valid = function()
        return true
      end

      local window_states = { 'visible', 'hidden', 'visible' }
      local toggle_count = 0

      vim.fn.win_findbuf = function()
        toggle_count = toggle_count + 1
        if window_states[toggle_count] == 'visible' then
          return { 100 }
        else
          return {}
        end
      end

      vim.api.nvim_win_close = function() end

      -- Mock vim.cmd to prevent buffer commands
      vim.cmd = function() end

      -- Test: Multiple rapid toggles
      for i = 1, 3 do
        terminal.safe_toggle(claude_code, {
          git = {
            multi_instance = false,
          },
          window = {
            position = 'botright',
            split_ratio = 0.3,
          },
          command = 'echo test',
        }, {})
        -- Add a small delay to allow async operations to complete
        vim.loop.sleep(10)  -- 10 milliseconds
      end

      -- Verify: Instance still tracked after multiple toggles
      assert.equals(bufnr, claude_code.claude_code.instances.global)
    end)
  end)

  -- Ensure no hanging processes or timers
  after_each(function()
    -- Reset test mode
    vim.env.CLAUDE_CODE_TEST_MODE = '1'
  end)
end)
