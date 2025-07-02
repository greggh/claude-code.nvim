---@mod rovo-dev.commands Command registration for rovo-dev.nvim
---@brief [[
--- This module provides command registration and handling for rovo-dev.nvim.
--- It defines user commands and command handlers.
---@brief ]]

local M = {}

--- @type table<string, function> List of available commands and their handlers
M.commands = {}

--- Register commands for the rovo-dev plugin
--- @param rovo_dev table The main plugin module
function M.register_commands(rovo_dev)
  -- Create the user command for toggling Rovo Dev
  vim.api.nvim_create_user_command('RovoDev', function()
    rovo_dev.toggle()
  end, { desc = 'Toggle Rovo Dev terminal' })

  -- Create commands for each command variant
  for variant_name, variant_args in pairs(rovo_dev.config.command_variants) do
    if variant_args ~= false then
      -- Convert variant name to PascalCase for command name (e.g., "restore" -> "Restore")
      local capitalized_name = variant_name:gsub('^%l', string.upper)
      local cmd_name = 'RovoDev' .. capitalized_name

      vim.api.nvim_create_user_command(cmd_name, function()
        rovo_dev.toggle_with_variant(variant_name)
      end, { desc = 'Toggle Rovo Dev terminal with ' .. variant_name .. ' option' })
    end
  end

  -- Add version command
  vim.api.nvim_create_user_command('RovoDevVersion', function()
    vim.notify('Rovo Dev version: ' .. rovo_dev.version(), vim.log.levels.INFO)
  end, { desc = 'Display Rovo Dev version' })
end

return M
