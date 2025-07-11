-- Claude Code MCP Live Test
-- This file provides a quick live test that Claude can use to demonstrate its ability
-- to interact with Neovim through the MCP server.

local test_utils = require('test.test_utils')
local M = {}

-- Use shared color utilities
local cprint = test_utils.cprint

-- Create a test file for Claude to modify
function M.setup_test_file()
  -- Create a temp file in the project directory
  local file_path = 'test/claude_live_test_file.txt'

  -- Check if file exists
  local exists = vim.fn.filereadable(file_path) == 1

  if exists then
    -- Delete existing file
    vim.fn.delete(file_path)
  end

  -- Create the file with test content
  local file = io.open(file_path, 'w')
  if file then
    file:write('This is a test file for Claude Code MCP.\n')
    file:write('Claude should be able to read and modify this file.\n')
    file:write('\n')
    file:write('TODO: Claude should add content here to demonstrate MCP functionality.\n')
    file:write('\n')
    file:write('The current date and time is: ' .. os.date('%Y-%m-%d %H:%M:%S') .. '\n')
    file:close()

    cprint('green', '✅ Created test file at: ' .. file_path)
    return file_path
  else
    cprint('red', '❌ Failed to create test file')
    return nil
  end
end

-- Open the test file in a new buffer
function M.open_test_file(file_path)
  if not file_path then
    file_path = 'test/claude_live_test_file.txt'
  end

  if vim.fn.filereadable(file_path) == 1 then
    -- Open the file in a new buffer
    vim.cmd('edit ' .. file_path)
    cprint('green', '✅ Opened test file in buffer')
    return true
  else
    cprint('red', '❌ Test file not found: ' .. file_path)
    return false
  end
end

-- Run a simple live test that Claude can use
function M.run_live_test()
  cprint('magenta', '======================================')
  cprint('magenta', '🔌 CLAUDE CODE MCP LIVE TEST 🔌')
  cprint('magenta', '======================================')

  -- Create a test file
  local file_path = M.setup_test_file()

  if not file_path then
    cprint('red', '❌ Cannot continue with live test, file creation failed')
    return false
  end

  -- Generate MCP config if needed
  cprint('yellow', '📝 Checking MCP configuration...')
  local config_path = vim.fn.getcwd() .. '/.claude.json'
  if vim.fn.filereadable(config_path) == 0 then
    vim.cmd('ClaudeCodeSetup claude-code')
    cprint('green', '✅ Generated MCP configuration')
  else
    cprint('green', '✅ MCP configuration exists')
  end

  -- Open the test file
  if not M.open_test_file(file_path) then
    return false
  end

  -- Instructions for Claude
  cprint('cyan', '\n=== INSTRUCTIONS FOR CLAUDE ===')
  cprint('yellow', "1. I've created a test file for you to modify")
  cprint('yellow', '2. Use the MCP tools to demonstrate functionality:')
  cprint('yellow', '   a) mcp__neovim__vim_buffer - Read current buffer')
  cprint('yellow', '   b) mcp__neovim__vim_edit - Replace the TODO line')
  cprint('yellow', '   c) mcp__neovim__project_structure - Show files in test/')
  cprint('yellow', '   d) mcp__neovim__git_status - Check git status')
  cprint('yellow', '   e) mcp__neovim__vim_command - Save the file (:w)')
  cprint('yellow', '3. Add a validation section showing successful test')

  -- Create validation checklist in buffer
  vim.api.nvim_buf_set_lines(0, -1, -1, false, {
    '',
    '=== MCP VALIDATION CHECKLIST ===',
    '[ ] Buffer read successful',
    '[ ] Edit operation successful',
    '[ ] Project structure accessed',
    '[ ] Git status checked',
    '[ ] File saved via vim command',
    '',
    'Claude Code Test Results:',
    '(Claude should fill this section)',
  })

  -- Output additional context
  cprint('blue', '\n=== CONTEXT ===')
  cprint('blue', 'Test file: ' .. file_path)
  cprint('blue', 'Working directory: ' .. vim.fn.getcwd())
  cprint('blue', 'MCP config: ' .. config_path)

  cprint('magenta', '======================================')
  cprint('magenta', '🎬 TEST READY - CLAUDE CAN PROCEED 🎬')
  cprint('magenta', '======================================')

  return true
end

-- Comprehensive validation test
function M.validate_mcp_integration()
  cprint('cyan', '\n=== MCP INTEGRATION VALIDATION ===')

  local validation_results = {}

  -- Test 1: Check if we can access the current buffer
  validation_results.buffer_access = '❓ Awaiting Claude Code validation'

  -- Test 2: Check if we can execute commands
  validation_results.command_execution = '❓ Awaiting Claude Code validation'

  -- Test 3: Check if we can read project structure
  validation_results.project_structure = '❓ Awaiting Claude Code validation'

  -- Test 4: Check if we can access git information
  validation_results.git_access = '❓ Awaiting Claude Code validation'

  -- Test 5: Check if we can perform edits
  validation_results.edit_capability = '❓ Awaiting Claude Code validation'

  -- Display results
  cprint('yellow', '\nValidation Status:')
  for test, result in pairs(validation_results) do
    print('  ' .. test .. ': ' .. result)
  end

  cprint('cyan', '\nClaude Code should update these results via MCP tools!')

  return validation_results
end

-- Register commands - these are already being registered in plugin/self_test_command.lua
-- We're keeping the function here for reference
function M.setup_commands()
  -- Commands are now registered in plugin/self_test_command.lua
end

return M
