
# Claude code neovim plugin: enhanced context features implementation

## Overview

This document summarizes the comprehensive enhancements made to the claude-code.nvim plugin, focusing on adding context-aware features that mirror Claude Code's built-in IDE integrations while maintaining the powerful MCP (Model Context Protocol) server capabilities.

## Background

The original plugin provided:

- Basic terminal interface to Claude Code command-line tool
- Traditional MCP server for programmatic control
- Simple buffer management and file refresh

**The Challenge:** Users wanted the same seamless context experience as Claude Code's built-in VS Code/Cursor integrations, where current file, selection, and project context are automatically included in conversations.

## Implementation summary

### 1. context analysis module (`lua/claude-code/context.lua`)

Created a comprehensive context analysis system supporting multiple programming languages:

#### Language support

- **Lua**: `require()`, `dofile()`, `loadfile()` patterns
- **JavaScript/TypeScript**: `import`/`require` with relative path resolution
- **Python**: `import`/`from` with module path conversion
- **Go**: `import` statements with relative path handling

#### Key functions

- `get_related_files(filepath, max_depth)` - Discovers files through import/require analysis
- `get_recent_files(limit)` - Retrieves recently accessed project files
- `get_workspace_symbols()` - LSP workspace symbol discovery
- `get_enhanced_context()` - Comprehensive context aggregation

#### Smart features

- **Dependency depth control** (default: 2 levels)
- **Project-aware filtering** (only includes current project files)
- **Module-to-path conversion** for each language's conventions
- **Relative vs absolute import handling**

### 2. enhanced terminal interface (`lua/claude-code/terminal.lua`)

Extended the terminal interface with context-aware toggle functionality:

#### New function: `toggle_with_context(context_type)`

**Context Types:**

- `"file"` - Current file with cursor position (`claude --file "path#line"`)
- `"selection"` - Visual selection as temporary markdown file
- `"workspace"` - Enhanced context with related files, recent files, and current file content
- `"auto"` - Smart detection (selection if in visual mode, otherwise file)

#### Workspace context features

- **Context summary file** with current file info, cursor position, file type
- **Related files section** with dependency depth and import counts
- **Recent files list** (top 5 most recent)
- **Complete current file content** in proper markdown code blocks
- **Automatic cleanup** of temporary files after 10 seconds

### 3. enhanced mcp resources (`lua/claude-code/mcp/resources.lua`)

Added four new MCP resources for advanced context access:

#### **`neovim://related-files`**

```json
{
  "current_file": "lua/claude-code/init.lua",
  "related_files": [
    {
      "path": "lua/claude-code/config.lua",
      "depth": 1,
      "language": "lua",
      "import_count": 3
    }
  ]
}

```text

#### **`neovim://recent-files`**

```json
{
  "project_root": "/path/to/project",
  "recent_files": [
    {
      "path": "/path/to/file.lua",
      "relative_path": "lua/file.lua",
      "last_used": 1
    }
  ]
}

```text

#### **`neovim://workspace-context`**

Complete enhanced context including current file, related files, recent files, and workspace symbols.

#### **`neovim://search-results`**

```json
{
  "search_pattern": "function",
  "quickfix_list": [...],
  "readable_quickfix": [
    {
      "filename": "lua/init.lua",
      "lnum": 42,
      "text": "function M.setup()",
      "type": "I"
    }
  ]
}

```text

### 4. enhanced mcp tools (`lua/claude-code/mcp/tools.lua`)

Added three new MCP tools for intelligent workspace analysis:

#### **`analyze_related`**

- Analyzes files related through imports/requires
- Configurable dependency depth
- Lists imports and dependency relationships
- Returns markdown formatted analysis

#### **`find_symbols`**

- LSP workspace symbol search
- Query filtering support
- Returns symbol locations and metadata
- Supports symbol type and container information

#### **`search_files`**

- File pattern searching across project
- Optional content inclusion
- Returns file paths with preview content
- Limited results for performance

### 5. enhanced commands (`lua/claude-code/commands.lua`)

Added new user commands for context-aware interactions:

```vim
:ClaudeCodeWithFile      " Current file + cursor position
:ClaudeCodeWithSelection " Visual selection
:ClaudeCodeWithContext   " Smart auto-detection
:ClaudeCodeWithWorkspace " Enhanced workspace context

```text

### 6. test infrastructure consolidation

Reorganized and enhanced the testing structure:

#### **directory consolidation:**

- Moved files from `test/` to organized `tests/` subdirectories
- Created `tests/legacy/` for VimL-based tests
- Created `tests/interactive/` for manual testing utilities
- Updated all references in Makefile, scripts, and CI

#### **updated references:**

- Makefile test commands now use `tests/legacy/`
- MCP test script updated for new paths
- CI workflow enhanced with better directory verification
- README updated with new test structure documentation

### 7. documentation updates

Comprehensive documentation updates across multiple files:

#### **readme.md enhancements:**

- Added context-aware commands section
- Enhanced features list with new capabilities
- Updated MCP server description with new resources
- Added emoji indicators for new features

#### **roadmap.md updates:**

- Marked context helper features as completed ✅
- Added context-aware integration goals
- Updated completion status for workspace context features

## Technical details

### **import/require pattern matching**

The context analysis uses sophisticated regex patterns for each language:

```lua
-- Lua example
"require%s*%(?['\"]([^'\"]+)['\"]%)?",

-- JavaScript/TypeScript example
"import%s+.-from%s+['\"]([^'\"]+)['\"]",

-- Python example
"from%s+([%w%.]+)%s+import",

```text

### **path resolution logic**

Smart path resolution handles different import styles:

- **Relative imports:** `./module` → `current_dir/module.ext`
- **Absolute imports:** `module.name` → `project_root/module/name.ext`
- **Module conventions:** `module.name` → both `module/name.ext` and `module/name/index.ext`

### **context file generation**

Workspace context generates comprehensive markdown files:

```markdown

# Workspace context

**Current File:** lua/claude-code/init.lua
**Cursor Position:** Line 42
**File Type:** lua

## Related files (through imports/requires)

- **lua/claude-code/config.lua** (depth: 1, language: lua, imports: 3)

## Recent files

- lua/claude-code/terminal.lua

## Current file content

```lua
-- Complete file content here

```text

```text

### **temporary file management**

Context-aware features use secure temporary file handling:

- Files created in system temp directory with `.md` extension
- Automatic cleanup after 10 seconds using `vim.defer_fn()`
- Proper error handling for file operations

## Benefits achieved

### **for users:**

1. **Seamless Context Experience** - Same automatic context as built-in IDE integrations
2. **Smart Context Detection** - Auto-detects whether to send file or selection
3. **Enhanced Workspace Awareness** - Related files discovered automatically
4. **Flexible Context Control** - Choose specific context type when needed

### **for developers:**

1. **Comprehensive MCP Resources** - Rich context data for MCP clients
2. **Advanced Analysis Tools** - Programmatic access to workspace intelligence
3. **Language-Agnostic Design** - Extensible pattern system for new languages
4. **Robust Error Handling** - Graceful fallbacks when modules unavailable

### **for the project:**

1. **Test Organization** - Cleaner, more maintainable test structure
2. **Documentation Quality** - Comprehensive usage examples and feature descriptions
3. **Feature Completeness** - Addresses all missing context features identified
4. **Backward Compatibility** - All existing functionality preserved

## Usage examples

### **basic context commands:**

```vim
" Pass current file with cursor position
:ClaudeCodeWithFile

" Send visual selection (use in visual mode)
:ClaudeCodeWithSelection

" Smart detection - file or selection
:ClaudeCodeWithContext

" Full workspace context with related files
:ClaudeCodeWithWorkspace

```text

### **mcp client usage:**

```javascript
// Read related files through MCP
const relatedFiles = await client.readResource("neovim://related-files");

// Analyze dependencies programmatically
const analysis = await client.callTool("analyze_related", { max_depth: 3 });

// Search workspace symbols
const symbols = await client.callTool("find_symbols", { query: "setup" });

```text

## Latest update: configurable cli path support (tdd implementation)

### **command-line tool configuration enhancement**

Added robust configurable Claude command-line tool path support using Test-Driven Development:

#### **key features:**

- **`cli_path` Configuration Option** - Custom path to Claude command-line tool executable
- **Enhanced Detection Order:**
  1. Custom path from `config.cli_path` (if provided)
  2. Local installation at `~/.claude/local/claude` (preferred)
  3. Falls back to `claude` in PATH
- **Robust Error Handling** - Checks file readability before executability
- **User Notifications** - Informative messages about command-line tool detection results

#### **configuration example:**

```lua
require('claude-code').setup({
  cli_path = "/custom/path/to/claude",  -- Optional custom command-line tool path
  -- ... other config options
})

```text

#### **test-driven development:**

- **14 comprehensive test cases** covering all command-line tool detection scenarios
- **Custom path validation** with fallback behavior
- **Error handling tests** for invalid paths and missing command-line tool
- **Notification testing** for different detection outcomes

#### **benefits:**

- **Enterprise Compatibility** - Custom installation paths supported
- **Development Flexibility** - Test different Claude command-line tool versions
- **Robust Detection** - Graceful fallbacks when command-line tool not found
- **Clear User Feedback** - Notifications explain which command-line tool is being used

## Files modified/created

### **new files:**

- `lua/claude-code/context.lua` - Context analysis engine
- `tests/spec/cli_detection_spec.lua` - TDD test suite for command-line tool detection
- Various test files moved to organized structure

### **enhanced files:**

- `lua/claude-code/config.lua` - command-line tool detection and configuration validation
- `lua/claude-code/terminal.lua` - Context-aware toggle function
- `lua/claude-code/commands.lua` - New context commands
- `lua/claude-code/init.lua` - Expose context functions
- `lua/claude-code/mcp/resources.lua` - Enhanced resources
- `lua/claude-code/mcp/tools.lua` - Analysis tools
- `README.md` - Comprehensive documentation updates including command-line tool configuration
- `ROADMAP.md` - Progress tracking updates
- `Makefile` - Updated test paths
- `.github/workflows/ci.yml` - Enhanced CI verification
- `scripts/test_mcp.sh` - Updated module paths

## Testing and validation

### **automated tests:**

- MCP integration tests verify new resources load correctly
- Context module functions validated for proper API exposure
- Command registration confirmed for all new commands

### **manual validation:**

- Context analysis tested with multi-language projects
- Related file discovery validated across different import styles
- Workspace context generation tested with various file types

## Future enhancements

The implementation provides a solid foundation for additional features:

1. **Tree-sitter Integration** - Use AST parsing for more accurate import analysis
2. **Cache System** - Cache related file analysis for better performance
3. **Custom Language Support** - User-configurable import patterns
4. **Context Filtering** - User preferences for context inclusion/exclusion
5. **Visual Context Selection** - UI for choosing specific context elements

## Conclusion

This implementation successfully bridges the gap between traditional MCP server functionality and the context-aware experience of Claude Code's built-in IDE integrations. Users now have:

- **Automatic context passing** like built-in integrations
- **Powerful programmatic control** through enhanced MCP resources
- **Intelligent workspace analysis** through import/require discovery
- **Flexible context options** for different use cases

The modular design ensures maintainability while the comprehensive test coverage and documentation provide a solid foundation for future development.

