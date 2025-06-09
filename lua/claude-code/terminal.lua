---@mod claude-code.terminal Terminal management for claude-code.nvim
---@brief [[
--- This module provides terminal buffer management for claude-code.nvim.
--- It handles creating, toggling, and managing the terminal window.
---@brief ]]

local M = {}

--- Terminal buffer and window management
-- @table ClaudeCodeTerminal
-- @field instances table Key-value store of git root to buffer number
-- @field saved_updatetime number|nil Original updatetime before Claude Code was opened
-- @field current_instance string|nil Current git root path for active instance
-- @field floating_windows table Key-value store of instance to floating window ID
M.terminal = {
  instances = {},
  saved_updatetime = nil,
  current_instance = nil,
  process_states = {}, -- Track process states for safe window management
  floating_windows = {}, -- Track floating windows per instance
}

--- Check if a process is still running
--- @param job_id number The job ID to check
--- @return boolean True if process is still running
local function is_process_running(job_id)
  if not job_id then
    return false
  end

  -- Use jobwait with 0 timeout to check status without blocking
  local result = vim.fn.jobwait({ job_id }, 0)
  return result[1] == -1 -- -1 means still running
end

--- Update process state for an instance
--- @param claude_code table The main plugin module
--- @param instance_id string The instance identifier
--- @param status string The process status ("running", "finished", "unknown")
--- @param hidden boolean Whether the window is hidden
local function update_process_state(claude_code, instance_id, status, hidden)
  if not claude_code.claude_code.process_states then
    claude_code.claude_code.process_states = {}
  end

  claude_code.claude_code.process_states[instance_id] = {
    status = status,
    hidden = hidden or false,
    last_updated = vim.fn.localtime(),
  }
end

--- Get process state for an instance
--- @param claude_code table The main plugin module
--- @param instance_id string The instance identifier
--- @return table|nil Process state or nil if not found
local function get_process_state(claude_code, instance_id)
  if not claude_code.claude_code.process_states then
    return nil
  end
  return claude_code.claude_code.process_states[instance_id]
end

--- Clean up invalid buffers and update process states
--- Multi-instance support requires careful state management to prevent memory leaks
--- and stale references. This function removes references to buffers that no longer
--- exist and cleans up corresponding process state tracking.
--- @param claude_code table The main plugin module
local function cleanup_invalid_instances(claude_code)
  -- Iterate through all tracked Claude instances
  for instance_id, bufnr in pairs(claude_code.claude_code.instances) do
    -- Remove stale buffer references (deleted buffers or invalid handles)
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
      claude_code.claude_code.instances[instance_id] = nil
      -- Also clean up process state tracking for this instance
      if claude_code.claude_code.process_states then
        claude_code.claude_code.process_states[instance_id] = nil
      end
    end
  end
end

--- Get unique identifier for Claude instance based on project context
--- Multi-instance support: Each git repository gets its own Claude instance.
--- This prevents context bleeding between different projects and allows working
--- on multiple codebases simultaneously without losing conversation state.
--- @param git table The git module
--- @return string identifier Git root path or fallback identifier
local function get_instance_identifier(git)
  local git_root = git.get_git_root()
  if git_root then
    -- Use git root as identifier for consistency across terminal sessions
    -- This ensures the same Claude instance is used regardless of current directory
    return git_root
  else
    -- Fallback to current working directory if not in a git repo
    -- Non-git projects still get instance isolation based on working directory
    return vim.fn.getcwd()
  end
end

--- Create a floating window with the specified configuration
--- @param config table Plugin configuration containing floating window settings
--- @param existing_bufnr number|nil Buffer number to display in the floating window
--- @return number|nil Window ID of the created floating window
--- @private
local function create_floating_window(config, existing_bufnr)
  local float_config = config.window.float

  -- Calculate window dimensions based on percentages
  local width = math.floor(vim.o.columns * float_config.width)
  local height = math.floor(vim.o.lines * float_config.height)
  local row = math.floor(vim.o.lines * float_config.row)
  local col = math.floor(vim.o.columns * float_config.col)

  -- Create buffer if not provided
  local bufnr = existing_bufnr
  if not bufnr then
    bufnr = vim.api.nvim_create_buf(false, true)
  end

  -- Window configuration
  local win_config = {
    relative = float_config.relative,
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = float_config.border,
    title = float_config.title,
    title_pos = float_config.title_pos,
  }

  -- Create the floating window
  local win_id = vim.api.nvim_open_win(bufnr, true, win_config)

  -- Set window options
  vim.api.nvim_win_set_option(win_id, 'winblend', 0)
  vim.api.nvim_win_set_option(win_id, 'cursorline', true)

  -- Apply terminal window options if configured
  if config.window.hide_numbers then
    vim.api.nvim_win_set_option(win_id, 'number', false)
    vim.api.nvim_win_set_option(win_id, 'relativenumber', false)
  end

  if config.window.hide_signcolumn then
    vim.api.nvim_win_set_option(win_id, 'signcolumn', 'no')
  end

  return win_id
end

--- Create a split window according to the specified position configuration
--- @param position string Window position configuration
--- @param config table Plugin configuration containing window settings
--- @param existing_bufnr number|nil Buffer number of existing buffer to show in the split (optional)
--- @return number|nil Window ID if floating window was created
--- @private
local function create_split(position, config, existing_bufnr)
  -- Special handling for 'float' - create a floating window
  if position == 'float' then
    return create_floating_window(config, existing_bufnr)
  end

  -- Special handling for 'current' - use the current window instead of creating a split
  if position == 'current' then
    -- If we have an existing buffer to display, switch to it
    if existing_bufnr then
      vim.cmd('buffer ' .. existing_bufnr)
    end
    -- No resizing needed for current window
    return nil
  end

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

  return nil
end

--- Set up function to force insert mode when entering the Claude Code window
--- @param claude_code table The main plugin module
--- @param config table The plugin configuration
function M.force_insert_mode(claude_code, config)
  local current_bufnr = vim.fn.bufnr('%')

  -- Check if current buffer is any of our Claude instances
  local is_claude_instance = false
  for _, bufnr in pairs(claude_code.claude_code.instances) do
    if bufnr and bufnr == current_bufnr and vim.api.nvim_buf_is_valid(bufnr) then
      is_claude_instance = true
      break
    end
  end

  if is_claude_instance then
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

--- Get instance ID based on configuration
--- @param config table Plugin configuration
--- @param git table Git module
--- @return string Instance identifier
local function get_configured_instance_id(config, git)
  if config.git.multi_instance then
    if config.git.use_git_root then
      return get_instance_identifier(git)
    else
      return vim.fn.getcwd()
    end
  else
    return 'global'
  end
end

--- Handle existing instance toggle (show/hide)
--- @param claude_code table The main plugin module
--- @param config table Plugin configuration
--- @param instance_id string Instance identifier
--- @param bufnr number Buffer number
--- @return boolean True if handled, false if instance needs to be created
local function handle_existing_instance(claude_code, config, instance_id, bufnr)
  -- Special handling for floating windows
  if config.window.position == 'float' then
    local float_win_id = claude_code.claude_code.floating_windows[instance_id]
    if float_win_id and vim.api.nvim_win_is_valid(float_win_id) then
      -- Floating window exists and is visible: close it
      vim.api.nvim_win_close(float_win_id, true)
      claude_code.claude_code.floating_windows[instance_id] = nil
      update_process_state(claude_code, instance_id, 'running', true)
    else
      -- Create or restore floating window
      local win_id = create_floating_window(config, bufnr)
      claude_code.claude_code.floating_windows[instance_id] = win_id

      -- Terminal mode setup
      if not config.window.start_in_normal_mode then
        vim.schedule(function()
          vim.cmd 'stopinsert | startinsert'
        end)
      end
    end
    return true
  end

  -- Regular window handling (non-floating)
  local win_ids = vim.fn.win_findbuf(bufnr)
  if #win_ids > 0 then
    -- Claude is visible: Hide the window(s) but preserve the process
    for _, win_id in ipairs(win_ids) do
      vim.api.nvim_win_close(win_id, true)
    end
    update_process_state(claude_code, instance_id, 'running', true)
  else
    -- Claude buffer exists but is hidden: Restore it to a visible split
    create_split(config.window.position, config, bufnr)
    if not config.window.start_in_normal_mode then
      vim.schedule(function()
        vim.cmd 'stopinsert | startinsert'
      end)
    end
  end
  return true
end

--- Create new Claude Code instance
--- @param claude_code table The main plugin module
--- @param config table Plugin configuration
--- @param git table Git module
--- @param instance_id string Instance identifier
--- @param variant_name string|nil Optional command variant name
--- @return boolean Success status
local function create_new_instance(claude_code, config, git, instance_id, variant_name)
  -- Create window
  local win_id = create_split(config.window.position, config)

  -- Store floating window ID if created
  if config.window.position == 'float' and win_id then
    claude_code.claude_code.floating_windows[instance_id] = win_id
  end

  -- Build command with optional variant
  local cmd_suffix = ''
  if variant_name then
    local variant_flag = config.command_variants and config.command_variants[variant_name]
    if not variant_flag then
      vim.notify('Unknown command variant: ' .. variant_name, vim.log.levels.ERROR)
      return false
    end
    cmd_suffix = ' ' .. variant_flag
  end

  -- Determine terminal command
  local terminal_cmd = config.command .. cmd_suffix
  if config.git and config.git.use_git_root then
    local git_root = git.get_git_root()
    if git_root then
      terminal_cmd = 'pushd ' .. git_root .. ' && ' .. config.command .. cmd_suffix .. ' && popd'
    end
  end

  -- Create terminal
  if config.window.position == 'current' or config.window.position == 'float' then
    vim.cmd('enew')
  end
  vim.cmd('terminal ' .. terminal_cmd)
  vim.cmd 'setlocal bufhidden=hide'

  -- Generate buffer name
  local buffer_name = 'claude-code'
  if variant_name then
    buffer_name = buffer_name .. '-' .. variant_name
  end

  if config.git.multi_instance then
    local sanitized_id = instance_id:gsub('[^%w%-_]+', '-'):gsub('^%-+', ''):gsub('%-+$', '')
    buffer_name = buffer_name .. '-' .. sanitized_id
  end

  if _TEST or os.getenv('NVIM_TEST') then
    buffer_name = buffer_name
      .. '-'
      .. tostring(os.time())
      .. '-'
      .. tostring(math.random(10000, 99999))
  end

  vim.cmd('file ' .. buffer_name)

  -- Set window options
  if config.window.hide_numbers then
    vim.cmd 'setlocal nonumber norelativenumber'
  end
  if config.window.hide_signcolumn then
    vim.cmd 'setlocal signcolumn=no'
  end

  -- Store buffer number and update state
  local bufnr = vim.fn.bufnr('%')
  claude_code.claude_code.instances[instance_id] = bufnr

  -- Set up autocmd to close buffer when Claude Code exits
  vim.api.nvim_create_autocmd('TermClose', {
    buffer = bufnr,
    callback = function()
      -- Clean up the instance
      claude_code.claude_code.instances[instance_id] = nil
      if claude_code.claude_code.floating_windows[instance_id] then
        claude_code.claude_code.floating_windows[instance_id] = nil
      end

      -- Close the buffer after a short delay to ensure terminal cleanup
      vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
          -- Check if there are any windows showing this buffer
          local win_ids = vim.fn.win_findbuf(bufnr)
          for _, window_id in ipairs(win_ids) do
            if vim.api.nvim_win_is_valid(window_id) then
              -- Only close the window if it's not the last window
              -- Check for non-floating windows only
              local non_floating_count = 0
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                local win_config = vim.api.nvim_win_get_config(win)
                if win_config.relative == '' then
                  non_floating_count = non_floating_count + 1
                end
              end

              if non_floating_count > 1 then
                vim.api.nvim_win_close(window_id, false)
              else
                -- If it's the last window, switch to a new empty buffer instead
                vim.api.nvim_set_current_win(window_id)
                vim.cmd('enew')
              end
            end
          end
          -- Delete the buffer
          vim.api.nvim_buf_delete(bufnr, { force = true })
        end
      end, 100)
    end,
    desc = 'Close Claude Code buffer on exit',
  })

  -- Enter insert mode if configured
  if not config.window.start_in_normal_mode and config.window.enter_insert then
    vim.schedule(function()
      vim.cmd 'startinsert'
    end)
  end

  update_process_state(claude_code, instance_id, 'running', false)
  return true
end

--- Common logic for toggling Claude Code terminal
--- @param claude_code table The main plugin module
--- @param config table The plugin configuration
--- @param git table The git module
--- @param variant_name string|nil Optional command variant name
--- @return boolean Success status
local function toggle_common(claude_code, config, git, variant_name)
  -- Get instance ID using extracted function
  local instance_id = get_configured_instance_id(config, git)
  claude_code.claude_code.current_instance = instance_id

  -- Check if instance exists and is valid
  local bufnr = claude_code.claude_code.instances[instance_id]
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    -- Handle existing instance (show/hide toggle)
    return handle_existing_instance(claude_code, config, instance_id, bufnr)
  else
    -- Clean up invalid buffer if needed
    if bufnr then
      claude_code.claude_code.instances[instance_id] = nil
    end
    -- Create new instance
    return create_new_instance(claude_code, config, git, instance_id, variant_name)
  end
end

--- Toggle the Claude Code terminal window
--- @param claude_code table The main plugin module
--- @param config table The plugin configuration
--- @param git table The git module
function M.toggle(claude_code, config, git)
  return toggle_common(claude_code, config, git, nil)
end

--- Toggle the Claude Code terminal window with a specific command variant
--- @param claude_code table The main plugin module
--- @param config table The plugin configuration
--- @param git table The git module
--- @param variant_name string The name of the command variant to use
function M.toggle_with_variant(claude_code, config, git, variant_name)
  return toggle_common(claude_code, config, git, variant_name)
end

--- Toggle the Claude Code terminal with current file/selection context
--- @param claude_code table The main plugin module
--- @param config table The plugin configuration
--- @param git table The git module
--- @param context_type string|nil The type of context ("file", "selection", "auto", "workspace")
function M.toggle_with_context(claude_code, config, git, context_type)
  context_type = context_type or 'auto'

  -- Save original command
  local original_cmd = config.command
  local temp_files = {}

  -- Build context-aware command
  if context_type == 'project_tree' then
    -- Create temporary file with project tree
    local ok, tree_helper = pcall(require, 'claude-code.tree_helper')
    if ok then
      local temp_file = tree_helper.create_tree_file({
        max_depth = 3,
        max_files = 50,
        show_size = false,
      })
      table.insert(temp_files, temp_file)
      config.command = string.format('%s --file "%s"', original_cmd, temp_file)
    else
      vim.notify('Tree helper not available', vim.log.levels.WARN)
    end
  elseif
    context_type == 'selection' or (context_type == 'auto' and vim.fn.mode():match('[vV]'))
  then
    -- Handle visual selection
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    if start_pos[2] > 0 and end_pos[2] > 0 then
      local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)

      -- Add file context header
      local current_file = vim.api.nvim_buf_get_name(0)
      if current_file ~= '' then
        table.insert(
          lines,
          1,
          string.format(
            '# Selection from: %s (lines %d-%d)',
            current_file,
            start_pos[2],
            end_pos[2]
          )
        )
        table.insert(lines, 2, '')
      end

      -- Save to temp file
      local tmpfile = vim.fn.tempname() .. '.md'
      vim.fn.writefile(lines, tmpfile)
      table.insert(temp_files, tmpfile)

      config.command = string.format('%s --file "%s"', original_cmd, tmpfile)
    end
  elseif context_type == 'workspace' then
    -- Enhanced workspace context with related files
    local ok, context_module = pcall(require, 'claude-code.context')
    if ok then
      local current_file = vim.api.nvim_buf_get_name(0)
      if current_file ~= '' then
        local enhanced_context = context_module.get_enhanced_context(true, true, false)

        -- Create context summary file
        local context_lines = {
          '# Workspace Context',
          '',
          string.format('**Current File:** %s', enhanced_context.current_file.relative_path),
          string.format(
            '**Cursor Position:** Line %d',
            enhanced_context.current_file.cursor_position[1]
          ),
          string.format('**File Type:** %s', enhanced_context.current_file.filetype),
          '',
        }

        -- Add related files
        if enhanced_context.related_files and #enhanced_context.related_files > 0 then
          table.insert(context_lines, '## Related Files (through imports/requires)')
          table.insert(context_lines, '')
          for _, file_info in ipairs(enhanced_context.related_files) do
            table.insert(
              context_lines,
              string.format(
                '- **%s** (depth: %d, language: %s, imports: %d)',
                file_info.path,
                file_info.depth,
                file_info.language,
                file_info.import_count
              )
            )
          end
          table.insert(context_lines, '')
        end

        -- Add recent files
        if enhanced_context.recent_files and #enhanced_context.recent_files > 0 then
          table.insert(context_lines, '## Recent Files')
          table.insert(context_lines, '')
          for i, file_info in ipairs(enhanced_context.recent_files) do
            if i <= 5 then -- Limit to top 5 recent files
              table.insert(context_lines, string.format('- %s', file_info.relative_path))
            end
          end
          table.insert(context_lines, '')
        end

        -- Add current file content
        table.insert(context_lines, '## Current File Content')
        table.insert(context_lines, '')
        table.insert(context_lines, string.format('```%s', enhanced_context.current_file.filetype))
        local current_buffer_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        for _, line in ipairs(current_buffer_lines) do
          table.insert(context_lines, line)
        end
        table.insert(context_lines, '```')

        -- Save context to temp file
        local tmpfile = vim.fn.tempname() .. '.md'
        vim.fn.writefile(context_lines, tmpfile)
        table.insert(temp_files, tmpfile)

        config.command = string.format('%s --file "%s"', original_cmd, tmpfile)
      end
    else
      -- Fallback to file context if context module not available
      local file = vim.api.nvim_buf_get_name(0)
      if file ~= '' then
        local cursor = vim.api.nvim_win_get_cursor(0)
        config.command = string.format('%s --file "%s#%d"', original_cmd, file, cursor[1])
      end
    end
  elseif context_type == 'file' or context_type == 'auto' then
    -- Pass current file with cursor position
    local file = vim.api.nvim_buf_get_name(0)
    if file ~= '' then
      local cursor = vim.api.nvim_win_get_cursor(0)
      config.command = string.format('%s --file "%s#%d"', original_cmd, file, cursor[1])
    end
  end

  -- Toggle with enhanced command
  M.toggle(claude_code, config, git)

  -- Restore original command
  config.command = original_cmd

  -- Clean up temp files after a delay
  if #temp_files > 0 then
    vim.defer_fn(function()
      for _, tmpfile in ipairs(temp_files) do
        vim.fn.delete(tmpfile)
      end
    end, 10000) -- 10 seconds
  end
end

--- Safe toggle that hides/shows window without stopping Claude Code process
--- @param claude_code table The main plugin module
--- @param config table The plugin configuration
--- @param git table The git module
function M.safe_toggle(claude_code, config, git)
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

  claude_code.claude_code.current_instance = instance_id

  -- Clean up invalid instances first
  cleanup_invalid_instances(claude_code)

  -- Check if this Claude Code instance exists
  local bufnr = claude_code.claude_code.instances[instance_id]
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    -- Get current process state
    local process_state = get_process_state(claude_code, instance_id)

    -- Check if there's a window displaying this Claude Code buffer
    local win_ids = vim.fn.win_findbuf(bufnr)
    if #win_ids > 0 then
      -- Claude Code is visible, hide the window (but keep process running)
      for _, win_id in ipairs(win_ids) do
        vim.api.nvim_win_close(win_id, false) -- Don't force close to avoid data loss
      end

      -- Update process state to hidden
      update_process_state(claude_code, instance_id, 'running', true)

      -- Notify user that Claude Code is now running in background
      vim.notify('Claude Code hidden - process continues in background', vim.log.levels.INFO)
    else
      -- Claude Code buffer exists but is not visible, show it

      -- Check if process is still running (if we have job ID)
      if process_state and process_state.job_id then
        local is_running = is_process_running(process_state.job_id)
        if not is_running then
          update_process_state(claude_code, instance_id, 'finished', false)
          vim.notify('Claude Code task completed while hidden', vim.log.levels.INFO)
        else
          update_process_state(claude_code, instance_id, 'running', false)
        end
      else
        -- No job ID tracked, assume it's still running
        update_process_state(claude_code, instance_id, 'running', false)
      end

      -- Open it in a split
      create_split(config.window.position, config, bufnr)

      -- Force insert mode more aggressively unless configured to start in normal mode
      if not config.window.start_in_normal_mode then
        vim.schedule(function()
          vim.cmd 'stopinsert | startinsert'
        end)
      end

      vim.notify('Claude Code window restored', vim.log.levels.INFO)
    end
  else
    -- No existing instance, create a new one (same as regular toggle)
    M.toggle(claude_code, config, git)

    -- Initialize process state for new instance
    update_process_state(claude_code, instance_id, 'running', false)
  end
end

--- Get process status for current or specified instance
--- @param claude_code table The main plugin module
--- @param instance_id string|nil The instance identifier (uses current if nil)
--- @return table Process status information
function M.get_process_status(claude_code, instance_id)
  instance_id = instance_id or claude_code.claude_code.current_instance

  if not instance_id then
    return { status = 'none', message = 'No active Claude Code instance' }
  end

  local bufnr = claude_code.claude_code.instances[instance_id]
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return { status = 'none', message = 'No Claude Code instance found' }
  end

  local process_state = get_process_state(claude_code, instance_id)
  if not process_state then
    return { status = 'unknown', message = 'Process state unknown' }
  end

  local win_ids = vim.fn.win_findbuf(bufnr)
  local is_visible = #win_ids > 0

  return {
    status = process_state.status,
    hidden = process_state.hidden,
    visible = is_visible,
    instance_id = instance_id,
    buffer_number = bufnr,
    message = string.format(
      'Claude Code %s (%s)',
      process_state.status,
      is_visible and 'visible' or 'hidden'
    ),
  }
end

--- List all Claude Code instances and their states
--- @param claude_code table The main plugin module
--- @return table List of all instance states
function M.list_instances(claude_code)
  local instances = {}

  cleanup_invalid_instances(claude_code)

  for instance_id, bufnr in pairs(claude_code.claude_code.instances) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local process_state = get_process_state(claude_code, instance_id)
      local win_ids = vim.fn.win_findbuf(bufnr)

      table.insert(instances, {
        instance_id = instance_id,
        buffer_number = bufnr,
        status = process_state and process_state.status or 'unknown',
        hidden = process_state and process_state.hidden or false,
        visible = #win_ids > 0,
        last_updated = process_state and process_state.last_updated or 0,
      })
    end
  end

  return instances
end

return M
