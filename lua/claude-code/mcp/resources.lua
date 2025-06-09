local M = {}

-- Resource: Current buffer content
M.current_buffer = {
  uri = 'neovim://current-buffer',
  name = 'Current Buffer',
  description = 'Content of the currently active buffer',
  mimeType = 'text/plain',
  handler = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local buf_name = vim.api.nvim_buf_get_name(bufnr)
    local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })

    local header = string.format('File: %s\nType: %s\nLines: %d\n\n', buf_name, filetype, #lines)
    return header .. table.concat(lines, '\n')
  end,
}

-- Resource: Buffer list
M.buffer_list = {
  uri = 'neovim://buffers',
  name = 'Buffer List',
  description = 'List of all open buffers with metadata',
  mimeType = 'application/json',
  handler = function()
    local buffers = {}

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(bufnr) then
        local buf_name = vim.api.nvim_buf_get_name(bufnr)
        local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
        local modified = vim.api.nvim_get_option_value('modified', { buf = bufnr })
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        local listed = vim.api.nvim_get_option_value('buflisted', { buf = bufnr })

        table.insert(buffers, {
          number = bufnr,
          name = buf_name,
          filetype = filetype,
          modified = modified,
          line_count = line_count,
          listed = listed,
          current = bufnr == vim.api.nvim_get_current_buf(),
        })
      end
    end

    return vim.json.encode({
      buffers = buffers,
      total_count = #buffers,
      current_buffer = vim.api.nvim_get_current_buf(),
    })
  end,
}

-- Resource: Project structure
M.project_structure = {
  uri = 'neovim://project',
  name = 'Project Structure',
  description = 'File tree of the current working directory',
  mimeType = 'text/plain',
  handler = function()
    local cwd = vim.fn.getcwd()

    -- Simple directory listing (could be enhanced with tree structure)
    local cmd = 'find '
      .. vim.fn.shellescape(cwd)
      .. " -type f -name '*.lua' -o -name '*.vim' -o -name '*.js'"
      .. " -o -name '*.ts' -o -name '*.py' -o -name '*.md' | head -50"

    local result = vim.fn.system(cmd)

    if vim.v.shell_error ~= 0 then
      return 'Error: Could not list project files'
    end

    local header = string.format('Project: %s\n\nRecent files:\n', cwd)
    return header .. result
  end,
}

-- Resource: Git status
M.git_status = {
  uri = 'neovim://git-status',
  name = 'Git Status',
  description = 'Current git repository status',
  mimeType = 'text/plain',
  handler = function()
    -- Validate git executable exists
    local ok, utils = pcall(require, 'claude-code.utils')
    if not ok then
      return 'Utils module not available'
    end

    local git_path = utils.find_executable_by_name('git')
    if not git_path then
      return 'Git executable not found in PATH'
    end

    local cmd = vim.fn.shellescape(git_path) .. ' status --porcelain 2>/dev/null'
    local status = vim.fn.system(cmd)

    -- Check if git command failed
    if vim.v.shell_error ~= 0 then
      return 'Not a git repository or git not available'
    end

    if status == '' then
      return 'Working tree clean'
    end

    local lines = vim.split(status, '\n', { plain = true })
    local result = 'Git Status:\n\n'

    for _, line in ipairs(lines) do
      if line ~= '' then
        local status_code = line:sub(1, 2)
        local file = line:sub(4)
        local status_desc = ''

        if status_code:match('^M') then
          status_desc = 'Modified'
        elseif status_code:match('^A') then
          status_desc = 'Added'
        elseif status_code:match('^D') then
          status_desc = 'Deleted'
        elseif status_code:match('^R') then
          status_desc = 'Renamed'
        elseif status_code:match('^C') then
          status_desc = 'Copied'
        elseif status_code:match('^U') then
          status_desc = 'Unmerged'
        elseif status_code:match('^%?') then
          status_desc = 'Untracked'
        else
          status_desc = 'Unknown'
        end

        result = result .. string.format('%s: %s\n', status_desc, file)
      end
    end

    return result
  end,
}

-- Resource: LSP diagnostics
M.lsp_diagnostics = {
  uri = 'neovim://lsp-diagnostics',
  name = 'LSP Diagnostics',
  description = 'Language server diagnostics for current buffer',
  mimeType = 'application/json',
  handler = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local diagnostics = vim.diagnostic.get(bufnr)

    local result = {
      buffer = bufnr,
      file = vim.api.nvim_buf_get_name(bufnr),
      diagnostics = {},
    }

    for _, diag in ipairs(diagnostics) do
      table.insert(result.diagnostics, {
        line = diag.lnum + 1, -- Convert to 1-indexed
        column = diag.col + 1, -- Convert to 1-indexed
        severity = diag.severity,
        message = diag.message,
        source = diag.source,
        code = diag.code,
      })
    end

    result.total_count = #result.diagnostics

    return vim.json.encode(result)
  end,
}

-- Resource: Vim options
M.vim_options = {
  uri = 'neovim://options',
  name = 'Vim Options',
  description = 'Current Neovim configuration and options',
  mimeType = 'application/json',
  handler = function()
    local options = {
      global = {},
      buffer = {},
      window = {},
    }

    -- Common global options
    local global_opts = {
      'background',
      'colorscheme',
      'encoding',
      'fileformat',
      'hidden',
      'ignorecase',
      'smartcase',
      'incsearch',
      'number',
      'relativenumber',
      'wrap',
      'scrolloff',
    }

    for _, opt in ipairs(global_opts) do
      local ok, value = pcall(vim.api.nvim_get_option, opt)
      if ok then
        options.global[opt] = value
      end
    end

    -- Buffer-local options
    local bufnr = vim.api.nvim_get_current_buf()
    local buffer_opts = {
      'filetype',
      'tabstop',
      'shiftwidth',
      'expandtab',
      'autoindent',
      'smartindent',
      'modified',
      'readonly',
    }

    for _, opt in ipairs(buffer_opts) do
      local ok, value = pcall(vim.api.nvim_get_option_value, opt, { buf = bufnr })
      if ok then
        options.buffer[opt] = value
      end
    end

    -- Window-local options
    local winnr = vim.api.nvim_get_current_win()
    local window_opts = {
      'number',
      'relativenumber',
      'wrap',
      'cursorline',
      'cursorcolumn',
      'foldcolumn',
      'signcolumn',
    }

    for _, opt in ipairs(window_opts) do
      local ok, value = pcall(vim.api.nvim_win_get_option, winnr, opt)
      if ok then
        options.window[opt] = value
      end
    end

    return vim.json.encode(options)
  end,
}

-- Resource: Related files through imports/requires
M.related_files = {
  uri = 'neovim://related-files',
  name = 'Related Files',
  description = 'Files related to current buffer through imports/requires',
  mimeType = 'application/json',
  handler = function()
    local ok, context_module = pcall(require, 'claude-code.context')
    if not ok then
      return vim.json.encode({ error = 'Context module not available' })
    end

    local current_file = vim.api.nvim_buf_get_name(0)
    if current_file == '' then
      return vim.json.encode({ files = {}, message = 'No current file' })
    end

    local related_files = context_module.get_related_files(current_file, 3)
    local result = {
      current_file = vim.fn.fnamemodify(current_file, ':~:.'),
      related_files = {},
    }

    for _, file_info in ipairs(related_files) do
      table.insert(result.related_files, {
        path = vim.fn.fnamemodify(file_info.path, ':~:.'),
        depth = file_info.depth,
        language = file_info.language,
        import_count = #file_info.imports,
      })
    end

    return vim.json.encode(result)
  end,
}

-- Resource: Recent files
M.recent_files = {
  uri = 'neovim://recent-files',
  name = 'Recent Files',
  description = 'Recently accessed files in current project',
  mimeType = 'application/json',
  handler = function()
    local ok, context_module = pcall(require, 'claude-code.context')
    if not ok then
      return vim.json.encode({ error = 'Context module not available' })
    end

    local recent_files = context_module.get_recent_files(15)
    local result = {
      project_root = vim.fn.getcwd(),
      recent_files = recent_files,
    }

    return vim.json.encode(result)
  end,
}

-- Resource: Current visual selection
M.visual_selection = {
  uri = 'neovim://visual-selection',
  name = 'Visual Selection',
  description = 'Currently selected text in visual mode or last visual selection',
  mimeType = 'application/json',
  handler = function()
    -- Get the current mode
    local mode = vim.api.nvim_get_mode().mode
    local is_visual = mode:match('[vV]') ~= nil

    -- Get visual selection marks
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    -- If not in visual mode and marks are not set, return empty
    if not is_visual and (start_pos[2] == 0 or end_pos[2] == 0) then
      return vim.json.encode({
        has_selection = false,
        message = 'No visual selection available',
      })
    end

    -- Get buffer information
    local bufnr = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(bufnr)
    local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })

    -- Get the selected lines
    local start_line = start_pos[2]
    local end_line = end_pos[2]
    local start_col = start_pos[3]
    local end_col = end_pos[3]

    -- Get the lines
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)

    -- Handle character-wise selection
    if mode == 'v' or (not is_visual and vim.fn.visualmode() == 'v') then
      -- Adjust for character-wise selection
      if #lines == 1 then
        -- Single line selection
        lines[1] = lines[1]:sub(start_col, end_col)
      else
        -- Multi-line selection
        lines[1] = lines[1]:sub(start_col)
        if #lines > 1 then
          lines[#lines] = lines[#lines]:sub(1, end_col)
        end
      end
    end

    local result = {
      has_selection = true,
      is_active = is_visual,
      mode = is_visual and mode or vim.fn.visualmode(),
      file = buf_name,
      filetype = filetype,
      start_line = start_line,
      end_line = end_line,
      start_column = start_col,
      end_column = end_col,
      line_count = end_line - start_line + 1,
      text = table.concat(lines, '\n'),
      lines = lines,
    }

    return vim.json.encode(result)
  end,
}

-- Resource: Enhanced workspace context
M.workspace_context = {
  uri = 'neovim://workspace-context',
  name = 'Workspace Context',
  description = 'Enhanced workspace context including related files, recent files, and symbols',
  mimeType = 'application/json',
  handler = function()
    local ok, context_module = pcall(require, 'claude-code.context')
    if not ok then
      return vim.json.encode({ error = 'Context module not available' })
    end

    local enhanced_context = context_module.get_enhanced_context(true, true, true)
    return vim.json.encode(enhanced_context)
  end,
}

-- Resource: Search results and quickfix
M.search_results = {
  uri = 'neovim://search-results',
  name = 'Search Results',
  description = 'Current search results and quickfix list',
  mimeType = 'application/json',
  handler = function()
    local result = {
      search_pattern = vim.fn.getreg('/'),
      quickfix_list = vim.fn.getqflist(),
      location_list = vim.fn.getloclist(0),
      last_search_count = vim.fn.searchcount(),
    }

    -- Add readable quickfix entries
    local readable_qf = {}
    for _, item in ipairs(result.quickfix_list) do
      if item.bufnr > 0 and vim.api.nvim_buf_is_valid(item.bufnr) then
        local bufname = vim.api.nvim_buf_get_name(item.bufnr)
        table.insert(readable_qf, {
          filename = vim.fn.fnamemodify(bufname, ':~:.'),
          lnum = item.lnum,
          col = item.col,
          text = item.text,
          type = item.type,
        })
      end
    end
    result.readable_quickfix = readable_qf

    return vim.json.encode(result)
  end,
}

return M
