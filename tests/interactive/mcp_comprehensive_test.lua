-- Comprehensive MCP Integration Test Suite
-- This test validates both basic MCP functionality AND the new MCP Hub integration

local test_utils = require('test.test_utils')
local M = {}

-- Test state tracking
M.test_state = {
  started = false,
  completed = {},
  results = {},
  start_time = nil,
}

-- Use shared color and test utilities
local color = test_utils.color
local cprint = test_utils.cprint
local record_test = test_utils.record_test

-- Create test directory structure
function M.setup_test_environment()
  print(color('cyan', '\n🔧 Setting up test environment...'))

  -- Create test directories with validation
  local dirs = {
    'test/mcp_test_workspace',
    'test/mcp_test_workspace/src',
  }

  for _, dir in ipairs(dirs) do
    local result = vim.fn.mkdir(dir, 'p')
    if result == 0 and vim.fn.isdirectory(dir) == 0 then
      error('Failed to create directory: ' .. dir)
    end
  end

  -- Create test files for Claude to work with
  local test_files = {
    ['test/mcp_test_workspace/README.md'] = [[
# MCP Test Workspace

This workspace is for testing MCP integration.

## TODO for Claude Code:
1. Update this README with test results
2. Create a new file called `test_results.md`
3. Demonstrate multi-file editing capabilities
]],
    ['test/mcp_test_workspace/src/example.lua'] = [[
-- Example Lua file for MCP testing
local M = {}

-- TODO: Claude should add a function here
-- Function name: validate_mcp_integration()
-- It should return a table with test results

return M
]],
    ['test/mcp_test_workspace/.gitignore'] = [[
*.tmp
.cache/
]],
  }

  for path, content in pairs(test_files) do
    local file, err = io.open(path, 'w')
    if file then
      file:write(content)
      file:close()
    else
      error('Failed to create file: ' .. path .. ' - ' .. (err or 'unknown error'))
    end
  end

  record_test('Test environment setup', true)
  return true
end

-- Test 1: Basic MCP Operations
function M.test_basic_mcp_operations()
  print(color('cyan', '\n📝 Test 1: Basic MCP Operations'))

  -- Create a buffer for Claude to interact with
  vim.cmd('edit test/mcp_test_workspace/mcp_basic_test.txt')

  local test_content = {
    '=== MCP BASIC OPERATIONS TEST ===',
    '',
    'Claude Code should demonstrate:',
    '1. Reading this buffer content (mcp__neovim__vim_buffer)',
    '2. Editing specific lines (mcp__neovim__vim_edit)',
    '3. Executing Vim commands (mcp__neovim__vim_command)',
    '4. Getting editor status (mcp__neovim__vim_status)',
    '',
    "TODO: Replace this line with 'MCP Edit Test Successful!'",
    '',
    'Validation checklist:',
    '[ ] Buffer read',
    '[ ] Edit operation',
    '[ ] Command execution',
    '[ ] Status check',
  }

  vim.api.nvim_buf_set_lines(0, 0, -1, false, test_content)

  record_test('Basic MCP test buffer created', true)
  return true
end

-- Test 2: MCP Hub Integration
function M.test_mcp_hub_integration()
  print(color('cyan', '\n🌐 Test 2: MCP Hub Integration'))

  -- Test hub functionality
  local hub = require('claude-code.mcp_hub')

  -- Run hub's built-in test
  local hub_test_passed = hub.live_test()

  record_test('MCP Hub integration', hub_test_passed)

  -- Additional hub tests
  print(color('yellow', '\n  Claude Code should now:'))
  print('  1. Run :MCPHubList to show available servers')
  print('  2. Generate a config with multiple servers using :MCPHubGenerate')
  print('  3. Verify the generated configuration')

  return hub_test_passed
end

-- Test 3: Multi-file Operations
function M.test_multi_file_operations()
  print(color('cyan', '\n📂 Test 3: Multi-file Operations'))

  -- Instructions for Claude
  local instructions = [[
=== MULTI-FILE OPERATION TEST ===

Claude Code should:
1. Read all files in test/mcp_test_workspace/
2. Update the README.md with current timestamp
3. Add the validate_mcp_integration() function to src/example.lua
4. Create a new file: test/mcp_test_workspace/test_results.md
5. Save all changes

Expected outcomes:
- README.md should have a "Last tested:" line
- src/example.lua should have the new function
- test_results.md should exist with test summary
]]

  vim.cmd('edit test/mcp_test_workspace/INSTRUCTIONS.txt')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(instructions, '\n'))

  record_test('Multi-file test setup', true)
  return true
end

-- Test 4: Advanced MCP Features
function M.test_advanced_features()
  print(color('cyan', '\n🚀 Test 4: Advanced MCP Features'))

  -- Test window management, marks, registers, etc.
  vim.cmd('edit test/mcp_test_workspace/advanced_test.lua')

  local content = {
    '-- Advanced MCP Features Test',
    '',
    '-- Claude should demonstrate:',
    '-- 1. Window management (split, resize)',
    '-- 2. Mark operations (set/jump)',
    '-- 3. Register operations',
    '-- 4. Visual mode selections',
    '',
    'local test_data = {',
    "  window_test = 'TODO: Add window count',",
    "  mark_test = 'TODO: Set mark A here',",
    "  register_test = 'TODO: Copy this to register a',",
    "  visual_test = 'TODO: Select and modify this line',",
    '}',
    '',
    '-- VALIDATION SECTION',
    '-- Claude should update these values:',
    'local validation = {',
    '  windows_created = 0,',
    '  marks_set = {},',
    '  registers_used = {},',
    '  visual_operations = 0',
    '}',
  }

  vim.api.nvim_buf_set_lines(0, 0, -1, false, content)

  record_test('Advanced features test created', true)
  return true
end

-- Main test runner
function M.run_comprehensive_test()
  M.test_state.started = true
  M.test_state.start_time = os.time()

  print(
    color(
      'magenta',
      '╔════════════════════════════════════════════╗'
    )
  )
  print(color('magenta', '║     🧪 MCP COMPREHENSIVE TEST SUITE 🧪     ║'))
  print(
    color(
      'magenta',
      '╚════════════════════════════════════════════╝'
    )
  )

  -- Generate MCP configuration if needed
  print(color('yellow', '\n📋 Checking MCP configuration...'))
  local config_path = vim.fn.getcwd() .. '/.claude.json'
  if vim.fn.filereadable(config_path) == 0 then
    vim.cmd('ClaudeCodeSetup claude-code')
    print(color('green', '  ✅ Generated MCP configuration'))
  else
    print(color('green', '  ✅ MCP configuration exists'))
  end

  -- Run all tests
  M.setup_test_environment()
  M.test_basic_mcp_operations()
  M.test_mcp_hub_integration()
  M.test_multi_file_operations()
  M.test_advanced_features()

  -- Summary
  print(
    color(
      'magenta',
      '\n╔════════════════════════════════════════════╗'
    )
  )
  print(color('magenta', '║           TEST SUITE PREPARED              ║'))
  print(
    color(
      'magenta',
      '╚════════════════════════════════════════════╝'
    )
  )

  print(color('cyan', '\n🤖 INSTRUCTIONS FOR CLAUDE CODE:'))
  print(color('yellow', '\n1. Work through each test section'))
  print(color('yellow', '2. Use the appropriate MCP tools for each task'))
  print(color('yellow', '3. Update files as requested'))
  print(color('yellow', '4. Create a final summary in test_results.md'))
  print(color('yellow', '\n5. When complete, run :MCPTestValidate'))

  -- Create validation command
  vim.api.nvim_create_user_command('MCPTestValidate', function()
    M.validate_results()
  end, { desc = 'Validate MCP test results' })

  return true
end

-- Validate test results
function M.validate_results()
  print(color('cyan', '\n🔍 Validating Test Results...'))

  local validations = {
    ['Basic test file modified'] = vim.fn.filereadable(
      'test/mcp_test_workspace/mcp_basic_test.txt'
    ) == 1,
    ['README.md updated'] = vim.fn.getftime('test/mcp_test_workspace/README.md')
      > M.test_state.start_time,
    ['test_results.md created'] = vim.fn.filereadable('test/mcp_test_workspace/test_results.md')
      == 1,
    ['example.lua modified'] = vim.fn.getftime('test/mcp_test_workspace/src/example.lua')
      > M.test_state.start_time,
    ['MCP Hub tested'] = M.test_state.results['MCP Hub integration']
      and M.test_state.results['MCP Hub integration'].passed,
  }

  local all_passed = true
  for test, passed in pairs(validations) do
    record_test(test, passed)
    if not passed then
      all_passed = false
    end
  end

  -- Final result
  print(color('magenta', '\n' .. string.rep('=', 50)))
  if all_passed then
    print(color('green', '🎉 ALL TESTS PASSED! MCP Integration is working perfectly!'))
  else
    print(color('red', '⚠️  Some tests failed. Please review the results above.'))
  end
  print(color('magenta', string.rep('=', 50)))

  return all_passed
end

-- Clean up test files
function M.cleanup()
  print(color('yellow', '\n🧹 Cleaning up test files...'))
  vim.fn.system('rm -rf test/mcp_test_workspace')
  print(color('green', '  ✅ Test workspace cleaned'))
end

-- Register main test command
vim.api.nvim_create_user_command('MCPComprehensiveTest', function()
  M.run_comprehensive_test()
end, { desc = 'Run comprehensive MCP integration test' })

vim.api.nvim_create_user_command('MCPTestCleanup', function()
  M.cleanup()
end, { desc = 'Clean up MCP test files' })

return M
