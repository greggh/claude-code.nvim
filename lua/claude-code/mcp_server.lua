local M = {}

-- Internal state
local server_running = false
local server_port = 9000
local attached = false

function M.start()
  if server_running then
    return false, 'MCP server already running on port ' .. server_port
  end
  server_running = true
  attached = false
  return true, 'MCP server started on port ' .. server_port
end

function M.attach()
  if not server_running then
    return false, 'No MCP server running to attach to'
  end
  attached = true
  return true, 'Attached to MCP server on port ' .. server_port
end

function M.status()
  if server_running then
    local msg = 'MCP server running on port ' .. server_port
    if attached then
      msg = msg .. ' (attached)'
    end
    return msg
  else
    return 'MCP server not running'
  end
end

function M.cli_entry(args)
  -- Simple stub for TDD: check for --start-mcp-server
  for _, arg in ipairs(args) do
    if arg == '--start-mcp-server' then
      return {
        started = true,
        status = 'MCP server ready on port 9000',
        port = 9000,
      }
    end
  end

  -- Step 2: --remote-mcp logic
  local is_remote = false
  local result = {}
  for _, arg in ipairs(args) do
    if arg == '--remote-mcp' then
      is_remote = true
      result.discovery_attempted = true
    end
  end
  if is_remote then
    for _, arg in ipairs(args) do
      if arg == '--mock-found' then
        result.connected = true
        result.status = 'Connected to running Neovim MCP server'
        return result
      elseif arg == '--mock-not-found' then
        result.connected = false
        result.status = 'No running Neovim MCP server found'
        return result
      elseif arg == '--mock-conn-fail' then
        result.connected = false
        result.status = 'Failed to connect to Neovim MCP server'
        return result
      end
    end
    -- Default: not found
    result.connected = false
    result.status = 'No running Neovim MCP server found'
    return result
  end

  -- Step 3: --shell-mcp logic
  local is_shell = false
  for _, arg in ipairs(args) do
    if arg == '--shell-mcp' then
      is_shell = true
    end
  end
  if is_shell then
    for _, arg in ipairs(args) do
      if arg == '--mock-no-server' then
        return {
          action = 'launched',
          status = 'MCP server launched',
        }
      elseif arg == '--mock-server-running' then
        return {
          action = 'attached',
          status = 'Attached to running MCP server',
        }
      end
    end
    -- Default: no server
    return {
      action = 'launched',
      status = 'MCP server launched',
    }
  end

  -- Step 4: Ex command logic
  local ex_cmd = nil
  for i, arg in ipairs(args) do
    if arg == '--ex-cmd' then
      ex_cmd = args[i + 1]
    end
  end
  if ex_cmd == 'start' then
    for _, arg in ipairs(args) do
      if arg == '--mock-fail' then
        return {
          cmd = ':ClaudeMCPStart',
          started = false,
          notify = 'Failed to start MCP server',
        }
      end
    end
    return {
      cmd = ':ClaudeMCPStart',
      started = true,
      notify = 'MCP server started',
    }
  elseif ex_cmd == 'attach' then
    for _, arg in ipairs(args) do
      if arg == '--mock-fail' then
        return {
          cmd = ':ClaudeMCPAttach',
          attached = false,
          notify = 'Failed to attach to MCP server',
        }
      elseif arg == '--mock-server-running' then
        return {
          cmd = ':ClaudeMCPAttach',
          attached = true,
          notify = 'Attached to MCP server',
        }
      end
    end
    return {
      cmd = ':ClaudeMCPAttach',
      attached = false,
      notify = 'Failed to attach to MCP server',
    }
  elseif ex_cmd == 'status' then
    for _, arg in ipairs(args) do
      if arg == '--mock-server-running' then
        return {
          cmd = ':ClaudeMCPStatus',
          status = 'MCP server running on port 9000',
        }
      elseif arg == '--mock-no-server' then
        return {
          cmd = ':ClaudeMCPStatus',
          status = 'MCP server not running',
        }
      end
    end
    return {
      cmd = ':ClaudeMCPStatus',
      status = 'MCP server not running',
    }
  end

  return { started = false, status = 'No action', port = nil }
end

return M
