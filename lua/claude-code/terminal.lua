---@mod claude-code.terminal Terminal management for claude-code.nvim
---@brief [[
--- This module provides terminal buffer management for claude-code.nvim.
--- It handles creating, toggling, and managing the terminal window.
---@brief ]]

local M = {}

--- Terminal buffer and window management
-- @table ClaudeCodeTerminal
-- @field instances table Key-value store of git root to buffer number
-- @field saved_updatetime number|nil Original updatetime before Claude Code was opened
-- @field current_instance string|nil Current git root path for active instance
M.terminal = {
  instances = {},
  saved_updatetime = nil,
  current_instance = nil,
}

--- Get the current git root or a fallback identifier
--- @param git table The git module
--- @return string identifier Git root path or fallback identifier
local function get_instance_identifier(git)
  local git_root = git.get_git_root()
  if git_root then
    return git_root
  else
    -- Fallback to current working directory if not in a git repo
    return vim.fn.getcwd()
  end
end

--- Calculate floating window dimensions from percentage strings
--- @param value number|string Dimension value (number or percentage string)
--- @param max_value number Maximum value (columns or lines)
--- @return number Calculated dimension
--- @private
local function calculate_float_dimension(value, max_value)
  if value == nil then
    return math.floor(max_value * 0.8) -- Default to 80% if not specified
  elseif type(value) == 'string' and value:match('^%d+%%$') then
    local percentage = tonumber(value:match('^(%d+)%%$'))
    return math.floor(max_value * percentage / 100)
  end
  return value
end

--- Calculate floating window position for centering
--- @param value number|string Position value (number, "center", or percentage)
--- @param window_size number Size of the window
--- @param max_value number Maximum value (columns or lines)
--- @return number Calculated position
--- @private
local function calculate_float_position(value, window_size, max_value)
  local pos
  if value == 'center' then
    pos = math.floor((max_value - window_size) / 2)
  elseif type(value) == 'string' and value:match('^%d+%%$') then
    local percentage = tonumber(value:match('^(%d+)%%$'))
    pos = math.floor(max_value * percentage / 100)
  else
    pos = value or 0
  end
  -- Clamp position to ensure window is visible
  return math.max(0, math.min(pos, max_value - window_size))
end

--- Create a floating window for Claude Code
--- @param config table Plugin configuration containing window settings
--- @param existing_bufnr number|nil Buffer number of existing buffer to show in the float (optional)
--- @param claude_code table|nil Main plugin module for terminal job management (optional)
--- @param git table|nil Git module for building commands (optional)
--- @param instance_id string|nil Instance identifier for cleanup tracking (optional)
--- @return number Window ID of the created floating window
--- @private
local function create_float(config, existing_bufnr, claude_code, git, instance_id)
  local float_config = config.window.float or {}

  -- Get editor dimensions (accounting for command line, status line, etc.)
  local editor_width = vim.o.columns
  local editor_height = vim.o.lines - vim.o.cmdheight - 1 -- Subtract command line and status line

  -- Calculate dimensions
  local width = calculate_float_dimension(float_config.width, editor_width)
  local height = calculate_float_dimension(float_config.height, editor_height)

  -- Calculate position
  local row = calculate_float_position(float_config.row, height, editor_height)
  local col = calculate_float_position(float_config.col, width, editor_width)

  -- Create floating window configuration
  local win_config = {
    relative = float_config.relative or 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    border = float_config.border or 'rounded',
    style = 'minimal',
  }

  -- Create buffer if we don't have an existing one
  local bufnr = existing_bufnr
  if not bufnr then
    bufnr = vim.api.nvim_create_buf(false, true) -- unlisted, scratch
  else
    -- Validate existing buffer is still valid and a terminal
    if not vim.api.nvim_buf_is_valid(bufnr) then
      bufnr = vim.api.nvim_create_buf(false, true) -- unlisted, scratch
    else
      local buftype = vim.api.nvim_get_option_value('buftype', {buf = bufnr})
      if buftype ~= 'terminal' then
        -- Buffer exists but is no longer a terminal, create a new one
        bufnr = vim.api.nvim_create_buf(false, true) -- unlisted, scratch
      end
    end
  end

  -- Create the floating window
  local win_id = vim.api.nvim_open_win(bufnr, true, win_config)
  
  -- If we're reusing an existing buffer and have full context, check if terminal job is still running
  if existing_bufnr and claude_code and git and instance_id then
    local job_id = vim.b[bufnr].terminal_job_id
    if not job_id or vim.fn.jobwait({job_id}, 0)[1] ~= -1 then
      -- Terminal job is not running, start a new one with on_exit callback
      local cmd = build_command_with_git_root(config, git, config.command)
      
      -- Ensure we got a valid command
      if type(cmd) ~= "string" or cmd == "" then
        vim.notify(
          "Claude Code: Failed to build terminal command; aborting restart. cmd=" .. vim.inspect(cmd),
          vim.log.levels.ERROR
        )
        return win_id
      end

      local new_job_id = vim.fn.termopen(cmd, {
        on_exit = create_terminal_exit_handler(claude_code, instance_id, bufnr, win_id)
      })
    end
  end
  
  return win_id
end

--- Handle buffer name collision by safely managing existing buffers
--- @param buffer_name string The intended buffer name
--- @param current_bufnr number The current buffer number
--- @return string The final buffer name to use (may be modified to avoid collision)
--- @private
local function handle_buffer_name_collision(buffer_name, current_bufnr)
  local existing_bufnr = vim.fn.bufnr(buffer_name)
  if existing_bufnr ~= -1 and existing_bufnr ~= current_bufnr then
    -- Only delete if the buffer is valid and not currently displayed
    if vim.api.nvim_buf_is_valid(existing_bufnr) then
      local buf_windows = vim.fn.win_findbuf(existing_bufnr)
      if #buf_windows == 0 then
        -- Buffer exists but isn't displayed, safe to delete
        vim.api.nvim_buf_delete(existing_bufnr, {force = true})
      else
        -- Buffer is being displayed, use a different name with timestamp
        -- Handle multiple levels of collision by trying different suffixes
        local base_name = buffer_name
        -- Use more granular timestamp to avoid collisions
        local timestamp = tostring(os.time()) .. '-' .. tostring(math.random(1000, 9999))
        local attempt = 0
        repeat
          if attempt == 0 then
            buffer_name = base_name .. '-' .. timestamp
          else
            buffer_name = base_name .. '-' .. timestamp .. '-' .. attempt
          end
          existing_bufnr = vim.fn.bufnr(buffer_name)
          attempt = attempt + 1
        until existing_bufnr == -1 or attempt > 10  -- Safety limit to prevent infinite loop
      end
    end
  end
  return buffer_name
end

--- Create terminal exit handler for floating windows
--- @param claude_code table The main plugin module
--- @param instance_id string The instance identifier
--- @param bufnr number The buffer number
--- @param win_id number The window ID
--- @return function The exit handler function
--- @private
local function create_terminal_exit_handler(claude_code, instance_id, bufnr, win_id)
  return function(job_id_exit, exit_code, event_type)
    vim.schedule(function()
      -- Robust cleanup with error handling
      local success, error_msg = pcall(function()
        -- Clean up instance tracking first
        if claude_code.claude_code.instances[instance_id] == bufnr then
          claude_code.claude_code.instances[instance_id] = nil
        end
        
        -- Check if window is still valid before attempting to close
        if vim.api.nvim_win_is_valid(win_id) then
          -- Get the config to confirm it's still a floating window
          local win_config = vim.api.nvim_win_get_config(win_id)
          if win_config.relative ~= '' then
            -- This is indeed a floating window, close it
            vim.api.nvim_win_close(win_id, true)
            
            -- Check if we need to create a fallback window
            local remaining_wins = vim.api.nvim_list_wins()
            local has_normal_window = false
            for _, w in ipairs(remaining_wins) do
              local cfg = vim.api.nvim_win_get_config(w)
              if cfg.relative == '' then
                has_normal_window = true
                break
              end
            end
            
            -- If no normal windows remain, create one
            if not has_normal_window then
              vim.cmd('new')
            end
          end
        end
      end)
      
      -- Log any errors for debugging
      if not success then
        vim.notify('Claude Code: Error in terminal exit handler: ' .. tostring(error_msg), vim.log.levels.WARN)
      end
    end)
  end
end

--- Build command with git root directory if configured
--- @param config table Plugin configuration
--- @param git table Git module
--- @param base_cmd string Base command to run
--- @return string Command with git root directory change if applicable
--- @private
local function build_command_with_git_root(config, git, base_cmd)
  if config.git and config.git.use_git_root then
    local git_root = git.get_git_root()
    if git_root then
      local quoted_root = vim.fn.shellescape(git_root)
      -- Use configurable shell commands
      local separator = config.shell.separator
      local pushd_cmd = config.shell.pushd_cmd
      local popd_cmd = config.shell.popd_cmd
      return pushd_cmd
        .. ' '
        .. quoted_root
        .. ' '
        .. separator
        .. ' '
        .. base_cmd
        .. ' '
        .. separator
        .. ' '
        .. popd_cmd
    end
  end
  return base_cmd
end

--- Configure common window options
--- @param win_id number Window ID to configure
--- @param config table Plugin configuration
--- @private
local function configure_window_options(win_id, config)
  if config.window.hide_numbers then
    vim.api.nvim_set_option_value('number', false, {win = win_id})
    vim.api.nvim_set_option_value('relativenumber', false, {win = win_id})
  end

  if config.window.hide_signcolumn then
    vim.api.nvim_set_option_value('signcolumn', 'no', {win = win_id})
  end
end

--- Generate buffer name for instance
--- @param instance_id string Instance identifier
--- @param config table Plugin configuration
--- @return string Buffer name
--- @private
local function generate_buffer_name(instance_id, config)
  if config.git.multi_instance then
    return 'claude-code-' .. instance_id:gsub('[^%w%-_]', '-')
  else
    return 'claude-code'
  end
end

--- Create a split window according to the specified position configuration
--- @param position string Window position configuration
--- @param config table Plugin configuration containing window settings
--- @param existing_bufnr number|nil Buffer number of existing buffer to show in the split (optional)
--- @private
local function create_split(position, config, existing_bufnr)
  -- Handle floating window
  if position == 'float' then
    return create_float(config, existing_bufnr, nil, nil, nil)
  end

  local is_vertical = position:match('vsplit') or position:match('vertical')

  -- Create the window with the user's specified command
  -- If the command already contains 'split', use it as is
  if position:match('split') then
    vim.cmd(position)
  else
    -- Otherwise append the appropriate split command
    local split_cmd = is_vertical and 'vsplit' or 'split'
    vim.cmd(position .. ' ' .. split_cmd)
  end

  -- If we have an existing buffer to display, switch to it
  if existing_bufnr then
    vim.cmd('buffer ' .. existing_bufnr)
  end

  -- Resize the window appropriately based on split type
  if is_vertical then
    vim.cmd('vertical resize ' .. math.floor(vim.o.columns * config.window.split_ratio))
  else
    vim.cmd('resize ' .. math.floor(vim.o.lines * config.window.split_ratio))
  end
end

--- Set up function to force insert mode when entering the Claude Code window
--- @param claude_code table The main plugin module
--- @param config table The plugin configuration
function M.force_insert_mode(claude_code, config)
  local current_bufnr = vim.fn.bufnr('%')

  -- Check if current buffer is any of our Claude instances
  local is_claude_instance = false
  for _, bufnr in pairs(claude_code.claude_code.instances) do
    if bufnr and bufnr == current_bufnr and vim.api.nvim_buf_is_valid(bufnr) then
      is_claude_instance = true
      break
    end
  end

  if is_claude_instance then
    -- Only enter insert mode if we're in the terminal buffer and not already in insert mode
    -- and not configured to stay in normal mode
    if config.window.start_in_normal_mode then
      return
    end

    local mode = vim.api.nvim_get_mode().mode
    if vim.bo.buftype == 'terminal' and mode ~= 't' and mode ~= 'i' then
      vim.cmd 'silent! stopinsert'
      vim.schedule(function()
        vim.cmd 'silent! startinsert'
      end)
    end
  end
end

--- Determine instance ID based on configuration
--- @param config table Plugin configuration
--- @param git table Git module
--- @return string instance_id Instance identifier
--- @private
local function get_instance_id(config, git)
  if config.git.multi_instance then
    if config.git.use_git_root then
      return get_instance_identifier(git)
    else
      return vim.fn.getcwd()
    end
  else
    -- Use a fixed ID for single instance mode
    return 'global'
  end
end

--- Check if buffer is a valid terminal
--- @param bufnr number Buffer number
--- @return boolean is_valid True if buffer is a valid terminal
--- @private
local function is_valid_terminal_buffer(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local buftype = nil
  pcall(function()
    buftype = vim.api.nvim_get_option_value('buftype', {buf = bufnr})
  end)
  
  local terminal_job_id = nil
  pcall(function()
    terminal_job_id = vim.b[bufnr].terminal_job_id
  end)

  return buftype == 'terminal'
    and terminal_job_id
    and vim.fn.jobwait({ terminal_job_id }, 0)[1] == -1
end

--- Handle existing instance (toggle visibility)
--- @param bufnr number Buffer number
--- @param config table Plugin configuration
--- @private
local function handle_existing_instance(bufnr, config, claude_code, git, instance_id)
  local win_ids = vim.fn.win_findbuf(bufnr)
  if #win_ids > 0 then
    -- Claude Code is visible, close the window
    for _, win_id in ipairs(win_ids) do
      -- For floating windows, ensure we have a valid window to return to
      local win_config = vim.api.nvim_win_get_config(win_id)
      if win_config.relative ~= '' then
        -- This is a floating window
        -- Store the current window that will be focused after closing
        local current_win = vim.api.nvim_get_current_win()
        
        -- Close the floating window
        vim.api.nvim_win_close(win_id, true)
        
        -- Ensure we have a valid window after closing
        -- This handles the case where the underlying window might have been closed
        local remaining_wins = vim.api.nvim_list_wins()
        if #remaining_wins == 0 then
          -- No windows left, create a new one
          vim.cmd('enew')
        end
      else
        -- Regular window, just close it
        vim.api.nvim_win_close(win_id, true)
      end
    end
  else
    -- Claude Code buffer exists but is not visible, open it in a split or float
    if config.window.position == 'float' then
      create_float(config, bufnr, claude_code, git, instance_id)
    else
      create_split(config.window.position, config, bufnr)
    end
    -- Force insert mode more aggressively unless configured to start in normal mode
    if not config.window.start_in_normal_mode then
      vim.schedule(function()
        vim.cmd 'stopinsert | startinsert'
      end)
    end
  end
end

--- Create new Claude Code instance
--- @param claude_code table The main plugin module
--- @param config table Plugin configuration
--- @param git table Git module
--- @param instance_id string Instance identifier
--- @private
local function create_new_instance(claude_code, config, git, instance_id)
  if config.window.position == 'float' then
    -- For floating window, create buffer first with terminal
    local new_bufnr = vim.api.nvim_create_buf(false, true) -- unlisted, scratch
    vim.api.nvim_set_option_value('bufhidden', 'hide', {buf = new_bufnr})

    -- Create the floating window
    local win_id = create_float(config, new_bufnr, claude_code, git, instance_id)

    -- Set current buffer to run terminal command
    vim.api.nvim_win_set_buf(win_id, new_bufnr)

    -- Determine command
    local cmd = build_command_with_git_root(config, git, config.command)

    -- Run terminal in the buffer
    local job_id = vim.fn.termopen(cmd, {
      on_exit = create_terminal_exit_handler(claude_code, instance_id, new_bufnr, win_id)
    })

    -- Create a unique buffer name
    local buffer_name = generate_buffer_name(instance_id, config)
    buffer_name = handle_buffer_name_collision(buffer_name, new_bufnr)
    vim.api.nvim_buf_set_name(new_bufnr, buffer_name)

    -- Configure window options
    configure_window_options(win_id, config)

    -- Store buffer number for this instance
    claude_code.claude_code.instances[instance_id] = new_bufnr

    -- Enter insert mode if configured
    if config.window.enter_insert and not config.window.start_in_normal_mode then
      vim.cmd 'startinsert'
    end
  else
    -- Regular split window
    create_split(config.window.position, config)

    -- Determine if we should use the git root directory
    local base_cmd = build_command_with_git_root(config, git, config.command)
    local cmd = 'terminal ' .. base_cmd

    vim.cmd(cmd)
    vim.cmd 'setlocal bufhidden=hide'

    -- Create a unique buffer name
    local buffer_name = generate_buffer_name(instance_id, config)
    local current_bufnr = vim.api.nvim_get_current_buf()
    buffer_name = handle_buffer_name_collision(buffer_name, current_bufnr)
    vim.cmd('file ' .. buffer_name)

    -- Configure window options using helper function
    local current_win = vim.api.nvim_get_current_win()
    configure_window_options(current_win, config)

    -- Store buffer number for this instance
    claude_code.claude_code.instances[instance_id] = vim.fn.bufnr('%')

    -- Automatically enter insert mode in terminal unless configured to start in normal mode
    if config.window.enter_insert and not config.window.start_in_normal_mode then
      vim.cmd 'startinsert'
    end
  end
end

--- Toggle the Claude Code terminal window
--- @param claude_code table The main plugin module
--- @param config table The plugin configuration
--- @param git table The git module
function M.toggle(claude_code, config, git)
  -- Determine instance ID based on config
  local instance_id = get_instance_id(config, git)
  claude_code.claude_code.current_instance = instance_id

  -- Check if this Claude Code instance is already running
  local bufnr = claude_code.claude_code.instances[instance_id]

  -- Validate existing buffer
  if bufnr and not is_valid_terminal_buffer(bufnr) then
    -- Buffer is no longer a valid terminal, reset
    claude_code.claude_code.instances[instance_id] = nil
    bufnr = nil
  end

  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    -- Handle existing instance (toggle visibility)
    handle_existing_instance(bufnr, config, claude_code, git, instance_id)
  else
    -- Prune invalid buffer entries
    if bufnr and not vim.api.nvim_buf_is_valid(bufnr) then
      claude_code.claude_code.instances[instance_id] = nil
    end
    -- Create new instance
    create_new_instance(claude_code, config, git, instance_id)
  end
end

return M
