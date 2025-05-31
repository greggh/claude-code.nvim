local uv = vim.loop
local M = {}

-- Active sessions table
local active_sessions = {}

-- Simple HTTP server for MCP endpoints compliant with Claude Code CLI
function M.start(opts)
  opts = opts or {}
  local host = opts.host or "127.0.0.1"
  local port = opts.port or 27123
  local base_server_name = "neovim-lua"

  local server = uv.new_tcp()
  server:bind(host, port)
  
  -- Define tool schemas with proper naming convention
  local tools = {
    {
      name = "mcp__" .. base_server_name .. "__vim_buffer",
      description = "Read/write buffer content",
      schema = {
        type = "object",
        properties = {
          filename = {
            type = "string", 
            description = "Optional file name to view a specific buffer"
          }
        },
        additionalProperties = false
      }
    },
    {
      name = "mcp__" .. base_server_name .. "__vim_command",
      description = "Execute Vim commands",
      schema = {
        type = "object",
        properties = {
          command = {
            type = "string",
            description = "The Vim command to execute"
          }
        },
        required = ["command"],
        additionalProperties = false
      }
    },
    {
      name = "mcp__" .. base_server_name .. "__vim_status",
      description = "Get current editor status",
      schema = {
        type = "object",
        properties = {},
        additionalProperties = false
      }
    },
    {
      name = "mcp__" .. base_server_name .. "__vim_edit",
      description = "Edit buffer content with insert/replace/replaceAll modes",
      schema = {
        type = "object",
        properties = {
          filename = {
            type = "string",
            description = "File to edit"
          },
          mode = {
            type = "string",
            enum: ["insert", "replace", "replaceAll"],
            description: "Edit mode"
          },
          position = {
            type: "object",
            description: "Position for edit operation",
            properties: {
              line: { type: "number" },
              character: { type: "number" }
            }
          },
          text: {
            type: "string",
            description: "Text content to insert/replace"
          }
        },
        required: ["filename", "mode", "text"],
        additionalProperties: false
      }
    },
    {
      name = "mcp__" .. base_server_name .. "__vim_window",
      description = "Manage windows (split, close, navigate)",
      schema = {
        type = "object",
        properties = {
          action: {
            type: "string",
            enum: ["split", "vsplit", "close", "next", "prev"],
            description: "Window action to perform"
          },
          filename: {
            type: "string",
            description: "Optional filename for split actions"
          }
        },
        required: ["action"],
        additionalProperties: false
      }
    },
    {
      name = "mcp__" .. base_server_name .. "__analyze_related",
      description = "Analyze files related through imports/requires",
      schema = {
        type = "object",
        properties = {
          filename: {
            type: "string",
            description: "File to analyze for dependencies"
          },
          depth: {
            type: "number",
            description: "Depth of dependency search (default: 1)"
          }
        },
        required: ["filename"],
        additionalProperties: false
      }
    },
    {
      name = "mcp__" .. base_server_name .. "__search_files",
      description = "Find files by pattern with optional content preview",
      schema = {
        type = "object",
        properties = {
          pattern: {
            type: "string",
            description: "Glob pattern to search for files"
          },
          content_pattern: {
            type: "string",
            description: "Optional regex to search file contents"
          }
        },
        required: ["pattern"],
        additionalProperties: false
      }
    }
  }

  -- Define resources with proper URIs and descriptions
  local resources = {
    {
      uri = "mcp__" .. base_server_name .. "://current-buffer",
      description = "Contents of the current buffer",
      mimeType = "text/plain"
    },
    {
      uri = "mcp__" .. base_server_name .. "://buffers",
      description = "List of all open buffers",
      mimeType = "application/json"
    },
    {
      uri = "mcp__" .. base_server_name .. "://project",
      description = "Project structure and files",
      mimeType = "application/json"
    },
    {
      uri = "mcp__" .. base_server_name .. "://git-status",
      description = "Git status of the current repository",
      mimeType = "application/json"
    },
    {
      uri = "mcp__" .. base_server_name .. "://lsp-diagnostics",
      description = "LSP diagnostics for current workspace",
      mimeType = "application/json"
    }
  }

  server:listen(128, function(err)
    assert(not err, err)
    local client = uv.new_tcp()
    server:accept(client)
    client:read_start(function(err, chunk)
      assert(not err, err)
      if chunk then
        local req = chunk
        
        -- Parse request to get method, path and headers
        local method = req:match("^(%S+)%s+")
        local path = req:match("^%S+%s+(%S+)")
        
        -- Handle GET /mcp/config endpoint
        if method == "GET" and path == "/mcp/config" then
          local body = vim.json.encode({
            server = {
              name = base_server_name,
              version = "0.1.0",
              description = "Pure Lua MCP server for Neovim",
              vendor = "claude-code.nvim"
            },
            capabilities = {
              tools = tools,
              resources = resources
            }
          })
          local resp = "HTTP/1.1 200 OK\r\n" ..
                       "Content-Type: application/json\r\n" ..
                       "Access-Control-Allow-Origin: *\r\n" ..
                       "Content-Length: " .. #body .. "\r\n\r\n" .. body
          client:write(resp)
        
        -- Handle POST /mcp/session endpoint  
        elseif method == "POST" and path == "/mcp/session" then
          -- Create a new random session ID
          local session_id = "nvim-session-" .. tostring(math.random(100000,999999))
          
          -- Store session information
          active_sessions[session_id] = {
            created_at = os.time(),
            last_activity = os.time(),
            ip = client:getpeername() -- get client IP
          }
          
          local body = vim.json.encode({ 
            session_id = session_id,
            status = "created",
            server = base_server_name,
            created_at = os.date("!%Y-%m-%dT%H:%M:%SZ", active_sessions[session_id].created_at)
          })
          
          local resp = "HTTP/1.1 201 Created\r\n" ..
                       "Content-Type: application/json\r\n" ..
                       "Access-Control-Allow-Origin: *\r\n" ..
                       "Content-Length: " .. #body .. "\r\n\r\n" .. body
          client:write(resp)
        
        -- Handle DELETE /mcp/session/{session_id} endpoint
        elseif method == "DELETE" and path:match("^/mcp/session/") then
          local session_id = path:match("^/mcp/session/(.+)$")
          
          if active_sessions[session_id] then
            -- Remove the session
            active_sessions[session_id] = nil
            
            local body = vim.json.encode({ 
              status = "closed",
              message = "Session terminated successfully"
            })
            
            local resp = "HTTP/1.1 200 OK\r\n" ..
                         "Content-Type: application/json\r\n" ..
                         "Access-Control-Allow-Origin: *\r\n" ..
                         "Content-Length: " .. #body .. "\r\n\r\n" .. body
            client:write(resp)
          else
            -- Session not found
            local body = vim.json.encode({ 
              error = "session_not_found",
              message = "Session does not exist or has already been terminated"
            })
            
            local resp = "HTTP/1.1 404 Not Found\r\n" ..
                         "Content-Type: application/json\r\n" ..
                         "Access-Control-Allow-Origin: *\r\n" ..
                         "Content-Length: " .. #body .. "\r\n\r\n" .. body
            client:write(resp)
          end
        
        -- Handle OPTIONS requests for CORS
        elseif method == "OPTIONS" then
          local resp = "HTTP/1.1 200 OK\r\n" ..
                       "Access-Control-Allow-Origin: *\r\n" ..
                       "Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS\r\n" ..
                       "Access-Control-Allow-Headers: Content-Type\r\n" ..
                       "Content-Length: 0\r\n\r\n"
          client:write(resp)
          
        -- Handle all other requests with 404 Not Found
        else
          local body = vim.json.encode({
            error = "not_found",
            message = "Endpoint not found"
          })
          
          local resp = "HTTP/1.1 404 Not Found\r\n" ..
                       "Content-Type: application/json\r\n" ..
                       "Content-Length: " .. #body .. "\r\n\r\n" .. body
          client:write(resp)
        end
        
        client:shutdown()
        client:close()
      end
    end)
  end)
  
  vim.notify("Claude Code MCP HTTP server started on http://" .. host .. ":" .. port, vim.log.levels.INFO)
  
  -- Return server info for reference
  return {
    host = host,
    port = port,
    server_name = base_server_name
  }
end

-- Stop HTTP server
function M.stop()
  -- Clear active sessions
  active_sessions = {}
  -- Note: The actual server shutdown would need to be implemented here
  vim.notify("Claude Code MCP HTTP server stopped", vim.log.levels.INFO)
end

-- Get active sessions info
function M.get_sessions()
  return active_sessions
end

return M
