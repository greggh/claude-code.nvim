---@mod claude-code.keymaps Keymap management for claude-code.nvim
---@brief [[
--- This module provides keymap registration and handling for claude-code.nvim.
--- It handles normal mode, terminal mode, and window navigation keymaps.
---@brief ]]

local M = {}

--- Register keymaps for claude-code.nvim
--- @param claude_code table The main plugin module
--- @param config table The plugin configuration
function M.register_keymaps(claude_code, config)
  local map_opts = { noremap = true, silent = true }

  -- Normal mode toggle keymaps
  if config.keymaps.toggle.normal then
    vim.api.nvim_set_keymap(
      'n',
      config.keymaps.toggle.normal,
      [[<cmd>ClaudeCode<CR>]],
      vim.tbl_extend('force', map_opts, { desc = 'Claude Code: Toggle' })
    )
  end


  if config.keymaps.toggle.terminal then
    -- Terminal mode toggle keymap
    -- In terminal mode, special keys like Ctrl need different handling
    -- We use a direct escape sequence approach for more reliable terminal mappings
    vim.api.nvim_set_keymap(
      't',
      config.keymaps.toggle.terminal,
      [[<C-\><C-n>:ClaudeCode<CR>]],
      vim.tbl_extend('force', map_opts, { desc = 'Claude Code: Toggle' })
    )
  end

  -- Register variant keymaps if configured
  if config.keymaps.toggle.variants then
    for variant_name, keymap in pairs(config.keymaps.toggle.variants) do
      if keymap then
        -- Convert variant name to PascalCase for command name (e.g., "continue" -> "Continue")
        local capitalized_name = variant_name:gsub('^%l', string.upper)
        local cmd_name = 'ClaudeCode' .. capitalized_name

        vim.api.nvim_set_keymap(
          'n',
          keymap,
          string.format([[<cmd>%s<CR>]], cmd_name),
          vim.tbl_extend('force', map_opts, { desc = 'Claude Code: ' .. capitalized_name })
        )
      end
    end
  end

  -- Register with which-key if it's available
  vim.defer_fn(function()
    local status_ok, which_key = pcall(require, 'which-key')
    if status_ok then
      if config.keymaps.toggle.normal then
        which_key.add {
          mode = 'n',
          { config.keymaps.toggle.normal, desc = 'Claude Code: Toggle', icon = '🤖' },
        }
      end
      if config.keymaps.toggle.terminal then
        which_key.add {
          mode = 't',
          { config.keymaps.toggle.terminal, desc = 'Claude Code: Toggle', icon = '🤖' },
        }
      end

      -- Register variant keymaps with which-key
      if config.keymaps.toggle.variants then
        for variant_name, keymap in pairs(config.keymaps.toggle.variants) do
          if keymap then
            local capitalized_name = variant_name:gsub('^%l', string.upper)
            which_key.add {
              mode = 'n',
              { keymap, desc = 'Claude Code: ' .. capitalized_name, icon = '🤖' },
            }
          end
        end
      end
    end
  end, 100)
end

--- Set up terminal-specific keymaps for window navigation
--- @param claude_code table The main plugin module
--- @param config table The plugin configuration
function M.setup_terminal_navigation(claude_code, config)
  -- Get current active Claude instance buffer
  local current_instance = claude_code.claude_code.current_instance
  local buf = current_instance and claude_code.claude_code.instances[current_instance]
  if buf and vim.api.nvim_buf_is_valid(buf) then
    -- Create autocommand to enter insert mode when the terminal window gets focus
    local augroup = vim.api.nvim_create_augroup('ClaudeCodeTerminalFocus_' .. buf, { clear = true })

    -- Set up multiple events for more reliable focus detection
    vim.api.nvim_create_autocmd(
      { 'WinEnter', 'BufEnter', 'WinLeave', 'FocusGained', 'CmdLineLeave' },
      {
        group = augroup,
        callback = function()
          vim.schedule(claude_code.force_insert_mode)
        end,
        desc = 'Auto-enter insert mode when focusing Claude Code terminal',
      }
    )

    -- Window navigation keymaps
    if config.keymaps.window_navigation then
      -- Window navigation keymaps with special handling to force insert mode in the target window
      vim.api.nvim_buf_set_keymap(
        buf,
        't',
        '<C-h>',
        [[<C-\><C-n><C-w>h:lua require("claude-code").force_insert_mode()<CR>]],
        { noremap = true, silent = true, desc = 'Window: move left' }
      )
      vim.api.nvim_buf_set_keymap(
        buf,
        't',
        '<C-j>',
        [[<C-\><C-n><C-w>j:lua require("claude-code").force_insert_mode()<CR>]],
        { noremap = true, silent = true, desc = 'Window: move down' }
      )
      vim.api.nvim_buf_set_keymap(
        buf,
        't',
        '<C-k>',
        [[<C-\><C-n><C-w>k:lua require("claude-code").force_insert_mode()<CR>]],
        { noremap = true, silent = true, desc = 'Window: move up' }
      )
      vim.api.nvim_buf_set_keymap(
        buf,
        't',
        '<C-l>',
        [[<C-\><C-n><C-w>l:lua require("claude-code").force_insert_mode()<CR>]],
        { noremap = true, silent = true, desc = 'Window: move right' }
      )

      -- Also add normal mode mappings for when user is in normal mode in the terminal
      vim.api.nvim_buf_set_keymap(
        buf,
        'n',
        '<C-h>',
        [[<C-w>h:lua require("claude-code").force_insert_mode()<CR>]],
        { noremap = true, silent = true, desc = 'Window: move left' }
      )
      vim.api.nvim_buf_set_keymap(
        buf,
        'n',
        '<C-j>',
        [[<C-w>j:lua require("claude-code").force_insert_mode()<CR>]],
        { noremap = true, silent = true, desc = 'Window: move down' }
      )
      vim.api.nvim_buf_set_keymap(
        buf,
        'n',
        '<C-k>',
        [[<C-w>k:lua require("claude-code").force_insert_mode()<CR>]],
        { noremap = true, silent = true, desc = 'Window: move up' }
      )
      vim.api.nvim_buf_set_keymap(
        buf,
        'n',
        '<C-l>',
        [[<C-w>l:lua require("claude-code").force_insert_mode()<CR>]],
        { noremap = true, silent = true, desc = 'Window: move right' }
      )
    end

    -- Add scrolling keymaps
    if config.keymaps.scrolling then
      vim.api.nvim_buf_set_keymap(
        buf,
        't',
        '<C-f>',
        [[<C-\><C-n><C-f>i]],
        { noremap = true, silent = true, desc = 'Scroll full page down' }
      )
      vim.api.nvim_buf_set_keymap(
        buf,
        't',
        '<C-b>',
        [[<C-\><C-n><C-b>i]],
        { noremap = true, silent = true, desc = 'Scroll full page up' }
      )
    end
  end
end

return M
