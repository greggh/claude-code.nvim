-- Test runner for Plenary-based tests
print('Test runner started')
print('Loading plenary test harness...')
local ok, plenary = pcall(require, 'plenary')
if not ok then
  print('ERROR: Could not load plenary: ' .. tostring(plenary))
  vim.cmd('cquit 1')
  return
end
print('Plenary loaded successfully')

-- Run tests
print('Starting test run...')
print('Test directory: tests/spec/')
print('Current working directory: ' .. vim.fn.getcwd())

-- Check if test directory exists
local test_dir = vim.fn.expand('tests/spec/')
if vim.fn.isdirectory(test_dir) == 0 then
  print('ERROR: Test directory not found: ' .. test_dir)
  vim.cmd('cquit 1')
  return
end

-- List test files
local test_files = vim.fn.glob('tests/spec/*_spec.lua', false, true)
print('Found ' .. #test_files .. ' test files')
if #test_files > 0 then
  print('First few test files:')
  for i = 1, math.min(5, #test_files) do
    print('  ' .. test_files[i])
  end
end

-- Add better error handling and diagnostics
local original_error = error
_G.error = function(msg, level)
  print(string.format('\n❌ ERROR: %s\n', tostring(msg)))
  print(debug.traceback())
  original_error(msg, level)
end

-- Add test lifecycle logging
local test_count = 0
local original_it = _G.it
if original_it then
  _G.it = function(name, fn)
    return original_it(name, function()
      test_count = test_count + 1
      print(string.format('\n🧪 Test #%d: %s', test_count, name))
      local start_time = vim.loop.hrtime()

      local ok, err = pcall(fn)

      local elapsed = (vim.loop.hrtime() - start_time) / 1e9
      if ok then
        print(string.format('✅ Passed (%.3fs)', elapsed))
      else
        print(string.format('❌ Failed (%.3fs): %s', elapsed, tostring(err)))
        error(err)
      end
    end)
  end
end

-- Run the tests with enhanced error handling
local ok, err = pcall(function()
  require('plenary.test_harness').test_directory('tests/spec/', {
    minimal_init = 'tests/minimal-init.lua',
    sequential = true, -- Run tests sequentially to avoid race conditions in CI
  })
end)

if not ok then
  print(string.format('\n💥 Test suite failed with error: %s', tostring(err)))
  vim.cmd('cquit 1')
end
