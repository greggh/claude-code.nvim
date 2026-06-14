---@mod claude-code.file_refresh File refresh functionality for claude-code.nvim
---@brief [[
--- This module provides file refresh functionality to detect and reload files
--- that have been modified by Claude Code or other external processes.
---@brief ]]

local M = {}

--- Timer for checking file changes
--- @type userdata|nil
local refresh_timer = nil

--- Setup autocommands for file change detection
--- @param claude_code table The main plugin module
--- @param config table The plugin configuration
function M.setup(claude_code, config)
  if not config.refresh.enable then
    return
  end

  local augroup = vim.api.nvim_create_augroup('ClaudeCodeFileRefresh', { clear = true })

  -- Create an autocommand that checks for file changes more frequently
  vim.api.nvim_create_autocmd({
    'CursorHold',
    'CursorHoldI',
    'FocusGained',
    'BufEnter',
    'InsertLeave',
    'TextChanged',
    'TermLeave',
    'TermEnter',
    'BufWinEnter',
  }, {
    group = augroup,
    pattern = '*',
    callback = function()
      if vim.fn.filereadable(vim.fn.expand '%') == 1 then
        vim.cmd 'checktime'
      end
    end,
    desc = 'Check for file changes on disk',
  })

  -- Clean up any existing timer
  if refresh_timer then
    refresh_timer:stop()
    refresh_timer:close()
    refresh_timer = nil
  end

  -- Create a timer to check for file changes periodically
  refresh_timer = vim.loop.new_timer()
  if refresh_timer then
    refresh_timer:start(
      0,
      config.refresh.timer_interval,
      vim.schedule_wrap(function()
        -- Only check time if there's an active Claude Code terminal
        local current_instance = claude_code.claude_code.current_instance
        local bufnr = current_instance and claude_code.claude_code.instances[current_instance]
        if bufnr and vim.api.nvim_buf_is_valid(bufnr) and #vim.fn.win_findbuf(bufnr) > 0 then
          vim.cmd 'silent! checktime'
        end
      end)
    )
  end

  -- Create an autocommand that notifies when a file has been changed externally
  if config.refresh.show_notifications then
    vim.api.nvim_create_autocmd('FileChangedShellPost', {
      group = augroup,
      pattern = '*',
      callback = function()
        vim.notify('File changed on disk. Buffer reloaded.', vim.log.levels.INFO)
      end,
      desc = 'Notify when a file is changed externally',
    })
  end

  -- Set a shorter updatetime while Claude Code is open
  claude_code.claude_code.saved_updatetime = vim.o.updatetime

  -- When Claude Code opens, set a shorter updatetime
  vim.api.nvim_create_autocmd('TermOpen', {
    group = augroup,
    pattern = '*',
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name:match('claude%-code$') then
        claude_code.claude_code.saved_updatetime = vim.o.updatetime
        vim.o.updatetime = config.refresh.updatetime
      end
    end,
    desc = 'Set shorter updatetime when Claude Code is open',
  })

  -- When Claude Code closes, restore normal updatetime and clean up
  vim.api.nvim_create_autocmd('TermClose', {
    group = augroup,
    pattern = '*',
    callback = function(args)
      if not vim.api.nvim_buf_is_valid(args.buf) then return end
      local buf_name = vim.api.nvim_buf_get_name(args.buf)
      if buf_name:match('claude%-code') then
        vim.o.updatetime = claude_code.claude_code.saved_updatetime
        -- Clean up instance tracking and close window
        for instance_id, bufnr in pairs(claude_code.claude_code.instances) do
          if bufnr == args.buf then
            claude_code.claude_code.instances[instance_id] = nil
            break
          end
        end
        -- Close windows and delete buffer after a short delay to allow TermClose to complete
        vim.schedule(function()
          local win_ids = vim.fn.win_findbuf(args.buf)
          for _, win_id in ipairs(win_ids) do
            pcall(vim.api.nvim_win_close, win_id, true)
          end
          pcall(vim.api.nvim_buf_delete, args.buf, { force = true })
        end)
      end
    end,
    desc = 'Restore normal updatetime and clean up when Claude Code is closed',
  })
end

--- Clean up the file refresh functionality (stop the timer)
function M.cleanup()
  if refresh_timer then
    refresh_timer:stop()
    refresh_timer:close()
    refresh_timer = nil
  end
end

return M
