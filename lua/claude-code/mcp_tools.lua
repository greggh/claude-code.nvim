local M = {}

-- Tool: Edit buffer content
M.vim_buffer = {
  name = 'vim_buffer',
  description = 'View or edit buffer content in Neovim',
  inputSchema = {
    type = 'object',
    properties = {
      filename = {
        type = 'string',
        description = 'Optional file name to view a specific buffer',
      },
    },
    additionalProperties = false,
  },
  handler = function(args)
    local filename = args.filename
    local bufnr

    if filename then
      -- Find buffer by filename
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local buf_name = vim.api.nvim_buf_get_name(buf)
        if buf_name:match(vim.pesc(filename) .. '$') then
          bufnr = buf
          break
        end
      end

      if not bufnr then
        return 'Buffer not found: ' .. filename
      end
    else
      -- Use current buffer
      bufnr = vim.api.nvim_get_current_buf()
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local buf_name = vim.api.nvim_buf_get_name(bufnr)
    local line_count = #lines

    local result = string.format('Buffer: %s (%d lines)\n\n', buf_name, line_count)

    for i, line in ipairs(lines) do
      result = result .. string.format('%4d\t%s\n', i, line)
    end

    return result
  end,
}

-- Tool: Execute Vim command
M.vim_command = {
  name = 'vim_command',
  description = 'Execute a Vim command in Neovim',
  inputSchema = {
    type = 'object',
    properties = {
      command = {
        type = 'string',
        description = 'Vim command to execute (use ! prefix for shell commands if enabled)',
      },
    },
    required = { 'command' },
    additionalProperties = false,
  },
  handler = function(args)
    local command = args.command

    local ok, result = pcall(vim.cmd, command)
    if not ok then
      return 'Error executing command: ' .. result
    end

    return 'Command executed successfully: ' .. command
  end,
}

-- Tool: Get Neovim status
M.vim_status = {
  name = 'vim_status',
  description = 'Get current Neovim status and context',
  inputSchema = {
    type = 'object',
    properties = {
      filename = {
        type = 'string',
        description = 'Optional file name to get status for a specific buffer',
      },
    },
    additionalProperties = false,
  },
  handler = function(args)
    local filename = args.filename
    local bufnr

    if filename then
      -- Find buffer by filename
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local buf_name = vim.api.nvim_buf_get_name(buf)
        if buf_name:match(vim.pesc(filename) .. '$') then
          bufnr = buf
          break
        end
      end

      if not bufnr then
        return 'Buffer not found: ' .. filename
      end
    else
      bufnr = vim.api.nvim_get_current_buf()
    end

    local cursor_pos = { 1, 0 } -- Default to line 1, column 0
    local mode = vim.api.nvim_get_mode().mode

    -- Find window ID for the buffer
    local winnr = 0
    local wins = vim.api.nvim_list_wins()
    for _, win in ipairs(wins) do
      if vim.api.nvim_win_get_buf(win) == bufnr then
        cursor_pos = vim.api.nvim_win_get_cursor(win)
        winnr = win
        break
      end
    end

    local buf_name = vim.api.nvim_buf_get_name(bufnr)
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    local modified = vim.api.nvim_get_option_value('modified', { buf = bufnr })
    local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })

    local result = {
      buffer = {
        number = bufnr,
        name = buf_name,
        filetype = filetype,
        line_count = line_count,
        modified = modified,
      },
      cursor = {
        line = cursor_pos[1],
        column = cursor_pos[2],
      },
      mode = mode,
      window = winnr,
    }

    return vim.json.encode(result)
  end,
}

-- Tool: Edit buffer content
M.vim_edit = {
  name = 'vim_edit',
  description = 'Edit buffer content in Neovim',
  inputSchema = {
    type = 'object',
    properties = {
      startLine = {
        type = 'number',
        description = 'The line number where editing should begin (1-indexed)',
      },
      mode = {
        type = 'string',
        enum = { 'insert', 'replace', 'replaceAll' },
        description = 'Whether to insert new content, replace existing content, or replace entire buffer',
      },
      lines = {
        type = 'string',
        description = 'The text content to insert or use as replacement',
      },
    },
    required = { 'startLine', 'mode', 'lines' },
    additionalProperties = false,
  },
  handler = function(args)
    local start_line = args.startLine
    local mode = args.mode
    local lines_text = args.lines

    -- Convert text to lines array
    local lines = vim.split(lines_text, '\n', { plain = true })

    local bufnr = vim.api.nvim_get_current_buf()

    if mode == 'replaceAll' then
      -- Replace entire buffer
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      return 'Buffer content replaced entirely'
    elseif mode == 'insert' then
      -- Insert lines at specified position
      vim.api.nvim_buf_set_lines(bufnr, start_line - 1, start_line - 1, false, lines)
      return string.format('Inserted %d lines at line %d', #lines, start_line)
    elseif mode == 'replace' then
      -- Replace lines starting at specified position
      local end_line = start_line - 1 + #lines
      vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, lines)
      return string.format('Replaced %d lines starting at line %d', #lines, start_line)
    else
      return 'Invalid mode: ' .. mode
    end
  end,
}

-- Tool: Window management
M.vim_window = {
  name = 'vim_window',
  description = 'Manage Neovim windows',
  inputSchema = {
    type = 'object',
    properties = {
      command = {
        type = 'string',
        enum = {
          'split',
          'vsplit',
          'only',
          'close',
          'wincmd h',
          'wincmd j',
          'wincmd k',
          'wincmd l',
        },
        description = 'Window manipulation command',
      },
    },
    required = { 'command' },
    additionalProperties = false,
  },
  handler = function(args)
    local command = args.command

    local ok, result = pcall(vim.cmd, command)
    if not ok then
      return 'Error executing window command: ' .. result
    end

    return 'Window command executed: ' .. command
  end,
}

-- Tool: Set marks
M.vim_mark = {
  name = 'vim_mark',
  description = 'Set marks in Neovim',
  inputSchema = {
    type = 'object',
    properties = {
      mark = {
        type = 'string',
        pattern = '^[a-z]$',
        description = 'Single lowercase letter [a-z] to use as the mark name',
      },
      line = {
        type = 'number',
        description = 'The line number where the mark should be placed (1-indexed)',
      },
      column = {
        type = 'number',
        description = 'The column number where the mark should be placed (0-indexed)',
      },
    },
    required = { 'mark', 'line', 'column' },
    additionalProperties = false,
  },
  handler = function(args)
    local mark = args.mark
    local line = args.line
    local column = args.column

    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_mark(bufnr, mark, line, column, {})

    return string.format("Mark '%s' set at line %d, column %d", mark, line, column)
  end,
}

-- Tool: Register operations
M.vim_register = {
  name = 'vim_register',
  description = 'Set register content in Neovim',
  inputSchema = {
    type = 'object',
    properties = {
      register = {
        type = 'string',
        pattern = '^[a-z"]$',
        description = 'Register name - a lowercase letter [a-z] or double-quote ["] for the unnamed register',
      },
      content = {
        type = 'string',
        description = 'The text content to store in the specified register',
      },
    },
    required = { 'register', 'content' },
    additionalProperties = false,
  },
  handler = function(args)
    local register = args.register
    local content = args.content

    vim.fn.setreg(register, content)

    return string.format("Register '%s' set with content", register)
  end,
}

-- Tool: Visual selection
M.vim_visual = {
  name = 'vim_visual',
  description = 'Make visual selections in Neovim',
  inputSchema = {
    type = 'object',
    properties = {
      startLine = {
        type = 'number',
        description = 'The starting line number for visual selection (1-indexed)',
      },
      startColumn = {
        type = 'number',
        description = 'The starting column number for visual selection (0-indexed)',
      },
      endLine = {
        type = 'number',
        description = 'The ending line number for visual selection (1-indexed)',
      },
      endColumn = {
        type = 'number',
        description = 'The ending column number for visual selection (0-indexed)',
      },
    },
    required = { 'startLine', 'startColumn', 'endLine', 'endColumn' },
    additionalProperties = false,
  },
  handler = function(args)
    local start_line = args.startLine
    local start_col = args.startColumn
    local end_line = args.endLine
    local end_col = args.endColumn

    -- Set cursor to start position
    vim.api.nvim_win_set_cursor(0, { start_line, start_col })

    -- Enter visual mode
    vim.cmd('normal! v')

    -- Move to end position
    vim.api.nvim_win_set_cursor(0, { end_line, end_col })

    return string.format(
      'Visual selection from %d:%d to %d:%d',
      start_line,
      start_col,
      end_line,
      end_col
    )
  end,
}

-- Tool: Analyze related files
M.analyze_related = {
  name = 'analyze_related',
  description = 'Analyze files related to current buffer through imports/requires',
  inputSchema = {
    type = 'object',
    properties = {
      max_depth = {
        type = 'number',
        description = 'Maximum dependency depth to analyze (default: 2)',
        default = 2,
      },
    },
  },
  handler = function(args)
    local ok, context_module = pcall(require, 'claude-code.context')
    if not ok then
      return { content = { type = 'text', text = 'Context module not available' } }
    end

    local current_file = vim.api.nvim_buf_get_name(0)
    if current_file == '' then
      return { content = { type = 'text', text = 'No current file open' } }
    end

    local max_depth = args.max_depth or 2
    local related_files = context_module.get_related_files(current_file, max_depth)

    local result_lines = {
      string.format('# Related Files Analysis for: %s', vim.fn.fnamemodify(current_file, ':~:.')),
      '',
      string.format('Found %d related files:', #related_files),
      '',
    }

    for _, file_info in ipairs(related_files) do
      table.insert(result_lines, string.format('## %s', file_info.path))
      table.insert(result_lines, string.format('- **Depth:** %d', file_info.depth))
      table.insert(result_lines, string.format('- **Language:** %s', file_info.language))
      table.insert(result_lines, string.format('- **Imports:** %d', #file_info.imports))
      if #file_info.imports > 0 then
        table.insert(result_lines, '- **Import List:**')
        for _, import in ipairs(file_info.imports) do
          table.insert(result_lines, string.format('  - `%s`', import))
        end
      end
      table.insert(result_lines, '')
    end

    return { content = { type = 'text', text = table.concat(result_lines, '\n') } }
  end,
}

-- Tool: Find workspace symbols
M.find_symbols = {
  name = 'find_symbols',
  description = 'Find symbols in the current workspace using LSP',
  inputSchema = {
    type = 'object',
    properties = {
      query = {
        type = 'string',
        description = 'Symbol name to search for (empty for all symbols)',
      },
      limit = {
        type = 'number',
        description = 'Maximum number of symbols to return (default: 20)',
        default = 20,
      },
    },
  },
  handler = function(args)
    local ok, context_module = pcall(require, 'claude-code.context')
    if not ok then
      return { content = { type = 'text', text = 'Context module not available' } }
    end

    local symbols = context_module.get_workspace_symbols()
    local query = args.query or ''
    local limit = args.limit or 20

    -- Filter symbols by query if provided
    local filtered_symbols = {}
    for _, symbol in ipairs(symbols) do
      if query == '' or symbol.name:lower():match(query:lower()) then
        table.insert(filtered_symbols, symbol)
        if #filtered_symbols >= limit then
          break
        end
      end
    end

    local result_lines = {
      string.format('# Workspace Symbols%s', query ~= '' and (' matching: ' .. query) or ''),
      '',
      string.format('Found %d symbols:', #filtered_symbols),
      '',
    }

    for _, symbol in ipairs(filtered_symbols) do
      local location = symbol.location
      local file = location.uri:gsub('file://', '')
      local relative_file = vim.fn.fnamemodify(file, ':~:.')

      table.insert(result_lines, string.format('## %s', symbol.name))
      table.insert(result_lines, string.format('- **Type:** %s', symbol.kind))
      table.insert(result_lines, string.format('- **File:** %s', relative_file))
      table.insert(result_lines, string.format('- **Line:** %d', location.range.start.line + 1))
      if symbol.container_name then
        table.insert(result_lines, string.format('- **Container:** %s', symbol.container_name))
      end
      table.insert(result_lines, '')
    end

    return { content = { type = 'text', text = table.concat(result_lines, '\n') } }
  end,
}

-- Tool: Search project files
M.search_files = {
  name = 'search_files',
  description = 'Search for files in the current project',
  inputSchema = {
    type = 'object',
    properties = {
      pattern = {
        type = 'string',
        description = 'File name pattern to search for',
        required = true,
      },
      include_content = {
        type = 'boolean',
        description = 'Whether to include file content in results (default: false)',
        default = false,
      },
    },
  },
  handler = function(args)
    local pattern = args.pattern
    local include_content = args.include_content or false

    if not pattern then
      return { content = { type = 'text', text = 'Pattern is required' } }
    end

    -- Use find command to search for files
    local cmd = string.format("find . -name '*%s*' -type f | head -20", pattern)
    local handle = io.popen(cmd)
    if not handle then
      return { content = { type = 'text', text = 'Failed to execute search' } }
    end

    local output = handle:read('*a')
    handle:close()

    local files = vim.split(output, '\n', { plain = true })
    local result_lines = {
      string.format('# Files matching pattern: %s', pattern),
      '',
      string.format('Found %d files:', #files - 1), -- -1 for empty last line
      '',
    }

    for _, file in ipairs(files) do
      if file ~= '' then
        local relative_file = file:gsub('^%./', '')
        table.insert(result_lines, string.format('## %s', relative_file))

        if include_content and vim.fn.filereadable(file) == 1 then
          local lines = vim.fn.readfile(file, '', 20) -- First 20 lines
          table.insert(result_lines, '```')
          for _, line in ipairs(lines) do
            table.insert(result_lines, line)
          end
          if #lines == 20 then
            table.insert(result_lines, '... (truncated)')
          end
          table.insert(result_lines, '```')
        end
        table.insert(result_lines, '')
      end
    end

    return { content = { type = 'text', text = table.concat(result_lines, '\n') } }
  end,
}

-- Tool: Get current selection
M.get_selection = {
  name = 'get_selection',
  description = 'Get the currently selected text or last visual selection from Neovim',
  inputSchema = {
    type = 'object',
    properties = {
      include_context = {
        type = 'boolean',
        description = 'Include surrounding context (5 lines before/after) (default: false)',
        default = false,
      },
    },
  },
  handler = function(args)
    local include_context = args.include_context or false

    -- Get the current mode
    local mode = vim.api.nvim_get_mode().mode
    local is_visual = mode:match('[vV]') ~= nil

    -- Get visual selection marks
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    -- If not in visual mode and marks are not set, return empty
    if not is_visual and (start_pos[2] == 0 or end_pos[2] == 0) then
      return { content = { type = 'text', text = 'No visual selection available' } }
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

    local result_lines = {
      string.format('# Selection from: %s', vim.fn.fnamemodify(buf_name, ':~:.')),
      string.format('**File Type:** %s', filetype),
      string.format('**Lines:** %d-%d', start_line, end_line),
      string.format('**Mode:** %s', is_visual and mode or vim.fn.visualmode()),
      '',
    }

    -- Add context if requested
    if include_context then
      table.insert(result_lines, '## Context')
      table.insert(result_lines, '')

      -- Get context lines (5 before and after)
      local context_start = math.max(1, start_line - 5)
      local context_end = math.min(vim.api.nvim_buf_line_count(bufnr), end_line + 5)
      local context_lines = vim.api.nvim_buf_get_lines(bufnr, context_start - 1, context_end, false)

      table.insert(result_lines, string.format('```%s', filetype))
      for i, line in ipairs(context_lines) do
        local line_num = context_start + i - 1
        local prefix = '  '
        if line_num >= start_line and line_num <= end_line then
          prefix = '> '
        end
        table.insert(result_lines, string.format('%s%4d: %s', prefix, line_num, line))
      end
      table.insert(result_lines, '```')
      table.insert(result_lines, '')
    end

    -- Add the selection
    table.insert(result_lines, '## Selected Text')
    table.insert(result_lines, '')
    table.insert(result_lines, string.format('```%s', filetype))
    for _, line in ipairs(lines) do
      table.insert(result_lines, line)
    end
    table.insert(result_lines, '```')

    return { content = { type = 'text', text = table.concat(result_lines, '\n') } }
  end,
}

return M
