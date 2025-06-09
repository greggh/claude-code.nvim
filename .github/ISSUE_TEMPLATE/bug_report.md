---
name: Bug report
about: Create a report to help improve Claude-Code.nvim
title: '[BUG] '
labels: bug
assignees: ''
---

 ## bug description

A clear and concise description of what the bug is.

 ## steps to reproduce

1. Go to '...'
2. Run command '....'
3. See error

 ## expected behavior

A clear and concise description of what you expected to happen.

 ## screenshots

If applicable, add screenshots to help explain your problem.

 ## environment

- OS: [for example, Ubuntu 22.04, macOS 13.0, Windows 11]
- Neovim version: [for example, 0.9.0]
- Claude Code command-line tool version: [for example, 1.0.0]
- Plugin version or commit hash: [for example, main branch as of date]

 ## plugin configuration

```lua
-- Your Claude-Code.nvim configuration here
require("claude-code").setup({
  -- Your configuration options
})

```text

 ## additional context

Add any other context about the problem here, such as:

- Error messages from Neovim (:messages)
- Logs from the Claude Code terminal
- Any recent changes to your setup

 ## minimal reproduction

For faster debugging, try to reproduce the issue using our minimal configuration:

1. Create a new directory for testing
2. Copy `tests/minimal-init.lua` from this repo to your test directory
3. Start Neovim with this minimal config:
   ```bash
   nvim --clean -u minimal-init.lua
   ```

4. Try to reproduce the issue with this minimal setup

