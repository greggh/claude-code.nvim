-- Claude Code Test Commands
-- Commands to run the self-test functionality

-- Helper function to find plugin root directory
local function get_plugin_root()
  -- Try to use the current file's location to determine plugin root
  local current_file = debug.getinfo(1, "S").source:sub(2)
  local plugin_dir = vim.fn.fnamemodify(current_file, ":h:h")
  return plugin_dir
end

-- Define command to run the general functionality test
vim.api.nvim_create_user_command("ClaudeCodeSelfTest", function()
  -- Use dofile directly to load the test file
  local plugin_root = get_plugin_root()
  local self_test = dofile(plugin_root .. "/test/self_test.lua")
  self_test.run_all_tests()
end, {
  desc = "Run Claude Code Self-Test to verify functionality",
})

-- Define command to run the MCP-specific test
vim.api.nvim_create_user_command("ClaudeCodeMCPTest", function()
  -- Use dofile directly to load the test file
  local plugin_root = get_plugin_root()
  local mcp_test = dofile(plugin_root .. "/test/self_test_mcp.lua")
  mcp_test.run_all_tests()
end, {
  desc = "Run Claude Code MCP-specific tests",
})

-- Define command to run both tests
vim.api.nvim_create_user_command("ClaudeCodeTestAll", function()
  -- Use dofile directly to load the test files
  local plugin_root = get_plugin_root()
  local self_test = dofile(plugin_root .. "/test/self_test.lua")
  local mcp_test = dofile(plugin_root .. "/test/self_test_mcp.lua")
  
  self_test.run_all_tests()
  print("\n")
  mcp_test.run_all_tests()
  
  -- Show overall summary
  print("\n\n==== OVERALL TEST SUMMARY ====")
  
  local general_passed = 0
  local general_total = 0
  for _, result in pairs(self_test.results) do
    general_total = general_total + 1
    if result then general_passed = general_passed + 1 end
  end
  
  local mcp_passed = 0
  local mcp_total = 0
  for _, result in pairs(mcp_test.results) do
    mcp_total = mcp_total + 1
    if result then mcp_passed = mcp_passed + 1 end
  end
  
  local total_passed = general_passed + mcp_passed
  local total_total = general_total + mcp_total
  
  print(string.format("General Tests: %d/%d passed", general_passed, general_total))
  print(string.format("MCP Tests: %d/%d passed", mcp_passed, mcp_total))
  print(string.format("Total: %d/%d passed (%d%%)", 
                     total_passed, 
                     total_total, 
                     math.floor((total_passed / total_total) * 100)))
  
  if total_passed == total_total then
    print("\n🎉 ALL TESTS PASSED! The Claude Code Neovim plugin is functioning correctly.")
  else
    print("\n⚠️  Some tests failed. Check the logs above for details.")
  end
end, {
  desc = "Run all Claude Code tests (general and MCP functionality)",
})

-- Run the live test for Claude to demonstrate MCP functionality
vim.api.nvim_create_user_command("ClaudeCodeLiveTest", function()
  -- Load and run the live test using dofile
  local plugin_root = get_plugin_root()
  local live_test = dofile(plugin_root .. "/test/mcp_live_test.lua")
  live_test.run_live_test()
end, {
  desc = "Run a live test for Claude to demonstrate MCP functionality",
})

-- Open the test file that Claude can modify
vim.api.nvim_create_user_command("ClaudeCodeOpenTestFile", function()
  -- Load the live test module and open the test file
  local plugin_root = get_plugin_root()
  local live_test = dofile(plugin_root .. "/test/mcp_live_test.lua")
  live_test.open_test_file()
end, {
  desc = "Open the Claude Code test file",
})

-- Create command for interactive demo (list of features user can try)
vim.api.nvim_create_user_command("ClaudeCodeDemo", function()
  -- Print interactive demo instructions
  print("=== Claude Code Interactive Demo ===")
  print("Try these features to test Claude Code functionality:")
  print("")
  print("1. MCP Server:")
  print("   - :ClaudeCodeMCPStart - Start MCP server")
  print("   - :ClaudeCodeMCPStatus - Check server status")
  print("   - :ClaudeCodeMCPStop - Stop MCP server")
  print("")
  print("2. MCP Configuration:")
  print("   - :ClaudeCodeMCPConfig - Generate config files")
  print("   - :ClaudeCodeSetup - Generate config with instructions")
  print("")
  print("3. Terminal Interface:")
  print("   - <C-,> - Toggle Claude Code terminal")
  print("   - :ClaudeCodeContinue - Continue last conversation")
  print("   - Window navigation: <C-h/j/k/l> in terminal")
  print("")
  print("4. Testing:")
  print("   - :ClaudeCodeSelfTest - Run general functionality tests")
  print("   - :ClaudeCodeMCPTest - Run MCP server tests")
  print("   - :ClaudeCodeTestAll - Run all tests")
  print("")
  print("5. Ask Claude to modify a file:")
  print("   - With MCP server running, ask Claude to modify a file")
  print("   - Example: \"Please add a comment to the top of this file\"")
  print("")
end, {
  desc = "Show interactive demo instructions for Claude Code",
})
