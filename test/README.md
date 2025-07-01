# Rovo Dev Automated Tests

This directory contains the automated test setup for Rovo Dev plugin.

## Test Structure

- **minimal.vim**: A minimal Neovim configuration for automated testing
- **basic_test.vim**: A simple test script that verifies the plugin loads correctly
- **config_test.vim**: Tests for the configuration validation and merging functionality

## Running Tests

To run all tests:

```bash
make test
```

For more verbose output:

```bash
make test-debug
```

### Running Individual Tests

You can run specific test groups:

```bash
make test-basic  # Run only the basic functionality tests
make test-config  # Run only the configuration tests
```

## CI Integration

The tests are integrated with GitHub Actions CI, which runs tests against multiple Neovim versions:

- Neovim 0.8.0
- Neovim 0.9.0
- Neovim stable
- Neovim nightly

This ensures compatibility across different Neovim versions.

## Test Coverage

### Current Status

The test suite provides coverage for:

1. **Basic Functionality (`basic_test.vim`)**
   - Plugin loading
   - Module structure verification
   - Basic API availability

2. **Configuration (`config_test.vim`)**
   - Default configuration validation
   - User configuration validation
   - Configuration merging
   - Error handling

### Future Plans

We plan to expand the tests to include:

1. Integration tests for terminal communication
2. Command functionality tests
3. Keymapping tests
4. Git integration tests

## Writing New Tests

When adding new functionality, please add corresponding tests following the same pattern as the existing tests:

1. Create a new test file in the test directory (e.g., `feature_test.vim`)
2. Add a new target to the Makefile
3. Update the CI workflow if needed

All tests should:

- Be self-contained and independent
- Provide clear pass/fail output
- Exit with an error code on failure
