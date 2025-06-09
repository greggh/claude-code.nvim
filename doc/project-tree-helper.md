
# Project tree helper

## Overview

The Project Tree Helper provides utilities for generating comprehensive file tree representations to include as context when interacting with Claude Code. This feature helps Claude understand your project structure at a glance.

## Features

- **Intelligent Filtering** - Excludes common development artifacts (`.git`, `node_modules`, etc.)
- **Configurable Depth** - Control how deep to scan directory structure
- **File Limiting** - Prevent overwhelming output with file count limits
- **Size Information** - Optional file size display
- **Markdown Formatting** - Clean, readable output format

## Usage

### Command

```vim
:ClaudeCodeWithProjectTree

```text

This command generates a project file tree and passes it to Claude Code as context.

### Example output

```text

# Project structure

**Project:** claude-code.nvim
**Root:** ./

```text
claude-code.nvim/
  README.md
  lua/
    claude-code/
      init.lua
      config.lua
      terminal.lua
      tree_helper.lua
  tests/
    spec/
      tree_helper_spec.lua
  doc/
    claude-code.txt

```text

## Configuration

The tree helper uses sensible defaults but can be customized:

### Default settings

- **Max Depth:** 3 levels
- **Max Files:** 50 files
- **Show Size:** false
- **Ignore Patterns:** Common development artifacts

### Default ignore patterns

```lua
{
  "%.git",
  "node_modules",
  "%.DS_Store",
  "%.vscode",
  "%.idea",
  "target",
  "build",
  "dist",
  "%.pytest_cache",
  "__pycache__",
  "%.mypy_cache"
}

```text

## Api reference

### Core functions

#### `generate_tree(root_dir, options)`

Generate a file tree representation of a directory.

**Parameters:**

- `root_dir` (string): Root directory to scan
- `options` (table, optional): Configuration options
  - `max_depth` (number): Maximum depth to scan (default: 3)
  - `max_files` (number): Maximum files to include (default: 100)
  - `ignore_patterns` (table): Patterns to ignore (default: common patterns)
  - `show_size` (boolean): Include file sizes (default: false)

**Returns:** string - Tree representation

#### `get_project_tree_context(options)`

Get project tree context as formatted markdown.

**Parameters:**

- `options` (table, optional): Same as `generate_tree`

**Returns:** string - Markdown formatted project tree

#### `create_tree_file(options)`

Create a temporary file with project tree content.

**Parameters:**

- `options` (table, optional): Same as `generate_tree`

**Returns:** string - Path to temporary file

### Utility functions

#### `get_default_ignore_patterns()`

Get the default ignore patterns.

**Returns:** table - Default ignore patterns

#### `add_ignore_pattern(pattern)`

Add a new ignore pattern to the default list.

**Parameters:**

- `pattern` (string): Pattern to add

## Integration

### With claude code cli

The project tree helper integrates seamlessly with Claude Code:

1. **Automatic Detection** - Uses git root or current directory
2. **Temporary Files** - Creates markdown files that are auto-cleaned
3. **command-line tool Integration** - Passes files using `--file` parameter

### With mcp server

The tree functionality is also available through MCP resources:

- **`neovim://project-structure`** - Access via MCP clients
- **Programmatic Access** - Use from other MCP tools
- **Real-time Generation** - Generate trees on demand

## Examples

### Basic usage

```lua
local tree_helper = require('claude-code.tree_helper')

-- Generate simple tree
local tree = tree_helper.generate_tree("/path/to/project")
print(tree)

-- Generate with options
local tree = tree_helper.generate_tree("/path/to/project", {
  max_depth = 2,
  max_files = 25,
  show_size = true
})

```text

### Custom ignore patterns

```lua
local tree_helper = require('claude-code.tree_helper')

-- Add custom ignore pattern
tree_helper.add_ignore_pattern("%.log$")

-- Generate tree with custom patterns
local tree = tree_helper.generate_tree("/path/to/project", {
  ignore_patterns = {"%.git", "node_modules", "%.tmp$"}
})

```text

### Markdown context

```lua
local tree_helper = require('claude-code.tree_helper')

-- Get formatted markdown context
local context = tree_helper.get_project_tree_context({
  max_depth = 3,
  show_size = false
})

-- Create temporary file for Claude Code
local temp_file = tree_helper.create_tree_file()
-- File is automatically cleaned up after 10 seconds

```text

## Implementation details

### File system traversal

The tree helper uses Neovim's built-in file system functions:

- **`vim.fn.glob()`** - Directory listing
- **`vim.fn.isdirectory()`** - Directory detection
- **`vim.fn.filereadable()`** - File accessibility
- **`vim.fn.getfsize()`** - File size information

### Pattern matching

Ignore patterns use Lua pattern matching:

- **`%.git`** - Literal `.git` directory
- **`%.%w+$`** - Files ending with extension
- **`^node_modules$`** - Exact directory name match

### Performance considerations

- **Depth Limiting** - Prevents excessive directory traversal
- **File Count Limiting** - Avoids overwhelming output
- **Efficient Sorting** - Directories first, then files alphabetically
- **Lazy Evaluation** - Only processes needed files

## Best practices

### When to use

- **Project Overview** - Give Claude context about codebase structure
- **Architecture Discussions** - Show how project is organized
- **Code Navigation** - Help Claude understand file relationships
- **Refactoring Planning** - Provide context for large changes

### Recommended settings

```lua
-- For small projects
local options = {
  max_depth = 4,
  max_files = 100,
  show_size = false
}

-- For large projects
local options = {
  max_depth = 2,
  max_files = 30,
  show_size = false
}

-- For documentation
local options = {
  max_depth = 3,
  max_files = 50,
  show_size = true
}

```text

### Custom workflows

Combine with other context types:

```vim
" Start with project overview
:ClaudeCodeWithProjectTree

" Then dive into specific file
:ClaudeCodeWithFile

" Or provide workspace context
:ClaudeCodeWithWorkspace

```text

## Troubleshooting

### Empty output

If tree generation returns empty results:

1. **Check Permissions** - Ensure directory is readable
2. **Verify Path** - Confirm directory exists
3. **Review Patterns** - Check if ignore patterns are too restrictive

### Performance issues

For large projects:

1. **Reduce max_depth** - Limit directory traversal
2. **Lower max_files** - Reduce file count
3. **Add Ignore Patterns** - Exclude large directories

### Integration problems

If command doesn't work:

1. **Check Module Loading** - Ensure tree_helper loads correctly
2. **Verify Git Integration** - Git module may be required
3. **Test Manually** - Try direct API calls

## Testing

The tree helper includes comprehensive tests:

- **9 test scenarios** covering all major functionality
- **Mock file system** for reliable testing
- **Edge case handling** for empty directories and permissions
- **Integration testing** with git and MCP modules

Run tests:

```bash
nvim --headless -c "lua require('tests.run_tests').run_specific('tree_helper_spec')" -c "qall"

```text

