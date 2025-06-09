
# Mcp solutions analysis for neovim

## Executive summary

There are existing solutions for MCP integration with Neovim:

- **mcp-neovim-server**: An MCP server that exposes Neovim capabilities (what we need)
- **mcphub.nvim**: An MCP client for connecting Neovim to other MCP servers (opposite direction)

## Existing solutions

### 1. mcp-neovim-server (by bigcodegen)

**What it does:** Exposes Neovim as an MCP server that Claude Code can connect to.

**GitHub:** <https://github.com/bigcodegen/mcp-neovim-server>

**Key Features:**

- Buffer management (list buffers with metadata)
- Command execution (run vim commands)
- Editor status (cursor position, mode, visual selection, etc.)
- Socket-based connection to Neovim

**Requirements:**

- Node.js runtime
- Neovim started with socket: `nvim --listen /tmp/nvim`
- Configuration in Claude Desktop or other MCP clients

**Pros:**

- Already exists and works
- Uses official neovim/node-client
- Claude already understands Vim commands
- Active development (1k+ stars)

**Cons:**

- Described as "proof of concept"
- JavaScript/Node.js based (not native Lua)
- Security concerns mentioned
- May not work well with custom configs

### 2. mcphub.nvim (by ravitemer)

**What it does:** MCP client for Neovim - connects to external MCP servers.

**GitHub:** <https://github.com/ravitemer/mcphub.nvim>

**Note:** This is the opposite of what we need. It allows Neovim to consume MCP servers, not expose Neovim as an MCP server.

## Claude code mcp configuration

Claude Code command-line tool has built-in MCP support with the following commands:

- `claude mcp serve` - Start Claude Code's own MCP server
- `claude mcp add <name> <command> [args...]` - Add an MCP server
- `claude mcp remove <name>` - Remove an MCP server
- `claude mcp list` - List configured servers

### Adding an mcp server

```bash

# Add a stdio-based mcp server (default)
claude mcp add neovim-server nvim-mcp-server

# Add with environment variables
claude mcp add neovim-server nvim-mcp-server -e NVIM_SOCKET=/tmp/nvim

# Add with specific scope
claude mcp add neovim-server nvim-mcp-server --scope project

```text

Scopes:

- `local` - Current directory only (default)
- `user` - User-wide configuration
- `project` - Project-wide (using .mcp.json)

## Integration approaches

### Option 1: use mcp-neovim-server as-is

**Advantages:**

- Immediate solution, no development needed
- Can start testing Claude Code integration today
- Community support and updates

**Disadvantages:**

- Requires Node.js dependency
- Limited control over implementation
- May have security/stability issues

**Integration Steps:**

1. Document installation of mcp-neovim-server
2. Add configuration helpers in claude-code.nvim
3. Auto-start Neovim with socket when needed
4. Manage server lifecycle from plugin

### Option 2: fork and enhance mcp-neovim-server

**Advantages:**

- Start with working code
- Can address security/stability concerns
- Maintain JavaScript compatibility

**Disadvantages:**

- Still requires Node.js
- Maintenance burden
- Divergence from upstream

### Option 3: build native lua mcp server

**Advantages:**

- No external dependencies
- Full control over implementation
- Better Neovim integration
- Can optimize for claude-code.nvim use case

**Disadvantages:**

- Significant development effort
- Need to implement MCP protocol from scratch
- Longer time to market

**Architecture if building native:**

```lua
-- Core components needed:
-- 1. JSON-RPC server (stdio or socket based)
-- 2. MCP protocol handler
-- 3. Neovim API wrapper
-- 4. Tool definitions (edit, read, etc.)
-- 5. Resource providers (buffers, files)

```text

## Recommendation

**Short-term (1-2 weeks):**

1. Integrate with existing mcp-neovim-server
2. Document setup and configuration
3. Test with Claude Code command-line tool
4. Identify limitations and issues

**Medium-term (1-2 months):**

1. Contribute improvements to mcp-neovim-server
2. Add claude-code.nvim specific enhancements
3. Improve security and stability

**Long-term (3+ months):**

1. Evaluate need for native Lua implementation
2. If justified, build incrementally while maintaining compatibility
3. Consider hybrid approach (Lua core with Node.js compatibility layer)

## Technical comparison

| Feature | mcp-neovim-server | Native Lua (Proposed) |
|---------|-------------------|----------------------|
| Runtime | Node.js | Pure Lua |
| Protocol | JSON-RPC over stdio | JSON-RPC over stdio/socket |
| Neovim Integration | Via node-client | Direct vim.api |
| Performance | Good | Potentially better |
| Dependencies | npm packages | Lua libraries only |
| Maintenance | Community | This project |
| Security | Concerns noted | Can be hardened |
| Customization | Limited | Full control |

## Next steps

1. **Immediate Action:** Test mcp-neovim-server with Claude Code
2. **Documentation:** Create setup guide for users
3. **Integration:** Add helper commands in claude-code.nvim
4. **Evaluation:** After 2 weeks of testing, decide on long-term approach

## Security considerations

The MCP ecosystem has known security concerns:

- Local MCP servers can access SSH keys and credentials
- No sandboxing by default
- Trust model assumes benign servers

Any solution must address:

- Permission models
- Sandboxing capabilities
- Audit logging
- User consent for operations

