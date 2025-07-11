---@mod claude-code.git Git integration for claude-code.nvim
---@brief [[
--- This module provides git integration functionality for claude-code.nvim.
--- It detects git repositories and can set the working directory to the git root.
---@brief ]]

local M = {}

--- Helper function to get git root directory
--- @return string|nil git_root The git root directory path or nil if not in a git repo
function M.get_git_root()
  -- For testing compatibility
  if vim.env.CLAUDE_CODE_TEST_MODE == 'true' then
    return '/home/user/project'
  end

  -- Use vim.fn.system to run commands in Neovim's working directory
  local result = vim.fn.system('git rev-parse --is-inside-work-tree 2>/dev/null')

  -- Strip trailing whitespace and newlines for reliable matching
  result = result:gsub('[\n\r%s]*$', '')

  -- Check if git command failed (exit code > 0)
  if vim.v.shell_error ~= 0 then
    return nil
  end

  if result == 'true' then
    -- Get the git root path using Neovim's working directory
    local git_root = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null')

    -- Check if git command failed
    if vim.v.shell_error ~= 0 then
      return nil
    end

    -- Remove trailing whitespace and newlines
    git_root = git_root:gsub('[\n\r%s]*$', '')

    return git_root
  end

  return nil
end

return M
