---@mod rovo-dev.git Git integration for rovo-dev.nvim
---@brief [[
--- This module provides git integration functionality for rovo-dev.nvim.
--- It detects git repositories and can set the working directory to the git root.
---@brief ]]

local M = {}

--- Helper function to get git root directory
--- @return string|nil git_root The git root directory path or nil if not in a git repo
function M.get_git_root()
  -- For testing compatibility
  if vim.env.ROVO_DEV_TEST_MODE == 'true' then
    return '/home/user/project'
  end

  -- Check if we're in a git repository
  local handle = io.popen('git rev-parse --is-inside-work-tree 2>/dev/null')
  if not handle then
    return nil
  end

  local result = handle:read('*a')
  handle:close()

  -- Strip trailing whitespace and newlines for reliable matching
  result = result:gsub('[\n\r%s]*$', '')

  if result == 'true' then
    -- Get the git root path
    local root_handle = io.popen('git rev-parse --show-toplevel 2>/dev/null')
    if not root_handle then
      return nil
    end

    local git_root = root_handle:read('*a')
    root_handle:close()

    -- Remove trailing whitespace and newlines
    git_root = git_root:gsub('[\n\r%s]*$', '')

    return git_root
  end

  return nil
end

return M
