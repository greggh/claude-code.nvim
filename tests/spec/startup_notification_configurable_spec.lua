local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local assert = require('luassert')
local before_each = require('plenary.busted').before_each

describe('Startup Notification Configuration', function()
  local claude_code
  local original_notify
  local notifications

  before_each(function()
    -- Clear module cache
    package.loaded['claude-code'] = nil
    package.loaded['claude-code.config'] = nil

    -- Capture notifications
    notifications = {}
    original_notify = vim.notify
    vim.notify = function(msg, level, opts)
      table.insert(notifications, { msg = msg, level = level, opts = opts })
    end
  end)

  after_each(function()
    -- Restore original notify
    vim.notify = original_notify
  end)

  describe('startup notification control', function()
    it('should hide startup notification by default', function()
      -- Load plugin with default configuration (notifications disabled by default)
      claude_code = require('claude-code')
      claude_code.setup({
        command = 'echo', -- Use echo as mock command for tests to avoid CLI detection
      })

      -- Should NOT have startup notification by default
      local found_startup = false
      for _, notif in ipairs(notifications) do
        if notif.msg:match('Claude Code plugin loaded') then
          found_startup = true
          break
        end
      end

      assert.is_false(found_startup, 'Should hide startup notification by default')
    end)

    it('should show startup notification when explicitly enabled', function()
      -- Load plugin with startup notification explicitly enabled
      claude_code = require('claude-code')
      claude_code.setup({
        command = 'echo', -- Use echo as mock command for tests to avoid CLI detection
        startup_notification = {
          enabled = true,
        },
      })

      -- Should have startup notification when enabled
      local found_startup = false
      for _, notif in ipairs(notifications) do
        if notif.msg:match('Claude Code plugin loaded') then
          found_startup = true
          assert.equals(vim.log.levels.INFO, notif.level)
          break
        end
      end

      assert.is_true(found_startup, 'Should show startup notification when explicitly enabled')
    end)

    it('should hide startup notification when disabled in config', function()
      -- Load plugin with startup notification disabled
      claude_code = require('claude-code')
      claude_code.setup({
        startup_notification = false,
      })

      -- Should not have startup notification
      local found_startup = false
      for _, notif in ipairs(notifications) do
        if notif.msg:match('Claude Code plugin loaded') then
          found_startup = true
          break
        end
      end

      assert.is_false(found_startup, 'Should hide startup notification when disabled')
    end)

    it('should allow custom startup notification message', function()
      -- Load plugin with custom startup message
      claude_code = require('claude-code')
      claude_code.setup({
        startup_notification = {
          enabled = true,
          message = 'Custom Claude Code ready!',
          level = vim.log.levels.WARN,
        },
      })

      -- Should have custom startup notification
      local found_custom = false
      for _, notif in ipairs(notifications) do
        if notif.msg:match('Custom Claude Code ready!') then
          found_custom = true
          assert.equals(vim.log.levels.WARN, notif.level)
          break
        end
      end

      assert.is_true(found_custom, 'Should show custom startup notification')
    end)

    it('should support different notification levels', function()
      local test_levels = {
        { level = vim.log.levels.DEBUG, name = 'DEBUG' },
        { level = vim.log.levels.INFO, name = 'INFO' },
        { level = vim.log.levels.WARN, name = 'WARN' },
        { level = vim.log.levels.ERROR, name = 'ERROR' },
      }

      for _, test_case in ipairs(test_levels) do
        -- Clear notifications
        notifications = {}

        -- Clear module cache
        package.loaded['claude-code'] = nil

        -- Load plugin with specific level
        claude_code = require('claude-code')
        claude_code.setup({
          startup_notification = {
            enabled = true,
            message = 'Test message for ' .. test_case.name,
            level = test_case.level,
          },
        })

        -- Find the notification
        local found = false
        for _, notif in ipairs(notifications) do
          if notif.msg:match('Test message for ' .. test_case.name) then
            assert.equals(test_case.level, notif.level)
            found = true
            break
          end
        end

        assert.is_true(found, 'Should support ' .. test_case.name .. ' level')
      end
    end)

    it('should handle invalid configuration gracefully', function()
      -- Test with various invalid configurations
      local invalid_configs = {
        { startup_notification = 'invalid_string' },
        { startup_notification = 123 },
        { startup_notification = { enabled = 'not_boolean' } },
        { startup_notification = { message = 123 } },
        { startup_notification = { level = 'invalid_level' } },
      }

      for _, invalid_config in ipairs(invalid_configs) do
        -- Clear notifications
        notifications = {}

        -- Clear module cache
        package.loaded['claude-code'] = nil

        -- Should not crash with invalid config
        assert.has_no.error(function()
          claude_code = require('claude-code')
          claude_code.setup(invalid_config)
        end)
      end
    end)
  end)

  describe('notification timing', function()
    it('should notify after successful setup', function()
      -- Setup should complete before notification
      claude_code = require('claude-code')

      -- Should have some notifications before setup
      local pre_setup_count = #notifications

      claude_code.setup({
        startup_notification = {
          enabled = true,
          message = 'Setup completed successfully',
        },
      })

      -- Should have more notifications after setup
      assert.is_true(#notifications > pre_setup_count, 'Should have more notifications after setup')

      -- The startup notification should be among the last
      local found_at_end = false
      for i = pre_setup_count + 1, #notifications do
        if notifications[i].msg:match('Setup completed successfully') then
          found_at_end = true
          break
        end
      end

      assert.is_true(found_at_end, 'Startup notification should appear after setup')
    end)
  end)
end)
