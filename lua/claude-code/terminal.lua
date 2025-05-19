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

--- Create a split window according to the specified position configuration
--- @param position string Window position configuration
--- @param config table Plugin configuration containing window settings
--- @param existing_bufnr number|nil Buffer number of existing buffer to show in the split (optional)
--- @private
local function create_split(position, config, existing_bufnr)
  local is_vertical = position:match('vsplit') or position:match('vertical')

  -- Create the window with the user's specified command
  -- If the command already contains 'split' or 'vsplit', use it as is
  if position:match('split') then
    vim.cmd(position)
  else
    -- Otherwise append 'split'
    vim.cmd(position .. ' split')
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
    -- Claude Code is not running, start it in a new split
    create_split(config.window.position, config)

    -- Determine if we should use the git root directory
    local cmd = 'terminal ' .. config.command
    if config.git and config.git.use_git_root then
      local git_root = git.get_git_root()
      if git_root then
        -- Use pushd/popd to change directory instead of --cwd
        cmd = 'terminal pushd ' .. git_root .. ' && ' .. config.command .. ' && popd'
      end
    end

    vim.cmd(cmd)
    vim.cmd 'setlocal bufhidden=hide'
    vim.cmd 'setlocal nobuflisted'
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

return M
