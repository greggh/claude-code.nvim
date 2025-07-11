-- Single test runner that properly exits with verbose logging
local test_file = os.getenv('TEST_FILE')

if not test_file then
  print("Error: No test file specified via TEST_FILE environment variable")
  vim.cmd('cquit 1')
  return
end

print("=== VERBOSE TEST RUNNER ===")
print("Test file: " .. test_file)
print("Environment:")
print("  CI: " .. tostring(os.getenv('CI')))
print("  GITHUB_ACTIONS: " .. tostring(os.getenv('GITHUB_ACTIONS')))
print("  CLAUDE_CODE_TEST_MODE: " .. tostring(os.getenv('CLAUDE_CODE_TEST_MODE')))
print("  PLUGIN_ROOT: " .. tostring(os.getenv('PLUGIN_ROOT')))
print("Working directory: " .. vim.fn.getcwd())
print("Neovim version: " .. tostring(vim.version()))

-- Track test completion
local test_completed = false
local test_failed = false
local test_errors = 0

-- Set up verbose logging for plenary
local original_print = print
local test_output = {}
_G.print = function(...)
  local args = {...}
  local output = table.concat(args, " ")
  table.insert(test_output, output)
  original_print(...)
  
  -- Check for test completion patterns
  if output:match("Success:%s*%d+") and output:match("Failed%s*:%s*%d+") then
    test_completed = true
    local failed = tonumber(output:match("Failed%s*:%s*(%d+)")) or 0
    local errors = tonumber(output:match("Errors%s*:%s*(%d+)")) or 0
    if failed > 0 or errors > 0 then
      test_failed = true
      test_errors = failed + errors
    end
  end
end

print("Starting test execution...")
local start_time = vim.loop.now()

-- Run the test and capture results
local ok, result = pcall(require('plenary.test_harness').test_file, test_file, {
  minimal_init = 'tests/minimal-init.lua'
})

local end_time = vim.loop.now()
local duration = end_time - start_time

-- Restore original print
_G.print = original_print

print("=== TEST EXECUTION COMPLETE ===")
print("Duration: " .. duration .. "ms")
print("Plenary execution success: " .. tostring(ok))
print("Test completion detected: " .. tostring(test_completed))
print("Test failed: " .. tostring(test_failed))

if not ok then
  print("Error details: " .. tostring(result))
  print("=== TEST OUTPUT CAPTURE ===")
  for i, line in ipairs(test_output) do
    print(string.format("%d: %s", i, line))
  end
  print("=== END OUTPUT CAPTURE ===")
  
  -- Cleanup before exit
  if _G.cleanup_test_environment then
    _G.cleanup_test_environment()
  end
  
  vim.cmd('cquit 1')
elseif test_failed then
  print("Tests failed with " .. test_errors .. " errors/failures")
  print("=== FAILED TEST OUTPUT ===")
  -- Show all output for failed tests
  for i, line in ipairs(test_output) do
    print(string.format("%d: %s", i, line))
  end
  print("=== END FAILED OUTPUT ===")
  
  -- Cleanup before exit
  if _G.cleanup_test_environment then
    _G.cleanup_test_environment()
  end
  
  vim.cmd('cquit 1')
else
  print("All tests passed successfully")
  print("=== FINAL TEST OUTPUT ===")
  -- Show last 20 lines of output
  local start_idx = math.max(1, #test_output - 19)
  for i = start_idx, #test_output do
    if test_output[i] then
      print(string.format("%d: %s", i, test_output[i]))
    end
  end
  print("=== END FINAL OUTPUT ===")
  
  -- Cleanup before exit
  if _G.cleanup_test_environment then
    _G.cleanup_test_environment()
  end
  
  -- Force immediate exit with success
  vim.cmd('qa!')
end