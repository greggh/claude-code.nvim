
# Pure lua mcp server implementation analysis

## Is it feasible? YES

MCP is just JSON-RPC 2.0 over stdio, which Neovim's Lua can handle natively.

## What we need

### 1. json-rpc 2.0 protocol ✅

- Neovim has `vim.json` for JSON encoding/decoding
- Simple request/response pattern over stdio
- Can use `vim.loop` (libuv) for async I/O

### 2. stdio communication ✅

- Read from stdin: `vim.loop.new_pipe(false)`
- Write to stdout: `io.stdout:write()` or `vim.loop.write()`
- Neovim's event loop handles async naturally

### 3. MCP protocol implementation ✅

- Just need to implement the message patterns
- Tools, resources, and prompts are simple JSON structures
- No complex dependencies required

## Pure lua architecture

```lua
-- lua/claude-code/mcp/server.lua
local uv = vim.loop
local M = {}

-- JSON-RPC message handling
M.handle_message = function(message)
  local request = vim.json.decode(message)

  if request.method == "tools/list" then
    return {
      jsonrpc = "2.0",
      id = request.id,
      result = {
        tools = {
          {
            name = "edit_buffer",
            description = "Edit a buffer",
            inputSchema = {
              type = "object",
              properties = {
                buffer = { type = "number" },
                line = { type = "number" },
                text = { type = "string" }
              }
            }
          }
        }
      }
    }
  elseif request.method == "tools/call" then
    -- Handle tool execution
    local tool_name = request.params.name
    local args = request.params.arguments

    if tool_name == "edit_buffer" then
      -- Direct Neovim API call!
      vim.api.nvim_buf_set_lines(
        args.buffer,
        args.line - 1,
        args.line,
        false,
        { args.text }
      )

      return {
        jsonrpc = "2.0",
        id = request.id,
        result = {
          content = {
            { type = "text", text = "Buffer edited successfully" }
          }
        }
      }
    end
  end
end

-- Start the MCP server
M.start = function()
  local stdin = uv.new_pipe(false)
  local stdout = uv.new_pipe(false)

  -- Setup stdin reading
  stdin:open(0)  -- 0 = stdin fd
  stdout:open(1) -- 1 = stdout fd

  local buffer = ""

  stdin:read_start(function(err, data)
    if err then return end
    if not data then return end

    buffer = buffer .. data

    -- Parse complete messages (simple length check)
    -- Real implementation needs proper JSON-RPC parsing
    local messages = vim.split(buffer, "\n", { plain = true })

    for _, msg in ipairs(messages) do
      if msg ~= "" then
        local response = M.handle_message(msg)
        if response then
          local json = vim.json.encode(response)
          stdout:write(json .. "\n")
        end
      end
    end
  end)
end

return M

```text

## Advantages of pure lua

1. **No Dependencies**
   - No Node.js required
   - No npm packages
   - No build step

2. **Native Integration**
   - Direct `vim.api` calls
   - No RPC overhead to Neovim
   - Runs in Neovim's event loop

3. **Simpler Distribution**
   - Just Lua files
   - Works with any plugin manager
   - No post-install steps

4. **Better Performance**
   - No IPC between processes
   - Direct buffer manipulation
   - Lower memory footprint

5. **Easier Debugging**
   - All in Lua/Neovim ecosystem
   - Use Neovim's built-in debugging
   - Single process to monitor

## Implementation approach

### Phase 1: basic server

```lua
-- Minimal MCP server that can:
-- 1. Accept connections over stdio
-- 2. List available tools
-- 3. Execute simple buffer edits

```text

### Phase 2: full protocol

```lua
-- Add:
-- 1. All MCP methods (initialize, tools/*, resources/*)
-- 2. Error handling
-- 3. Async operations
-- 4. Progress notifications

```text

### Phase 3: advanced features

```lua
-- Add:
-- 1. LSP integration
-- 2. Git operations
-- 3. Project-wide search
-- 4. Security/permissions

```text

## Key components needed

### 1. json-rpc parser

```lua
-- Parse incoming messages
-- Handle Content-Length headers
-- Support batch requests

```text

### 2. message router

```lua
-- Route methods to handlers
-- Manage request IDs
-- Handle async responses

```text

### 3. tool implementations

```lua
-- Buffer operations
-- File operations
-- LSP queries
-- Search functionality

```text

### 4. resource providers

```lua
-- Buffer list
-- Project structure
-- Diagnostics
-- Git status

```text

## Example: complete mini server

```lua
#!/usr/bin/env -S nvim -l

-- Standalone MCP server in pure Lua
local function start_mcp_server()
  -- Initialize server
  local server = {
    name = "claude-code-nvim",
    version = "1.0.0",
    tools = {},
    resources = {}
  }

  -- Register tools
  server.tools["edit_buffer"] = {
    description = "Edit a buffer",
    handler = function(params)
      vim.api.nvim_buf_set_lines(
        params.buffer,
        params.line - 1,
        params.line,
        false,
        { params.text }
      )
      return { success = true }
    end
  }

  -- Main message loop
  local stdin = io.stdin
  stdin:setvbuf("no")  -- Unbuffered

  while true do
    local line = stdin:read("*l")
    if not line then break end

    -- Parse JSON-RPC
    local ok, request = pcall(vim.json.decode, line)
    if ok and request.method then
      -- Handle request
      local response = handle_request(server, request)
      print(vim.json.encode(response))
      io.stdout:flush()
    end
  end
end

-- Run if called directly
if arg and arg[0]:match("mcp%-server%.lua$") then
  start_mcp_server()
end

```text

## Conclusion

A pure Lua MCP server is not only feasible but **preferable** for a Neovim plugin:

- Simpler architecture
- Better integration
- Easier maintenance
- No external dependencies

We should definitely go with pure Lua!

