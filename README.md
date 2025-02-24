# Claude Code Neovim Plugin

A Neovim plugin for seamless integration between [Claude Code](https://github.com/anthropics/claude-code) AI assistant and Neovim.

![Claude Code in Neovim](https://github.com/greggh/claude-code.nvim/assets/claude-code-demo.gif)

## Features

- 🚀 Toggle Claude Code in a terminal window with a single key press
- 🔄 Automatically detect and reload files modified by Claude Code
- ⚡ Real-time buffer updates when files are changed externally
- 📱 Customizable window position and size
- 🤖 Integration with which-key (if available)

## Requirements

- Neovim 0.7.0 or later
- [Claude Code CLI](https://github.com/anthropics/claude-code) tool installed and available in your PATH

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  "greggh/claude-code.nvim",
  config = function()
    require("claude-code").setup()
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'greggh/claude-code.nvim',
  config = function()
    require('claude-code').setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'greggh/claude-code.nvim'
" After installing, add this to your init.vim:
" lua require('claude-code').setup()
```

## Configuration

The plugin can be configured by passing a table to the `setup` function. Here's the default configuration:

```lua
require("claude-code").setup({
  -- Terminal window settings
  window = {
    height_ratio = 0.3,     -- Percentage of screen height for the terminal window
    position = "botright",  -- Position of the window: "botright", "topleft", etc.
    enter_insert = true,    -- Whether to enter insert mode when opening Claude Code
    hide_numbers = true,    -- Hide line numbers in the terminal window
    hide_signcolumn = true, -- Hide the sign column in the terminal window
  },
  -- File refresh settings
  refresh = {
    enable = true,           -- Enable file change detection
    updatetime = 100,        -- updatetime when Claude Code is active (milliseconds)
    timer_interval = 1000,   -- How often to check for file changes (milliseconds)
    show_notifications = true, -- Show notification when files are reloaded
  },
  -- Keymaps
  keymaps = {
    toggle = {
      normal = "<leader>ac",  -- Normal mode keymap for toggling Claude Code
      terminal = "<C-O>",     -- Terminal mode keymap for toggling Claude Code
    }
  }
})
```

## Usage

### Commands

- `:ClaudeCode` - Toggle the Claude Code terminal window

### Key Mappings

Default key mappings:

- `<leader>ac` - Toggle Claude Code terminal window (normal mode)
- `<C-O>` - Toggle Claude Code terminal window (terminal mode)

When Claude Code modifies files that are open in Neovim, they'll be automatically reloaded.

## How it Works

This plugin:

1. Creates a terminal buffer running the Claude Code CLI
2. Sets up autocommands to detect file changes on disk
3. Automatically reloads files when they're modified by Claude Code
4. Provides convenient keymaps and commands for toggling the terminal

## License

MIT License - See [LICENSE](LICENSE) for more information.

---

💻 Created by [greggh](https://github.com/greggh)