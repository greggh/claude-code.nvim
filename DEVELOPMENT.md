# Development Guide for Neovim Projects

This document outlines the development workflow, testing setup, and requirements for working with Neovim Lua projects such as this configuration, Laravel Helper plugin, and Claude Code plugin.

## Requirements

### Core Dependencies

- **Neovim**: Version 0.10.0 or higher
  - Required for `vim.system()`, splitkeep, and modern LSP features
- **Git**: For version control
- **Make**: For running development commands

### Development Tools

- **stylua**: Lua code formatter
- **luacheck**: Lua linter
- **ripgrep**: Used for searching (optional but recommended)
- **fd**: Used for finding files (optional but recommended)

## Installation Instructions

### Linux

#### Ubuntu/Debian

```bash
# Install Neovim (from PPA for latest version)
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt-get update
sudo apt-get install neovim

# Install luarocks and other dependencies
sudo apt-get install luarocks ripgrep fd-find git make

# Install luacheck
sudo luarocks install luacheck

# Install stylua
curl -L -o stylua.zip $(curl -s https://api.github.com/repos/JohnnyMorganz/StyLua/releases/latest | grep -o "https://.*stylua-linux-x86_64.zip")
unzip stylua.zip
chmod +x stylua
sudo mv stylua /usr/local/bin/
```

#### Arch Linux

```bash
# Install dependencies
sudo pacman -S neovim luarocks ripgrep fd git make

# Install luacheck
sudo luarocks install luacheck

# Install stylua (from AUR)
yay -S stylua
```

#### Fedora

```bash
# Install dependencies
sudo dnf install neovim luarocks ripgrep fd-find git make

# Install luacheck
sudo luarocks install luacheck

# Install stylua
curl -L -o stylua.zip $(curl -s https://api.github.com/repos/JohnnyMorganz/StyLua/releases/latest | grep -o "https://.*stylua-linux-x86_64.zip")
unzip stylua.zip
chmod +x stylua
sudo mv stylua /usr/local/bin/
```

### macOS

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install neovim luarocks ripgrep fd git make

# Install luacheck
luarocks install luacheck

# Install stylua
brew install stylua
```

### Windows

#### Using scoop

```powershell
# Install scoop if not already installed
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# Install dependencies
scoop install neovim git make ripgrep fd

# Install luarocks
scoop install luarocks

# Install luacheck
luarocks install luacheck

# Install stylua
scoop install stylua
```

#### Using chocolatey

```powershell
# Install chocolatey if not already installed
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install dependencies
choco install neovim git make ripgrep fd

# Install luarocks
choco install luarocks

# Install luacheck
luarocks install luacheck

# Install stylua (download from GitHub)
# Visit https://github.com/JohnnyMorganz/StyLua/releases
```

## Development Workflow

### Setting Up the Environment

1. Clone the repository:

   ```bash
   git clone https://github.com/greggh/claude-code.nvim.git
   ```

2. Install Git hooks:

   ```bash
   cd claude-code.nvim
   ./scripts/setup-hooks.sh
   ```

### Common Development Tasks

- **Run tests**: `make test`
- **Run linting**: `make lint`
- **Format code**: `make format`
- **View available commands**: `make help`

### Pre-commit Hooks

The pre-commit hook automatically runs:

1. Code formatting with stylua
2. Linting with luacheck
3. Basic tests

If you need to bypass these checks, use:

```bash
git commit --no-verify
```

## Testing

### Running Tests

```bash
# Run all tests
make test

# Run with verbose output
make test-verbose

# Run specific test suites
make test-basic
make test-config
```

### Running Tests from Within Neovim/Claude Code

When running tests from within a Neovim instance (such as when using Claude Code via claude-code.nvim), the test script automatically handles the `$NVIM` environment variable which normally points to a socket file instead of the nvim executable.

The test script will:

- Use the `$NVIM` variable if it points to a valid executable file
- Fall back to finding `nvim` in `$PATH` if `$NVIM` points to a socket or invalid path
- Display which nvim binary is being used for transparency

To verify the NVIM detection logic works correctly, you can run:

```bash
./scripts/test_nvim_detection.sh
```

### Writing Tests

Tests are written in Lua using a simple BDD-style API:

```lua
local test = require("tests.run_tests")

test.describe("Feature name", function()
  test.it("should do something", function()
    -- Test code
    test.expect(result).to_be(expected)
  end)
end)
```

## Continuous Integration

This project uses GitHub Actions for CI:

- **Triggers**: Push to main branch, Pull Requests to main
- **Jobs**: Install dependencies, Run linting, Run tests
- **Platforms**: Ubuntu Linux (primary)

## Tools and Their Purposes

Understanding why we use each tool helps in appreciating their role in the development process:

### Neovim

Neovim is the primary development platform and runtime environment. We use version 0.10.0+ because it provides:

- Better API support for plugin development
- Improved performance for larger codebases
- Enhanced LSP integration
- Support for modern Lua features via LuaJIT

### StyLua

StyLua is a Lua formatter specifically designed for Neovim configurations. It:

- Ensures consistent code style across all contributors
- Formats according to Lua best practices
- Handles Neovim-specific formatting conventions
- Integrates with our pre-commit hooks for automated formatting

Our configuration uses 2-space indentation and 100-character line length limits.

### LuaCheck

LuaCheck is a static analyzer that helps catch issues before they cause problems:

- Identifies syntax errors and semantic issues
- Flags unused variables and unused function parameters
- Detects global variable access without declaration
- Warns about whitespace and style issues
- Ensures code adheres to project-specific standards

We configure LuaCheck with `.luacheckrc` files that define project-specific globals and rules.

### Ripgrep & FD

These tools improve development efficiency:

- **Ripgrep**: Extremely fast code searching to find patterns and references
- **FD**: Fast alternative to `find` for locating files in complex directory structures

### Git & Make

- **Git**: Version control with support for feature branches and collaborative development
- **Make**: Common interface for development tasks that work across different platforms

## Project Structure

All our Neovim projects follow a similar structure:

```plaintext
```

.
├── .github/            # GitHub-specific files and workflows
├── .githooks/          # Git hooks for pre-commit validation
├── lua/                # Main Lua source code
│   └── [project-name]/ # Project-specific modules
├── test/               # Basic test modules
├── tests/              # Extended test suites
├── .luacheckrc         # LuaCheck configuration

```plaintext
```

├── .stylua.toml        # StyLua configuration
├── Makefile            # Common commands
├── CHANGELOG.md        # Project version history
└── README.md           # Project overview

```plaintext
```

## Troubleshooting

### Common Issues

- **stylua not found**: Make sure it's installed and in your PATH
- **luacheck errors**: Run `make lint` to see specific issues
- **Test failures**: Use `make test-verbose` for detailed output
- **Module not found errors**: Check that you're using the correct module name and path
- **Plugin functionality not loading**: Verify your Neovim version is 0.10.0 or higher

### Getting Help

If you encounter issues:

1. Check the error messages carefully
2. Verify all dependencies are correctly installed
3. Check that your Neovim version is 0.10.0 or higher
4. Review the project's issues on GitHub for similar problems
5. Open a new issue with detailed reproduction steps if needed
