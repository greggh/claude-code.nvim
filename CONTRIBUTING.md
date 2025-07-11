# Contributing to claude-Code.nvim

Thank you for your interest in contributing to Claude-Code.nvim! This document provides guidelines and instructions to help you contribute effectively.

## Code of conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone.

## Ways to contribute

There are several ways you can contribute to Claude-Code.nvim:

- Reporting bugs
- Suggesting enhancements
- Submitting pull requests
- Improving documentation
- Sharing your experience using the plugin

## Reporting issues

Before submitting an issue, please:

1. Check if the issue already exists in the [issues section](https://github.com/greggh/claude-code.nvim/issues)
2. Use the issue template if available
3. Include as much relevant information as possible:
   - Neovim version
   - Claude Code command-line tool version
   - Operating system
   - Steps to reproduce the issue
   - Expected vs. actual behavior
   - Any error messages or logs

## Pull request process

1. Fork the repository
2. Create a new branch for your changes
3. Make your changes, following the coding standards below
4. Test your changes thoroughly
5. Submit a pull request with a clear description of the changes

For significant changes, please open an issue first to discuss your proposed changes.

## Development setup

### Requirements

#### Core dependencies

- **Neovim**: Version 0.10.0 or higher
  - Required for `vim.system()`, splitkeep, and modern LSP features
- **Git**: For version control
- **Make**: For running development commands

#### Development tools

- **stylua**: Lua code formatter
- **luacheck**: Lua linter
- **ripgrep**: Used for searching (optional but recommended)
- **fd**: Used for finding files (optional but recommended)

### Installation instructions

#### Linux

##### Ubuntu/Debian

```bash
# Install neovim (from ppa for latest version)
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

##### Arch Linux

```bash
# Install dependencies
sudo pacman -S neovim luarocks ripgrep fd git make

# Install luacheck
sudo luarocks install luacheck

# Install stylua (from aur)
yay -S stylua
```

##### Fedora

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

#### macOS

```bash
# Install homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install neovim luarocks ripgrep fd git make

# Install luacheck
luarocks install luacheck

# Install stylua
brew install stylua
```

#### Windows

##### Using Scoop

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

##### Using Chocolatey

```powershell
# Install chocolatey if not already installed
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install dependencies
choco install neovim git make ripgrep fd

# Install luarocks
choco install luarocks

# Install luacheck
luarocks install luacheck

# Install stylua (download from github)
# Visit https://github.com/johnnymorganz/stylua/releases
```

### Setting up the development environment

1. Clone your fork of the repository:

   ```bash
   git clone https://github.com/YOUR_USERNAME/claude-code.nvim.git
   cd claude-code.nvim
   ```

2. Set up Git hooks for automatic code formatting:

   ```bash
   ./scripts/setup-hooks.sh
   ```

3. Link the repository to your Neovim plugins directory or use your plugin manager's development mode

4. Make sure you have the Claude Code command-line tool installed and properly configured

### Development workflow

#### Common development tasks

- **Run tests**: `make test`
- **Run linting**: `make lint`
- **Format code**: `make format`
- **View available commands**: `make help`

#### Pre-commit hooks

The pre-commit hook automatically runs:

1. Code formatting with stylua
2. Linting with luacheck
3. Basic tests

If you need to bypass these checks, use:

```bash
git commit --no-verify
```

## Coding standards

- Follow the existing code style and structure
- Use meaningful variable and function names
- Write clear comments for complex logic
- Keep functions focused and modular
- Add appropriate documentation for new features

## Lua style guide

We use [StyLua](https://github.com/JohnnyMorganz/StyLua) to enforce consistent formatting of the codebase. The formatting is done automatically via pre-commit hooks if you've set them up using the script provided.

Key style guidelines:

- Configuration is in `stylua.toml` at the project root
- Maximum line length is 120 characters
- Use 2 spaces for indentation
- Use local variables when possible
- Group related functions together
- Follow existing naming conventions:
  - `snake_case` for variables and functions
  - `PascalCase` for classes and constructors

Files are linted using [LuaCheck](https://github.com/mpeterv/luacheck) according to `.luacheckrc`.

## Testing

Before submitting your changes, please test them thoroughly:

### Running tests

You can run the test suite using the Makefile:

```bash
# Run all tests
make test

# Run with verbose output
make test-debug

# Run specific test groups
make test-basic    # Run basic functionality tests
make test-config   # Run configuration tests
make test-mcp      # Run MCP integration tests
```

See `test/README.md` and `tests/README.md` for more details on the different test types.

### Writing tests

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

### Manual testing

- Test in different environments (Linux, macOS, Windows if possible)
- Test with different configurations
- Test the integration with the Claude Code command-line tool
- Use the minimal test configuration (`tests/minimal-init.lua`) to verify your changes in isolation

### Project structure

```
.
├── .github/            # GitHub-specific files and workflows
├── .githooks/          # Git hooks for pre-commit validation
├── lua/                # Main Lua source code
│   └── claude-code/    # Project-specific modules
├── test/               # Basic test modules
├── tests/              # Extended test suites
├── .luacheckrc         # LuaCheck configuration
├── stylua.toml         # StyLua configuration
├── Makefile            # Common commands
├── CHANGELOG.md        # Project version history
└── README.md           # Project overview
```

### Continuous integration

This project uses GitHub Actions for CI:

- **Triggers**: Push to main branch, Pull Requests to main
- **Jobs**: Install dependencies, Run linting, Run tests
- **Platforms**: Ubuntu Linux (primary)

### Troubleshooting

#### Common issues

- **stylua not found**: Make sure it's installed and in your PATH
- **luacheck errors**: Run `make lint` to see specific issues
- **Test failures**: Use `make test-debug` for detailed output
- **Module not found errors**: Check that you're using the correct module name and path
- **Plugin functionality not loading**: Verify your Neovim version is 0.10.0 or higher

#### Getting help

If you encounter issues:

1. Check the error messages carefully
2. Verify all dependencies are correctly installed
3. Check that your Neovim version is 0.10.0 or higher
4. Review the project's issues on GitHub for similar problems
5. Open a new issue with detailed reproduction steps if needed

## Documentation

When adding new features, please update the documentation:

- Update README.md with any new features, configurations, or dependencies
- Update the Neovim help documentation in doc/claude-code.txt
- Include examples of how to use the new features

## License

By contributing to Claude-Code.nvim, you agree that your contributions will be licensed under the project's MIT license.

## Questions?

If you have any questions about contributing, please open an issue with your question.

Thank you for contributing to Claude-Code.nvim!
