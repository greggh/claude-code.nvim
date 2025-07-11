-- claude-code.nvim plugin initialization file
-- This file is automatically loaded by Neovim when the plugin is in the runtimepath

-- Only load once
if vim.g.loaded_claude_code then
  return
end
vim.g.loaded_claude_code = 1

-- Don't auto-setup here - let lazy.nvim handle it or user can call setup manually