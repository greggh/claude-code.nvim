---@mod claude-code.config Configuration management for claude-code.nvim
---@brief [[
--- This module handles configuration management and validation for claude-code.nvim.
--- It provides the default configuration, validation, and merging of user config.
---@brief ]]

local M = {}

--- ClaudeCodeWindow class for window configuration
-- @table ClaudeCodeWindow
-- @field split_ratio number Percentage of screen for the terminal window
-- (height for horizontal, width for vertical splits)
-- @field position string Position of the window: "botright", "topleft", "vertical", etc.
-- @field enter_insert boolean Whether to enter insert mode when opening Claude Code
-- @field start_in_normal_mode boolean Whether to start in normal mode instead of insert mode when opening Claude Code
-- @field hide_numbers boolean Hide line numbers in the terminal window
-- @field hide_signcolumn boolean Hide the sign column in the terminal window

--- ClaudeCodeRefresh class for file refresh configuration
-- @table ClaudeCodeRefresh
-- @field enable boolean Enable file change detection
-- @field updatetime number updatetime when Claude Code is active (milliseconds)
-- @field timer_interval number How often to check for file changes (milliseconds)
-- @field show_notifications boolean Show notification when files are reloaded

--- ClaudeCodeGit class for git integration configuration
-- @table ClaudeCodeGit
-- @field use_git_root boolean Set CWD to git root when opening Claude Code (if in git project)
-- @field multi_instance boolean Use multiple Claude instances (one per git root)

--- ClaudeCodeKeymapsToggle class for toggle keymap configuration
-- @table ClaudeCodeKeymapsToggle
-- @field normal string|boolean Normal mode keymap for toggling Claude Code, false to disable
-- @field terminal string|boolean Terminal mode keymap for toggling Claude Code, false to disable

--- ClaudeCodeKeymaps class for keymap configuration
-- @table ClaudeCodeKeymaps
-- @field toggle ClaudeCodeKeymapsToggle Keymaps for toggling Claude Code
-- @field window_navigation boolean Enable window navigation keymaps
-- @field scrolling boolean Enable scrolling keymaps

--- ClaudeCodeCommandVariants class for command variant configuration
-- @table ClaudeCodeCommandVariants
-- Conversation management:
-- @field continue string|boolean Resume the most recent conversation
-- @field resume string|boolean Display an interactive conversation picker
-- Output options:
-- @field verbose string|boolean Enable verbose logging with full turn-by-turn output
-- Additional options can be added as needed

--- ClaudeCodeMCP class for MCP server configuration
-- @table ClaudeCodeMCP
-- @field enabled boolean Enable MCP server
-- @field http_server table HTTP server configuration
-- @field http_server.host string Host to bind HTTP server to (default: "127.0.0.1")
-- @field http_server.port number Port for HTTP server (default: 27123)
-- @field session_timeout_minutes number Session timeout in minutes (default: 30)

--- ClaudeCodeConfig class for main configuration
-- @table ClaudeCodeConfig
-- @field window ClaudeCodeWindow Terminal window settings
-- @field refresh ClaudeCodeRefresh File refresh settings
-- @field git ClaudeCodeGit Git integration settings
-- @field command string Command used to launch Claude Code
-- @field command_variants ClaudeCodeCommandVariants Command variants configuration
-- @field keymaps ClaudeCodeKeymaps Keymaps configuration
-- @field mcp ClaudeCodeMCP MCP server configuration

--- Default configuration options
--- @type ClaudeCodeConfig
M.default_config = {
  -- Terminal window settings
  window = {
    split_ratio = 0.3, -- Percentage of screen for the terminal window (height or width)
    height_ratio = 0.3, -- DEPRECATED: Use split_ratio instead
    -- Window position: "current" (default - use current window), "float", "botright", "topleft", "vertical", etc.
    position = 'current',
    enter_insert = true, -- Whether to enter insert mode when opening Claude Code
    start_in_normal_mode = false, -- Whether to start in normal mode instead of insert mode
    hide_numbers = true, -- Hide line numbers in the terminal window
    hide_signcolumn = true, -- Hide the sign column in the terminal window
    -- Floating window specific settings
    float = {
      relative = 'editor', -- 'editor' or 'cursor'
      width = 0.8, -- Width as percentage of editor width (0.0-1.0)
      height = 0.8, -- Height as percentage of editor height (0.0-1.0)
      row = 0.1, -- Row position as percentage (0.0-1.0), 0.1 = 10% from top
      col = 0.1, -- Column position as percentage (0.0-1.0), 0.1 = 10% from left
      border = 'rounded', -- Border style: 'none', 'single', 'double', 'rounded', 'solid', 'shadow'
      title = ' Claude Code ', -- Window title
      title_pos = 'center', -- Title position: 'left', 'center', 'right'
    },
  },
  -- File refresh settings
  refresh = {
    enable = true, -- Enable file change detection
    updatetime = 100, -- updatetime to use when Claude Code is active (milliseconds)
    timer_interval = 1000, -- How often to check for file changes (milliseconds)
    show_notifications = true, -- Show notification when files are reloaded
  },
  -- Git integration settings
  git = {
    use_git_root = true, -- Set CWD to git root when opening Claude Code (if in git project)
    multi_instance = true, -- Use multiple Claude instances (one per git root)
  },
  -- Command settings
  command = 'claude', -- Command used to launch Claude Code
  cli_path = nil, -- Optional custom path to Claude CLI executable
  -- Command variants
  command_variants = {
    -- Conversation management
    continue = '--continue', -- Resume the most recent conversation
    resume = '--resume', -- Display an interactive conversation picker

    -- Output options
    verbose = '--verbose', -- Enable verbose logging with full turn-by-turn output
    -- Debugging options
    mcp_debug = '--mcp-debug', -- Enable MCP debug mode
  },
  -- Keymaps
  keymaps = {
    toggle = {
      normal = '<leader>aa', -- Normal mode keymap for toggling Claude Code
      terminal = '<leader>aa', -- Terminal mode keymap for toggling Claude Code
      variants = {
        continue = '<leader>ac', -- Normal mode keymap for Claude Code with continue flag
        verbose = '<leader>av', -- Normal mode keymap for Claude Code with verbose flag
        mcp_debug = '<leader>ad', -- Normal mode keymap for Claude Code with MCP debug flag
      },
    },
    selection = {
      send = '<leader>as', -- Visual mode keymap for sending selection to Claude Code
      explain = '<leader>ae', -- Visual mode keymap for explaining selection
      with_context = '<leader>aw', -- Visual mode keymap for toggling with selection
    },
    seamless = {
      claude = '<leader>cc', -- Normal/visual mode keymap for seamless Claude
      ask = '<leader>ca', -- Normal mode keymap for quick ask
    },
    window_navigation = true, -- Enable window navigation keymaps (<C-h/j/k/l>)
    scrolling = true, -- Enable scrolling keymaps (<C-f/b>) for page up/down
  },
  -- MCP server settings
  mcp = {
    enabled = true, -- Enable MCP server functionality
    http_server = {
      host = '127.0.0.1', -- Host to bind HTTP server to
      port = 27123, -- Port for HTTP server
    },
    session_timeout_minutes = 30, -- Session timeout in minutes
    auto_start = false, -- Don't auto-start by default (MCP server runs as separate process)
    auto_server_start = true, -- Auto-start Neovim server socket for seamless MCP connection
    tools = {
      buffer = true,
      command = true,
      status = true,
      edit = true,
      window = true,
      mark = true,
      register = true,
      visual = true,
    },
    resources = {
      current_buffer = true,
      buffer_list = true,
      project_structure = true,
      git_status = true,
      lsp_diagnostics = true,
      vim_options = true,
    },
    http_server = {
      host = '127.0.0.1', -- Host to bind HTTP server to
      port = 27123, -- Port for HTTP server
    },
    session_timeout_minutes = 30, -- Session timeout in minutes
  },
  -- Startup notification settings
  startup_notification = {
    enabled = false, -- Show startup notification when plugin loads (disabled by default)
    message = 'Claude Code plugin loaded', -- Custom startup message
    level = vim.log.levels.INFO, -- Log level for startup notification
  },
}

--- Validate window configuration
--- @param window table
--- @return boolean valid
--- @return string? error_message
local function validate_window_config(window)
  if type(window) ~= 'table' then
    return false, 'window config must be a table'
  end

  if type(window.split_ratio) ~= 'number' or window.split_ratio <= 0 or window.split_ratio > 1 then
    return false, 'window.split_ratio must be a number between 0 and 1'
  end

  if type(window.position) ~= 'string' then
    return false, 'window.position must be a string'
  end

  if type(window.enter_insert) ~= 'boolean' then
    return false, 'window.enter_insert must be a boolean'
  end

  if type(window.start_in_normal_mode) ~= 'boolean' then
    return false, 'window.start_in_normal_mode must be a boolean'
  end

  if type(window.hide_numbers) ~= 'boolean' then
    return false, 'window.hide_numbers must be a boolean'
  end

  if type(window.hide_signcolumn) ~= 'boolean' then
    return false, 'window.hide_signcolumn must be a boolean'
  end

  return true, nil
end

--- Validate refresh configuration
--- @param refresh table
--- @return boolean valid
--- @return string? error_message
local function validate_refresh_config(refresh)
  if type(refresh) ~= 'table' then
    return false, 'refresh config must be a table'
  end

  if type(refresh.enable) ~= 'boolean' then
    return false, 'refresh.enable must be a boolean'
  end

  if type(refresh.updatetime) ~= 'number' or refresh.updatetime <= 0 then
    return false, 'refresh.updatetime must be a positive number'
  end

  if type(refresh.timer_interval) ~= 'number' or refresh.timer_interval <= 0 then
    return false, 'refresh.timer_interval must be a positive number'
  end

  if type(refresh.show_notifications) ~= 'boolean' then
    return false, 'refresh.show_notifications must be a boolean'
  end

  return true, nil
end

--- Validate git configuration
--- @param git table
--- @return boolean valid
--- @return string? error_message
local function validate_git_config(git)
  if type(git) ~= 'table' then
    return false, 'git config must be a table'
  end

  if type(git.use_git_root) ~= 'boolean' then
    return false, 'git.use_git_root must be a boolean'
  end

  if type(git.multi_instance) ~= 'boolean' then
    return false, 'git.multi_instance must be a boolean'
  end

  return true, nil
end

--- Validate command configuration
--- @param config table
--- @return boolean valid
--- @return string? error_message
local function validate_command_config(config)
  if type(config.command) ~= 'string' then
    return false, 'command must be a string'
  end

  if config.cli_path ~= nil and type(config.cli_path) ~= 'string' then
    return false, 'cli_path must be a string or nil'
  end

  if type(config.command_variants) ~= 'table' then
    return false, 'command_variants config must be a table'
  end

  for variant_name, variant_args in pairs(config.command_variants) do
    if not (variant_args == false or type(variant_args) == 'string') then
      return false, 'command_variants.' .. variant_name .. ' must be a string or false'
    end
  end

  return true, nil
end

--- Validate keymaps configuration
--- @param keymaps table
--- @param command_variants table
--- @return boolean valid
--- @return string? error_message
local function validate_keymaps_config(keymaps, command_variants)
  if type(keymaps) ~= 'table' then
    return false, 'keymaps config must be a table'
  end

  if type(keymaps.toggle) ~= 'table' then
    return false, 'keymaps.toggle must be a table'
  end

  if not (keymaps.toggle.normal == false or type(keymaps.toggle.normal) == 'string') then
    return false, 'keymaps.toggle.normal must be a string or false'
  end

  if not (keymaps.toggle.terminal == false or type(keymaps.toggle.terminal) == 'string') then
    return false, 'keymaps.toggle.terminal must be a string or false'
  end

  -- Validate variant keymaps
  if keymaps.toggle.variants then
    if type(keymaps.toggle.variants) ~= 'table' then
      return false, 'keymaps.toggle.variants must be a table'
    end

    for variant_name, keymap in pairs(keymaps.toggle.variants) do
      if not (keymap == false or type(keymap) == 'string') then
        return false, 'keymaps.toggle.variants.' .. variant_name .. ' must be a string or false'
      end
      if keymap ~= false and not command_variants[variant_name] then
        return false,
          'keymaps.toggle.variants.' .. variant_name .. ' has no corresponding command variant'
      end
    end
  end

  -- Validate selection keymaps
  if keymaps.selection then
    if type(keymaps.selection) ~= 'table' then
      return false, 'keymaps.selection must be a table'
    end

    for key_name, keymap in pairs(keymaps.selection) do
      if not (keymap == false or type(keymap) == 'string' or keymap == nil) then
        return false, 'keymaps.selection.' .. key_name .. ' must be a string, false, or nil'
      end
    end
  end

  -- Validate seamless keymaps
  if keymaps.seamless then
    if type(keymaps.seamless) ~= 'table' then
      return false, 'keymaps.seamless must be a table'
    end

    for key_name, keymap in pairs(keymaps.seamless) do
      if not (keymap == false or type(keymap) == 'string' or keymap == nil) then
        return false, 'keymaps.seamless.' .. key_name .. ' must be a string, false, or nil'
      end
    end
  end

  if type(keymaps.window_navigation) ~= 'boolean' then
    return false, 'keymaps.window_navigation must be a boolean'
  end

  if type(keymaps.scrolling) ~= 'boolean' then
    return false, 'keymaps.scrolling must be a boolean'
  end

  return true, nil
end

--- Validate MCP configuration
--- @param mcp table
--- @return boolean valid
--- @return string? error_message
local function validate_mcp_config(mcp)
  if type(mcp) ~= 'table' then
    return false, 'mcp config must be a table'
  end

  if type(mcp.enabled) ~= 'boolean' then
    return false, 'mcp.enabled must be a boolean'
  end

  if type(mcp.http_server) ~= 'table' then
    return false, 'mcp.http_server config must be a table'
  end

  if type(mcp.http_server.host) ~= 'string' then
    return false, 'mcp.http_server.host must be a string'
  end

  if type(mcp.http_server.port) ~= 'number' then
    return false, 'mcp.http_server.port must be a number'
  end

  if type(mcp.session_timeout_minutes) ~= 'number' then
    return false, 'mcp.session_timeout_minutes must be a number'
  end

  if mcp.auto_start ~= nil and type(mcp.auto_start) ~= 'boolean' then
    return false, 'mcp.auto_start must be a boolean'
  end

  return true, nil
end

--- Validate startup notification configuration
--- @param config table
--- @return boolean valid
--- @return string? error_message
local function validate_startup_notification_config(config)
  if config.startup_notification == nil then
    return true, nil
  end

  if type(config.startup_notification) == 'boolean' then
    -- Allow simple boolean to enable/disable
    config.startup_notification = {
      enabled = config.startup_notification,
      message = 'Claude Code plugin loaded',
      level = vim.log.levels.INFO,
    }
  elseif type(config.startup_notification) == 'table' then
    -- Validate table structure
    if
      config.startup_notification.enabled ~= nil
      and type(config.startup_notification.enabled) ~= 'boolean'
    then
      return false, 'startup_notification.enabled must be a boolean'
    end

    if
      config.startup_notification.message ~= nil
      and type(config.startup_notification.message) ~= 'string'
    then
      return false, 'startup_notification.message must be a string'
    end

    if
      config.startup_notification.level ~= nil
      and type(config.startup_notification.level) ~= 'number'
    then
      return false, 'startup_notification.level must be a number'
    end

    -- Set defaults for missing values
    if config.startup_notification.enabled == nil then
      config.startup_notification.enabled = true
    end
    if config.startup_notification.message == nil then
      config.startup_notification.message = 'Claude Code plugin loaded'
    end
    if config.startup_notification.level == nil then
      config.startup_notification.level = vim.log.levels.INFO
    end
  else
    return false, 'startup_notification must be a boolean or table'
  end

  return true, nil
end

--- Validate the configuration
--- @param config ClaudeCodeConfig
--- @return boolean valid
--- @return string? error_message
local function validate_config(config)
  local valid, err

  valid, err = validate_window_config(config.window)
  if not valid then
    return false, err
  end

  valid, err = validate_refresh_config(config.refresh)
  if not valid then
    return false, err
  end

  valid, err = validate_git_config(config.git)
  if not valid then
    return false, err
  end

  valid, err = validate_command_config(config)
  if not valid then
    return false, err
  end

  valid, err = validate_keymaps_config(config.keymaps, config.command_variants)
  if not valid then
    return false, err
  end

  valid, err = validate_mcp_config(config.mcp)
  if not valid then
    return false, err
  end

  valid, err = validate_startup_notification_config(config)
  if not valid then
    return false, err
  end

  return true, nil
end

--- Detect Claude Code CLI installation
--- @param custom_path? string Optional custom CLI path to check first
--- @return string|nil The path to Claude Code executable, or nil if not found
local function detect_claude_cli(custom_path)
  -- First check custom path if provided
  if custom_path then
    if vim.fn.filereadable(custom_path) == 1 and vim.fn.executable(custom_path) == 1 then
      return custom_path
    end
    -- If custom path doesn't work, fall through to default search
  end

  -- Auto-detect Claude CLI across different installation methods
  -- Priority order ensures most specific/recent installations are preferred
  -- Check for local development installation (highest priority)
  -- ~/.claude/local/claude is used for development builds and custom installations
  local local_claude = vim.fn.expand('~/.claude/local/claude')
  if vim.fn.filereadable(local_claude) == 1 and vim.fn.executable(local_claude) == 1 then
    return local_claude
  end

  -- Fall back to system-wide installation in PATH
  -- This handles package manager installations, official releases, etc.
  if vim.fn.executable('claude') == 1 then
    return 'claude'
  end

  -- No Claude CLI found - return nil to trigger user notification
  return nil
end

--- Parse user configuration and merge with defaults
--- @param user_config? table
--- @param silent? boolean Set to true to suppress error notifications (for tests)
--- @return ClaudeCodeConfig
function M.parse_config(user_config, silent)
  -- Handle backward compatibility first
  if user_config and user_config.window then
    if user_config.window.height_ratio and not user_config.window.split_ratio then
      -- Copy height_ratio to split_ratio for backward compatibility
      user_config.window.split_ratio = user_config.window.height_ratio
    end
  end

  local config = vim.tbl_deep_extend('force', {}, M.default_config, user_config or {})

  -- Auto-detect Claude CLI if not explicitly set (skip in silent mode for tests)
  if not silent and (not user_config or not user_config.command) then
    local custom_path = config.cli_path
    local detected_cli = detect_claude_cli(custom_path)
    config.command = detected_cli or 'claude'

    -- Notify user about the CLI selection
    if not silent then
      if custom_path then
        if detected_cli == custom_path then
          vim.notify('Claude Code: Using custom CLI at ' .. custom_path, vim.log.levels.INFO)
        else
          vim.notify(
            'Claude Code: Custom CLI path not found: '
              .. custom_path
              .. ' - falling back to default detection',
            vim.log.levels.WARN
          )
          -- Continue with default detection notifications
          if detected_cli == vim.fn.expand('~/.claude/local/claude') then
            vim.notify(
              'Claude Code: Using local installation at ~/.claude/local/claude',
              vim.log.levels.INFO
            )
          elseif detected_cli and vim.fn.executable(detected_cli) == 1 then
            vim.notify("Claude Code: Using 'claude' from PATH", vim.log.levels.INFO)
          else
            vim.notify(
              'Claude Code: CLI not found! Please install Claude Code or set config.command',
              vim.log.levels.WARN
            )
          end
        end
      else
        -- No custom path, use standard detection notifications
        if detected_cli == vim.fn.expand('~/.claude/local/claude') then
          vim.notify(
            'Claude Code: Using local installation at ~/.claude/local/claude',
            vim.log.levels.INFO
          )
        elseif detected_cli and vim.fn.executable(detected_cli) == 1 then
          vim.notify("Claude Code: Using 'claude' from PATH", vim.log.levels.INFO)
        else
          vim.notify(
            'Claude Code: CLI not found! Please install Claude Code or set config.command',
            vim.log.levels.WARN
          )
        end
      end
    end
  end

  local valid, err = validate_config(config)
  if not valid then
    -- Only notify if not in silent mode
    if not silent then
      vim.notify('Claude Code: ' .. err, vim.log.levels.ERROR)
    end
    -- Fall back to default config in case of error
    return vim.deepcopy(M.default_config)
  end

  return config
end

-- Internal API for testing
M._internal = {
  detect_claude_cli = detect_claude_cli,
}

return M
