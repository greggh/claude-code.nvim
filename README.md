# Claude code neovim plugin

[![GitHub License](https://img.shields.io/github/license/greggh/claude-code.nvim?style=flat-square)](https://github.com/greggh/claude-code.nvim/blob/main/LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/greggh/claude-code.nvim?style=flat-square)](https://github.com/greggh/claude-code.nvim/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/greggh/claude-code.nvim?style=flat-square)](https://github.com/greggh/claude-code.nvim/issues)
[![CI](https://img.shields.io/github/actions/workflow/status/greggh/claude-code.nvim/ci.yml?branch=main&style=flat-square&logo=github)](https://github.com/greggh/claude-code.nvim/actions/workflows/ci.yml)
[![Neovim Version](https://img.shields.io/badge/Neovim-0.7%2B-blueviolet?style=flat-square&logo=neovim)](https://github.com/neovim/neovim)
[![Tests](https://img.shields.io/badge/Tests-44%20passing-success?style=flat-square&logo=github-actions)](https://github.com/greggh/claude-code.nvim/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/Version-0.4.2-blue?style=flat-square)](https://github.com/greggh/claude-code.nvim/releases/tag/v0.4.2)
[![Discussions](https://img.shields.io/github/discussions/greggh/claude-code.nvim?style=flat-square&logo=github)](https://github.com/greggh/claude-code.nvim/discussions)

_A seamless integration between [Claude Code](https://github.com/anthropics/claude-code) AI assistant and Neovim with context-aware commands and pure Lua MCP server_

[Features](#features) •
[Requirements](#requirements) •
[Installation](#installation) •
[MCP Server](#mcp-server) •
[Configuration](#configuration) •
[Usage](#usage) •
[Tutorials](#tutorials) •
[Contributing](#contributing) •
[Discussions](https://github.com/greggh/claude-code.nvim/discussions)

![Claude Code in Neovim](https://github.com/greggh/claude-code.nvim/blob/main/assets/claude-code.png?raw=true)

This plugin provides:

- **Context-aware commands** that automatically pass file content, selections, and workspace context to Claude Code
- **Traditional terminal interface** for interactive conversations
- **Native MCP (Model Context Protocol) server** that allows Claude Code to directly read and edit your Neovim buffers, execute commands, and access project context

## Features

### Terminal interface

- 🚀 Toggle Claude Code in a terminal window with a single key press
- 🔒 **Safe window toggle** - Hide/show window without interrupting Claude Code execution
- 🧠 Support for command-line arguments like `--continue` and custom variants
- 🔄 Automatically detect and reload files modified by Claude Code
- ⚡ Real-time buffer updates when files are changed externally
- 📊 Process status monitoring and instance management
- 📱 Customizable window position and size
- 🤖 Integration with which-key (if available)
- 📂 Automatically uses git project root as working directory (when available)

### Context-aware integration ✨

- 📄 **File Context** - Automatically pass current file with cursor position
- ✂️ **Selection Context** - Send visual selections directly to Claude
- 🔍 **Smart Context** - Auto-detect whether to send file or selection
- 🌐 **Workspace Context** - Enhanced context with related files through imports/requires
- 📚 **Recent Files** - Access to recently edited files in project
- 🔗 **Related Files** - Automatic discovery of imported/required files
- 🌳 **Project Tree** - Generate comprehensive file tree structures with intelligent filtering

### Mcp server (new!)

- 🔌 **Official mcp-neovim-server** - Uses the community-maintained MCP server
- 📝 **Direct buffer editing** - Claude Code can read and modify your Neovim buffers directly
- ⚡ **Real-time context** - Access to cursor position, buffer content, and editor state
- 🛠️ **Vim command execution** - Run any Vim command through Claude Code
- 🎯 **Visual selections** - Work with selected text and visual mode
- 🔍 **Window management** - Control splits and window layout
- 📌 **Marks & registers** - Full access to Vim's marks and registers
- 🔒 **Secure by design** - All operations go through Neovim's socket API

### Development

- 🧩 Modular and maintainable code structure
- 📋 Type annotations with LuaCATS for better IDE support
- ✅ Configuration validation to prevent errors
- 🧪 Testing framework for reliability (44 comprehensive tests)

## Planned features for ide integration parity

To match the full feature set of GUI IDE integrations (VSCode, JetBrains, etc.), the following features are planned:

- **File Reference Shortcut:** Keyboard mapping to insert `@File#L1-99` style references into Claude prompts.
- **External `/ide` Command Support:** Ability to attach an external Claude Code command-line tool session to a running Neovim MCP server, similar to the `/ide` command in GUI IDEs.
- **User-Friendly Config UI:** A terminal-based UI for configuring plugin options, making setup more accessible for all users.

These features are tracked in the [ROADMAP.md](ROADMAP.md) and ensure full parity with Anthropic's official IDE integrations.

## Requirements

- Neovim 0.7.0 or later
- [Claude Code command-line tool](https://github.com/anthropics/claude-code) installed
  - The plugin automatically detects Claude Code in the following order:
    1. Custom path specified in `config.cli_path` (if provided)
    2. Local installation at `~/.claude/local/claude` (preferred)
    3. Falls back to `claude` in PATH
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (dependency for git operations)
- Node.js (for MCP server) - the wrapper will install `mcp-neovim-server` automatically

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  "greggh/claude-code.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for git operations
  },
  config = function()
    require("claude-code").setup()
  end
}

```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'greggh/claude-code.nvim',
  requires = {
    'nvim-lua/plenary.nvim', -- Required for git operations
  },
  config = function()
    require('claude-code').setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'nvim-lua/plenary.nvim'
Plug 'greggh/claude-code.nvim'
" After installing, add this to your init.vim:
" lua require('claude-code').setup()
```

### Post-installation (optional)

To use the `claude-nvim` wrapper from anywhere:

```bash
# Add to your shell configuration (.bashrc, .zshrc, etc.)
export PATH="$PATH:~/.local/share/nvim/lazy/claude-code.nvim/bin"

# Or create a symlink
ln -s ~/.local/share/nvim/lazy/claude-code.nvim/bin/claude-nvim ~/.local/bin/

# Now you can use from anywhere:
claude-nvim "Help me with this code"
```

## MCP Server Integration

The plugin integrates with the official `mcp-neovim-server` to enable Claude Code to directly interact with your Neovim instance via the Model Context Protocol (MCP).

### Quick start

1. **The plugin automatically installs `mcp-neovim-server` if needed**

2. **Use the seamless wrapper script:**

   ```bash
   # From within Neovim with the plugin loaded:
   claude-nvim "Help me refactor this code"
   ```

   The wrapper automatically connects Claude to your running Neovim instance.

3. **Or manually configure Claude Code:**

   ```bash
   # Generate MCP configuration
   :ClaudeMCPGenerateConfig

   # Use with Claude Code
   claude --mcp-config ~/.config/claude-code/neovim-mcp.json "refactor this function"
   ```

### Available tools

The `mcp-neovim-server` provides these tools to Claude Code:

- **`vim_buffer`** - View buffer content with optional filename filtering
- **`vim_command`** - Execute any Vim command (`:w`, `:bd`, custom commands, etc.)
- **`vim_status`** - Get current editor status (cursor position, mode, buffer info)
- **`vim_edit`** - Edit buffer content with insert/replace/replaceAll modes
- **`vim_window`** - Manage windows (split, close, navigate)
- **`vim_mark`** - Set marks in buffers
- **`vim_register`** - Set register content
- **`vim_visual`** - Make visual selections
- **`analyze_related`** - Analyze files related through imports/requires (NEW!)
- **`find_symbols`** - Search workspace symbols using LSP (NEW!)
- **`search_files`** - Find files by pattern with optional content preview (NEW!)

### Available resources

The `mcp-neovim-server` exposes these resources:

- **`neovim://current-buffer`** - Content of the currently active buffer (config key: `current_buffer`)
- **`neovim://buffers`** - List of all open buffers with metadata (config key: `buffer_list`)
- **`neovim://project`** - Project file structure (config key: `project_structure`)
- **`neovim://git-status`** - Current git repository status (config key: `git_status`)
- **`neovim://lsp-diagnostics`** - LSP diagnostics for current buffer (config key: `lsp_diagnostics`)
- **`neovim://options`** - Current Neovim configuration and options (config key: `vim_options`)
- **`neovim://related-files`** - Files related through imports/requires (config key: `related_files`) (NEW!)
- **`neovim://recent-files`** - Recently accessed project files (config key: `recent_files`) (NEW!)
- **`neovim://workspace-context`** - Enhanced context with all related information (config key: `workspace_context`) (NEW!)
- **`neovim://search-results`** - Current search results and quickfix list (config key: `search_results`) (NEW!)

### Commands

- `:ClaudeCodeMCPStart` - Start the MCP server
- `:ClaudeCodeMCPStop` - Stop the MCP server
- `:ClaudeCodeMCPStatus` - Show server status and information

### Standalone usage

You can also run the MCP server standalone:

```bash
# Start standalone mcp server
./bin/claude-code-mcp-server
# Test the server
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | ./bin/claude-code-mcp-server
```

## Configuration

The plugin can be configured by passing a table to the `setup` function. Here's the default configuration:

```lua
require("claude-code").setup({
  -- MCP server settings
  mcp = {
    enabled = true,          -- Enable MCP server functionality
    auto_start = false,      -- Automatically start MCP server with Neovim
    tools = {
      buffer = true,         -- Enable buffer viewing tool
      command = true,        -- Enable Vim command execution tool
      status = true,         -- Enable status information tool
      edit = true,           -- Enable buffer editing tool
      window = true,         -- Enable window management tool
      mark = true,           -- Enable mark setting tool
      register = true,       -- Enable register operations tool
      visual = true,         -- Enable visual selection tool
      analyze_related = true,-- Enable related files analysis tool
      find_symbols = true,   -- Enable workspace symbol search tool
      search_files = true    -- Enable project file search tool
    },
    resources = {
      current_buffer = true,    -- Expose current buffer content
      buffer_list = true,       -- Expose list of all buffers
      project_structure = true, -- Expose project file structure
      git_status = true,        -- Expose git repository status
      lsp_diagnostics = true,   -- Expose LSP diagnostics
      vim_options = true,       -- Expose Neovim configuration
      related_files = true,     -- Expose files related through imports
      recent_files = true,      -- Expose recently accessed files
      workspace_context = true, -- Expose enhanced workspace context
      search_results = true     -- Expose search results and quickfix
    }
  },
  -- Terminal window settings
  window = {
    split_ratio = 0.3,      -- Percentage of screen for the terminal window (height for horizontal, width for vertical splits)
    position = "current",   -- Position of the window: "current" (use current window), "float" (floating overlay), "botright", "topleft", "vertical", etc.
    enter_insert = true,    -- Whether to enter insert mode when opening Claude Code
    hide_numbers = true,    -- Hide line numbers in the terminal window
    hide_signcolumn = true, -- Hide the sign column in the terminal window
    -- Floating window specific settings (when position = "float")
    float = {
      relative = "editor",  -- Window position relative to: "editor" or "cursor"
      width = 0.8,         -- Width as percentage of editor width (0.0-1.0)
      height = 0.8,        -- Height as percentage of editor height (0.0-1.0)
      row = 0.1,           -- Row position as percentage (0.0-1.0), 0.1 = 10% from top
      col = 0.1,           -- Column position as percentage (0.0-1.0), 0.1 = 10% from left
      border = "rounded",  -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
      title = " Claude Code ", -- Window title
      title_pos = "center",    -- Title position: "left", "center", "right"
    },
  },
  -- File refresh settings
  refresh = {
    enable = true,           -- Enable file change detection
    updatetime = 100,        -- updatetime when Claude Code is active (milliseconds)
    timer_interval = 1000,   -- How often to check for file changes (milliseconds)
    show_notifications = true, -- Show notification when files are reloaded
  },
  -- Git project settings
  git = {
    use_git_root = true,     -- Set CWD to git root when opening Claude Code (if in git project)
  },
  -- Command settings
  command = "claude",        -- Command used to launch Claude Code
  cli_path = nil,            -- Optional custom path to Claude command-line tool executable (e.g., "/custom/path/to/claude")
  -- Command variants
  command_variants = {
    -- Conversation management
    continue = "--continue", -- Resume the most recent conversation
    resume = "--resume",     -- Display an interactive conversation picker

    -- Output options
    verbose = "--verbose",   -- Enable verbose logging with full turn-by-turn output
  },
  -- Keymaps
  keymaps = {
    toggle = {
      normal = "<leader>aa",   -- Normal mode keymap for toggling Claude Code, false to disable
      terminal = "<leader>aa", -- Terminal mode keymap for toggling Claude Code, false to disable
      variants = {
        continue = "<leader>ac", -- Normal mode keymap for Claude Code with continue flag
        verbose = "<leader>av",  -- Normal mode keymap for Claude Code with verbose flag
        mcp_debug = "<leader>ad", -- Normal mode keymap for Claude Code with MCP debug flag
      },
    },
    selection = {
      send = "<leader>as",      -- Visual mode keymap for sending selection
      explain = "<leader>ae",   -- Visual mode keymap for explaining selection
      with_context = "<leader>aw", -- Visual mode keymap for toggling with selection
    },
    window_navigation = true, -- Enable window navigation keymaps (<C-h/j/k/l>)
    scrolling = true,         -- Enable scrolling keymaps (<C-f/b>) for page up/down
  }
})
```

## Claude code integration

The plugin provides seamless integration with the Claude Code command-line tool through MCP (Model Context Protocol):

### Quick setup

#### Zero-config usage (recommended)

Just use the new seamless commands - everything is handled automatically:

```vim
" In Neovim - just ask Claude directly!
:Claude How can I optimize this function?

" Or use the wrapper from terminal
$ claude-nvim "Help me debug this error"
````

The plugin automatically:

- ✅ Starts a server socket if needed
- ✅ Installs mcp-neovim-server if missing
- ✅ Manages all configuration
- ✅ Connects Claude to your Neovim instance

#### Manual setup (for advanced users)

If you prefer manual control:

1. **Install MCP server:**

   ```bash
   npm install -g mcp-neovim-server
   ```

2. **Start Neovim with socket:**

   ```bash
   nvim --listen /tmp/nvim
   ```

3. **Use with Claude:**

  ```bash
   export NVIM_SOCKET_PATH=/tmp/nvim
   claude "Your prompt"
   ```

### Available commands

- `:ClaudeCodeSetup [type]` - Generate MCP config with instructions (claude-code|workspace)
- `:ClaudeCodeMCPConfig [type] [path]` - Generate MCP config file (claude-code|workspace|custom)
- `:ClaudeCodeMCPStart` - Start the MCP server
- `:ClaudeCodeMCPStop` - Stop the MCP server
- `:ClaudeCodeMCPStatus` - Show server status

### Configuration types

- **`claude-code`** - Creates `.claude.json` for Claude Code command-line tool
- **`workspace`** - Creates `.vscode/mcp.json` for VS Code MCP extension
- **`custom`** - Creates `mcp-config.json` for other MCP clients

### Mcp tools

The official `mcp-neovim-server` provides these tools:

- `vim_buffer` - View buffer content
- `vim_command` - Execute Vim commands (shell commands optional via ALLOW_SHELL_COMMANDS env var)
- `vim_status` - Get current buffer, cursor position, mode, and file name
- `vim_edit` - Edit buffer content (insert/replace/replaceAll modes)
- `vim_window` - Window management (split, vsplit, close, navigation)
- `vim_mark` - Set marks in buffers
- `vim_register` - Set register content
- `vim_visual` - Make visual selections

## Usage

### Quick start

The plugin now provides multiple ways to interact with Claude:

#### 1. Seamless MCP integration (NEW!)

```vim
" Ask Claude anything - it automatically connects to your Neovim
:Claude How do I implement a binary search?

" With visual selection - select code then:
:'<,'>Claude Explain this code

" Quick question with response in buffer:
:ClaudeAsk What's the difference between vim.api and vim.fn?
```

#### 2. Traditional terminal interface

```vim
" Toggle Claude Code terminal
:ClaudeCode

" With specific context:
:ClaudeCodeWithFile          " Current file
:ClaudeCodeWithSelection     " Visual selection
:ClaudeCodeWithWorkspace     " Related files and context
```

#### 3. Using the wrapper directly

```bash
# In your terminal (automatically finds your Neovim instance)
claude-nvim "Help me refactor this function"

# The wrapper handles:
# - Building the TypeScript server if needed
# - Finding your Neovim socket
# - Setting up MCP configuration
# - Launching Claude with full access to your editor
```

### Context-aware usage examples

```vim
" Pass current file with cursor position
:ClaudeCodeWithFile

" Send visual selection to Claude (select text first)
:'<,'>ClaudeCodeWithSelection

" Smart detection - uses selection if available, otherwise current file
:ClaudeCodeWithContext

" Enhanced workspace context with related files
:ClaudeCodeWithWorkspace

" Project file tree structure for codebase overview
:ClaudeCodeWithProjectTree
```

### Visual selection with MCP

When Claude Code is connected via MCP, it can directly access your visual selections:

```lua
-- Select some code in visual mode, then:
-- Press <leader>as to send selection to Claude Code
-- Press <leader>ae to ask Claude to explain the selection
-- Press <leader>aw to start Claude with the selection as context

-- Claude Code can also query your selection programmatically:
-- Using tool: mcp__neovim__get_selection
-- Using resource: mcp__neovim__visual_selection
```

The context-aware commands automatically include relevant information:

- **File context**: Passes file path with line number (`file.lua#42`)
- **Selection context**: Creates a temporary markdown file with selected text
- **Workspace context**: Includes related files through imports, recent files, and current file content
- **Project tree context**: Provides a comprehensive file tree structure with configurable depth and filtering

### Commands

#### Basic commands

- `:ClaudeCode` - Toggle the Claude Code terminal window
- `:ClaudeCodeVersion` - Display the plugin version

#### Context-aware commands ✨

- `:ClaudeCodeWithFile` - Toggle with current file and cursor position
- `:ClaudeCodeWithSelection` - Toggle with visual selection
- `:ClaudeCodeWithContext` - Smart context detection (file or selection)
- `:ClaudeCodeWithWorkspace` - Enhanced workspace context with related files
- `:ClaudeCodeWithProjectTree` - Toggle with project file tree structure

#### Conversation management commands

- `:ClaudeCodeContinue` - Resume the most recent conversation
- `:ClaudeCodeResume` - Display an interactive conversation picker

#### Output options commands

- `:ClaudeCodeVerbose` - Enable verbose logging with full turn-by-turn output
- `:ClaudeCodeMcpDebug` - Enable MCP debug mode for troubleshooting MCP server issues

#### Window management commands

- `:ClaudeCodeHide` - Hide Claude Code window without stopping the process
- `:ClaudeCodeShow` - Show Claude Code window if hidden
- `:ClaudeCodeSafeToggle` - Safely toggle window without interrupting execution
- `:ClaudeCodeStatus` - Show current Claude Code process status
- `:ClaudeCodeInstances` - List all Claude Code instances and their states

#### Mcp integration commands

- `:ClaudeCodeMCPStart` - Start MCP server
- `:ClaudeCodeMCPStop` - Stop MCP server
- `:ClaudeCodeMCPStatus` - Show MCP server status
- `:ClaudeCodeMCPConfig` - Generate MCP configuration
- `:ClaudeCodeSetup` - Setup MCP integration

#### Visual selection commands ✨

- `:ClaudeCodeSendSelection` - Send visual selection to Claude Code (copies to clipboard)
- `:ClaudeCodeExplainSelection` - Explain visual selection with Claude Code

Note: Commands are automatically generated for each entry in your `command_variants` configuration.

### Key mappings

Default key mappings:

**Normal mode:**

- `<leader>aa` - Toggle Claude Code terminal window
- `<leader>ac` - Toggle Claude Code with --continue flag
- `<leader>av` - Toggle Claude Code with --verbose flag
- `<leader>ad` - Toggle Claude Code with --mcp-debug flag

**Visual mode:**

- `<leader>as` - Send visual selection to Claude Code
- `<leader>ae` - Explain visual selection with Claude Code
- `<leader>aw` - Toggle Claude Code with visual selection as context

**Seamless mode (NEW!):**

- `<leader>cc` - Launch Claude with MCP (normal/visual mode)
- `<leader>ca` - Quick ask Claude (opens command prompt)

Additionally, when in the Claude Code terminal:

- `<C-h>` - Move to the window on the left
- `<C-j>` - Move to the window below
- `<C-k>` - Move to the window above
- `<C-l>` - Move to the window on the right
- `<C-f>` - Scroll full-page down
- `<C-b>` - Scroll full-page up

Note: After scrolling with `<C-f>` or `<C-b>`, you'll need to press the `i` key to re-enter insert mode so you can continue typing to Claude Code.

When Claude Code modifies files that are open in Neovim, they'll be automatically reloaded.

## Tutorials

For comprehensive tutorials and practical examples, see our [Tutorials Guide](docs/TUTORIALS.md). The guide covers:

- **Resume Previous Conversations** - Continue where you left off with session management
- **Understand New Codebases** - Quickly navigate and understand unfamiliar projects
- **Fix Bugs Efficiently** - Diagnose and resolve issues with Claude's help
- **Refactor Code** - Modernize legacy code with confidence
- **Work with Tests** - Generate and improve test coverage
- **Create Pull Requests** - Generate comprehensive PR descriptions
- **Handle Documentation** - Auto-generate and update docs
- **Work with Images** - Analyze mockups and screenshots
- **Use Extended Thinking** - Leverage deep reasoning for complex tasks
- **Set up Project Memory** - Configure CLAUDE.md for project context
- **MCP Integration** - Configure and use the Model Context Protocol
- **Custom Commands** - Create reusable slash commands
- **Parallel Sessions** - Work on multiple features simultaneously

Each tutorial includes step-by-step instructions, tips, and real-world examples tailored for Neovim users.

## How it works

This plugin provides two complementary ways to interact with Claude Code:

### Terminal interface

1. Creates a terminal buffer running the Claude Code command-line tool
2. Sets up autocommands to detect file changes on disk
3. Automatically reloads files when they're modified by Claude Code
4. Provides convenient keymaps and commands for toggling the terminal
5. Automatically detects git repositories and sets working directory to the git root

### Context-aware integration

1. Analyzes your codebase to discover related files through imports/requires
2. Tracks recently accessed files within your project
3. Provides multiple context modes (file, selection, workspace)
4. Automatically passes relevant context to Claude Code command-line tool
5. Supports multiple programming languages (Lua, JavaScript, TypeScript, Python, Go)

### Mcp server

1. Runs a pure Lua MCP server exposing Neovim functionality
2. Provides tools for Claude Code to directly edit buffers and run commands
3. Exposes enhanced resources including related files and workspace context
4. Enables programmatic access to your development environment

## Contributing

Contributions are welcome. Please check out our [contribution guidelines](CONTRIBUTING.md) for details on how to get started.

## License

MIT License - See [LICENSE](LICENSE) for more information.

## Development

For a complete guide on setting up a development environment, installing all required tools, and understanding the project structure, please refer to [DEVELOPMENT.md](DEVELOPMENT.md).

### Development setup

The project includes comprehensive setup for development:

- Complete installation instructions for all platforms in [DEVELOPMENT.md](DEVELOPMENT.md)
- Pre-commit hooks for code quality
- Testing framework with 44 comprehensive tests
- Linting and formatting tools
- Weekly dependency updates workflow for Claude command-line tool and actions

#### Run tests

```bash
make test
```

#### Check code quality

```bash
make lint
```

#### Set up pre-commit hooks

```bash
scripts/setup-hooks.sh
```

#### Format code

```bash
make format
```

## Community

- [GitHub Discussions](https://github.com/greggh/claude-code.nvim/discussions) - Get help, share ideas, and connect with other users
- [GitHub Issues](https://github.com/greggh/claude-code.nvim/issues) - Report bugs or suggest features
- [GitHub Pull Requests](https://github.com/greggh/claude-code.nvim/pulls) - Contribute to the project

## Acknowledgements

- [Claude Code](https://github.com/anthropics/claude-code) by Anthropic - This plugin was entirely built using Claude Code. Development cost: $5.42 with 17m 12.9s of API time
- [Plenary.nvim](https://github.com/nvim-lua/plenary.nvim) - Core dependency for testing framework and Git operations
- [Semantic Versioning](https://semver.org/) - Versioning standard used in this project
- [Contributor Covenant](https://www.contributor-covenant.org/) - Code of Conduct standard
- [Keep a Changelog](https://keepachangelog.com/) - Changelog format
- [LuaCATS](https://luals.github.io/wiki/annotations/) - Type annotations for better IDE support
- [StyLua](https://github.com/JohnnyMorganz/StyLua) - Lua code formatter
- [Luacheck](https://github.com/lunarmodules/luacheck) - Lua static analyzer and linter

---

Made with ❤️ by [Gregg Housh](https://github.com/greggh)

---

### File reference shortcut ✨

- Quickly insert a file reference in the form `@File#L1-99` into the Claude prompt input.
- **How to use:**
  - Press `<leader>cf` in normal mode to insert the current file and line (e.g., `@myfile.lua#L10`).
  - In visual mode, `<leader>cf` inserts the current file and selected line range (e.g., `@myfile.lua#L5-7`).
- **Where it works:**
  - Inserts into the Claude prompt input buffer (or falls back to the command line if not available).
- **Why:**
  - Useful for referencing code locations in your Claude conversations, just like in VSCode/JetBrains integrations.

**Examples:**

- Normal mode, cursor on line 10: `@myfile.lua#L10`
- Visual mode, lines 5-7 selected: `@myfile.lua#L5-7`
