
# Tutorials

> Practical examples and patterns for effectively using Claude Code in Neovim.

This guide provides step-by-step tutorials for common workflows with Claude Code in Neovim. Each tutorial includes clear instructions, example commands, and best practices to help you get the most from Claude Code.

## Table of contents

* [Resume Previous Conversations](#resume-previous-conversations)
* [Understand New Codebases](#understand-new-codebases)
* [Fix Bugs Efficiently](#fix-bugs-efficiently)
* [Refactor Code](#refactor-code)
* [Work with Tests](#work-with-tests)
* [Create Pull Requests](#create-pull-requests)
* [Handle Documentation](#handle-documentation)
* [Work with Images](#work-with-images)
* [Use Extended Thinking](#use-extended-thinking)
* [Set up Project Memory](#set-up-project-memory)
* [Set up Model Context Protocol (MCP)](#set-up-model-context-protocol-mcp)
* [Use Claude as a Unix-Style Utility](#use-claude-as-a-unix-style-utility)
* [Create Custom Slash Commands](#create-custom-slash-commands)
* [Run Parallel Claude Code Sessions](#run-parallel-claude-code-sessions)

## Resume previous conversations

### Continue your work seamlessly

**When to use:** you've been working on a task with Claude Code and need to continue where you left off in a later session.

Claude Code in Neovim provides several options for resuming previous conversations:

#### Steps

1. **Resume a suspended session**
   ```vim
   :ClaudeCodeResume
   ```
   This resumes a previously suspended Claude Code session, maintaining all context.

2. **Continue with command variants**
   ```vim
   :ClaudeCode --continue
   ```
   Or use the keymap: `<leader>cc` (if configured)

3. **Continue in non-interactive mode**
   ```vim
   :ClaudeCode --continue "Continue with my task"
   ```

**How it works:**

- **Session Management**: Claude Code sessions can be suspended and resumed
- **Context Preservation**: The entire conversation context is maintained
- **Multi-Instance Support**: Each git repository can have its own Claude instance
- **Buffer State**: The terminal buffer preserves the full conversation history

**Tips:**

- Use `:ClaudeCodeSuspend` to pause a session without losing context
- Sessions are tied to git repositories when `git.multi_instance` is enabled
- The terminal buffer shows the entire conversation history when resumed
- Use safe toggle (`:ClaudeCodeSafeToggle`) to hide Claude without stopping it

**Examples:**

```vim
" Suspend current session
:ClaudeCodeSuspend

" Resume later
:ClaudeCodeResume

" Toggle with continuation variant
:ClaudeCodeToggle continue

" Use custom keymaps (if configured)
<leader>cc  " Continue conversation
<leader>cr  " Resume session

```text

## Understand new codebases

### Get a quick codebase overview

**When to use:** you've just joined a new project and need to understand its structure quickly.

#### Steps

1. **Open Neovim in the project root**
   ```bash
   cd /path/to/project
   nvim
   ```

2. **Start Claude Code**
   ```vim
   :ClaudeCode
   ```
   Or use the keymap: `<leader>cc`

3. **Ask for a high-level overview**
   ```
   > give me an overview of this codebase
   ```

4. **Dive deeper into specific components**
   ```
   > explain the main architecture patterns used here
   > what are the key data models?
   > how is authentication handled?
   ```

**Tips:**

- Use `:ClaudeCodeRefreshFiles` to update Claude's view of the project
- The MCP server provides access to project structure via resources
- Start with broad questions, then narrow down to specific areas
- Ask about coding conventions and patterns used in the project

### Find relevant code

**When to use:** you need to locate code related to a specific feature or functionality.

#### Steps

1. **Ask Claude to find relevant files**
   ```
   > find the files that handle user authentication
   ```

2. **Get context on how components interact**
   ```
   > how do these authentication files work together?
   ```

3. **Navigate to specific locations**
   ```
   > show me the login function implementation
   ```
   Claude can provide file paths like `auth/login.lua:42` that you can navigate to.

**Tips:**

- Use file reference shortcut `<leader>cf` to quickly insert file references
- Claude has access to LSP diagnostics and can find symbols
- The `search_files` tool helps locate specific patterns
- Be specific about what you're looking for

## Fix bugs efficiently

### Diagnose error messages

**When to use:** you've encountered an error and need to find and fix its source.

#### Steps

1. **Share the error with Claude**
   ```
   > I'm seeing this error in the quickfix list
   ```
   Or select the error text and use `:ClaudeCodeToggle selection`

2. **Ask for diagnostic information**
   ```
   > check LSP diagnostics for this file
   ```

3. **Get fix recommendations**
   ```
   > suggest ways to fix this TypeScript error
   ```

4. **Apply the fix**
   ```
   > update the file to add the null check you suggested
   ```

**Tips:**

- Claude has access to LSP diagnostics through MCP resources
- Use visual selection to share specific error messages
- The `vim_edit` tool can apply fixes directly
- Let Claude know about any compilation commands

## Refactor code

### Modernize legacy code

**When to use:** you need to update old code to use modern patterns and practices.

#### Steps

1. **Select code to refactor**
   - Visual select the code block
   - Use `:ClaudeCodeToggle selection`

2. **Get refactoring recommendations**
   ```
   > suggest how to refactor this to use modern Lua patterns
   ```

3. **Apply changes safely**
   ```
   > refactor this function to use modern patterns while maintaining the same behavior
   ```

4. **Verify the refactoring**
   ```
   > run tests for the refactored code
   ```

**Tips:**

- Use visual mode to precisely select code for refactoring
- Claude can maintain git history awareness with multi-instance mode
- Request incremental refactoring for large changes
- Use the `vim_edit` tool's different modes (insert, replace, replace_all)

## Work with tests

### Add test coverage

**When to use:** you need to add tests for uncovered code.

#### Steps

1. **Identify untested code**
   ```
   > find functions in user_service.lua that lack test coverage
   ```

2. **Generate test scaffolding**
   ```
   > create plenary test suite for the user service
   ```

3. **Add meaningful test cases**
   ```
   > add edge case tests for the notification system
   ```

4. **Run and verify tests**
   ```
   > run the test suite with plenary
   ```

**Tips:**

- Claude understands plenary.nvim test framework
- Request both unit and integration tests
- Use `:ClaudeCodeToggle file` to include entire test files
- Ask for tests that cover edge cases and error conditions

## Create pull requests

### Generate comprehensive prs

**When to use:** you need to create a well-documented pull request for your changes.

#### Steps

1. **Review your changes**
   ```
   > show me all changes in the current git repository
   ```

2. **Generate a PR with Claude**
   ```
   > create a pull request for these authentication improvements
   ```

3. **Review and refine**
   ```
   > enhance the PR description with security considerations
   ```

4. **Create the commit**
   ```
   > create a git commit with a comprehensive message
   ```

**Tips:**

- Claude has access to git status through MCP resources
- Use `git.multi_instance` to work on multiple PRs simultaneously
- Ask Claude to follow your project's PR template
- Request specific sections like "Testing," "Breaking Changes," etc.

## Handle documentation

### Generate code documentation

**When to use:** you need to add or update documentation for your code.

#### Steps

1. **Identify undocumented code**
   ```
   > find Lua functions without proper documentation
   ```

2. **Generate documentation**
   ```
   > add LuaDoc comments to all public functions in this module
   ```

3. **Create user-facing docs**
   ```
   > create a README.md explaining how to use this plugin
   ```

4. **Update existing docs**
   ```
   > update the API documentation with the new methods
   ```

**Tips:**

- Specify documentation style (LuaDoc, Markdown, etc.)
- Use `:ClaudeCodeToggle workspace` for project-wide documentation
- Request examples in the documentation
- Ask Claude to follow your project's documentation standards

## Work with images

### Analyze images and screenshots

**When to use:** you need to work with UI mockups, error screenshots, or diagrams.

#### Steps

1. **Share an image with Claude**
   - Copy an image to clipboard and paste in the Claude terminal
   - Or reference an image file path:
   ```
   > analyze this mockup: ~/Desktop/new-ui-design.png
   ```

2. **Get implementation suggestions**
   ```
   > how would I implement this UI design in Neovim?
   ```

3. **Debug visual issues**
   ```
   > here's a screenshot of the rendering issue
   ```

**Tips:**

- Claude can analyze UI mockups and suggest implementations
- Use screenshots to show visual bugs or desired outcomes
- Share terminal screenshots for debugging command-line tool issues
- Include multiple images for complex comparisons

## Use extended thinking

### Leverage claude's extended thinking for complex tasks

**When to use:** working on complex architectural decisions, challenging bugs, or multi-step implementations.

#### Steps

1. **Trigger extended thinking**
   ```
   > think deeply about implementing a plugin architecture for this project
   ```

2. **Intensify thinking for complex problems**
   ```
   > think harder about potential race conditions in this async code
   ```

3. **Review the thinking process**
   Claude displays its thinking in italic gray text above the response

**Best use cases:**

- Planning Neovim plugin architectures
- Debugging complex Lua coroutine issues
- Designing async/await patterns
- Evaluating performance optimizations
- Understanding complex codebases

**Tips:**

- "think" triggers basic extended thinking
- "think harder/longer/more" triggers deeper analysis
- Extended thinking is shown as italic gray text
- Best for problems requiring deep analysis

## Set up project memory

### Create an effective claude.md file

**When to use:** you want to store project-specific information and conventions for Claude.

#### Steps

1. **Bootstrap a CLAUDE.md file**
   ```
   > /init
   ```

2. **Add project-specific information**
   ```markdown
# Project: my Neovim plugin

## Essential commands

   - Run tests: `make test`
   - Lint code: `make lint`
   - Generate docs: `make docs`

## Code conventions

   - Use snake case for Lua functions
   - Prefix private functions with underscore
   - Always use plenary.nvim for testing

## Architecture notes

   - Main entry point: lua/myplugin/init.lua
   - Configuration: lua/myplugin/config.lua
   - Use vim.notify for user messages
   ```

**Tips:**

- Include frequently used commands
- Document naming conventions
- Add architectural decisions
- List important file locations
- Include debugging commands

## Set up model context protocol (mcp)

### Configure mcp for neovim development

**When to use:** You want to enhance Claude's capabilities with Neovim-specific tools and resources.

#### Steps

1. **Enable MCP in your configuration**
   ```lua
   require('claude-code').setup({
     mcp = {
       enabled = true,
       -- Optional: customize which tools/resources to enable
     }
   })
   ```

2. **Start the MCP server**
   ```vim
   :ClaudeCodeMCPStart
   ```

3. **Check MCP status**
   ```vim
   :ClaudeCodeMCPStatus
   ```
   Or within Claude: `/mcp`

**Available MCP Tools:**

- `vim_buffer` - Read/write buffer contents
- `vim_command` - Execute Vim commands
- `vim_edit` - Edit buffer content
- `vim_status` - Get editor status
- `vim_window` - Window management
- `vim_mark` - Set marks
- `vim_register` - Access registers
- `vim_visual` - Make selections
- `analyze_related` - Find related files
- `find_symbols` - LSP workspace symbols
- `search_files` - Search project files

**Available MCP Resources:**

- `neovim://current-buffer` - Active buffer content
- `neovim://buffer-list` - All open buffers
- `neovim://project-structure` - File tree
- `neovim://git-status` - Repository status
- `neovim://lsp-diagnostics` - Language server diagnostics
- `neovim://vim-options` - Configuration
- `neovim://related-files` - Import dependencies
- `neovim://recent-files` - Recently accessed files

**Tips:**

- MCP runs in headless Neovim for isolation
- Tools provide safe, controlled access to Neovim
- Resources update automatically
- The MCP server is native Lua (no external dependencies)

## Use claude as a unix-style utility

### Integrate with shell commands

**When to use:** you want to use Claude in your development workflow scripts.

#### Steps

1. **Use from the command line**
   ```bash
# Get help with an error
   cat error.log | claude --print "explain this error"

# Generate documentation
   claude --print "document this module" < mymodule.lua > docs.md
   ```

2. **Add to Neovim commands**
   ```vim
   :!git diff | claude --print "review these changes"
   ```

3. **Create custom commands**
   ```vim
   command! -range ClaudeExplain 
     \ '<,'>w !claude --print "explain this code"
   ```

**Tips:**

- Use `--print` flag for non-interactive mode
- Pipe input and output for automation
- Integrate with quickfix for error analysis
- Create Neovim commands for common tasks

## Create custom slash commands

### Neovim-specific commands

**When to use:** you want to create reusable commands for common Neovim development tasks.

#### Steps

1. **Create project commands directory**
   ```bash
   mkdir -p .claude/commands
   ```

2. **Add Neovim-specific commands**
   ```bash
# Command for plugin development
   echo "Review this Neovim plugin code for best practices. Check for:

   - Proper use of vim.api vs vim.fn
   - Correct autocommand patterns
   - Memory leak prevention
   - Performance considerations" > .claude/commands/plugin-review.md

# Command for configuration review
   echo "Review this Neovim configuration for:

   - Deprecated options
   - Performance optimizations
   - Plugin compatibility
   - Modern Lua patterns" > .claude/commands/config-review.md
   ```

3. **Use your commands**
   ```
   > /project:plugin-review
   > /project:config-review
   ```

**Tips:**

- Create commands for repetitive tasks
- Include checklist items in commands
- Use $ARGUMENTS for flexible commands
- Share useful commands with your team

## Run parallel claude code sessions

### Multi-instance development

**When to use:** You need to work on multiple features or bugs simultaneously.

#### With git multi-instance mode

1. **Enable multi-instance mode** (default)
   ```lua
   require('claude-code').setup({
     git = {
       multi_instance = true
     }
   })
   ```

2. **Work in different git repositories**
   ```bash
# Terminal 1
   cd ~/projects/frontend
   nvim
   :ClaudeCode  # Instance for frontend

# Terminal 2
   cd ~/projects/backend
   nvim
   :ClaudeCode  # Separate instance for backend
   ```

#### With neovim tabs

1. **Use different tabs for different contexts**
   ```vim
   " Tab 1: Feature development
   :tabnew
   :cd ~/project/feature-branch
   :ClaudeCode

   " Tab 2: Bug fixing
   :tabnew
   :cd ~/project/bugfix
   :ClaudeCode
   ```

**Tips:**

- Each git root gets its own Claude instance
- Instances maintain separate contexts
- Use `:ClaudeCodeToggle` to switch between instances
- Buffer names include git root for identification
- Safe toggle allows hiding without stopping

## Next steps

- Review the [Configuration Guide](CLI_CONFIGURATION.md) for customization options
- Explore [MCP Integration](MCP_INTEGRATION.md) for advanced features
- Check [CLAUDE.md](../CLAUDE.md) for project-specific setup
- Join the community for tips and best practices

