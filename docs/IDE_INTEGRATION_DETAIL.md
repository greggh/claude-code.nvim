
# Ide integration implementation details

## Architecture clarification

This document describes how to implement an **MCP server** within claude-code.nvim that exposes Neovim's editing capabilities. Claude Code command-line tool (which has MCP client support) will connect to our server to perform IDE operations. This is the opposite of creating an MCP client - we are making Neovim accessible to AI assistants, not connecting Neovim to external services.

**Flow:**

1. claude-code.nvim starts an MCP server (either embedded or as subprocess)
2. The MCP server exposes Neovim operations as tools/resources
3. Claude Code command-line tool connects to our MCP server
4. Claude can then read buffers, edit files, and perform IDE operations

## Table of contents

1. [Model Context Protocol (MCP) Implementation](#model-context-protocol-mcp-implementation)
2. [Connection Architecture](#connection-architecture)
3. [Context Synchronization Protocol](#context-synchronization-protocol)
4. [Editor Operations API](#editor-operations-api)
5. [Security & Sandboxing](#security--sandboxing)
6. [Technical Requirements](#technical-requirements)
7. [Implementation Roadmap](#implementation-roadmap)

## Model context protocol (mcp) implementation

### Protocol overview

The Model Context Protocol is an open standard for connecting AI assistants to data sources and tools. According to the official specification¹, MCP uses JSON-RPC 2.0 over WebSocket or HTTP transport layers.

### Core protocol components

#### 1. transport layer

MCP supports two transport mechanisms²:

- **WebSocket**: For persistent, bidirectional communication
- **HTTP/HTTP2**: For request-response patterns

For our MCP server, stdio is the standard transport (following MCP conventions):

```lua
-- Example server configuration
{
  transport = "stdio",  -- Standard for MCP servers
  name = "claude-code-nvim",
  version = "1.0.0",
  capabilities = {
    tools = true,
    resources = true,
    prompts = false
  }
}

```text

#### 2. message format

All MCP messages follow JSON-RPC 2.0 specification³:

- Request messages include `method`, `params`, and unique `id`
- Response messages include `result` or `error` with matching `id`
- Notification messages have no `id` field

#### 3. authentication

MCP uses OAuth 2.1 for authentication⁴:

- Initial handshake with client credentials
- Token refresh mechanism for long-lived sessions
- Capability negotiation during authentication

### Reference implementations

Several VSCode extensions demonstrate MCP integration patterns:

- **juehang/vscode-mcp-server**⁵: Exposes editing primitives via MCP
- **acomagu/vscode-as-mcp-server**⁶: Full VSCode API exposure
- **SDGLBL/mcp-claude-code**⁷: Claude-specific capabilities

## Connection architecture

### 1. server process manager

The server manager handles MCP server lifecycle:

**Responsibilities:**

- Start MCP server process when needed
- Manage stdio pipes for communication
- Monitor server health and restart if needed
- Handle graceful shutdown on Neovim exit

**State Machine:**

```text
STOPPED → STARTING → INITIALIZING → READY → SERVING
    ↑          ↓            ↓          ↓        ↓
    └──────────┴────────────┴──────────┴────────┘
                    (error/restart)

```text

### 2. message router

Routes messages between Neovim components and MCP server:

**Components:**

- **Inbound Queue**: Processes server messages asynchronously
- **Outbound Queue**: Batches and sends client messages
- **Handler Registry**: Maps message types to Lua callbacks
- **Priority System**: Ensures time-sensitive messages (cursor updates) process first

### 3. session management

Maintains per-repository Claude instances as specified in CLAUDE.md⁸:

**Features:**

- Git repository detection for instance isolation
- Session persistence across Neovim restarts
- Context preservation when switching buffers
- Configurable via `git.multi_instance` option

## Context synchronization protocol

### 1. buffer context

Real-time synchronization of editor state to Claude:

**Data Points:**

- Full buffer content with incremental updates
- Cursor position(s) and visual selections
- Language ID and file path
- Syntax tree information (via Tree-sitter)

**Update Strategy:**

- Debounce TextChanged events (100ms default)
- Send deltas using operational transformation
- Include surrounding context for partial updates

### 2. project context

Provides Claude with understanding of project structure:

**Components:**

- File tree with .gitignore filtering
- Package manifests (package.json, Cargo.toml, etc.)
- Configuration files (.eslintrc, tsconfig.json, etc.)
- Build system information

**Optimization:**

- Lazy load based on Claude's file access patterns
- Cache directory listings with inotify watches
- Compress large file trees before transmission

### 3. runtime context

Dynamic information about code execution state:

**Sources:**

- LSP diagnostics and hover information
- DAP (Debug Adapter Protocol) state
- Terminal output from recent commands
- Git status and recent commits

### 4. semantic context

Higher-level code understanding:

**Elements:**

- Symbol definitions and references (via LSP)
- Call hierarchies and type relationships
- Test coverage information
- Documentation strings and comments

## Editor operations api

### 1. text manipulation

Claude can perform various text operations:

**Primitive Operations:**

- `insert(position, text)`: Add text at position
- `delete(range)`: Remove text in range
- `replace(range, text)`: Replace text in range

**Complex Operations:**

- Multi-cursor edits with transaction support
- Snippet expansion with placeholders
- Format-preserving transformations

### 2. diff preview system

Shows proposed changes before application:

**Implementation Requirements:**

- Virtual buffer for diff display
- Syntax highlighting for added/removed lines
- Hunk-level accept/reject controls
- Integration with native diff mode

### 3. refactoring operations

Support for project-wide code transformations:

**Capabilities:**

- Rename symbol across files (LSP rename)
- Extract function/variable/component
- Move definitions between files
- Safe delete with reference checking

### 4. file system operations

Controlled file manipulation:

**Allowed Operations:**

- Create files with template support
- Delete files with safety checks
- Rename/move with reference updates
- Directory structure modifications

**Restrictions:**

- Require explicit user confirmation
- Sandbox to project directory
- Prevent system file modifications

## Security & sandboxing

### 1. permission model

Fine-grained control over Claude's capabilities:

**Permission Levels:**

- **Read-only**: View files and context
- **Suggest**: Propose changes via diff
- **Edit**: Modify current buffer only
- **Full**: All operations with confirmation

### 2. operation validation

All Claude operations undergo validation:

**Checks:**

- Path traversal prevention
- File size limits for operations
- Rate limiting for expensive operations
- Syntax validation before application

### 3. audit trail

Comprehensive logging of all operations:

**Logged Information:**

- Timestamp and operation type
- Before/after content hashes
- User confirmation status
- Revert information for undo

## Technical requirements

### 1. Lua libraries

Required dependencies for implementation:

**Core Libraries:**

- **lua-cjson**: JSON encoding/decoding⁹
- **luv**: Async I/O and WebSocket support¹⁰
- **lpeg**: Parser for protocol messages¹¹

**Optional Libraries:**

- **lua-resty-websocket**: Alternative WebSocket client¹²
- **luaossl**: TLS support for secure connections¹³

### 2. Neovim apis

Leveraging Neovim's built-in capabilities:

**Essential APIs:**

- `vim.lsp`: Language server integration
- `vim.treesitter`: Syntax tree access
- `vim.loop` (luv): Event loop integration
- `vim.api.nvim_buf_*`: Buffer manipulation
- `vim.notify`: User notifications

### 3. performance targets

Ensuring responsive user experience:

**Metrics:**

- Context sync latency: <50ms
- Operation application: <100ms
- Memory overhead: <100MB
- CPU usage: <5% idle

## Implementation roadmap

### Phase 1: foundation (weeks 1-2)

**Deliverables:**

1. Basic WebSocket client implementation
2. JSON-RPC message handling
3. Authentication flow
4. Connection state management

**Validation:**

- Successfully connect to MCP server
- Complete authentication handshake
- Send/receive basic messages

### Phase 2: context system (weeks 3-4)

**Deliverables:**

1. Buffer content synchronization
2. Incremental update algorithm
3. Project structure indexing
4. Context prioritization logic

**Validation:**

- Real-time buffer sync without lag
- Accurate project representation
- Efficient bandwidth usage

### Phase 3: editor integration (weeks 5-6)

**Deliverables:**

1. Text manipulation primitives
2. Diff preview implementation
3. Transaction support
4. Undo/redo integration

**Validation:**

- All operations preserve buffer state
- Preview accurately shows changes
- Undo reliably reverts operations

### Phase 4: advanced features (weeks 7-8)

**Deliverables:**

1. Refactoring operations
2. Multi-file coordination
3. Chat interface
4. Inline suggestions

**Validation:**

- Refactoring maintains correctness
- UI responsive during operations
- Feature parity with VSCode

### Phase 5: polish & release (weeks 9-10)

**Deliverables:**

1. Performance optimization
2. Security hardening
3. Documentation
4. Test coverage

**Validation:**

- Meet all performance targets
- Pass security review
- 80%+ test coverage

## Open questions and research needs

### Critical implementation blockers

#### 1. MCP server implementation details

**Questions:**

- What transport should our MCP server use?
  - stdio (like most MCP servers)?
  - WebSocket for remote connections?
  - Named pipes for local IPC?
- How do we spawn and manage the MCP server process from Neovim?
  - Embedded in Neovim process or separate process?
  - How to handle server lifecycle (start/stop/restart)?
- What port should we listen on for network transports?
- How do we advertise our server to Claude Code command-line tool?
  - Configuration file location?
  - Discovery mechanism?

#### 2. MCP tools and resources to expose

**Questions:**

- Which Neovim capabilities should we expose as MCP tools?
  - Buffer operations (read, write, edit)?
  - File system operations?
  - LSP integration?
  - Terminal commands?
- What resources should we provide?
  - Open buffers list?
  - Project file tree?
  - Git status?
  - Diagnostics?
- How do we handle permissions?
  - Read-only vs. write access?
  - Destructive operation safeguards?
  - User confirmation flows?

#### 3. integration with claude-code.nvim

**Questions:**

- How do we manage the MCP server lifecycle?
  - Auto-start when Claude Code is invoked?
  - Manual start/stop commands?
  - Process management and monitoring?
- How do we configure the connection?
  - Socket path management?
  - Port allocation for network transport?
  - Discovery mechanism for Claude Code?
- Should we use existing mcp-neovim-server or build native?
  - Pros/cons of each approach?
  - Migration path if we start with one?
  - Compatibility requirements?

#### 4. message flow and sequencing

**Questions:**

- What is the initialization sequence after connection?
  - Must we register the client type?
  - Initial context sync requirements?
  - Capability announcement?
- How are request IDs generated and managed?
- Are there message ordering guarantees?
- What happens to in-flight requests on reconnection?
- Are there batch message capabilities?
- How do we handle concurrent operations?

#### 5. context synchronization protocol

**Questions:**

- What is the exact format for sending buffer updates?
  - Full content vs. operational transforms?
  - Character-based or line-based deltas?
  - UTF-8 encoding considerations?
- How do we handle conflict resolution?
  - Server-side or client-side resolution?
  - Three-way merge support?
  - Conflict notification mechanism?
- What metadata must accompany each update?
  - Timestamps? Version vectors?
  - Checksum or hash validation?
- How frequently should we sync?
  - Is there a rate limit?
  - Preferred debounce intervals?
- How much context can we send?
  - Maximum message size?
  - Context window limitations?

#### 6. editor operations format

**Questions:**

- What is the exact schema for edit operations?
  - Position format (line/column, byte offset, character offset)?
  - Range specification format?
  - Multi-cursor edit format?
- How are file paths specified?
  - Absolute? Relative to project root?
  - URI format? Platform-specific paths?
- How do we handle special characters and escaping?
- What are the transaction boundaries?
- Can we preview changes before applying?
  - Is there a diff format?
  - Approval/rejection protocol?

#### 7. websocket implementation details

**Questions:**

- Does luv provide sufficient WebSocket client capabilities?
  - Do we need additional libraries?
  - TLS/SSL support requirements?
- How do we handle:
  - Ping/pong frames?
  - Connection keepalive?
  - Automatic reconnection?
  - Binary vs. text frames?
- What are the performance characteristics?
  - Message size limits?
  - Compression support (permessage-deflate)?
  - Multiplexing capabilities?

#### 8. error handling and recovery

**Questions:**

- What are all possible error states?
- How do we handle:
  - Network failures?
  - Protocol errors?
  - Server-side errors?
  - Rate limiting?
- What is the reconnection strategy?
  - Exponential backoff parameters?
  - Maximum retry attempts?
  - State recovery after reconnection?
- How do we notify users of errors?
- Can we fall back to command-line tool mode gracefully?

#### 9. security and privacy

**Questions:**

- How is data encrypted in transit?
- Are there additional security headers required?
- How do we handle:
  - Code ownership and licensing?
  - Sensitive data in code?
  - Audit logging requirements?
- What data is sent to Claude's servers?
  - Can users opt out of certain data collection?
  - GDPR/privacy compliance?
- How do we validate server certificates?

#### 10. Claude code cli mcp client configuration

**Questions:**

- How do we configure Claude Code to connect to our MCP server?
  - Command line flags?
  - Configuration file format?
  - Environment variables?
- Can Claude Code auto-discover local MCP servers?
- How do we handle multiple Neovim instances?
  - Different socket paths?
  - Port management?
  - Instance identification?
- What's the handshake process when Claude connects?
- Can we pass context about the current project?

#### 11. performance and resource management

**Questions:**

- What are the actual latency characteristics?
- How much memory does a typical session consume?
- CPU usage patterns during:
  - Idle state?
  - Active editing?
  - Large refactoring operations?
- How do we handle:
  - Large files (>1MB)?
  - Many open buffers?
  - Slow network connections?
- Are there server-side quotas or limits?

#### 12. testing and validation

**Questions:**

- Is there a test/sandbox MCP server?
- How do we write integration tests?
- Are there reference test cases?
- How do we validate our implementation?
  - Conformance test suite?
  - Compatibility testing with Claude Code?
- How do we debug protocol issues?
  - Message logging format?
  - Debug mode in server?

### Research tasks priority

1. **Immediate Priority:**
   - Find Claude Code MCP server endpoint documentation
   - Understand authentication mechanism
   - Identify available MCP methods

2. **Short-term Priority:**
   - Study VSCode extension implementation (if source available)
   - Test WebSocket connectivity with luv
   - Design message format schemas

3. **Medium-term Priority:**
   - Build protocol test harness
   - Implement authentication flow
   - Create minimal proof of concept

### Potential information sources

1. **Documentation:**
   - Claude Code official docs (deeper dive needed)
   - MCP specification details
   - VSCode/IntelliJ extension documentation

2. **Code Analysis:**
   - VSCode extension source (if available)
   - Claude Code command-line tool source (as last resort)
   - Other MCP client implementations

3. **Experimentation:**
   - Network traffic analysis of existing integrations
   - Protocol probing with test client
   - Reverse engineering message formats

4. **Community:**
   - Claude Code GitHub issues/discussions
   - MCP protocol community
   - Anthropic developer forums

## References

1. Model Context Protocol Specification: <https://modelcontextprotocol.io/specification/2025-03-26>
2. MCP Transport Documentation: <https://modelcontextprotocol.io/docs/concepts/transports>
3. JSON-RPC 2.0 Specification: <https://www.jsonrpc.org/specification>
4. OAuth 2.1 Specification: <https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-1-10>
5. juehang/vscode-mcp-server: <https://github.com/juehang/vscode-mcp-server>
6. acomagu/vscode-as-mcp-server: <https://github.com/acomagu/vscode-as-mcp-server>
7. SDGLBL/mcp-claude-code: <https://github.com/SDGLBL/mcp-claude-code>
8. Claude Code Multi-Instance Support: /Users/beanie/source/claude-code.nvim/CLAUDE.md
9. lua-cjson Documentation: <https://github.com/openresty/lua-cjson>
10. luv Documentation: <https://github.com/luvit/luv>
11. LPeg Documentation: <http://www.inf.puc-rio.br/~roberto/lpeg/>
12. lua-resty-websocket: <https://github.com/openresty/lua-resty-websocket>
13. luaossl Documentation: <https://github.com/wahern/luaossl>

