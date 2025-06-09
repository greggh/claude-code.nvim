---@mod claude-code.context Context analysis for claude-code.nvim
---@brief [[
--- This module provides intelligent context analysis for the Claude Code plugin.
--- It can analyze file dependencies, imports, and relationships to provide better context.
---@brief ]]

local M = {}

--- Language-specific import/require patterns
local import_patterns = {
  lua = {
    patterns = {
      'require%s*%(?[\'"]([^\'"]+)[\'"]%)?',
      'dofile%s*%(?[\'"]([^\'"]+)[\'"]%)?',
      'loadfile%s*%(?[\'"]([^\'"]+)[\'"]%)?',
    },
    extensions = { '.lua' },
    module_to_path = function(module_name)
      -- Language-specific module resolution: Lua dot notation to file paths
      -- Lua follows specific patterns for module-to-file mapping
      local paths = {}

      -- Primary pattern: module.name -> module/name.lua
      -- This handles most require('foo.bar') cases
      local path = module_name:gsub('%.', '/') .. '.lua'
      table.insert(paths, path)

      -- Secondary pattern: module.name -> module/name/init.lua
      -- This handles package-style modules where init.lua serves as entry point
      table.insert(paths, module_name:gsub('%.', '/') .. '/init.lua')

      return paths
    end,
  },

  javascript = {
    patterns = {
      'import%s+.-from%s+[\'"]([^\'"]+)[\'"]',
      'require%s*%([\'"]([^\'"]+)[\'"]%)',
      'import%s*%([\'"]([^\'"]+)[\'"]%)',
    },
    extensions = { '.js', '.mjs', '.jsx' },
    module_to_path = function(module_name)
      -- JavaScript/ES6 module resolution with extension variants
      -- Only process relative imports (local files), skip node_modules
      local paths = {}

      -- Filter: Only process relative imports starting with . or ./
      if module_name:match('^%.') then
        -- Base path as-is (may already have extension)
        table.insert(paths, module_name)
        -- Extension resolution: Try multiple file extensions if not specified
        if not module_name:match('%.js$') then
          table.insert(paths, module_name .. '.js') -- Standard JS
          table.insert(paths, module_name .. '.jsx') -- React JSX
          table.insert(paths, module_name .. '/index.js') -- Directory with index
          table.insert(paths, module_name .. '/index.jsx') -- Directory with JSX index
        end
      else
        -- Skip external modules (node_modules) - not local project files
        return {}
      end

      return paths
    end,
  },

  typescript = {
    patterns = {
      'import%s+.-from%s+[\'"]([^\'"]+)[\'"]',
      'import%s*%([\'"]([^\'"]+)[\'"]%)',
    },
    extensions = { '.ts', '.tsx' },
    module_to_path = function(module_name)
      local paths = {}

      if module_name:match('^%.') then
        table.insert(paths, module_name)
        if not module_name:match('%.tsx?$') then
          table.insert(paths, module_name .. '.ts')
          table.insert(paths, module_name .. '.tsx')
          table.insert(paths, module_name .. '/index.ts')
          table.insert(paths, module_name .. '/index.tsx')
        end
      end

      return paths
    end,
  },

  python = {
    patterns = {
      'from%s+([%w%.]+)%s+import',
      'import%s+([%w%.]+)',
    },
    extensions = { '.py' },
    module_to_path = function(module_name)
      local paths = {}
      local path = module_name:gsub('%.', '/') .. '.py'
      table.insert(paths, path)
      table.insert(paths, module_name:gsub('%.', '/') .. '/__init__.py')
      return paths
    end,
  },

  go = {
    patterns = {
      'import%s+["\']([^"\']+)["\']',
      'import%s+%w+%s+["\']([^"\']+)["\']',
    },
    extensions = { '.go' },
    module_to_path = function(module_name)
      -- Go imports are usually full URLs or relative paths
      if module_name:match('^%.') then
        return { module_name }
      end
      return {} -- External packages
    end,
  },
}

--- Get file type from extension or vim filetype
--- @param filepath string The file path
--- @return string|nil The detected language
local function get_file_language(filepath)
  local filetype = vim.bo.filetype
  if filetype and import_patterns[filetype] then
    return filetype
  end

  local ext = filepath:match('%.([^%.]+)$')
  for lang, config in pairs(import_patterns) do
    for _, lang_ext in ipairs(config.extensions) do
      if lang_ext == '.' .. ext then
        return lang
      end
    end
  end

  return nil
end

--- Extract imports/requires from file content
--- @param content string The file content
--- @param language string The programming language
--- @return table List of imported modules/files
local function extract_imports(content, language)
  local config = import_patterns[language]
  if not config then
    return {}
  end

  local imports = {}
  for _, pattern in ipairs(config.patterns) do
    for match in content:gmatch(pattern) do
      table.insert(imports, match)
    end
  end

  return imports
end

--- Resolve import/require to actual file paths
--- @param import_name string The import/require statement
--- @param current_file string The current file path
--- @param language string The programming language
--- @return table List of possible file paths
local function resolve_import_paths(import_name, current_file, language)
  local config = import_patterns[language]
  if not config or not config.module_to_path then
    return {}
  end

  local possible_paths = config.module_to_path(import_name)
  local resolved_paths = {}

  local current_dir = vim.fn.fnamemodify(current_file, ':h')
  local project_root = vim.fn.getcwd()

  for _, path in ipairs(possible_paths) do
    local full_path

    if path:match('^%.') then
      -- Relative import
      full_path = vim.fn.resolve(current_dir .. '/' .. path:gsub('^%./', ''))
    else
      -- Absolute from project root
      full_path = vim.fn.resolve(project_root .. '/' .. path)
    end

    if vim.fn.filereadable(full_path) == 1 then
      table.insert(resolved_paths, full_path)
    end
  end

  return resolved_paths
end

--- Recursive dependency analysis with cycle detection
--- Follows import/require statements to build a dependency graph of related files.
--- This enables Claude to understand file relationships and provide better context.
--- Uses breadth-first traversal with depth limiting to prevent infinite loops.
--- @param filepath string The file to analyze
--- @param max_depth number|nil Maximum dependency depth (default: 2)
--- @return table List of related file paths with metadata
function M.get_related_files(filepath, max_depth)
  max_depth = max_depth or 2
  local related_files = {}
  local visited = {} -- Cycle detection: prevents infinite loops in circular dependencies
  local to_process = { { path = filepath, depth = 0 } } -- BFS queue with depth tracking

  -- Breadth-first traversal of the dependency tree
  while #to_process > 0 do
    local current = table.remove(to_process, 1) -- Dequeue next file to process
    local current_path = current.path
    local current_depth = current.depth

    -- Skip if already processed (cycle detection) or depth limit reached
    if visited[current_path] or current_depth >= max_depth then
      goto continue
    end

    -- Mark as visited to prevent reprocessing
    visited[current_path] = true

    -- Read file content
    local content = ''
    if vim.fn.filereadable(current_path) == 1 then
      local lines = vim.fn.readfile(current_path)
      content = table.concat(lines, '\n')
    elseif current_path == vim.api.nvim_buf_get_name(0) then
      -- Current buffer content
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      content = table.concat(lines, '\n')
    else
      goto continue
    end

    local language = get_file_language(current_path)
    if not language then
      goto continue
    end

    -- Extract imports
    local imports = extract_imports(content, language)

    -- Add current file to results (unless it's the original file)
    if current_depth > 0 then
      table.insert(related_files, {
        path = current_path,
        depth = current_depth,
        language = language,
        imports = imports,
      })
    end

    -- Resolve imports and add to processing queue
    for _, import_name in ipairs(imports) do
      local resolved_paths = resolve_import_paths(import_name, current_path, language)
      for _, resolved_path in ipairs(resolved_paths) do
        if not visited[resolved_path] then
          table.insert(to_process, { path = resolved_path, depth = current_depth + 1 })
        end
      end
    end

    ::continue::
  end

  return related_files
end

--- Get recent files from Neovim's oldfiles
--- @param limit number|nil Maximum number of recent files (default: 10)
--- @return table List of recent file paths
function M.get_recent_files(limit)
  limit = limit or 10
  local recent_files = {}
  local oldfiles = vim.v.oldfiles or {}
  local project_root = vim.fn.getcwd()

  for i, file in ipairs(oldfiles) do
    if #recent_files >= limit then
      break
    end

    -- Only include files from current project
    if file:match('^' .. vim.pesc(project_root)) and vim.fn.filereadable(file) == 1 then
      table.insert(recent_files, {
        path = file,
        relative_path = vim.fn.fnamemodify(file, ':~:.'),
        last_used = i, -- Approximate ordering
      })
    end
  end

  return recent_files
end

--- Get workspace symbols and their locations
--- @return table List of workspace symbols
function M.get_workspace_symbols()
  local symbols = {}

  -- Try to get LSP workspace symbols
  local clients = vim.lsp.get_active_clients({ bufnr = 0 })
  if #clients > 0 then
    local params = { query = '' }

    for _, client in ipairs(clients) do
      if client.server_capabilities.workspaceSymbolProvider then
        local results = client.request_sync('workspace/symbol', params, 5000, 0)
        if results and results.result then
          for _, symbol in ipairs(results.result) do
            table.insert(symbols, {
              name = symbol.name,
              kind = symbol.kind,
              location = symbol.location,
              container_name = symbol.containerName,
            })
          end
        end
      end
    end
  end

  return symbols
end

--- Get enhanced context for the current file
--- @param include_related boolean|nil Whether to include related files (default: true)
--- @param include_recent boolean|nil Whether to include recent files (default: true)
--- @param include_symbols boolean|nil Whether to include workspace symbols (default: false)
--- @return table Enhanced context information
function M.get_enhanced_context(include_related, include_recent, include_symbols)
  include_related = include_related ~= false
  include_recent = include_recent ~= false
  include_symbols = include_symbols or false

  local current_file = vim.api.nvim_buf_get_name(0)
  local context = {
    current_file = {
      path = current_file,
      relative_path = vim.fn.fnamemodify(current_file, ':~:.'),
      filetype = vim.bo.filetype,
      line_count = vim.api.nvim_buf_line_count(0),
      cursor_position = vim.api.nvim_win_get_cursor(0),
    },
  }

  if include_related and current_file ~= '' then
    context.related_files = M.get_related_files(current_file)
  end

  if include_recent then
    context.recent_files = M.get_recent_files()
  end

  if include_symbols then
    context.workspace_symbols = M.get_workspace_symbols()
  end

  return context
end

return M
