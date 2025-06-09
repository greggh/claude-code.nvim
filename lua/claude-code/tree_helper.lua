---@mod claude-code.tree_helper Project tree helper for context generation
---@brief [[
--- This module provides utilities for generating project file tree representations
--- to include as context when interacting with Claude Code.
---@brief ]]

local M = {}

--- Default ignore patterns for file tree generation
local DEFAULT_IGNORE_PATTERNS = {
  '%.git',
  'node_modules',
  '%.DS_Store',
  '%.vscode',
  '%.idea',
  'target',
  'build',
  'dist',
  '%.pytest_cache',
  '__pycache__',
  '%.mypy_cache',
}

--- Format file size in human readable format
--- @param size number File size in bytes
--- @return string Formatted size (e.g., "1.5KB", "2.3MB")
local function format_file_size(size)
  if size < 1024 then
    return size .. 'B'
  elseif size < 1024 * 1024 then
    return string.format('%.1fKB', size / 1024)
  elseif size < 1024 * 1024 * 1024 then
    return string.format('%.1fMB', size / (1024 * 1024))
  else
    return string.format('%.1fGB', size / (1024 * 1024 * 1024))
  end
end

--- Check if a path matches any of the ignore patterns
--- @param path string Path to check
--- @param ignore_patterns table List of patterns to ignore
--- @return boolean True if path should be ignored
local function should_ignore(path, ignore_patterns)
  local basename = vim.fn.fnamemodify(path, ':t')

  for _, pattern in ipairs(ignore_patterns) do
    if basename:match(pattern) then
      return true
    end
  end

  return false
end

--- Generate tree structure recursively
--- @param dir string Directory path
--- @param options table Options for tree generation
--- @param depth number Current depth (internal)
--- @param file_count table File count tracker (internal)
--- @return table Lines of tree output
local function generate_tree_recursive(dir, options, depth, file_count)
  depth = depth or 0
  file_count = file_count or { count = 0 }

  local lines = {}
  local max_depth = options.max_depth or 3
  local max_files = options.max_files or 100
  local ignore_patterns = options.ignore_patterns or DEFAULT_IGNORE_PATTERNS
  local show_size = options.show_size or false

  -- Check depth limit
  if depth >= max_depth then
    return lines
  end

  -- Check file count limit
  if file_count.count >= max_files then
    table.insert(lines, string.rep('  ', depth) .. '... (truncated - max files reached)')
    return lines
  end

  -- Get directory contents
  local glob_pattern = dir .. '/*'
  local glob_result = vim.fn.glob(glob_pattern, false, true)

  -- Handle different return types from glob
  local entries = {}
  if type(glob_result) == 'table' then
    entries = glob_result
  elseif type(glob_result) == 'string' and glob_result ~= '' then
    entries = vim.split(glob_result, '\n', { plain = true })
  end

  if not entries or #entries == 0 then
    return lines
  end

  -- Sort entries: directories first, then files
  table.sort(entries, function(a, b)
    local a_is_dir = vim.fn.isdirectory(a) == 1
    local b_is_dir = vim.fn.isdirectory(b) == 1

    if a_is_dir and not b_is_dir then
      return true
    elseif not a_is_dir and b_is_dir then
      return false
    else
      return vim.fn.fnamemodify(a, ':t') < vim.fn.fnamemodify(b, ':t')
    end
  end)

  for _, entry in ipairs(entries) do
    -- Check file count limit
    if file_count.count >= max_files then
      table.insert(lines, string.rep('  ', depth) .. '... (truncated - max files reached)')
      break
    end

    -- Check ignore patterns
    if not should_ignore(entry, ignore_patterns) then
      local basename = vim.fn.fnamemodify(entry, ':t')
      local prefix = string.rep('  ', depth)
      local is_dir = vim.fn.isdirectory(entry) == 1

      if is_dir then
        table.insert(lines, prefix .. basename .. '/')
        -- Recursively process subdirectory
        local sublines = generate_tree_recursive(entry, options, depth + 1, file_count)
        for _, line in ipairs(sublines) do
          table.insert(lines, line)
        end
      else
        file_count.count = file_count.count + 1
        local line = prefix .. basename

        if show_size then
          local size = vim.fn.getfsize(entry)
          if size >= 0 then
            line = line .. ' (' .. format_file_size(size) .. ')'
          end
        end

        table.insert(lines, line)
      end
    end
  end

  return lines
end

--- Generate a file tree representation of a directory
--- @param root_dir string Root directory to scan
--- @param options? table Options for tree generation
---   - max_depth: number Maximum depth to scan (default: 3)
---   - max_files: number Maximum number of files to include (default: 100)
---   - ignore_patterns: table Patterns to ignore (default: common ignore patterns)
---   - show_size: boolean Include file sizes (default: false)
--- @return string Tree representation
function M.generate_tree(root_dir, options)
  options = options or {}

  if not root_dir or vim.fn.isdirectory(root_dir) ~= 1 then
    return 'Error: Invalid directory path'
  end

  local lines = generate_tree_recursive(root_dir, options)

  if #lines == 0 then
    return '(empty directory)'
  end

  return table.concat(lines, '\n')
end

--- Get project tree context as formatted markdown
--- @param options? table Options for tree generation
--- @return string Markdown formatted project tree
function M.get_project_tree_context(options)
  options = options or {}

  -- Try to get git root, fall back to current directory
  local root_dir
  local ok, git = pcall(require, 'claude-code.git')
  if ok and git.get_root then
    root_dir = git.get_root()
  end

  if not root_dir then
    root_dir = vim.fn.getcwd()
  end

  local project_name = vim.fn.fnamemodify(root_dir, ':t')
  local relative_root = vim.fn.fnamemodify(root_dir, ':~:.')

  local tree_content = M.generate_tree(root_dir, options)

  local lines = {
    '# Project Structure',
    '',
    '**Project:** ' .. project_name,
    '**Root:** ' .. relative_root,
    '',
    '```',
    tree_content,
    '```',
  }

  return table.concat(lines, '\n')
end

--- Create a temporary file with project tree content
--- @param options? table Options for tree generation
--- @return string Path to temporary file
function M.create_tree_file(options)
  local content = M.get_project_tree_context(options)

  -- Create temporary file
  local temp_file = vim.fn.tempname()
  if not temp_file:match('%.md$') then
    temp_file = temp_file .. '.md'
  end

  -- Write content to file
  local lines = vim.split(content, '\n', { plain = true })
  local success = vim.fn.writefile(lines, temp_file)

  if success ~= 0 then
    error('Failed to write tree content to temporary file')
  end

  return temp_file
end

--- Get default ignore patterns
--- @return table Default ignore patterns
function M.get_default_ignore_patterns()
  return vim.deepcopy(DEFAULT_IGNORE_PATTERNS)
end

--- Add ignore pattern to default list
--- @param pattern string Pattern to add
function M.add_ignore_pattern(pattern)
  table.insert(DEFAULT_IGNORE_PATTERNS, pattern)
end

return M
