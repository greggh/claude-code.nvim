---@mod claude-code.commands Command registration for claude-code.nvim
---@brief [[
--- This module provides command registration and handling for claude-code.nvim.
--- It defines user commands and command handlers.
---@brief ]]

local M = {}

--- @type table<string, function> List of available commands and their handlers
M.commands = {}

local mcp = require('claude-code.mcp')

--- Register commands for the claude-code plugin
--- @param claude_code table The main plugin module
function M.register_commands(claude_code)
  -- Create the user command for toggling Claude Code
  vim.api.nvim_create_user_command('ClaudeCode', function()
    claude_code.toggle()
  end, { desc = 'Toggle Claude Code terminal' })

  -- Create commands for each command variant
  for variant_name, variant_args in pairs(claude_code.config.command_variants) do
    if variant_args ~= false then
      -- Convert variant name to PascalCase for command name (e.g., "continue" -> "Continue", "mcp_debug" -> "McpDebug")
      local capitalized_name = variant_name
        :gsub('_(.)', function(c)
          return c:upper()
        end)
        :gsub('^%l', string.upper)
      local cmd_name = 'ClaudeCode' .. capitalized_name

      vim.api.nvim_create_user_command(cmd_name, function()
        claude_code.toggle_with_variant(variant_name)
      end, { desc = 'Toggle Claude Code terminal with ' .. variant_name .. ' option' })
    end
  end

  -- Add version command
  vim.api.nvim_create_user_command('ClaudeCodeVersion', function()
    vim.notify('Claude Code version: ' .. claude_code.version(), vim.log.levels.INFO)
  end, { desc = 'Display Claude Code version' })

  -- Add context-aware commands
  vim.api.nvim_create_user_command('ClaudeCodeWithFile', function()
    claude_code.toggle_with_context('file')
  end, { desc = 'Toggle Claude Code with current file context' })

  vim.api.nvim_create_user_command('ClaudeCodeWithSelection', function()
    claude_code.toggle_with_context('selection')
  end, { desc = 'Toggle Claude Code with visual selection', range = true })

  vim.api.nvim_create_user_command('ClaudeCodeWithContext', function()
    claude_code.toggle_with_context('auto')
  end, { desc = 'Toggle Claude Code with automatic context detection', range = true })

  vim.api.nvim_create_user_command('ClaudeCodeWithWorkspace', function()
    claude_code.toggle_with_context('workspace')
  end, { desc = 'Toggle Claude Code with enhanced workspace context including related files' })

  vim.api.nvim_create_user_command('ClaudeCodeWithProjectTree', function()
    claude_code.toggle_with_context('project_tree')
  end, { desc = 'Toggle Claude Code with project file tree structure' })

  -- Add safe window toggle commands
  vim.api.nvim_create_user_command('ClaudeCodeHide', function()
    claude_code.safe_toggle()
  end, { desc = 'Hide Claude Code window without stopping the process' })

  vim.api.nvim_create_user_command('ClaudeCodeShow', function()
    claude_code.safe_toggle()
  end, { desc = 'Show Claude Code window if hidden' })

  vim.api.nvim_create_user_command('ClaudeCodeSafeToggle', function()
    claude_code.safe_toggle()
  end, { desc = 'Safely toggle Claude Code window without interrupting execution' })

  -- Add status and management commands
  vim.api.nvim_create_user_command('ClaudeCodeStatus', function()
    local status = claude_code.get_process_status()
    vim.notify(status.message, vim.log.levels.INFO)
  end, { desc = 'Show current Claude Code process status' })

  vim.api.nvim_create_user_command('ClaudeCodeInstances', function()
    local instances = claude_code.list_instances()
    if #instances == 0 then
      vim.notify('No Claude Code instances running', vim.log.levels.INFO)
    else
      local msg = 'Claude Code instances:\n'
      for _, instance in ipairs(instances) do
        msg = msg
          .. string.format(
            '  %s: %s (%s)\n',
            instance.instance_id,
            instance.status,
            instance.visible and 'visible' or 'hidden'
          )
      end
      vim.notify(msg, vim.log.levels.INFO)
    end
  end, { desc = 'List all Claude Code instances and their states' })

  -- MCP status command (updated for mcp-neovim-server)
  vim.api.nvim_create_user_command('ClaudeMCPStatus', function()
    if vim.fn.executable('mcp-neovim-server') == 1 then
      vim.notify('mcp-neovim-server is available', vim.log.levels.INFO)
    else
      vim.notify(
        'mcp-neovim-server not found. Install with: npm install -g mcp-neovim-server',
        vim.log.levels.WARN
      )
    end
  end, { desc = 'Show Claude MCP server status' })

  -- MCP-based selection commands
  vim.api.nvim_create_user_command('ClaudeCodeSendSelection', function(opts)
    -- Check if Claude Code is running
    local status = claude_code.get_process_status()
    if status.status == 'none' then
      vim.notify('Claude Code is not running. Start it first with :ClaudeCode', vim.log.levels.WARN)
      return
    end

    -- Get visual selection
    local start_line = opts.line1
    local end_line = opts.line2
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

    if #lines == 0 then
      vim.notify('No selection to send', vim.log.levels.WARN)
      return
    end

    -- Get file info
    local bufnr = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(bufnr)
    local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })

    -- Create a formatted message
    local message = string.format(
      'Selected code from %s (lines %d-%d):\n\n```%s\n%s\n```',
      vim.fn.fnamemodify(buf_name, ':~:.'),
      start_line,
      end_line,
      filetype,
      table.concat(lines, '\n')
    )

    -- Send to Claude Code via clipboard (temporary approach)
    vim.fn.setreg('+', message)
    vim.notify('Selection copied to clipboard. Paste in Claude Code to share.', vim.log.levels.INFO)

    -- TODO: When MCP bidirectional communication is fully implemented,
    -- this will directly send the selection to Claude Code
  end, { desc = 'Send visual selection to Claude Code via MCP', range = true })

  vim.api.nvim_create_user_command('ClaudeCodeExplainSelection', function(opts)
    -- Start Claude Code with selection context and explanation prompt
    local start_line = opts.line1
    local end_line = opts.line2
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

    if #lines == 0 then
      vim.notify('No selection to explain', vim.log.levels.WARN)
      return
    end

    -- Get file info
    local bufnr = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(bufnr)
    local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })

    -- Create temp file with selection and prompt
    local temp_content = {
      '# Code Explanation Request',
      '',
      string.format('**File:** %s', vim.fn.fnamemodify(buf_name, ':~:.')),
      string.format('**Lines:** %d-%d', start_line, end_line),
      string.format('**Language:** %s', filetype),
      '',
      '## Selected Code',
      '',
      '```' .. filetype,
    }

    for _, line in ipairs(lines) do
      table.insert(temp_content, line)
    end

    table.insert(temp_content, '```')
    table.insert(temp_content, '')
    table.insert(temp_content, '## Task')
    table.insert(temp_content, '')
    table.insert(temp_content, 'Please explain what this code does, including:')
    table.insert(temp_content, '1. The overall purpose and functionality')
    table.insert(temp_content, '2. How it works step by step')
    table.insert(temp_content, '3. Any potential issues or improvements')
    table.insert(temp_content, '4. Key concepts or patterns used')

    -- Save to temp file
    local tmpfile = vim.fn.tempname() .. '.md'
    vim.fn.writefile(temp_content, tmpfile)

    -- Save original command and toggle with context
    local original_cmd = claude_code.config.command
    claude_code.config.command = string.format('%s --file "%s"', original_cmd, tmpfile)
    claude_code.toggle()
    claude_code.config.command = original_cmd

    -- Clean up temp file after delay
    vim.defer_fn(function()
      vim.fn.delete(tmpfile)
    end, 10000)
  end, { desc = 'Explain visual selection with Claude Code', range = true })

  -- MCP configuration helper
  vim.api.nvim_create_user_command('ClaudeCodeMCPConfig', function(opts)
    local config_type = opts.args or 'claude-code'
    local mcp_module = require('claude-code.mcp')
    local success = mcp_module.setup_claude_integration(config_type)
    if not success then
      vim.notify('Failed to generate MCP configuration', vim.log.levels.ERROR)
    end
  end, {
    desc = 'Generate MCP configuration for Claude Code CLI',
    nargs = '?',
    complete = function()
      return { 'claude-code', 'workspace', 'generic' }
    end,
  })

  -- Seamless Claude invocation with MCP
  vim.api.nvim_create_user_command('Claude', function(opts)
    local prompt = opts.args

    -- Get visual selection if in visual mode
    local mode = vim.fn.mode()
    local selection = nil
    if mode:match('[vV]') or opts.range > 0 then
      local start_line = opts.line1
      local end_line = opts.line2
      local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
      if #lines > 0 then
        selection = table.concat(lines, '\n')
      end
    end

    -- Get the claude-nvim wrapper path
    local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h:h')
    local claude_nvim = plugin_dir .. '/bin/claude-nvim'

    -- Build the command
    local cmd = vim.fn.shellescape(claude_nvim)

    -- Add selection context if available
    if selection then
      -- Save selection to temp file
      local tmpfile = vim.fn.tempname() .. '.txt'
      vim.fn.writefile(vim.split(selection, '\n'), tmpfile)
      cmd = cmd .. ' --file ' .. vim.fn.shellescape(tmpfile)

      -- Clean up temp file after a delay
      vim.defer_fn(function()
        vim.fn.delete(tmpfile)
      end, 10000)
    end

    -- Add the prompt
    if prompt and prompt ~= '' then
      cmd = cmd .. ' ' .. vim.fn.shellescape(prompt)
    else
      -- If no prompt, at least provide some context
      local bufname = vim.api.nvim_buf_get_name(0)
      if bufname ~= '' then
        cmd = cmd .. ' "Help me with this ' .. vim.bo.filetype .. ' file"'
      end
    end

    -- Launch in terminal
    vim.cmd('tabnew')
    vim.cmd('terminal ' .. cmd)
    vim.cmd('startinsert')
  end, {
    desc = 'Launch Claude with MCP integration (seamless)',
    nargs = '*',
    range = true,
  })

  -- Quick Claude query that shows response in buffer
  vim.api.nvim_create_user_command('ClaudeAsk', function(opts)
    local prompt = opts.args
    if not prompt or prompt == '' then
      vim.notify('Usage: :ClaudeAsk <your question>', vim.log.levels.WARN)
      return
    end

    -- Get the claude-nvim wrapper path
    local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h:h')
    local claude_nvim = plugin_dir .. '/bin/claude-nvim'

    -- Create a new buffer for the response
    vim.cmd('new')
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
    vim.api.nvim_buf_set_name(buf, 'Claude Response')

    -- Add header
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      '# Claude Response',
      '',
      '**Question:** ' .. prompt,
      '',
      '---',
      '',
      '_Waiting for response..._',
    })

    -- Run claude-nvim and capture output
    local lines = {}
    local job_id = vim.fn.jobstart({ claude_nvim, prompt }, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        if data then
          for _, line in ipairs(data) do
            if line ~= '' then
              table.insert(lines, line)
            end
          end
        end
      end,
      on_exit = function(_, exit_code)
        vim.schedule(function()
          if exit_code == 0 and #lines > 0 then
            -- Update buffer with response
            vim.api.nvim_buf_set_lines(buf, 6, -1, false, lines)
          else
            vim.api.nvim_buf_set_lines(buf, 6, -1, false, {
              '_Error: Failed to get response from Claude_',
            })
          end
        end)
      end,
    })

    -- Add keybinding to close the buffer
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':bd<CR>', {
      noremap = true,
      silent = true,
      desc = 'Close Claude response',
    })
  end, {
    desc = 'Ask Claude a quick question and show response in buffer',
    nargs = '+',
  })
end

return M
