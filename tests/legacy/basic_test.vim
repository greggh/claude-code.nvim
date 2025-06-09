" Basic test script for Claude Code
" Doesn't rely on busted, just checks that the plugin loads

echo "Basic test started"

" Check if we can load the plugin
lua << EOF
-- Helper function for colored output
local function colored(msg, color)
  local colors = {
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    reset = "\27[0m"
  }
  return (colors[color] or "") .. msg .. colors.reset
end

print(colored("Attempting to load claude-code module...", "blue"))

-- First try to require all modules directly
print(colored("Loading core components separately...", "blue"))
local modules = {
  "claude-code",
  "claude-code.version",
  "claude-code.config",
  "claude-code.commands",
  "claude-code.keymaps",
  "claude-code.terminal",
  "claude-code.file_refresh",
  "claude-code.git"
}

for _, module_name in ipairs(modules) do
  local ok, mod = pcall(require, module_name)
  if ok then
    print(colored("✓ Successfully loaded " .. module_name, "green"))
    if module_name == "claude-code.version" then
      print("  Version info: " .. mod.string())
    end
  else
    print(colored("✗ Failed to load " .. module_name, "red"))
    print("  Error: " .. tostring(mod))
  end
end

-- Now load the main module
print(colored("\nLoading main module...", "blue"))
local ok, claude_code = pcall(require, 'claude-code')
if not ok then
  print(colored("✗ Failed to load claude-code: " .. tostring(claude_code), "red"))
  print("Exiting with error...")
  vim.cmd('cq')  -- Exit with error code
end

print(colored("✓ Main module loaded successfully", "green"))

-- Initialize the module
print(colored("\nInitializing module with setup()...", "blue"))
claude_code.setup()

-- Check key components
print(colored("\nChecking key components:", "blue"))

local checks = {
  { 
    name = "setup function", 
    expr = type(claude_code.setup) == "function"
  },
  { 
    name = "version function (callable)",
    expr = type(claude_code.version) == "function" and pcall(claude_code.version)
  },
  { 
    name = "get_version function (callable)",
    expr = type(claude_code.get_version) == "function" and pcall(claude_code.get_version)
  },
  { 
    name = "version module", 
    expr = type(claude_code.version) == "table" or type(claude_code.version) == "function"
  },
  { 
    name = "config", 
    expr = type(claude_code.config) == "table"
  },
  {
    name = "commands",
    expr = claude_code.commands ~= nil
  }
}

local all_pass = true
for _, check in ipairs(checks) do
  if check.expr then
    print(colored("✓ " .. check.name, "green"))
  else
    print(colored("✗ " .. check.name, "red"))
    all_pass = false
  end
end

-- Print debug info for version functions
print(colored("\nDebug: version() and get_version() results:", "yellow"))
if type(claude_code.version) == "function" then
  local ok, res = pcall(claude_code.version)
  print("  version() ->", ok, res)
end
if type(claude_code.get_version) == "function" then
  local ok, res = pcall(claude_code.get_version)
  print("  get_version() ->", ok, res)
end

-- Print all available functions for reference
print(colored("\nAvailable API:", "blue"))
for k, v in pairs(claude_code) do
  print("  - " .. k .. " (" .. type(v) .. ")")
  -- If it's a nested table, show its contents too
  if type(v) == "table" and k ~= "config" then
    for subk, subv in pairs(v) do
      print("    ." .. subk .. " (" .. type(subv) .. ")")
    end
  end
end

print(colored("\nBasic test " .. (all_pass and "PASSED" or "FAILED"), all_pass and "green" or "red"))

if not all_pass then
  print("Exiting with error code")
  vim.cmd('cq')
end
EOF

echo "Basic test completed"