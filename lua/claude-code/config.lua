---@mod claude-code.config Configuration management for claude-code.nvim
---@brief [[
--- This module handles configuration management and validation for claude-code.nvim.
--- It provides the default configuration, validation, and merging of user config.
---@brief ]]

local M = {}

--- ClaudeCodeWindow class for window configuration
-- @table ClaudeCodeWindow
-- @field split_ratio number Percentage of screen for the terminal window (height for horizontal, width for vertical splits)
-- @field position string Position of the window: "botright", "topleft", "vertical", "float" etc.
-- @field enter_insert boolean Whether to enter insert mode when opening Claude Code
-- @field start_in_normal_mode boolean Whether to start in normal mode instead of insert mode when opening Claude Code
-- @field hide_numbers boolean Hide line numbers in the terminal window
-- @field hide_signcolumn boolean Hide the sign column in the terminal window
-- @field float table|nil Floating window configuration (only used when position is "float")
-- @field float.width number|string Width of floating window (number: columns, string: percentage like "80%")
-- @field float.height number|string Height of floating window (number: rows, string: percentage like "80%")
-- @field float.row number|string|nil Row position (number: absolute, string: "center" or percentage)
-- @field float.col number|string|nil Column position (number: absolute, string: "center" or percentage)
-- @field float.border string Border style: "none", "single", "double", "rounded", "solid", "shadow", or array
-- @field float.relative string Relative positioning: "editor" or "cursor"

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

--- ClaudeCodeConfig class for main configuration
-- @table ClaudeCodeConfig
-- @field window ClaudeCodeWindow Terminal window settings
-- @field refresh ClaudeCodeRefresh File refresh settings
-- @field git ClaudeCodeGit Git integration settings
-- @field command string Command used to launch Claude Code
-- @field command_variants ClaudeCodeCommandVariants Command variants configuration
-- @field keymaps ClaudeCodeKeymaps Keymaps configuration

--- Default configuration options
--- @type ClaudeCodeConfig
M.default_config = {
  -- Terminal window settings
  window = {
    split_ratio = 0.3, -- Percentage of screen for the terminal window (height or width)
    height_ratio = 0.3, -- DEPRECATED: Use split_ratio instead
    position = 'botright', -- Position of the window: "botright", "topleft", "vertical", "float", etc.
    enter_insert = true, -- Whether to enter insert mode when opening Claude Code
    start_in_normal_mode = false, -- Whether to start in normal mode instead of insert mode
    hide_numbers = true, -- Hide line numbers in the terminal window
    hide_signcolumn = true, -- Hide the sign column in the terminal window
    -- Default floating window configuration
    float = {
      width = '80%', -- Width as percentage of editor
      height = '80%', -- Height as percentage of editor
      row = 'center', -- Center vertically
      col = 'center', -- Center horizontally
      relative = 'editor', -- Position relative to editor
      border = 'rounded', -- Border style
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
  -- Command variants
  command_variants = {
    -- Conversation management
    continue = '--continue', -- Resume the most recent conversation
    resume = '--resume', -- Display an interactive conversation picker

    -- Output options
    verbose = '--verbose', -- Enable verbose logging with full turn-by-turn output
  },
  -- Keymaps
  keymaps = {
    toggle = {
      normal = '<C-,>', -- Normal mode keymap for toggling Claude Code
      terminal = '<C-,>', -- Terminal mode keymap for toggling Claude Code
      variants = {
        continue = '<leader>cC', -- Normal mode keymap for Claude Code with continue flag
        verbose = '<leader>cV', -- Normal mode keymap for Claude Code with verbose flag
      },
    },
    window_navigation = true, -- Enable window navigation keymaps (<C-h/j/k/l>)
    scrolling = true, -- Enable scrolling keymaps (<C-f/b>) for page up/down
  },
}

--- Validate the configuration
--- @param config ClaudeCodeConfig
--- @return boolean valid
--- @return string? error_message
local function validate_config(config)
  -- Validate window settings
  if type(config.window) ~= 'table' then
    return false, 'window config must be a table'
  end

  if
    type(config.window.split_ratio) ~= 'number'
    or config.window.split_ratio <= 0
    or config.window.split_ratio > 1
  then
    return false, 'window.split_ratio must be a number between 0 and 1'
  end

  if type(config.window.position) ~= 'string' then
    return false, 'window.position must be a string'
  end

  if type(config.window.enter_insert) ~= 'boolean' then
    return false, 'window.enter_insert must be a boolean'
  end

  if type(config.window.start_in_normal_mode) ~= 'boolean' then
    return false, 'window.start_in_normal_mode must be a boolean'
  end

  if type(config.window.hide_numbers) ~= 'boolean' then
    return false, 'window.hide_numbers must be a boolean'
  end

  if type(config.window.hide_signcolumn) ~= 'boolean' then
    return false, 'window.hide_signcolumn must be a boolean'
  end

  -- Validate float configuration if position is "float"
  if config.window.position == 'float' then
    if type(config.window.float) ~= 'table' then
      return false, 'window.float must be a table when position is "float"'
    end

    -- Validate width (can be number or percentage string)
    if type(config.window.float.width) == 'string' then
      if not config.window.float.width:match('^%d+%%$') then
        return false, 'window.float.width must be a number or percentage (e.g., "80%")'
      end
    elseif type(config.window.float.width) ~= 'number' or config.window.float.width <= 0 then
      return false, 'window.float.width must be a positive number or percentage string'
    end

    -- Validate height (can be number or percentage string)
    if type(config.window.float.height) == 'string' then
      if not config.window.float.height:match('^%d+%%$') then
        return false, 'window.float.height must be a number or percentage (e.g., "80%")'
      end
    elseif type(config.window.float.height) ~= 'number' or config.window.float.height <= 0 then
      return false, 'window.float.height must be a positive number or percentage string'
    end

    -- Validate relative (must be "editor" or "cursor")
    if config.window.float.relative ~= 'editor' and config.window.float.relative ~= 'cursor' then
      return false, 'window.float.relative must be "editor" or "cursor"'
    end

    -- Validate border (must be valid border style)
    local valid_borders = { 'none', 'single', 'double', 'rounded', 'solid', 'shadow' }
    local is_valid_border = false
    for _, border in ipairs(valid_borders) do
      if config.window.float.border == border then
        is_valid_border = true
        break
      end
    end
    -- Also allow array borders
    if not is_valid_border and type(config.window.float.border) ~= 'table' then
      return false, 'window.float.border must be one of: none, single, double, rounded, solid, shadow, or an array'
    end

    -- Validate row and col if they exist
    if config.window.float.row ~= nil then
      if type(config.window.float.row) == 'string' and config.window.float.row ~= 'center' then
        if not config.window.float.row:match('^%d+%%$') then
          return false, 'window.float.row must be a number, "center", or percentage string'
        end
      elseif type(config.window.float.row) ~= 'number' and config.window.float.row ~= 'center' then
        return false, 'window.float.row must be a number, "center", or percentage string'
      end
    end

    if config.window.float.col ~= nil then
      if type(config.window.float.col) == 'string' and config.window.float.col ~= 'center' then
        if not config.window.float.col:match('^%d+%%$') then
          return false, 'window.float.col must be a number, "center", or percentage string'
        end
      elseif type(config.window.float.col) ~= 'number' and config.window.float.col ~= 'center' then
        return false, 'window.float.col must be a number, "center", or percentage string'
      end
    end
  end

  -- Validate refresh settings
  if type(config.refresh) ~= 'table' then
    return false, 'refresh config must be a table'
  end

  if type(config.refresh.enable) ~= 'boolean' then
    return false, 'refresh.enable must be a boolean'
  end

  if type(config.refresh.updatetime) ~= 'number' or config.refresh.updatetime <= 0 then
    return false, 'refresh.updatetime must be a positive number'
  end

  if type(config.refresh.timer_interval) ~= 'number' or config.refresh.timer_interval <= 0 then
    return false, 'refresh.timer_interval must be a positive number'
  end

  if type(config.refresh.show_notifications) ~= 'boolean' then
    return false, 'refresh.show_notifications must be a boolean'
  end

  -- Validate git settings
  if type(config.git) ~= 'table' then
    return false, 'git config must be a table'
  end

  if type(config.git.use_git_root) ~= 'boolean' then
    return false, 'git.use_git_root must be a boolean'
  end

  if type(config.git.multi_instance) ~= 'boolean' then
    return false, 'git.multi_instance must be a boolean'
  end

  -- Validate command settings
  if type(config.command) ~= 'string' then
    return false, 'command must be a string'
  end

  -- Validate command variants settings
  if type(config.command_variants) ~= 'table' then
    return false, 'command_variants config must be a table'
  end

  -- Check each command variant
  for variant_name, variant_args in pairs(config.command_variants) do
    if not (variant_args == false or type(variant_args) == 'string') then
      return false, 'command_variants.' .. variant_name .. ' must be a string or false'
    end
  end

  -- Validate keymaps settings
  if type(config.keymaps) ~= 'table' then
    return false, 'keymaps config must be a table'
  end

  if type(config.keymaps.toggle) ~= 'table' then
    return false, 'keymaps.toggle must be a table'
  end

  if
    not (config.keymaps.toggle.normal == false or type(config.keymaps.toggle.normal) == 'string')
  then
    return false, 'keymaps.toggle.normal must be a string or false'
  end

  if
    not (
      config.keymaps.toggle.terminal == false or type(config.keymaps.toggle.terminal) == 'string'
    )
  then
    return false, 'keymaps.toggle.terminal must be a string or false'
  end

  -- Validate variant keymaps if they exist
  if config.keymaps.toggle.variants then
    if type(config.keymaps.toggle.variants) ~= 'table' then
      return false, 'keymaps.toggle.variants must be a table'
    end

    -- Check each variant keymap
    for variant_name, keymap in pairs(config.keymaps.toggle.variants) do
      if not (keymap == false or type(keymap) == 'string') then
        return false, 'keymaps.toggle.variants.' .. variant_name .. ' must be a string or false'
      end
      -- Ensure variant exists in command_variants
      if keymap ~= false and not config.command_variants[variant_name] then
        return false,
          'keymaps.toggle.variants.' .. variant_name .. ' has no corresponding command variant'
      end
    end
  end

  if type(config.keymaps.window_navigation) ~= 'boolean' then
    return false, 'keymaps.window_navigation must be a boolean'
  end

  if type(config.keymaps.scrolling) ~= 'boolean' then
    return false, 'keymaps.scrolling must be a boolean'
  end

  return true, nil
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

  -- If position is float and no float config provided, use default float config
  if config.window.position == 'float' and not (user_config and user_config.window and user_config.window.float) then
    config.window.float = vim.deepcopy(M.default_config.window.float)
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

return M
