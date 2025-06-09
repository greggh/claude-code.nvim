-- Shared test utilities for claude-code.nvim tests
local M = {}

-- Import general utils for color support
local utils = require('claude-code.utils')

-- Re-export color utilities for backward compatibility
M.colors = utils.colors
M.cprint = utils.cprint
M.color = utils.color

-- Test result tracking
M.results = {}

-- Record a test result with colored output
-- @param name string Test name
-- @param passed boolean Whether test passed
-- @param details string|nil Additional details
function M.record_test(name, passed, details)
  M.results[name] = {
    passed = passed,
    details = details or '',
    timestamp = os.time(),
  }

  if passed then
    M.cprint('green', '  ✅ ' .. name)
  else
    M.cprint('red', '  ❌ ' .. name .. ' - ' .. (details or 'Failed'))
  end
end

-- Print test header
-- @param title string Test suite title
function M.print_header(title)
  M.cprint('magenta', string.rep('=', 50))
  M.cprint('magenta', title)
  M.cprint('magenta', string.rep('=', 50))
end

-- Print test section
-- @param section string Section name
function M.print_section(section)
  M.cprint('cyan', '\n' .. section)
end

-- Create a temporary test file
-- @param path string File path
-- @param content string File content
-- @return boolean Success
function M.create_test_file(path, content)
  local file = io.open(path, 'w')
  if file then
    file:write(content)
    file:close()
    return true
  end
  return false
end

-- Generate test summary
-- @return string Summary of test results
function M.generate_summary()
  local total = 0
  local passed = 0

  for _, result in pairs(M.results) do
    total = total + 1
    if result.passed then
      passed = passed + 1
    end
  end

  local summary =
    string.format('\nTest Summary: %d/%d passed (%.1f%%)', passed, total, (passed / total) * 100)

  if passed == total then
    return M.color('green', summary .. ' 🎉')
  elseif passed > 0 then
    return M.color('yellow', summary .. ' ⚠️')
  else
    return M.color('red', summary .. ' ❌')
  end
end

-- Reset test results
function M.reset()
  M.results = {}
end

return M
