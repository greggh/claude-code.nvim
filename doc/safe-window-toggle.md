
# Safe window toggle

## Overview

The Safe Window Toggle feature prevents accidental interruption of Claude Code processes when toggling window visibility. This addresses a common UX issue where users would close the Claude Code window and unintentionally stop ongoing tasks.

## Problem solved

Previously, using `:ClaudeCode` to hide a visible Claude Code window would forcefully close the terminal and stop any running process. This was problematic when:

- Claude Code was processing a long-running task
- Users wanted to temporarily hide the window to see other content
- Switching between projects while keeping Claude Code running

## Features

### Safe window management

- **Hide without termination** - Close the window but keep the process running in background
- **Show hidden windows** - Restore previously hidden Claude Code windows
- **Process state tracking** - Monitor whether Claude Code is running, finished, or hidden
- **User notifications** - Inform users about process state changes

### Multi-instance support

- Works with both single instance and multi-instance modes
- Each git repository can have its own Claude Code process state
- Independent state tracking for multiple projects

### Status monitoring

- Check current process status
- List all running instances across projects
- Detect when hidden processes complete

## Commands

### Core commands

- `:ClaudeCodeSafeToggle` - Main safe toggle command
- `:ClaudeCodeHide` - Alias for hiding (calls safe toggle)
- `:ClaudeCodeShow` - Alias for showing (calls safe toggle)

### Status commands

- `:ClaudeCodeStatus` - Show current instance status
- `:ClaudeCodeInstances` - List all instances and their states

## Usage examples

### Basic safe toggle

```vim
" Hide Claude Code window but keep process running
:ClaudeCodeHide

" Show Claude Code window if hidden
:ClaudeCodeShow

" Smart toggle - hides if visible, shows if hidden
:ClaudeCodeSafeToggle

```text

### Status checking

```vim
" Check current process status
:ClaudeCodeStatus
" Output: "Claude Code running (hidden)" or "Claude Code running (visible)"

" List all instances across projects
:ClaudeCodeInstances
" Output: Lists all git roots with their Claude Code states

```text

### Multi-project workflow

```vim
" Project A - start Claude Code
:ClaudeCode

" Hide window to work on something else
:ClaudeCodeHide

" Switch to Project B tab
" Start separate Claude Code instance
:ClaudeCode

" Check all running instances
:ClaudeCodeInstances
" Shows both Project A (hidden) and Project B (visible)

```text

## Implementation details

### Process state tracking

The plugin maintains state for each Claude Code instance:

```lua
process_states = {
  [instance_id] = {
    status = "running" | "finished" | "unknown",
    hidden = true | false,
    last_updated = timestamp
  }
}

```text

### Window detection

- Uses `vim.fn.win_findbuf()` to check window visibility
- Distinguishes between "buffer exists" and "window visible"
- Gracefully handles externally deleted buffers

### Notifications

- **Hide**: "Claude Code hidden - process continues in background"
- **Show**: "Claude Code window restored"
- **Completion**: "Claude Code task completed while hidden"

## Technical implementation

### Core functions

#### `safe_toggle(claude_code, config, git)`
Main function that handles safe window toggling logic.

#### `get_process_status(claude_code, instance_id)`
Returns detailed status information for a Claude Code instance.

#### `list_instances(claude_code)`
Returns array of all active instances with their states.

### Helper functions

#### `is_process_running(job_id)`
Uses `vim.fn.jobwait()` with zero timeout to check if process is active.

#### `update_process_state(claude_code, instance_id, status, hidden)`
Updates the tracked state for a specific instance.

#### `cleanup_invalid_instances(claude_code)`
Removes entries for deleted or invalid buffers.

## Testing

The feature includes comprehensive TDD tests covering:

- **Hide/Show Behavior** - Window management without process termination
- **Process State Management** - State tracking and updates
- **User Notifications** - Appropriate messaging for different scenarios
- **Multi-Instance Behavior** - Independent operation across projects
- **Edge Cases** - Buffer deletion, rapid toggling, invalid states

Run tests:

```bash
nvim --headless -c "lua require('tests.run_tests').run_specific('safe_window_toggle_spec')" -c "qall"

```text

## Configuration

No additional configuration is required. The safe window toggle uses existing configuration settings:

- `git.multi_instance` - Controls single vs multi-instance behavior
- `git.use_git_root` - Determines instance identifier strategy
- `window.*` - Window creation and positioning settings

## Migration from regular toggle

The regular `:ClaudeCode` command continues to work as before. Users who want the safer behavior can:

1. **Use safe commands directly**: `:ClaudeCodeSafeToggle`
2. **Remap existing keybindings**: Update keymaps to use `safe_toggle` instead of `toggle`
3. **Create custom keybindings**: Add specific mappings for hide/show operations

## Best practices

### When to use safe toggle

- **Long-running tasks** - When Claude Code is processing large requests
- **Multi-window workflows** - Switching focus between windows frequently
- **Project switching** - Working on multiple codebases simultaneously

### When regular toggle is fine

- **Starting new sessions** - No existing process to preserve
- **Intentional termination** - When you want to stop Claude Code completely
- **Quick interactions** - Brief, fast-completing requests

## Troubleshooting

### Window won't show
If `:ClaudeCodeShow` doesn't work:

1. Check status with `:ClaudeCodeStatus`
2. Verify buffer still exists
3. Try `:ClaudeCodeSafeToggle` instead

### Process state issues
If state tracking seems incorrect:

1. Use `:ClaudeCodeInstances` to see all tracked instances
2. Invalid buffers are automatically cleaned up
3. Restart Neovim to reset all state if needed

### Multiple instances confusion
When working with multiple projects:

1. Use `:ClaudeCodeInstances` to see all running instances
2. Each git root maintains separate state
3. Buffer names include project path for identification

