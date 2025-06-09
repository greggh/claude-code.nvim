.PHONY: test test-debug test-legacy test-basic test-config test-mcp lint format docs clean

# Configuration
LUA_PATH ?= lua/
TEST_PATH ?= tests/
DOC_PATH ?= doc/

# Test command (runs only Plenary tests by default)
test:
	@echo "Running Plenary tests..."
	@./scripts/test.sh

# Debug test command - more verbose output
test-debug:
	@echo "Running tests in debug mode..."
	@echo "Path: $(PATH)"
	@echo "LUA_PATH: $(LUA_PATH)"
	@which nvim
	@nvim --version
	@echo "Running Plenary tests with debug output..."
	@PLENARY_DEBUG=1 ./scripts/test.sh

# Legacy test commands
test-legacy:
	@echo "Running legacy tests..."
	@nvim --headless --noplugin -u tests/legacy/minimal.vim -c "lua print('Running basic tests')" -c "source tests/legacy/basic_test.vim" -c "qa!"
	@nvim --headless --noplugin -u tests/legacy/minimal.vim -c "lua print('Running config tests')" -c "source tests/legacy/config_test.vim" -c "qa!"

# Individual test commands
test-basic:
	@echo "Running basic tests..."
	@nvim --headless --noplugin -u tests/legacy/minimal.vim -c "source tests/legacy/basic_test.vim" -c "qa!"

test-config:
	@echo "Running config tests..."
	@nvim --headless --noplugin -u tests/legacy/minimal.vim -c "source tests/legacy/config_test.vim" -c "qa!"

# MCP integration tests
test-mcp:
	@echo "Running MCP integration tests..."
	@./scripts/test_mcp.sh

# Comprehensive linting for all file types
lint: lint-lua lint-shell lint-stylua lint-markdown lint-yaml

# Lint Lua files with luacheck
lint-lua:
	@echo "Linting Lua files..."
	@if command -v luacheck > /dev/null 2>&1; then \
		luacheck $(LUA_PATH); \
	else \
		echo "luacheck not found. Install with: luarocks install luacheck"; \
		exit 1; \
	fi

# Check Lua formatting with stylua
lint-stylua:
	@echo "Checking Lua formatting..."
	@if command -v stylua > /dev/null 2>&1; then \
		stylua --check $(LUA_PATH); \
	else \
		echo "stylua not found. Install with: cargo install stylua"; \
		exit 1; \
	fi

# Lint shell scripts with shellcheck
lint-shell:
	@echo "Linting shell scripts..."
	@if command -v shellcheck > /dev/null 2>&1; then \
		find . -name "*.sh" -type f ! -path "./.git/*" ! -path "./node_modules/*" ! -path "./.vscode/*" -print0 | \
		xargs -0 -I {} sh -c 'echo "Checking {}"; shellcheck "{}"'; \
	else \
		echo "shellcheck not found. Install with your package manager (apt install shellcheck, brew install shellcheck, etc.)"; \
		exit 1; \
	fi

# Lint markdown files
lint-markdown:
	@echo "Linting markdown files..."
	@if command -v vale > /dev/null 2>&1; then \
		if [ ! -d ".vale/styles/Google" ]; then \
			echo "Downloading Vale style packages..."; \
			vale sync; \
		fi; \
		vale *.md docs/*.md doc/*.md .github/**/*.md; \
	else \
		echo "vale not found. Install with: make install-dependencies"; \
		exit 1; \
	fi

# Lint YAML files
lint-yaml:
	@echo "Linting YAML files..."
	@if command -v yamllint > /dev/null 2>&1; then \
		yamllint .; \
	else \
		echo "yamllint not found. Install with: pip install yamllint"; \
		exit 1; \
	fi

# Format Lua files with stylua
format:
	@echo "Formatting Lua files..."
	@stylua $(LUA_PATH)

# Generate documentation
docs:
	@echo "Generating documentation..."
	@if command -v ldoc > /dev/null 2>&1; then \
		ldoc $(LUA_PATH) -d $(DOC_PATH)luadoc -c .ldoc.cfg || true; \
	else \
		echo "ldoc not installed. Skipping documentation generation."; \
	fi

# Check if development dependencies are installed
check-dependencies:
	@echo "Checking development dependencies..."
	@echo "=================================="
	@failed=0; \
	echo "Essential tools:"; \
	if command -v nvim > /dev/null 2>&1; then \
		echo "  ✓ neovim: $$(nvim --version | head -1)"; \
	else \
		echo "  ✗ neovim: not found"; \
		failed=1; \
	fi; \
	if command -v lua > /dev/null 2>&1 || command -v lua5.1 > /dev/null 2>&1 || command -v lua5.3 > /dev/null 2>&1; then \
		lua_ver=$$(lua -v 2>/dev/null || lua5.1 -v 2>/dev/null || lua5.3 -v 2>/dev/null || echo "unknown version"); \
		echo "  ✓ lua: $$lua_ver"; \
	else \
		echo "  ✗ lua: not found"; \
		failed=1; \
	fi; \
	if command -v luarocks > /dev/null 2>&1; then \
		echo "  ✓ luarocks: $$(luarocks --version | head -1)"; \
	else \
		echo "  ✗ luarocks: not found"; \
		failed=1; \
	fi; \
	echo; \
	echo "Linting tools:"; \
	if command -v luacheck > /dev/null 2>&1; then \
		echo "  ✓ luacheck: $$(luacheck --version)"; \
	else \
		echo "  ✗ luacheck: not found"; \
		failed=1; \
	fi; \
	if command -v stylua > /dev/null 2>&1; then \
		echo "  ✓ stylua: $$(stylua --version)"; \
	else \
		echo "  ✗ stylua: not found"; \
		failed=1; \
	fi; \
	if command -v shellcheck > /dev/null 2>&1; then \
		echo "  ✓ shellcheck: $$(shellcheck --version | grep version:)"; \
	else \
		echo "  ✗ shellcheck: not found"; \
		failed=1; \
	fi; \
	if command -v vale > /dev/null 2>&1; then \
		echo "  ✓ vale: $$(vale --version | head -1)"; \
	else \
		echo "  ✗ vale: not found"; \
		failed=1; \
	fi; \
	if command -v yamllint > /dev/null 2>&1; then \
		echo "  ✓ yamllint: $$(yamllint --version)"; \
	else \
		echo "  ✗ yamllint: not found"; \
		failed=1; \
	fi; \
	echo; \
	echo "Optional tools:"; \
	if command -v ldoc > /dev/null 2>&1; then \
		echo "  ✓ ldoc: available"; \
	else \
		echo "  ○ ldoc: not found (optional for documentation)"; \
	fi; \
	if command -v git > /dev/null 2>&1; then \
		echo "  ✓ git: $$(git --version)"; \
	else \
		echo "  ○ git: not found (recommended)"; \
	fi; \
	echo; \
	if [ $$failed -eq 0 ]; then \
		echo "✅ All required dependencies are installed!"; \
	else \
		echo "❌ Some dependencies are missing. Run 'make install-dependencies' to install them."; \
		exit 1; \
	fi

# Install development dependencies
install-dependencies:
	@echo "Installing development dependencies..."
	@echo "====================================="
	@echo "Detecting package manager and installing dependencies..."
	@echo
	@if command -v brew > /dev/null 2>&1; then \
		echo "🍺 Detected Homebrew - Installing macOS dependencies"; \
		brew install neovim lua luarocks shellcheck stylua vale; \
		luarocks install luacheck; \
		luarocks install ldoc; \
	elif command -v apt > /dev/null 2>&1 || command -v apt-get > /dev/null 2>&1; then \
		echo "🐧 Detected APT - Installing Ubuntu/Debian dependencies"; \
		sudo apt update; \
		sudo apt install -y neovim lua5.3 luarocks shellcheck; \
		if ! command -v vale > /dev/null 2>&1; then \
			echo "Installing vale..."; \
			wget https://github.com/errata-ai/vale/releases/download/v3.0.3/vale_3.0.3_Linux_64-bit.tar.gz && \
			tar -xzf vale_3.0.3_Linux_64-bit.tar.gz && \
			sudo mv vale /usr/local/bin/ && \
			rm vale_3.0.3_Linux_64-bit.tar.gz; \
		fi; \
		luarocks install luacheck; \
		luarocks install ldoc; \
		if command -v cargo > /dev/null 2>&1; then \
			cargo install stylua; \
		else \
			echo "Installing Rust for stylua..."; \
			curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; \
			source ~/.cargo/env; \
			cargo install stylua; \
		fi; \
	elif command -v dnf > /dev/null 2>&1; then \
		echo "🎩 Detected DNF - Installing Fedora dependencies"; \
		sudo dnf install -y neovim lua luarocks ShellCheck; \
		if ! command -v vale > /dev/null 2>&1; then \
			echo "Installing vale..."; \
			wget https://github.com/errata-ai/vale/releases/download/v3.0.3/vale_3.0.3_Linux_64-bit.tar.gz && \
			tar -xzf vale_3.0.3_Linux_64-bit.tar.gz && \
			sudo mv vale /usr/local/bin/ && \
			rm vale_3.0.3_Linux_64-bit.tar.gz; \
		fi; \
		luarocks install luacheck; \
		luarocks install ldoc; \
		if command -v cargo > /dev/null 2>&1; then \
			cargo install stylua; \
		else \
			echo "Installing Rust for stylua..."; \
			curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; \
			source ~/.cargo/env; \
			cargo install stylua; \
		fi; \
	elif command -v pacman > /dev/null 2>&1; then \
		echo "🏹 Detected Pacman - Installing Arch Linux dependencies"; \
		sudo pacman -S --noconfirm neovim lua luarocks shellcheck; \
		if command -v yay > /dev/null 2>&1; then \
			yay -S --noconfirm vale; \
		elif command -v paru > /dev/null 2>&1; then \
			paru -S --noconfirm vale; \
		else \
			echo "Installing vale from binary..."; \
			wget https://github.com/errata-ai/vale/releases/download/v3.0.3/vale_3.0.3_Linux_64-bit.tar.gz && \
			tar -xzf vale_3.0.3_Linux_64-bit.tar.gz && \
			sudo mv vale /usr/local/bin/ && \
			rm vale_3.0.3_Linux_64-bit.tar.gz; \
		fi; \
		luarocks install luacheck; \
		luarocks install ldoc; \
		if command -v yay > /dev/null 2>&1; then \
			yay -S --noconfirm stylua; \
		elif command -v paru > /dev/null 2>&1; then \
			paru -S --noconfirm stylua; \
		elif command -v cargo > /dev/null 2>&1; then \
			cargo install stylua; \
		else \
			echo "Installing Rust for stylua..."; \
			curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; \
			source ~/.cargo/env; \
			cargo install stylua; \
		fi; \
	else \
		echo "❌ No supported package manager found"; \
		echo "Supported platforms:"; \
		echo "  🍺 macOS: Homebrew (brew)"; \
		echo "  🐧 Ubuntu/Debian: APT (apt/apt-get)"; \
		echo "  🎩 Fedora: DNF (dnf)"; \
		echo "  🏹 Arch Linux: Pacman (pacman)"; \
		echo ""; \
		echo "Manual installation required:"; \
		echo "  1. neovim (https://neovim.io/)"; \
		echo "  2. lua + luarocks (https://luarocks.org/)"; \
		echo "  3. shellcheck (https://shellcheck.net/)"; \
		echo "  4. stylua: cargo install stylua"; \
		echo "  5. vale: https://github.com/errata-ai/vale/releases"; \
		echo "  6. luacheck: luarocks install luacheck"; \
		exit 1; \
	fi; \
	echo; \
	echo "✅ Installation complete! Verifying..."; \
	$(MAKE) check-dependencies

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	@rm -rf $(DOC_PATH)luadoc

# Default target
all: lint format test docs

help:
	@echo "Claude Code development commands:"
	@echo "  make test         - Run all tests (using Plenary test framework)"
	@echo "  make test-debug   - Run all tests with debug output"
	@echo "  make test-mcp     - Run MCP integration tests"
	@echo "  make test-legacy  - Run legacy tests (VimL-based)"
	@echo "  make test-basic   - Run only basic functionality tests (legacy)"
	@echo "  make test-config  - Run only configuration tests (legacy)"
	@echo "  make lint         - Run comprehensive linting (Lua, shell, markdown)"
	@echo "  make lint-lua     - Lint only Lua files with luacheck"
	@echo "  make lint-stylua  - Check Lua formatting with stylua"
	@echo "  make lint-shell   - Lint shell scripts with shellcheck"
	@echo "  make lint-markdown - Lint markdown files with vale"
	@echo "  make lint-yaml    - Lint YAML files with yamllint"
	@echo "  make format       - Format Lua files with stylua"
	@echo "  make docs         - Generate documentation"
	@echo "  make clean        - Remove generated files"
	@echo "  make all          - Run lint, format, test, and docs"
	@echo ""
	@echo "Development setup:"
	@echo "  make check-dependencies   - Check if dev dependencies are installed"
	@echo "  make install-dependencies - Install missing dev dependencies"