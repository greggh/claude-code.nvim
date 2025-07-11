local uv = vim.loop or vim.uv
local utils = require('claude-code.utils')

local M = {}

-- Use shared notification utility (force stderr in server context)
local function notify(msg, level)
  utils.notify(msg, level, { prefix = 'MCP Server', force_stderr = true })
end

-- MCP Server state
local server = {
  name = 'claude-code-nvim',
  version = '1.0.0',
  protocol_version = '2024-11-05', -- Default MCP protocol version
  initialized = false,
  tools = {},
  resources = {},
  request_id = 0,
  pipes = {}, -- Track active pipes for cleanup
}

-- Generate unique request ID
local function next_id()
  server.request_id = server.request_id + 1
  return server.request_id
end

-- JSON-RPC message parser
local function parse_message(data)
  local ok, message = pcall(vim.json.decode, data)
  if not ok then
    return nil, 'Invalid JSON'
  end

  if message.jsonrpc ~= '2.0' then
    return nil, 'Invalid JSON-RPC version'
  end

  return message, nil
end

-- Create JSON-RPC response
local function create_response(id, result, error_obj)
  local response = {
    jsonrpc = '2.0',
    id = id,
  }

  if error_obj then
    response.error = error_obj
  else
    response.result = result
  end

  return response
end

-- Create JSON-RPC error
local function create_error(code, message, data)
  return {
    code = code,
    message = message,
    data = data,
  }
end

-- Handle MCP initialize method
local function handle_initialize(params)
  server.initialized = true

  return {
    protocolVersion = server.protocol_version,
    capabilities = {
      tools = {},
      resources = {},
    },
    serverInfo = {
      name = server.name,
      version = server.version,
    },
  }
end

-- Handle tools/list method
local function handle_tools_list()
  local tools = {}

  for name, tool in pairs(server.tools) do
    table.insert(tools, {
      name = name,
      description = tool.description,
      inputSchema = tool.inputSchema,
    })
  end

  return { tools = tools }
end

-- Handle tools/call method
local function handle_tools_call(params)
  local tool_name = params.name
  local arguments = params.arguments or {}

  local tool = server.tools[tool_name]
  if not tool then
    return nil, create_error(-32601, 'Tool not found: ' .. tool_name)
  end

  local ok, result = pcall(tool.handler, arguments)
  if not ok then
    return nil, create_error(-32603, 'Tool execution failed', result)
  end

  return {
    content = {
      { type = 'text', text = result },
    },
  }
end

-- Handle resources/list method
local function handle_resources_list()
  local resources = {}

  for name, resource in pairs(server.resources) do
    table.insert(resources, {
      uri = resource.uri,
      name = name,
      description = resource.description,
      mimeType = resource.mimeType,
    })
  end

  return { resources = resources }
end

-- Handle resources/read method
local function handle_resources_read(params)
  local uri = params.uri

  -- Find resource by URI
  local resource = nil
  for _, res in pairs(server.resources) do
    if res.uri == uri then
      resource = res
      break
    end
  end

  if not resource then
    return nil, create_error(-32601, 'Resource not found: ' .. uri)
  end

  local ok, content = pcall(resource.handler)
  if not ok then
    return nil, create_error(-32603, 'Resource read failed', content)
  end

  return {
    contents = {
      {
        uri = uri,
        mimeType = resource.mimeType,
        text = content,
      },
    },
  }
end

-- Main message handler
local function handle_message(message)
  if not message.method then
    return create_response(message.id, nil, create_error(-32600, 'Invalid Request'))
  end

  local result, error_obj

  if message.method == 'initialize' then
    result, error_obj = handle_initialize(message.params)
  elseif message.method == 'tools/list' then
    if not server.initialized then
      error_obj = create_error(-32002, 'Server not initialized')
    else
      result, error_obj = handle_tools_list()
    end
  elseif message.method == 'tools/call' then
    if not server.initialized then
      error_obj = create_error(-32002, 'Server not initialized')
    else
      result, error_obj = handle_tools_call(message.params)
    end
  elseif message.method == 'resources/list' then
    if not server.initialized then
      error_obj = create_error(-32002, 'Server not initialized')
    else
      result, error_obj = handle_resources_list()
    end
  elseif message.method == 'resources/read' then
    if not server.initialized then
      error_obj = create_error(-32002, 'Server not initialized')
    else
      result, error_obj = handle_resources_read(message.params)
    end
  else
    error_obj = create_error(-32601, 'Method not found: ' .. message.method)
  end

  return create_response(message.id, result, error_obj)
end

-- Register a tool
function M.register_tool(name, description, inputSchema, handler)
  server.tools[name] = {
    description = description,
    inputSchema = inputSchema,
    handler = handler,
  }
end

-- Register a resource
function M.register_resource(name, uri, description, mimeType, handler)
  server.resources[name] = {
    uri = uri,
    description = description,
    mimeType = mimeType,
    handler = handler,
  }
end

-- Configure server settings
function M.configure(config)
  if not config then
    return
  end

  -- Validate and set protocol version
  if config.protocol_version ~= nil then
    if type(config.protocol_version) == 'string' and config.protocol_version ~= '' then
      -- Basic validation: should be in YYYY-MM-DD format
      if config.protocol_version:match('^%d%d%d%d%-%d%d%-%d%d$') then
        server.protocol_version = config.protocol_version
      else
        -- Allow non-standard formats but warn
        notify(
          'Non-standard protocol version format: ' .. config.protocol_version,
          vim.log.levels.WARN
        )
        server.protocol_version = config.protocol_version
      end
    else
      -- Invalid type, use default
      notify('Invalid protocol version type, using default', vim.log.levels.WARN)
    end
  end

  -- Allow overriding server name and version
  if config.server_name and type(config.server_name) == 'string' then
    server.name = config.server_name
  end

  if config.server_version and type(config.server_version) == 'string' then
    server.version = config.server_version
  end
end

-- Start the MCP server
function M.start()
  -- Check if we're in test mode to avoid actual pipe creation in CI
  if os.getenv('CLAUDE_CODE_TEST_MODE') == 'true' then
    notify('MCP server start skipped in CI test mode', vim.log.levels.INFO)
    return true
  end

  -- Check if we're in headless mode for appropriate file descriptor usage
  local is_headless = utils.is_headless()

  if not is_headless then
    notify(
      'MCP server should typically run in headless mode for stdin/stdout communication',
      vim.log.levels.WARN
    )
  end

  local stdin = uv.new_pipe(false)
  local stdout = uv.new_pipe(false)

  if not stdin or not stdout then
    notify('Failed to create pipes for MCP server', vim.log.levels.ERROR)
    return false
  end

  -- Store pipes for cleanup
  server.pipes.stdin = stdin
  server.pipes.stdout = stdout

  -- Platform-specific file descriptor validation for MCP communication
  -- MCP uses stdin/stdout for JSON-RPC message exchange per specification
  local stdin_fd = 0 -- Standard input file descriptor
  local stdout_fd = 1 -- Standard output file descriptor

  -- Headless mode requires strict validation since MCP clients expect reliable I/O
  -- UI mode is more forgiving as stdin/stdout may be redirected or unavailable
  if is_headless then
    -- Strict validation required for MCP client communication
    -- Headless Neovim running as MCP server must have working stdio
    local stdin_ok = stdin:open(stdin_fd)
    local stdout_ok = stdout:open(stdout_fd)

    if not stdin_ok then
      notify('Failed to open stdin file descriptor in headless mode', vim.log.levels.ERROR)
      stdin:close()
      stdout:close()
      return false
    end

    if not stdout_ok then
      notify('Failed to open stdout file descriptor in headless mode', vim.log.levels.ERROR)
      stdin:close()
      stdout:close()
      return false
    end
  else
    -- UI mode: Best effort opening without strict error handling
    -- Interactive Neovim may have stdio redirected or used by other processes
    stdin:open(stdin_fd)
    stdout:open(stdout_fd)
  end

  local buffer = ''

  -- Read from stdin
  stdin:read_start(function(err, data)
    if err then
      notify('MCP server stdin error: ' .. err, vim.log.levels.ERROR)
      stdin:close()
      stdout:close()
      vim.cmd('quit')
      return
    end

    if not data then
      -- EOF received - client disconnected
      stdin:close()
      stdout:close()
      vim.cmd('quit')
      return
    end

    -- Accumulate incoming data in buffer for line-based processing
    buffer = buffer .. data

    -- JSON-RPC message processing: MCP uses line-delimited JSON format
    -- Each complete message is terminated by a newline character
    -- This loop processes all complete messages in the current buffer
    while true do
      local newline_pos = buffer:find('\n')
      if not newline_pos then
        -- No complete message available, wait for more data
        break
      end

      -- Extract one complete JSON message (everything before newline)
      local line = buffer:sub(1, newline_pos - 1)
      -- Remove processed message from buffer, keep remaining data
      buffer = buffer:sub(newline_pos + 1)

      -- Process non-empty messages (skip empty lines for robustness)
      if line ~= '' then
        -- Parse JSON-RPC message and validate structure
        local message, parse_err = parse_message(line)
        if message then
          -- Handle valid message and generate appropriate response
          local response = handle_message(message)
          -- Send response back to MCP client with newline terminator
          local json_response = vim.json.encode(response)
          stdout:write(json_response .. '\n')
        else
          -- Log parsing errors but continue processing (resilient to malformed input)
          notify('MCP parse error: ' .. (parse_err or 'unknown'), vim.log.levels.WARN)
        end
      end
    end
  end)

  return true
end

-- Stop the MCP server
function M.stop()
  server.initialized = false

  -- Clean up pipes
  if server.pipes.stdin then
    pcall(function()
      server.pipes.stdin:close()
    end)
    server.pipes.stdin = nil
  end

  if server.pipes.stdout then
    pcall(function()
      server.pipes.stdout:close()
    end)
    server.pipes.stdout = nil
  end

  -- Clear pipes table
  server.pipes = {}
end

-- Get server info
function M.get_server_info()
  return {
    name = server.name,
    version = server.version,
    protocol_version = server.protocol_version,
    initialized = server.initialized,
    tool_count = vim.tbl_count(server.tools),
    resource_count = vim.tbl_count(server.resources),
  }
end

-- Expose internal functions for testing
M._internal = {
  handle_initialize = handle_initialize,
}

return M
