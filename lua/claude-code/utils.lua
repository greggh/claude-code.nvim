-- Shared utility functions for claude-code.nvim
local M = {}

-- Safe notification function that works in both UI and headless modes
-- @param msg string The message to notify
-- @param level number|nil Vim log level (default: INFO)
-- @param opts table|nil Additional options {prefix = string, force_stderr = boolean}
function M.notify(msg, level, opts)
  level = level or vim.log.levels.INFO
  opts = opts or {}

  local prefix = opts.prefix or 'Claude Code'
  local full_msg = prefix and ('[' .. prefix .. '] ' .. msg) or msg

  -- In server context or when forced, always use stderr
  if opts.force_stderr then
    io.stderr:write(full_msg .. '\n')
    io.stderr:flush()
    return
  end

  -- Check if we're in a UI context
  local ok, uis = pcall(vim.api.nvim_list_uis)
  if not ok or #uis == 0 then
    -- Headless mode - write to stderr
    io.stderr:write(full_msg .. '\n')
    io.stderr:flush()
  else
    -- UI mode - use vim.notify with scheduling
    vim.schedule(function()
      vim.notify(full_msg, level)
    end)
  end
end

-- Terminal color codes
M.colors = {
  red = '\27[31m',
  green = '\27[32m',
  yellow = '\27[33m',
  blue = '\27[34m',
  magenta = '\27[35m',
  cyan = '\27[36m',
  reset = '\27[0m',
}

-- Print colored text to stdout
-- @param color string Color name from M.colors
-- @param text string Text to print
function M.cprint(color, text)
  vim.print(M.colors[color] .. text .. M.colors.reset)
end

-- Colorize text without printing
-- @param color string Color name from M.colors
-- @param text string Text to colorize
-- @return string Colorized text
function M.color(color, text)
  local color_code = M.colors[color] or ''
  return color_code .. text .. M.colors.reset
end

-- Get git root with fallback to current directory
-- @param git table|nil Git module (optional, will require if not provided)
-- @return string Git root directory or current working directory
function M.get_working_directory(git)
  -- Handle git module loading with error handling
  if not git then
    local ok, git_module = pcall(require, 'claude-code.git')
    git = ok and git_module or nil
  end

  -- If git module failed to load or is nil, fall back to cwd
  if not git then
    return vim.fn.getcwd()
  end

  -- Try to get git root, fall back to cwd if it returns nil
  local git_root = git.get_git_root()
  return git_root or vim.fn.getcwd()
end

-- Find executable with fallback options
-- @param paths table Array of paths to check
-- @return string|nil First executable path found, or nil
function M.find_executable(paths)
  -- Add path validation
  if type(paths) ~= 'table' then
    return nil
  end

  for _, path in ipairs(paths) do
    if type(path) == 'string' then
      local expanded = vim.fn.expand(path)
      if vim.fn.executable(expanded) == 1 then
        return expanded
      end
    end
  end
  return nil
end

-- Find executable by name using system which/where command
-- @param name string Name of the executable to find (e.g., 'git')
-- @return string|nil Full path to executable, or nil if not found
function M.find_executable_by_name(name)
  -- Validate input
  if type(name) ~= 'string' or name == '' then
    return nil
  end

  -- Use 'where' on Windows, 'which' on Unix-like systems
  local cmd
  if vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
    cmd = 'where ' .. vim.fn.shellescape(name) .. ' 2>NUL'
  else
    cmd = 'which ' .. vim.fn.shellescape(name) .. ' 2>/dev/null'
  end

  local handle = io.popen(cmd)
  if not handle then
    return nil
  end

  local result = handle:read('*l') -- Read first line only
  local close_result = handle:close()

  -- Handle different return formats from close()
  local exit_code
  if type(close_result) == 'number' then
    exit_code = close_result
  elseif type(close_result) == 'boolean' then
    exit_code = close_result and 0 or 1
  else
    exit_code = 1
  end

  if exit_code == 0 and result and result ~= '' then
    -- Trim whitespace and validate the path exists
    result = result:gsub('^%s+', ''):gsub('%s+$', '')
    if vim.fn.executable(result) == 1 then
      return result
    end
  end

  return nil
end

-- Check if running in headless mode
-- @return boolean True if in headless mode
function M.is_headless()
  local ok, uis = pcall(vim.api.nvim_list_uis)
  return not ok or #uis == 0
end

-- Create directory if it doesn't exist
-- @param path string Directory path
-- @return boolean Success
-- @return string|nil Error message if failed
function M.ensure_directory(path)
  -- Validate input
  if type(path) ~= 'string' or path == '' then
    return false, 'Invalid directory path'
  end

  -- Check if already exists
  if vim.fn.isdirectory(path) == 1 then
    return true
  end

  -- Try to create directory
  local success = vim.fn.mkdir(path, 'p')
  if success ~= 1 then
    return false, 'Failed to create directory: ' .. path
  end

  return true
end

return M
