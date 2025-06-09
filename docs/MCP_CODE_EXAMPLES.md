
# Mcp server code examples

## Basic server structure (typescript)

### Minimal server setup

```typescript
import { McpServer, StdioServerTransport } from "@modelcontextprotocol/sdk/server/index.js";
import { z } from "zod";

// Create server instance
const server = new McpServer({
  name: "my-neovim-server",
  version: "1.0.0"
});

// Define a simple tool
server.tool(
  "edit_buffer",
  {
    buffer: z.number(),
    line: z.number(),
    text: z.string()
  },
  async ({ buffer, line, text }) => {
    // Tool implementation here
    return {
      content: [{
        type: "text",
        text: `Edited buffer ${buffer} at line ${line}`
      }]
    };
  }
);

// Connect to stdio transport
const transport = new StdioServerTransport();
await server.connect(transport);

```text

### Complete server pattern

Based on MCP example servers structure:

```typescript
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListResourcesRequestSchema,
  ListToolsRequestSchema,
  ReadResourceRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

class NeovimMCPServer {
  private server: Server;
  private nvimClient: NeovimClient; // Your Neovim connection

  constructor() {
    this.server = new Server(
      {
        name: "neovim-mcp-server",
        version: "1.0.0",
      },
      {
        capabilities: {
          tools: {},
          resources: {},
        },
      }
    );

    this.setupHandlers();
  }

  private setupHandlers() {
    // List available tools
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: "edit_buffer",
          description: "Edit content in a buffer",
          inputSchema: {
            type: "object",
            properties: {
              buffer: { type: "number", description: "Buffer number" },
              line: { type: "number", description: "Line number (1-based)" },
              text: { type: "string", description: "New text for the line" }
            },
            required: ["buffer", "line", "text"]
          }
        },
        {
          name: "read_buffer",
          description: "Read buffer content",
          inputSchema: {
            type: "object",
            properties: {
              buffer: { type: "number", description: "Buffer number" }
            },
            required: ["buffer"]
          }
        }
      ]
    }));

    // Handle tool calls
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      switch (request.params.name) {
        case "edit_buffer":
          return this.handleEditBuffer(request.params.arguments);
        case "read_buffer":
          return this.handleReadBuffer(request.params.arguments);
        default:
          throw new Error(`Unknown tool: ${request.params.name}`);
      }
    });

    // List available resources
    this.server.setRequestHandler(ListResourcesRequestSchema, async () => ({
      resources: [
        {
          uri: "neovim://buffers",
          name: "Open Buffers",
          description: "List of currently open buffers",
          mimeType: "application/json"
        }
      ]
    }));

    // Read resources
    this.server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
      if (request.params.uri === "neovim://buffers") {
        return {
          contents: [
            {
              uri: "neovim://buffers",
              mimeType: "application/json",
              text: JSON.stringify(await this.nvimClient.listBuffers())
            }
          ]
        };
      }
      throw new Error(`Unknown resource: ${request.params.uri}`);
    });
  }

  private async handleEditBuffer(args: any) {
    const { buffer, line, text } = args;

    try {
      await this.nvimClient.setBufferLine(buffer, line - 1, text);
      return {
        content: [
          {
            type: "text",
            text: `Successfully edited buffer ${buffer} at line ${line}`
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          {
            type: "text",
            text: `Error editing buffer: ${error.message}`
          }
        ],
        isError: true
      };
    }
  }

  private async handleReadBuffer(args: any) {
    const { buffer } = args;

    try {
      const content = await this.nvimClient.getBufferContent(buffer);
      return {
        content: [
          {
            type: "text",
            text: content.join('\n')
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          {
            type: "text",
            text: `Error reading buffer: ${error.message}`
          }
        ],
        isError: true
      };
    }
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error("Neovim MCP server running on stdio");
  }
}

// Entry point
const server = new NeovimMCPServer();
server.run().catch(console.error);

```text

## Neovim client integration

### Using node-client (javascript)

```javascript
import { attach } from 'neovim';

class NeovimClient {
  private nvim: Neovim;

  async connect(socketPath: string) {
    this.nvim = await attach({ socket: socketPath });
  }

  async listBuffers() {
    const buffers = await this.nvim.buffers;
    return Promise.all(
      buffers.map(async (buf) => ({
        id: buf.id,
        name: await buf.name,
        loaded: await buf.loaded,
        modified: await buf.getOption('modified')
      }))
    );
  }

  async setBufferLine(bufNum: number, line: number, text: string) {
    const buffer = await this.nvim.buffer(bufNum);
    await buffer.setLines([text], { start: line, end: line + 1 });
  }

  async getBufferContent(bufNum: number) {
    const buffer = await this.nvim.buffer(bufNum);
    return await buffer.lines;
  }
}

```text

## Tool patterns

### Search tool

```typescript
{
  name: "search_project",
  description: "Search for text in project files",
  inputSchema: {
    type: "object",
    properties: {
      pattern: { type: "string", description: "Search pattern (regex)" },
      path: { type: "string", description: "Path to search in" },
      filePattern: { type: "string", description: "File pattern to match" }
    },
    required: ["pattern"]
  }
}

// Handler
async handleSearchProject(args) {
  const results = await this.nvimClient.eval(
    `systemlist('rg --json "${args.pattern}" ${args.path || '.'}')`
  );
  // Parse and return results
}

```text

### Lsp integration tool

```typescript
{
  name: "go_to_definition",
  description: "Navigate to symbol definition",
  inputSchema: {
    type: "object",
    properties: {
      buffer: { type: "number" },
      line: { type: "number" },
      column: { type: "number" }
    },
    required: ["buffer", "line", "column"]
  }
}

// Handler using Neovim's LSP
async handleGoToDefinition(args) {
  await this.nvimClient.command(
    `lua vim.lsp.buf.definition({buffer=${args.buffer}, position={${args.line}, ${args.column}}})`
  );
  // Return new cursor position
}

```text

## Resource patterns

### Dynamic resource provider

```typescript
// Provide LSP diagnostics as a resource
{
  uri: "neovim://diagnostics",
  name: "LSP Diagnostics",
  description: "Current LSP diagnostics across all buffers",
  mimeType: "application/json"
}

// Handler
async handleDiagnosticsResource() {
  const diagnostics = await this.nvimClient.eval(
    'luaeval("vim.diagnostic.get()")'
  );
  return {
    contents: [{
      uri: "neovim://diagnostics",
      mimeType: "application/json",
      text: JSON.stringify(diagnostics)
    }]
  };
}

```text

## Error handling pattern

```typescript
class MCPError extends Error {
  constructor(message: string, public code: string) {
    super(message);
  }
}

// In handlers
try {
  const result = await riskyOperation();
  return { content: [{ type: "text", text: result }] };
} catch (error) {
  if (error instanceof MCPError) {
    return {
      content: [{ type: "text", text: error.message }],
      isError: true,
      errorCode: error.code
    };
  }
  // Log unexpected errors
  console.error("Unexpected error:", error);
  return {
    content: [{ type: "text", text: "An unexpected error occurred" }],
    isError: true
  };
}

```text

## Security pattern

```typescript
class SecurityManager {
  private allowedPaths: Set<string>;
  private blockedPatterns: RegExp[];

  canAccessPath(path: string): boolean {
    // Check if path is allowed
    if (!this.isPathAllowed(path)) {
      throw new MCPError("Access denied", "PERMISSION_DENIED");
    }
    return true;
  }

  sanitizeCommand(command: string): string {
    // Remove dangerous characters
    return command.replace(/[;&|`$]/g, '');
  }
}

// Use in tools
async handleFileOperation(args) {
  this.security.canAccessPath(args.path);
  const sanitizedPath = this.security.sanitizePath(args.path);
  // Proceed with operation
}

```text

## Testing pattern

```typescript
// Mock Neovim client for testing
class MockNeovimClient {
  buffers = new Map();

  async setBufferLine(bufNum: number, line: number, text: string) {
    const buffer = this.buffers.get(bufNum) || [];
    buffer[line] = text;
    this.buffers.set(bufNum, buffer);
  }
}

// Test
describe("NeovimMCPServer", () => {
  it("should edit buffer line", async () => {
    const server = new NeovimMCPServer();
    server.nvimClient = new MockNeovimClient();

    const result = await server.handleEditBuffer({
      buffer: 1,
      line: 1,
      text: "Hello, world!"
    });

    expect(result.content[0].text).toContain("Successfully edited");
  });
});

```text

