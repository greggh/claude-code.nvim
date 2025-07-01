# Project: Rovo Dev Plugin

## Overview

Rovo Dev Plugin provides seamless integration between the Rovo Dev AI assistant and Neovim. It enables direct communication with the Rovo Dev CLI from within the editor, context-aware interactions, and various utilities to enhance AI-assisted development within Neovim.

## Essential Commands

- Run Tests: `env -C /home/gregg/Projects/neovim/plugins/rovo-dev lua tests/run_tests.lua`
- Check Formatting: `env -C /home/gregg/Projects/neovim/plugins/rovo-dev stylua lua/ -c`
- Format Code: `env -C /home/gregg/Projects/neovim/plugins/rovo-dev stylua lua/`
- Run Linter: `env -C /home/gregg/Projects/neovim/plugins/rovo-dev luacheck lua/`
- Build Documentation: `env -C /home/gregg/Projects/neovim/plugins/rovo-dev mkdocs build`

## Project Structure

- `/lua/rovo-dev`: Main plugin code
- `/lua/rovo-dev/cli`: Rovo Dev CLI integration
- `/lua/rovo-dev/ui`: UI components for interactions
- `/lua/rovo-dev/context`: Context management utilities
- `/after/plugin`: Plugin setup and initialization
- `/tests`: Test files for plugin functionality
- `/doc`: Vim help documentation

## Current Focus

- Integrating nvim-toolkit for shared utilities
- Adding hooks-util as git submodule for development workflow
- Enhancing bidirectional communication with Rovo Dev CLI
- Implementing better context synchronization
- Adding buffer-specific context management

## Multi-Instance Support

The plugin supports running multiple Rovo Dev instances, one per git repository root:

- Each git repository maintains its own Rovo instance
- Works across multiple Neovim tabs with different projects
- Allows working on multiple projects in parallel
- Configurable via `git.multi_instance` option (defaults to `true`)
- Instances remain in their own directory context when switching between tabs
- Buffer names include the git root path for easy identification

Example configuration to disable multi-instance mode:

```lua
require('rovo-dev').setup({
  git = {
    multi_instance = false  -- Use a single global Rovo instance
  }
})
```

## Documentation Links

- Tasks: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/tasks/rovo-dev-tasks.md`
- Project Status: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/project-status.md`
