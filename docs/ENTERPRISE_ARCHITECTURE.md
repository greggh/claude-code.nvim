
# Enterprise architecture for claude-code.nvim

## Problem statement

Current MCP integrations (like mcp-neovim-server → Claude Desktop) route code through cloud services, which is unacceptable for:

- Enterprises with strict data sovereignty requirements
- Organizations working on proprietary/sensitive code
- Regulated industries (finance, healthcare, defense)
- Companies with air-gapped development environments

## Solution architecture

### Local-first design

Instead of connecting to Claude Desktop (cloud), we need to enable **Claude Code command-line tool** (running locally) to connect to our MCP server:

```text
┌─────────────┐     MCP      ┌──────────────────┐     Neovim RPC     ┌────────────┐
│ Claude Code │ ◄──────────► │ mcp-server-nvim  │ ◄─────────────────► │   Neovim   │
│     command-line tool     │    (stdio)   │   (our server)   │                     │  Instance  │
└─────────────┘              └──────────────────┘                     └────────────┘
     LOCAL                          LOCAL                                   LOCAL

```text

**Key Points:**

- All communication stays on the local machine
- No external network connections required
- Code never leaves the developer's workstation
- Works in air-gapped environments

### Privacy-preserving features

1. **No Cloud Dependencies**
   - MCP server runs locally as part of Neovim
   - Claude Code command-line tool runs locally with local models or private API endpoints
   - Zero reliance on Anthropic's cloud infrastructure for transport

2. **Data Controls**
   - Configurable context filtering (exclude sensitive files)
   - Audit logging of all operations
   - Granular permissions per workspace
   - Encryption of local communication sockets

3. **Enterprise Configuration**

   ```lua
   require('claude-code').setup({
     mcp = {
       enterprise_mode = true,
       allowed_paths = {"/home/user/work/*"},
       blocked_patterns = {"*.key", "*.pem", "**/secrets/**"},
       audit_log = "/var/log/claude-code-audit.log",
       require_confirmation = true
     }
   })
   ```

### Integration options

#### Option 1: direct cli integration (recommended)

Claude Code command-line tool connects directly to our MCP server:

**Advantages:**

- Complete local control
- No cloud dependencies
- Works with self-hosted Claude instances
- Compatible with enterprise proxy settings

**Implementation:**

```bash

# Start neovim with socket listener
nvim --listen /tmp/nvim.sock

# Add our mcp server to claude code configuration
claude mcp add neovim-editor nvim-mcp-server -e NVIM_SOCKET=/tmp/nvim.sock

# Now claude code can access neovim via the mcp server
claude "Help me refactor this function"

```text

#### Option 2: enterprise claude deployment

For organizations using Claude via Amazon Bedrock or Google Vertex AI:

```text
┌─────────────┐      ┌──────────────────┐      ┌─────────────────┐
│   Neovim    │ ◄──► │  MCP Server      │ ◄──► │  Claude Code    │
│             │      │  (local)         │      │  command-line tool (local)    │
└─────────────┘      └──────────────────┘      └────────┬────────┘
                                                         │
                                                         ▼
                                                ┌─────────────────┐
                                                │ Private Claude  │
                                                │ (Bedrock/Vertex)│
                                                └─────────────────┘

```text

### Security considerations

1. **Authentication**
   - Local socket with filesystem permissions
   - Optional mTLS for network transport
   - Integration with enterprise SSO/SAML

2. **Authorization**
   - Role-based access control (RBAC)
   - Per-project permission policies
   - Workspace isolation

3. **Audit & Compliance**
   - Structured logging of all operations
   - Integration with SIEM systems
   - Compliance mode flags (HIPAA, SOC2, etc.)

### Implementation phases

#### Phase 1: local mcp server (priority)

Build a secure, local-only MCP server that:

- Runs as part of claude-code.nvim
- Exposes Neovim capabilities via stdio
- Works with Claude Code command-line tool locally
- Never connects to external services

#### Phase 2: enterprise features

- Audit logging
- Permission policies
- Context filtering
- Encryption options

#### Phase 3: integration support

- Bedrock/Vertex AI configuration guides
- On-premise deployment documentation
- Enterprise support channels

### Key differentiators

| Feature | mcp-neovim-server | Our Solution |
|---------|-------------------|--------------|
| Data Location | Routes through Claude Desktop | Fully local |
| Enterprise Ready | No | Yes |
| Air-gap Support | No | Yes |
| Audit Trail | No | Yes |
| Permission Control | Limited | Comprehensive |
| Context Filtering | No | Yes |

### Configuration examples

#### Minimal secure setup

```lua
require('claude-code').setup({
  mcp = {
    transport = "stdio",
    server = "embedded"  -- Run in Neovim process
  }
})

```text

#### Enterprise setup

```lua
require('claude-code').setup({
  mcp = {
    transport = "unix_socket",
    socket_path = "/var/run/claude-code/nvim.sock",
    permissions = "0600",

    security = {
      require_confirmation = true,
      allowed_operations = {"read", "edit", "analyze"},
      blocked_operations = {"execute", "delete"},

      context_filters = {
        exclude_patterns = {"**/node_modules/**", "**/.env*"},
        max_file_size = 1048576,  -- 1MB
        allowed_languages = {"lua", "python", "javascript"}
      }
    },

    audit = {
      enabled = true,
      path = "/var/log/claude-code/audit.jsonl",
      include_content = false,  -- Log operations, not code
      syslog = true
    }
  }
})

```text

### Conclusion

By building an MCP server that prioritizes local execution and enterprise security, we can enable AI-assisted development for organizations that cannot use cloud-based solutions. This approach provides the benefits of Claude Code integration while maintaining complete control over sensitive codebases.

