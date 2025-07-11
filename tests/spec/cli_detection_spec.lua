-- Test-Driven Development: CLI Detection Robustness Tests
-- Written BEFORE implementation to define expected behavior

describe('CLI detection', function()
  local config

  -- Mock vim functions for testing
  local original_expand
  local original_executable
  local original_filereadable
  local original_notify
  local notifications = {}

  before_each(function()
    -- Clear module cache and reload config
    package.loaded['claude-code.config'] = nil
    config = require('claude-code.config')

    -- Save original functions
    original_expand = vim.fn.expand
    original_executable = vim.fn.executable
    original_filereadable = vim.fn.filereadable
    original_notify = vim.notify

    -- Clear notifications
    notifications = {}

    -- Mock vim.notify to capture messages
    vim.notify = function(msg, level)
      table.insert(notifications, { msg = msg, level = level })
    end
  end)

  after_each(function()
    -- Restore original functions
    vim.fn.expand = original_expand
    vim.fn.executable = original_executable
    vim.fn.filereadable = original_filereadable
    vim.notify = original_notify

    -- Clear module cache to prevent pollution
    package.loaded['claude-code.config'] = nil
  end)

  describe('detect_claude_cli', function()
    it('should use custom CLI path from config when provided', function()
      -- Mock functions
      vim.fn.expand = function(path)
        return path
      end

      vim.fn.filereadable = function(path)
        if path == '/custom/path/to/claude' then
          return 1
        end
        return 0
      end

      vim.fn.executable = function(path)
        if path == '/custom/path/to/claude' then
          return 1
        end
        return 0
      end

      -- Test CLI detection with custom path
      local result = config._internal.detect_claude_cli('/custom/path/to/claude')
      assert.equals('/custom/path/to/claude', result)
    end)

    it('should return local installation path when it exists and is executable', function()
      -- Use environment-aware test paths
      local home_dir = os.getenv('HOME') or '/home/testuser'
      local expected_path = home_dir .. '/.claude/local/claude'

      -- Mock functions
      vim.fn.expand = function(path)
        if path == '~/.claude/local/claude' then
          return expected_path
        end
        return path
      end

      vim.fn.filereadable = function(path)
        if path == expected_path then
          return 1
        end
        return 0
      end

      vim.fn.executable = function(path)
        if path == expected_path then
          return 1
        end
        return 0
      end

      -- Test CLI detection without custom path
      local result = config._internal.detect_claude_cli()
      assert.equals(expected_path, result)
    end)

    it("should fall back to 'claude' in PATH when local installation doesn't exist", function()
      -- Mock functions
      vim.fn.expand = function(path)
        if path == '~/.claude/local/claude' then
          return '/home/user/.claude/local/claude'
        end
        return path
      end

      vim.fn.filereadable = function(path)
        return 0 -- Local file doesn't exist
      end

      vim.fn.executable = function(path)
        if path == 'claude' then
          return 1
        elseif path == '/home/user/.claude/local/claude' then
          return 0
        end
        return 0
      end

      -- Test CLI detection without custom path
      local result = config._internal.detect_claude_cli()
      assert.equals('claude', result)
    end)

    it('should return nil when no Claude CLI is found', function()
      -- Mock functions - no executable found
      vim.fn.expand = function(path)
        if path == '~/.claude/local/claude' then
          return '/home/user/.claude/local/claude'
        end
        return path
      end

      vim.fn.filereadable = function(path)
        return 0 -- Nothing is readable
      end

      vim.fn.executable = function(path)
        return 0 -- Nothing is executable
      end

      -- Test CLI detection without custom path
      local result = config._internal.detect_claude_cli()
      assert.is_nil(result)
    end)

    it('should return nil when custom CLI path is invalid', function()
      -- Mock functions
      vim.fn.expand = function(path)
        return path
      end

      vim.fn.filereadable = function(path)
        return 0 -- Custom path not readable
      end

      vim.fn.executable = function(path)
        return 0 -- Custom path not executable
      end

      -- Test CLI detection with invalid custom path
      local result = config._internal.detect_claude_cli('/invalid/path/claude')
      assert.is_nil(result)
    end)

    it('should fall back to default search when custom path is not found', function()
      -- Mock functions
      vim.fn.expand = function(path)
        if path == '~/.claude/local/claude' then
          return '/home/user/.claude/local/claude'
        end
        return path
      end

      vim.fn.filereadable = function(path)
        if path == '/invalid/custom/claude' then
          return 0 -- Custom path not found
        elseif path == '/home/user/.claude/local/claude' then
          return 1 -- Default local path exists
        end
        return 0
      end

      vim.fn.executable = function(path)
        if path == '/invalid/custom/claude' then
          return 0 -- Custom path not executable
        elseif path == '/home/user/.claude/local/claude' then
          return 1 -- Default local path executable
        end
        return 0
      end

      -- Test CLI detection with invalid custom path - should fall back
      local result = config._internal.detect_claude_cli('/invalid/custom/claude')
      assert.equals('/home/user/.claude/local/claude', result)
    end)

    it('should check file readability before executability for local installation', function()
      -- Mock functions
      vim.fn.expand = function(path)
        if path == '~/.claude/local/claude' then
          return '/home/user/.claude/local/claude'
        end
        return path
      end

      local checks = {}
      vim.fn.filereadable = function(path)
        table.insert(checks, { func = 'filereadable', path = path })
        if path == '/home/user/.claude/local/claude' then
          return 1
        end
        return 0
      end

      vim.fn.executable = function(path)
        table.insert(checks, { func = 'executable', path = path })
        if path == '/home/user/.claude/local/claude' then
          return 1
        end
        return 0
      end

      -- Test CLI detection without custom path
      local result = config._internal.detect_claude_cli()

      -- Verify order of checks
      assert.equals('filereadable', checks[1].func)
      assert.equals('/home/user/.claude/local/claude', checks[1].path)
      assert.equals('executable', checks[2].func)
      assert.equals('/home/user/.claude/local/claude', checks[2].path)

      assert.equals('/home/user/.claude/local/claude', result)
    end)
  end)

  describe('parse_config with CLI detection', function()
    it('should use detected CLI when no command is specified', function()
      -- Mock CLI detection
      vim.fn.expand = function(path)
        if path == '~/.claude/local/claude' then
          return '/home/user/.claude/local/claude'
        end
        return path
      end

      vim.fn.filereadable = function(path)
        if path == '/home/user/.claude/local/claude' then
          return 1
        end
        return 0
      end

      vim.fn.executable = function(path)
        if path == '/home/user/.claude/local/claude' then
          return 1
        end
        return 0
      end

      -- Parse config without command (not silent to test detection)
      local result = config.parse_config({})
      assert.equals('/home/user/.claude/local/claude', result.command)
    end)

    it('should notify user about detected local installation', function()
      -- Mock CLI detection
      vim.fn.expand = function(path)
        if path == '~/.claude/local/claude' then
          return '/home/user/.claude/local/claude'
        end
        return path
      end

      vim.fn.filereadable = function(path)
        if path == '/home/user/.claude/local/claude' then
          return 1
        end
        return 0
      end

      vim.fn.executable = function(path)
        if path == '/home/user/.claude/local/claude' then
          return 1
        end
        return 0
      end

      -- Parse config without silent mode
      local result = config.parse_config({ cli_notification = { enabled = true } })

      -- Check notification
      assert.equals(1, #notifications)
      assert.equals(
        'Claude Code: Using local installation at ~/.claude/local/claude',
        notifications[1].msg
      )
      assert.equals(vim.log.levels.INFO, notifications[1].level)
    end)

    it('should notify user about PATH installation', function()
      -- Mock CLI detection - only PATH available
      vim.fn.expand = function(path)
        if path == '~/.claude/local/claude' then
          return '/home/user/.claude/local/claude'
        end
        return path
      end

      vim.fn.filereadable = function(path)
        return 0 -- Local file doesn't exist
      end

      vim.fn.executable = function(path)
        if path == 'claude' then
          return 1
        else
          return 0
        end
      end

      -- Parse config without silent mode
      local result = config.parse_config({ cli_notification = { enabled = true } })

      -- Check notification
      assert.equals(1, #notifications)
      assert.equals("Claude Code: Using 'claude' from PATH", notifications[1].msg)
      assert.equals(vim.log.levels.INFO, notifications[1].level)
    end)

    it('should warn user when no CLI is found', function()
      -- Mock CLI detection - nothing found
      vim.fn.expand = function(path)
        if path == '~/.claude/local/claude' then
          return '/home/user/.claude/local/claude'
        end
        return path
      end

      vim.fn.filereadable = function(path)
        return 0 -- Nothing readable
      end

      vim.fn.executable = function(path)
        return 0 -- Nothing executable
      end

      -- Parse config without silent mode
      local result = config.parse_config({ cli_notification = { enabled = true } })

      -- Check warning notification
      assert.equals(1, #notifications)
      assert.equals(
        'Claude Code: CLI not found! Please install Claude Code or set config.command',
        notifications[1].msg
      )
      assert.equals(vim.log.levels.WARN, notifications[1].level)

      -- Should still set default command to avoid nil errors
      assert.equals('claude', result.command)
    end)

    it('should use custom CLI path from config when provided', function()
      -- Mock CLI detection
      vim.fn.expand = function(path)
        return path
      end

      vim.fn.filereadable = function(path)
        if path == '/custom/path/claude' then
          return 1
        end
        return 0
      end

      vim.fn.executable = function(path)
        if path == '/custom/path/claude' then
          return 1
        end
        return 0
      end

      -- Parse config with custom CLI path
      local result = config.parse_config({ cli_path = '/custom/path/claude', cli_notification = { enabled = true } }, false)

      -- Should use custom CLI path
      assert.equals('/custom/path/claude', result.command)

      -- Should notify about custom CLI
      assert.equals(1, #notifications)
      assert.equals('Claude Code: Using custom CLI at /custom/path/claude', notifications[1].msg)
      assert.equals(vim.log.levels.INFO, notifications[1].level)
    end)

    it('should warn when custom CLI path is not found', function()
      -- Mock CLI detection
      vim.fn.expand = function(path)
        return path
      end

      vim.fn.filereadable = function(path)
        return 0 -- Custom path not found
      end

      vim.fn.executable = function(path)
        return 0 -- Custom path not executable
      end

      -- Parse config with invalid custom CLI path
      local result = config.parse_config({ cli_path = '/invalid/path/claude', cli_notification = { enabled = true } }, false)

      -- Should fall back to default command
      assert.equals('claude', result.command)

      -- Should warn about invalid custom path and then warn about CLI not found
      assert.equals(2, #notifications)
      assert.equals(
        'Claude Code: Custom CLI path not found: /invalid/path/claude - falling back to default detection',
        notifications[1].msg
      )
      assert.equals(vim.log.levels.WARN, notifications[1].level)
      assert.equals(
        'Claude Code: CLI not found! Please install Claude Code or set config.command',
        notifications[2].msg
      )
      assert.equals(vim.log.levels.WARN, notifications[2].level)
    end)

    it('should use user-provided command over detection', function()
      -- Mock CLI detection
      vim.fn.expand = function(path)
        if path == '~/.claude/local/claude' then
          return '/home/user/.claude/local/claude'
        end
        return path
      end

      vim.fn.filereadable = function(path)
        return 1 -- Everything is readable
      end

      vim.fn.executable = function(path)
        return 1 -- Everything is executable
      end

      -- Parse config with explicit command
      local result = config.parse_config({ command = '/explicit/path/claude' }, false)

      -- Should use user's command
      assert.equals('/explicit/path/claude', result.command)

      -- Should not notify about detection
      assert.equals(0, #notifications)
    end)
  end)
end)
