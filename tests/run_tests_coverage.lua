-- Test runner for Plenary-based tests with coverage support
local ok, plenary = pcall(require, 'plenary')
if not ok then
  print('ERROR: Could not load plenary')
  vim.cmd('qa!')
  return
end

-- Load luacov for coverage - must be done before loading any modules to test
local has_luacov, luacov = pcall(require, 'luacov')
if has_luacov then
  print('LuaCov loaded - coverage will be collected')
  -- Start luacov if not already started
  if type(luacov.init) == 'function' then
    luacov.init()
  end
else
  print('Warning: LuaCov not found - coverage will not be collected')
  -- Try alternative loading methods
  local alt_paths = {
    '/usr/local/share/lua/5.1/luacov.lua',
    '/usr/share/lua/5.1/luacov.lua',
  }
  for _, path in ipairs(alt_paths) do
    local f = io.open(path, 'r')
    if f then
      f:close()
      package.path = package.path .. ';' .. path:gsub('/[^/]*$', '/?.lua')
      local success = pcall(require, 'luacov')
      if success then
        print('LuaCov loaded from alternative path: ' .. path)
        break
      end
    end
  end
end

-- Track test completion
local tests_started = false
local last_output_time = vim.loop.now()
local test_results = { success = 0, failed = 0, errors = 0 }

-- Hook into print to detect test output
local original_print = print
_G.print = function(...)
  original_print(...)
  last_output_time = vim.loop.now()
  
  local output = table.concat({...}, " ")
  -- Check for test completion patterns
  if output:match("Success:%s*(%d+)") then
    tests_started = true
    test_results.success = tonumber(output:match("Success:%s*(%d+)")) or 0
  end
  if output:match("Failed%s*:%s*(%d+)") then
    test_results.failed = tonumber(output:match("Failed%s*:%s*(%d+)")) or 0
  end
  if output:match("Errors%s*:%s*(%d+)") then
    test_results.errors = tonumber(output:match("Errors%s*:%s*(%d+)")) or 0
  end
end

-- Function to check if tests are complete and exit
local function check_completion()
  local now = vim.loop.now()
  local idle_time = now - last_output_time
  
  -- If we've seen test output and been idle for 2 seconds, tests are done
  if tests_started and idle_time > 2000 then
    -- Restore original print
    _G.print = original_print
    
    print(string.format("\nTest run complete: Success: %d, Failed: %d, Errors: %d",
      test_results.success, test_results.failed, test_results.errors))
    
    if test_results.failed > 0 or test_results.errors > 0 then
      vim.cmd('cquit 1')
    else
      vim.cmd('qa!')
    end
    return true
  end
  
  return false
end

-- Start checking for completion
local check_timer = vim.loop.new_timer()
check_timer:start(500, 500, vim.schedule_wrap(function()
  if check_completion() then
    check_timer:stop()
  end
end))

-- Failsafe exit after 30 seconds
vim.defer_fn(function()
  print("\nTest timeout - exiting")
  vim.cmd('cquit 1')
end, 30000)

-- Run tests
print('Starting test run with coverage...')
require('plenary.test_harness').test_directory('tests/spec/', {
  minimal_init = 'tests/minimal-init.lua',
  sequential = true,  -- Run tests sequentially to avoid race conditions in CI
})
