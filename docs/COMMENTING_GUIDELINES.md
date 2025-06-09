
# Code commenting guidelines

This document outlines the commenting strategy for claude-code.nvim to maintain code clarity while following the principle of "clean, self-documenting code."

## When to add comments

### ✅ Do comment

1. **Complex Algorithms**
   - Multi-instance buffer management
   - JSON-RPC message parsing loops
   - Recursive dependency traversal
   - Language-specific import resolution

2. **Platform-Specific Code**
   - Terminal escape sequence handling
   - Cross-platform command-line tool detection
   - File descriptor validation for headless mode

3. **Protocol Implementation Details**
   - MCP JSON-RPC message framing
   - Error code mappings
   - Schema validation patterns

4. **Non-Obvious Business Logic**
   - Git root-based instance identification
   - Process state tracking for safe toggles
   - Context gathering strategies

5. **Security-Sensitive Operations**
   - Path sanitization and validation
   - Command injection prevention
   - User input validation

### ❌ **don't comment:**

1. **Self-Explanatory Code**
   ```lua
   -- BAD: Redundant comment
   local count = 0  -- Initialize count to zero

   -- GOOD: No comment needed
   local count = 0
   ```

2. **Simple Getters/Setters**
3. **Obvious Variable Declarations**
4. **Standard Lua Patterns**

## Comment style guidelines

### **functional comments**

```lua
-- Multi-instance support: Each git repository gets its own Claude instance
-- This prevents context bleeding between different projects
local function get_instance_identifier(git)
  return git.get_git_root() or vim.fn.getcwd()
end

```text

### **complex logic blocks**

```lua
-- Process JSON-RPC messages line by line per MCP specification
-- Each message must be complete JSON on a single line
while true do
  local newline_pos = buffer:find('\n')
  if not newline_pos then break end

  local line = buffer:sub(1, newline_pos - 1)
  buffer = buffer:sub(newline_pos + 1)
  -- ... process message
end

```text

### **platform-specific handling**

```lua
-- Terminal mode requires special escape sequence handling
-- <C-\><C-n> exits terminal mode before executing commands
vim.api.nvim_set_keymap(
  't',
  '<leader>cc',
  [[<C-\><C-n>:ClaudeCode<CR>]],
  { noremap = true, silent = true }
)

```text

## Implementation priority

### **phase 1: high-impact areas**

1. Terminal buffer management (`terminal.lua`)
2. MCP protocol implementation (`mcp/server.lua`)
3. Import analysis algorithms (`context.lua`)

### **phase 2: platform-specific code**

1. command-line tool detection logic (`config.lua`)
2. Terminal keymap handling (`keymaps.lua`)

### **phase 3: security & edge cases**

1. Path validation utilities (`utils.lua`)
2. Error handling patterns
3. Git command execution

## Comment maintenance

- **Update comments when logic changes**
- **Remove outdated comments immediately**
- **Prefer explaining "why" over "what"**
- **Link to external documentation for protocols**

## Examples of good comments

```lua
-- Language-specific module resolution patterns
-- Lua: require('foo.bar') -> foo/bar.lua or foo/bar/init.lua
-- JS/TS: import from './file' -> ./file.js, ./file.ts, ./file/index.js
-- Python: from foo.bar -> foo/bar.py or foo/bar/__init__.py
local module_patterns = {
  lua = { '%s.lua', '%s/init.lua' },
  javascript = { '%s.js', '%s/index.js' },
  typescript = { '%s.ts', '%s.tsx', '%s/index.ts' },
  python = { '%s.py', '%s/__init__.py' }
}

```text

```lua
-- Track process states to enable safe window hiding without interruption
-- Maps instance_id -> { status: 'running'|'suspended', hidden: boolean }
-- This prevents accidentally stopping Claude processes during UI operations
local process_states = {}

```text

## Tools and automation

- Use `stylua` for consistent formatting around comments
- Consider `luacheck` annotations for complex type information
- Link comments to issues/PRs for complex business logic

This approach ensures comments add real value while keeping the codebase clean and maintainable.

