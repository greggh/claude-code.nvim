" Config module test script for Rovo Dev
" Tests the configuration validation and merging

echo "Config test started"

" Check if we can load the plugin
lua << EOF
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

-- Test setup
print(colored("Testing config module...", "blue"))

-- Load the config module
local ok, config = pcall(require, "rovo-dev.config")
if not ok then
  print(colored("✗ Failed to load config module: " .. tostring(config), "red"))
  vim.cmd('cq')  -- Exit with error code
end

print(colored("✓ Config module loaded successfully", "green"))

-- Test default configuration
print(colored("\nTesting default configuration...", "blue"))
local default_config = config.default_config

local tests = {
  { 
    name = "has window settings", 
    expected = "table",
    actual = type(default_config.window)
  },
  { 
    name = "has keymaps settings", 
    expected = "table",
    actual = type(default_config.keymaps)
  },
  { 
    name = "has window.height_ratio",
    expected = "number",
    actual = type(default_config.window.height_ratio)
  }
}

local all_pass = true
for _, test in ipairs(tests) do
  if test.actual == test.expected then
    print(colored("✓ " .. test.name, "green"))
  else
    print(colored("✗ " .. test.name .. " - Expected: " .. tostring(test.expected) .. ", Got: " .. tostring(test.actual), "red"))
    all_pass = false
  end
end

-- Test configuration parsing
print(colored("\nTesting configuration parsing and validation...", "blue"))

local validation_tests = {
  {
    name = "Valid config passes validation",
    config = {
      window = {
        height_ratio = 0.5,
        position = "botright",
      },
      keymaps = {
        toggle = {
          normal = "<leader>cc",
        }
      }
    },
    should_pass = true
  },
  {
    name = "Invalid height_ratio (too high)",
    config = {
      window = {
        height_ratio = 2.0, -- Should be between 0 and 1
      }
    },
    should_pass = false
  },
  {
    name = "Invalid height_ratio (negative)",
    config = {
      window = {
        height_ratio = -0.5, -- Should be between 0 and 1
      }
    },
    should_pass = false
  },
  {
    name = "Invalid position",
    config = {
      window = {
        position = "invalid-position", -- Should be one of the valid positions
      }
    },
    should_pass = false
  }
}

for _, test in ipairs(validation_tests) do
  local parsed_config = config.parse_config(test.config)
  local is_valid = parsed_config.window.height_ratio ~= default_config.window.height_ratio
                  or test.config.window == nil
                  or test.config.window.height_ratio == default_config.window.height_ratio
  
  if is_valid == test.should_pass then
    print(colored("✓ " .. test.name, "green"))
  else
    print(colored("✗ " .. test.name .. " - Expected validation: " .. tostring(test.should_pass) .. ", Got: " .. tostring(is_valid), "red"))
    all_pass = false
  end
end

-- Test configuration merging
print(colored("\nTesting configuration merging...", "blue"))

local merge_tests = {
  {
    name = "Merge with custom height_ratio",
    user_config = { window = { height_ratio = 0.7 } },
    expected_value = 0.7,
    property_path = {"window", "height_ratio"}
  },
  {
    name = "Merge with custom position",
    user_config = { window = { position = "topleft" } },
    expected_value = "topleft",
    property_path = {"window", "position"}
  },
  {
    name = "Default values preserved",
    user_config = { window = { height_ratio = 0.7 } },
    expected_value = default_config.window.position,
    property_path = {"window", "position"}
  }
}

for _, test in ipairs(merge_tests) do
  local merged = config.parse_config(test.user_config)
  
  -- Navigate to the property using the path
  local actual = merged
  for _, key in ipairs(test.property_path) do
    actual = actual[key]
  end
  
  if actual == test.expected_value then
    print(colored("✓ " .. test.name, "green"))
  else
    print(colored("✗ " .. test.name .. " - Expected: " .. tostring(test.expected_value) .. ", Got: " .. tostring(actual), "red"))
    all_pass = false
  end
end

print(colored("\nConfig test " .. (all_pass and "PASSED" or "FAILED"), all_pass and "green" or "red"))

if not all_pass then
  print("Exiting with error code")
  vim.cmd('cq')
end
EOF

echo "Config test completed"
