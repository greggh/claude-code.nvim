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

-- Run the tests and let plenary handle the exit
require('plenary.test_harness').test_directory('tests/spec/', {
  minimal_init = 'tests/minimal-init.lua',
  sequential = true,  -- Run tests sequentially to avoid race conditions in CI
})