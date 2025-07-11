# Claude code neovim plugin

[![GitHub License](https://img.shields.io/github/license/greggh/claude-code.nvim?style=flat-square)](https://github.com/greggh/claude-code.nvim/blob/main/LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/greggh/claude-code.nvim?style=flat-square)](https://github.com/greggh/claude-code.nvim/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/greggh/claude-code.nvim?style=flat-square)](https://github.com/greggh/claude-code.nvim/issues)
[![CI](https://img.shields.io/github/actions/workflow/status/greggh/claude-code.nvim/ci.yml?branch=main&style=flat-square&logo=github)](https://github.com/greggh/claude-code.nvim/actions/workflows/ci.yml)
[![Neovim Version](https://img.shields.io/badge/Neovim-0.7%2B-blueviolet?style=flat-square&logo=neovim)](https://github.com/neovim/neovim)
[![Tests](https://img.shields.io/badge/Tests-44%20passing-success?style=flat-square&logo=github-actions)](https://github.com/greggh/claude-code.nvim/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/Version-0.4.2-blue?style=flat-square)](https://github.com/greggh/claude-code.nvim/releases/tag/v0.4.2)
[![Discussions](https://img.shields.io/github/discussions/greggh/claude-code.nvim?style=flat-square&logo=github)](https://github.com/greggh/claude-code.nvim/discussions)

_A seamless integration between [Claude Code](https://github.com/anthropics/claude-code) AI assistant and Neovim with context-aware commands and enhanced MCP server_

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
- **Enhanced MCP (Model Context Protocol) server** that allows Claude Code to directly read and edit your Neovim buffers, execute commands, and access project context

## Features

### Terminal interface

- 🚀 Toggle Claude Code in a terminal window with a single key press
- 🔒 **Safe window toggle** - Hide/show window without interrupting Claude Code execution
- 🧠 Support for command-line arguments like `--continue` and custom variants
- 🔄 Automatically detect and reload files modified by Claude Code
- ⚡ Real-time buffer updates when files are changed externally
- 📊 Process status monitoring and instance management
- 📱 Customizable window position and size (including floating windows)
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

1. Uses an enhanced fork of mcp-neovim-server with additional features
2. Provides tools for Claude Code to directly edit buffers and run commands
3. Exposes enhanced resources including related files and workspace context
4. Enables programmatic access to your development environment

## Contributing

Contributions are welcome. Please check out our [contribution guidelines](CONTRIBUTING.md) for details on how to get started.

## License

MIT License - See [LICENSE](LICENSE) for more information.

## Development

For a complete guide on setting up a development environment, installing all required tools, and understanding the project structure, please refer to [CONTRIBUTING.md](CONTRIBUTING.md).

### Development setup

The project includes comprehensive setup for development:

- Complete installation instructions for all platforms in [CONTRIBUTING.md](CONTRIBUTING.md)
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
