
# Technical resources and documentation

## Mcp (model context protocol) resources

### Official documentation

- **MCP Specification**: <https://modelcontextprotocol.io/specification/2025-03-26>
- **MCP Main Site**: <https://modelcontextprotocol.io>
- **MCP GitHub Organization**: <https://github.com/modelcontextprotocol>

### Mcp sdk and implementation

- **TypeScript SDK**: <https://github.com/modelcontextprotocol/typescript-sdk>
  - Official SDK for building MCP servers and clients
  - Includes types, utilities, and protocol implementation
- **Python SDK**: <https://github.com/modelcontextprotocol/python-sdk>
  - Alternative for Python-based implementations
- **Example Servers**: <https://github.com/modelcontextprotocol/servers>
  - Reference implementations showing best practices
  - Includes filesystem, GitHub, GitLab, and more

### Community resources

- **Awesome MCP Servers**: <https://github.com/wong2/awesome-mcp-servers>
  - Curated list of MCP server implementations
  - Good for studying different approaches
- **FastMCP Framework**: <https://github.com/punkpeye/fastmcp>
  - Simplified framework for building MCP servers
  - Good abstraction layer over raw SDK
- **MCP Resources Collection**: <https://github.com/cyanheads/model-context-protocol-resources>
  - Tutorials, guides, and examples

### Example mcp servers to study

- **mcp-neovim-server**: <https://github.com/bigcodegen/mcp-neovim-server>
  - Existing Neovim MCP server (our starting point)
  - Uses neovim Node.js client
- **VSCode MCP Server**: <https://github.com/juehang/vscode-mcp-server>
  - Shows editor integration patterns
  - Good reference for tool implementation

## Neovim development resources

### Official documentation

- **Neovim API**: <https://neovim.io/doc/user/api.html>
  - Complete API reference
  - RPC protocol details
  - Function signatures and types
- **Lua Guide**: <https://neovim.io/doc/user/lua.html>
  - Lua integration in Neovim
  - vim.api namespace documentation
  - Best practices for Lua plugins
- **Developer Documentation**: <https://github.com/neovim/neovim/wiki#development>
  - Contributing guidelines
  - Architecture overview
  - Development setup

### Rpc and external integration

- **RPC Implementation**: <https://github.com/neovim/neovim/blob/master/runtime/lua/vim/lsp/rpc.lua>
  - Reference implementation for RPC communication
  - Shows MessagePack-RPC patterns
- **API Client Info**: Use `nvim_get_api_info()` to discover available functions
  - Returns metadata about all API functions
  - Version information
  - Type information

### Neovim client libraries

#### Node.js/javascript

- **Official Node Client**: <https://github.com/neovim/node-client>
  - Used by mcp-neovim-server
  - Full API coverage
  - TypeScript support

#### Lua

- **lua-client2**: <https://github.com/justinmk/lua-client2>
  - Modern Lua client for Neovim RPC
  - Good for native Lua MCP server
- **lua-client**: <https://github.com/timeyyy/lua-client>
  - Alternative implementation
  - Different approach to async handling

### Integration patterns

#### Socket connection

```lua
-- Neovim server
vim.fn.serverstart('/tmp/nvim.sock')

-- Client connection
local socket_path = '/tmp/nvim.sock'

```text

#### Rpc communication

- Uses MessagePack-RPC protocol
- Supports both synchronous and asynchronous calls
- Built-in request/response handling

## Implementation guides

### Creating an mcp server (typescript)

Reference the TypeScript SDK examples:

1. Initialize server with `@modelcontextprotocol/sdk`
2. Define tools with schemas
3. Implement tool handlers
4. Define resources
5. Handle lifecycle events

### Neovim rpc best practices

1. Use persistent connections for performance
2. Handle reconnection gracefully
3. Batch operations when possible
4. Use notifications for one-way communication
5. Implement proper error handling

## Testing resources

### Mcp testing

- **MCP Inspector**: Tool for testing MCP servers (check SDK)
- **Protocol Testing**: Use SDK test utilities
- **Integration Testing**: Test with actual Claude Code command-line tool

### Neovim testing

- **Plenary.nvim**: <https://github.com/nvim-lua/plenary.nvim>
  - Standard testing framework for Neovim plugins
  - Includes test harness and assertions
- **Neovim Test API**: Built-in testing capabilities
  - `nvim_exec_lua()` for remote execution
  - Headless mode for CI/CD

## Security resources

### Mcp security

- **Security Best Practices**: See MCP specification security section
- **Permission Models**: Study example servers for patterns
- **Audit Logging**: Implement structured logging

### Neovim security

- **Sandbox Execution**: Use `vim.secure` namespace
- **Path Validation**: Always validate file paths
- **Command Injection**: Sanitize all user input

## Performance resources

### Mcp performance

- **Streaming Responses**: Use SSE for long operations
- **Batch Operations**: Group related operations
- **Caching**: Implement intelligent caching

### Neovim performance

- **Async Operations**: Use `vim.loop` for non-blocking ops
- **Buffer Updates**: Use `nvim_buf_set_lines()` for bulk updates
- **Event Debouncing**: Limit update frequency

## Additional resources

### Tutorials and guides

- **Building Your First MCP Server**: Check modelcontextprotocol.io/docs
- **Neovim Plugin Development**: <https://github.com/nanotee/nvim-lua-guide>
- **RPC Protocol Deep Dive**: Neovim wiki

### Community

- **MCP Discord/Slack**: Check modelcontextprotocol.io for links
- **Neovim Discourse**: <https://neovim.discourse.group/>
- **GitHub Discussions**: Both MCP and Neovim repos

### Tools

- **MCP Hub**: <https://github.com/ravitemer/mcp-hub>
  - Server coordinator we'll integrate with
- **mcphub.nvim**: <https://github.com/ravitemer/mcphub.nvim>
  - Neovim plugin for MCP hub integration

