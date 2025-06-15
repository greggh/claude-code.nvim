---@mod claude-code.floating Floating window management for claude-code.nvim
---@brief [[
--- This module provides floating window functionality for claude-code.nvim.
--- It handles creating, toggling, and managing floating windows.
---@brief ]]

local M = {}

--- Floating window state management
-- @table ClaudeCodeFloating
-- @field instances table Key-value store of git root to floating window state
-- @field current_instance string|nil Current git root path for active instance
M.floating = {
  instances = {},
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

--- Calculate floating window dimensions and position
--- @param config table Plugin configuration containing floating window settings
--- @return table window_config Window configuration for nvim_open_win
local function get_window_config(config)
  local ui = vim.api.nvim_list_uis()[1]
  local floating_config = config.window.floating
  local width = math.floor(ui.width * floating_config.width)
  local height = math.floor(ui.height * floating_config.height)

  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)

  return {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = floating_config.border,
    title = ' Claude Code ',
    title_pos = 'center',
  }
end

--- Create or show floating window
--- @param claude_code table The main plugin module
--- @param config table The plugin configuration
--- @param git table The git module
--- @param existing_bufnr number|nil Buffer number of existing buffer to show in the floating window (optional)
--- @return number bufnr Buffer number of the floating window
--- @return number winid Window ID of the floating window
local function create_floating_window(claude_code, config, git, existing_bufnr)
  local win_config = get_window_config(config)

  -- Create buffer if not provided
  local bufnr = existing_bufnr
  if not bufnr then
    bufnr = vim.api.nvim_create_buf(false, true)
  end

  -- Create floating window
  local winid = vim.api.nvim_open_win(bufnr, true, win_config)

  -- Configure buffer and window options
  vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'hide')

  -- Use window config settings for floating windows
  local hide_numbers = config.window.hide_numbers
  local hide_signcolumn = config.window.hide_signcolumn

  if hide_numbers then
    vim.api.nvim_win_set_option(winid, 'number', false)
    vim.api.nvim_win_set_option(winid, 'relativenumber', false)
  end

  if hide_signcolumn then
    vim.api.nvim_win_set_option(winid, 'signcolumn', 'no')
  end

  return bufnr, winid
end

--- Toggle the Claude Code floating window
--- @param claude_code table The main plugin module
--- @param config table The plugin configuration
--- @param git table The git module
function M.toggle(claude_code, config, git)
  -- Determine instance ID based on config
  local instance_id
  if config.git.multi_instance then
    if config.git.use_git_root then
      instance_id = get_instance_identifier(git)
    else
      instance_id = vim.fn.getcwd()
    end
  else
    -- Use a fixed ID for single instance mode
    instance_id = 'global'
  end

  M.floating.current_instance = instance_id

  -- Check if this floating instance already exists
  local floating_state = M.floating.instances[instance_id]

  if floating_state then
    local bufnr = floating_state.bufnr
    local winid = floating_state.winid

    -- Check if window is still valid and visible
    if winid and vim.api.nvim_win_is_valid(winid) then
      -- Window is visible, close it
      vim.api.nvim_win_close(winid, true)
      M.floating.instances[instance_id].winid = nil
      return
    elseif bufnr and vim.api.nvim_buf_is_valid(bufnr) then
      -- Buffer exists but window is closed, recreate window
      local new_bufnr, new_winid = create_floating_window(claude_code, config, git, bufnr)
      M.floating.instances[instance_id].winid = new_winid

      -- Force insert mode if configured
      local enter_insert = config.window.enter_insert
      local start_in_normal_mode = config.window.start_in_normal_mode
      if enter_insert and not start_in_normal_mode then
        vim.schedule(function()
          vim.cmd 'startinsert'
        end)
      end
      return
    end
  end

  -- Create new floating window and terminal
  local bufnr, winid = create_floating_window(claude_code, config, git)

  -- Determine terminal command
  local cmd = config.command
  if config.git and config.git.use_git_root then
    local git_root = git.get_git_root()
    if git_root then
      -- Use pushd/popd to change directory
      local separator = config.shell.separator
      local pushd_cmd = config.shell.pushd_cmd
      local popd_cmd = config.shell.popd_cmd
      cmd = pushd_cmd
        .. ' '
        .. git_root
        .. ' '
        .. separator
        .. ' '
        .. config.command
        .. ' '
        .. separator
        .. ' '
        .. popd_cmd
    end
  end

  -- Start terminal in the floating window
  vim.fn.termopen(cmd)

  -- Create a unique buffer name
  local buffer_name
  if config.git.multi_instance then
    buffer_name = 'claude-code-floating-' .. instance_id:gsub('[^%w%-_]', '-')
  else
    buffer_name = 'claude-code-floating'
  end
  vim.api.nvim_buf_set_name(bufnr, buffer_name)

  -- Store the floating window state
  M.floating.instances[instance_id] = {
    bufnr = bufnr,
    winid = winid,
  }

  -- Set up window closing autocommand
  vim.api.nvim_create_autocmd({ 'WinClosed' }, {
    buffer = bufnr,
    callback = function()
      if M.floating.instances[instance_id] then
        M.floating.instances[instance_id].winid = nil
      end
    end,
    once = true,
  })

  -- Automatically enter insert mode if configured
  local enter_insert = config.window.enter_insert
  local start_in_normal_mode = config.window.start_in_normal_mode
  if enter_insert and not start_in_normal_mode then
    vim.cmd 'startinsert'
  end
end

--- Close floating window if open
--- @param claude_code table The main plugin module
--- @param config table The plugin configuration
--- @param git table The git module
function M.close(claude_code, config, git)
  -- Determine instance ID based on config
  local instance_id
  if config.git.multi_instance then
    if config.git.use_git_root then
      instance_id = get_instance_identifier(git)
    else
      instance_id = vim.fn.getcwd()
    end
  else
    instance_id = 'global'
  end

  local floating_state = M.floating.instances[instance_id]
  if
    floating_state
    and floating_state.winid
    and vim.api.nvim_win_is_valid(floating_state.winid)
  then
    vim.api.nvim_win_close(floating_state.winid, true)
    M.floating.instances[instance_id].winid = nil
  end
end

--- Check if floating window is currently open
--- @param claude_code table The main plugin module
--- @param config table The plugin configuration
--- @param git table The git module
--- @return boolean is_open Whether the floating window is currently open
function M.is_open(claude_code, config, git)
  -- Determine instance ID based on config
  local instance_id
  if config.git.multi_instance then
    if config.git.use_git_root then
      instance_id = get_instance_identifier(git)
    else
      instance_id = vim.fn.getcwd()
    end
  else
    instance_id = 'global'
  end

  local floating_state = M.floating.instances[instance_id]
  return floating_state and floating_state.winid and vim.api.nvim_win_is_valid(floating_state.winid)
end

return M
