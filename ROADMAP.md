
# Claude code plugin roadmap

This document outlines the planned development path for the Claude Code Neovim plugin. It's divided into short-term, medium-term, and long-term goals. This roadmap may evolve over time based on user feedback and project priorities.

## Short-term goals (next 3 months)

- **Enhanced Terminal Integration**: Improve the Neovim terminal experience with Claude Code ✅
  - Add better window management options ✅ (Safe window toggle implemented)
  - Implement automatic terminal resizing
  - Create improved keybindings for common interactions

- **Context Helpers**: Utilities for providing better context to Claude ✅
  - Add file/snippet insertion shortcuts ✅
  - Implement buffer content selection tools ✅
  - Create project file tree insertion helpers ✅
  - Context-aware commands (`:ClaudeCodeWithFile`, `:ClaudeCodeWithSelection`, `:ClaudeCodeWithContext`, `:ClaudeCodeWithProjectTree`) ✅

- **Plugin Configuration**: More flexible configuration options
  - Add per-filetype settings
  - Implement project-specific configurations
  - Create toggle options for different features
  - Make startup notification configurable in init.lua
  - Add Claude Code integration to LazyVim/Snacks dashboard
  - Add configuration to open Claude Code as full-sized buffer when no other buffers are open

- **Code Quality & Testing Improvements** (Remaining from PR #30 Review)
  - Replace hardcoded tool/resource counts in tests with configurable values
  - Make CI tests more flexible (avoid hardcoded expectations)
  - Make protocol version configurable in mcp/server.lua
  - Add headless mode check for file descriptor usage in mcp/server.lua
  - Make server path configurable in scripts/test_mcp.sh
  - Fix markdown formatting issues in documentation files

- **Development Infrastructure Enhancements**
  - Add explicit Windows dependency installation support to Makefile
  - Support PowerShell/CMD scripts and Windows package managers (Chocolatey, Scoop, winget)

## Medium-term goals (3-12 months)

- **Prompt Library**: Create a comprehensive prompt system
  - Implement a prompt template manager
  - Add customizable prompt categories
  - Create filetype-specific prompts
  - Build prompt insertion keybindings

- **Session Management**: Better handling of Claude Code sessions
  - Add session saving/restoration
  - Implement named sessions for different tasks
  - Create session export/import functionality

- **Editor Integration**: Tighter integration with Neovim workflow
  - Improve interaction with other plugins
  - Add support for output buffer navigation
  - Create clipboard integration options

## Long-term goals (12+ months)

- **Inline Code Suggestions**: Real-time AI assistance
  - Cursor-style completions using fast Haiku model
  - Context-aware code suggestions
  - Real-time error detection and fixes
  - Smart autocomplete integration

- **Advanced Output Handling**: Better ways to use Claude's responses
  - Implement code block extraction
  - Add output filtering options
  - Create automatic documentation generation

- **Project Analysis Helpers**: Tools to help Claude understand projects
  - File tree summarization utilities
  - Project structure visualization
  - Dependency analysis helpers

## Completed goals

### Core plugin features

- Basic Claude Code integration in Neovim ✅
- Terminal-based interaction ✅
- Configurable keybindings ✅
- Terminal toggle functionality ✅
- Git directory detection ✅
- Safe window toggle (prevents process interruption) ✅
- Context-aware commands (`ClaudeCodeWithFile`, `ClaudeCodeWithSelection`, etc.) ✅
- File reference shortcuts (`@File#L1-99` insertion) ✅
- Project tree context integration ✅

### Code quality & security (pr #30 review implementation)

- **Security & Validation** ✅
  - Path validation for plugin directory in MCP server binary ✅
  - Input validation for command line arguments ✅
  - Git executable path validation in MCP resources ✅
  - Enhanced path validation in utils.find_executable function ✅
  - Error handling for directory creation in utils.lua ✅

- **API Modernization** ✅
  - Replaced deprecated `nvim_buf_get_option` with `nvim_get_option_value` ✅
  - Hidden internal module exposure in init.lua (improved encapsulation) ✅

- **Documentation Cleanup** ✅
  - Removed stray chat transcript from README.md ✅

### Mcp integration

- Native Lua MCP server implementation ✅
- MCP resource handlers (buffers, git status, project structure, etc.) ✅
- MCP tool handlers (read buffer, edit buffer, run command, etc.) ✅
- MCP configuration generation ✅
- MCP Hub integration for server discovery ✅

## Feature requests and contributions

If you have feature requests or would like to contribute to the roadmap, please:

1. Check if your idea already exists as an issue on GitHub
2. If not, open a new issue with the "enhancement" label
3. Explain how your idea would improve the Claude Code plugin experience

We welcome community contributions to help achieve these goals. See [CONTRIBUTING.md](CONTRIBUTING.md) for more information on how to contribute.

## Planned features (from ide integration parity audit)

- **File Reference Shortcut:**
  Add a mapping to insert `@File#L1-99` style references into Claude prompts.

- **External `/ide` Command Support:**
  Implement a way for external Claude Code command-line tool sessions to attach to a running Neovim MCP server, mirroring the `/ide` command in GUI IDEs.

- **User-Friendly Config UI:**
  Develop a TUI for configuring plugin options, providing a more accessible alternative to Lua config files.

