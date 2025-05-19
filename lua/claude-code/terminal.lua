---@mod claude-code.terminal Terminal management for claude-code.nvim
---@brief [[
--- This module provides terminal buffer management for claude-code.nvim.
--- It handles creating, toggling, and managing the terminal window.
---@brief ]]

local M = {}

--- Terminal buffer and window management
-- @table ClaudeCodeTerminal
-- @field bufnr number|nil Buffer number of the Claude Code terminal
-- @field saved_updatetime number|nil Original updatetime before Claude Code was opened
M.terminal = {
  bufnr = nil,
  saved_updatetime = nil,
}

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
--- @return number Window ID of the created floating window
--- @private
local function create_float(config, existing_bufnr)
  local float_config = config.window.float or {}
  
  -- Calculate dimensions
  local width = calculate_float_dimension(float_config.width, vim.o.columns)
  local height = calculate_float_dimension(float_config.height, vim.o.lines)
  
  -- Calculate position
  local row = calculate_float_position(float_config.row, height, vim.o.lines)
  local col = calculate_float_position(float_config.col, width, vim.o.columns)
  
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
    -- Validate existing buffer is still a terminal
    local buftype = vim.api.nvim_buf_get_option(bufnr, 'buftype')
    if buftype ~= 'terminal' then
      -- Buffer exists but is no longer a terminal, create a new one
      bufnr = vim.api.nvim_create_buf(false, true) -- unlisted, scratch
    end
  end
  
  -- Create and return the floating window
  return vim.api.nvim_open_win(bufnr, true, win_config)
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
      return 'pushd ' .. quoted_root .. ' && ' .. base_cmd .. ' && popd'
    end
  end
  return base_cmd
end

--- Create a split window according to the specified position configuration
--- @param position string Window position configuration
--- @param config table Plugin configuration containing window settings
--- @param existing_bufnr number|nil Buffer number of existing buffer to show in the split (optional)
--- @private
local function create_split(position, config, existing_bufnr)
  -- Handle floating window
  if position == 'float' then
    local win_id = create_float(config, existing_bufnr)
    return win_id
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
  local bufnr = claude_code.claude_code.bufnr
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.fn.bufnr '%' == bufnr then
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

--- Toggle the Claude Code terminal window
--- @param claude_code table The main plugin module
--- @param config table The plugin configuration
--- @param git table The git module
function M.toggle(claude_code, config, git)
  -- Check if Claude Code is already running
  local bufnr = claude_code.claude_code.bufnr
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    -- Validate the buffer is still a valid terminal
    local buftype = vim.api.nvim_buf_get_option(bufnr, 'buftype')
    local terminal_job_id = nil
    pcall(function()
      terminal_job_id = vim.api.nvim_buf_get_var(bufnr, 'terminal_job_id')
    end)
    local is_valid_terminal = buftype == 'terminal' and terminal_job_id and vim.fn.jobwait({terminal_job_id}, 0)[1] == -1
    
    if not is_valid_terminal then
      -- Buffer is no longer a valid terminal, reset
      claude_code.claude_code.bufnr = nil
      bufnr = nil
    end
  end
  
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    -- Check if there's a window displaying Claude Code buffer
    local win_ids = vim.fn.win_findbuf(bufnr)
    if #win_ids > 0 then
      -- Claude Code is visible, close the window
      for _, win_id in ipairs(win_ids) do
        vim.api.nvim_win_close(win_id, true)
      end
    else
      -- Claude Code buffer exists but is not visible, open it in a split
      create_split(config.window.position, config, bufnr)
      -- Force insert mode more aggressively unless configured to start in normal mode
      if not config.window.start_in_normal_mode then
        vim.schedule(function()
          vim.cmd 'stopinsert | startinsert'
        end)
      end
    end
  else
    -- Claude Code is not running, start it in a new split or float
    if config.window.position == 'float' then
      -- For floating window, create buffer first with terminal
      local bufnr = vim.api.nvim_create_buf(false, true) -- unlisted, scratch
      vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'hide')
      
      -- Create the floating window
      local win_id = create_float(config, bufnr)
      
      -- Set current buffer to run terminal command
      vim.api.nvim_win_set_buf(win_id, bufnr)
      
      -- Determine command
      local cmd = build_command_with_git_root(config, git, config.command)
      
      -- Run terminal in the buffer
      vim.fn.termopen(cmd)
      vim.api.nvim_buf_set_name(bufnr, 'claude-code')
      
      -- Configure buffer options
      if config.window.hide_numbers then
        vim.api.nvim_win_set_option(win_id, 'number', false)
        vim.api.nvim_win_set_option(win_id, 'relativenumber', false)
      end
      
      if config.window.hide_signcolumn then
        vim.api.nvim_win_set_option(win_id, 'signcolumn', 'no')
      end
      
      -- Store buffer number
      claude_code.claude_code.bufnr = bufnr
      
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
      vim.cmd 'file claude-code'

      if config.window.hide_numbers then
        vim.cmd 'setlocal nonumber norelativenumber'
      end

      if config.window.hide_signcolumn then
        vim.cmd 'setlocal signcolumn=no'
      end

      -- Store buffer number for future reference
      claude_code.claude_code.bufnr = vim.fn.bufnr '%'

      -- Automatically enter insert mode in terminal unless configured to start in normal mode
      if config.window.enter_insert and not config.window.start_in_normal_mode then
        vim.cmd 'startinsert'
      end
    end
  end
end

return M
