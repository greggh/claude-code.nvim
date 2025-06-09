
# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- New `split_ratio` config option to replace `height_ratio` for better handling of both horizontal and vertical splits
- Docker-based CI workflows using lua-docker images for faster builds

### Changed

- Migrated CI workflows from APT package installation to pre-built Docker containers
- Optimized CI performance by using nickblah/lua Docker images with LuaRocks pre-installed
- Simplified CI workflow by removing gating logic - all jobs now run in parallel

### Fixed

- Fixed vertical split behavior when the window position is set to a vertical split command
- Fixed slow CI builds caused by compiling Lua from source

## [0.4.2] - 2025-03-03

### Changed

- Moved documentation validation to a dedicated workflow for better standardization

### Fixed

- Fixed test runner not properly exiting after tests
- Improved which-key handling in test environment
- Fixed window focus issues in terminal split

## [0.4.1] - 2025-03-03

### Changed

- Improved GitHub workflows with consolidated documentation checks
- Enhanced release workflow with more reliable changelog generation
- Updated dependency handling in CI workflows
- Refined workflow trigger conditions for better performance

### Fixed

- Fixed deprecated changelog generator in release workflow
- Fixed documentation validation in CI pipeline
- Resolved Markdown linting and validation issues
- Improved error handling in GitHub workflows

## [0.4.0] - 2025-03-02

### Added

- GitHub Discussions integration
- Release automation workflow
- Acknowledgements section in README
- Enhanced badges and Table of Contents in README
- Comprehensive test suite with 44 tests covering all core functionality
- Terminal integration tests for Claude Code
- Git module tests for repository handling
- Keymap tests for custom key mappings

### Changed

- Improved README organization and structure
- Standardized GitHub workflow naming conventions
- Enhanced test infrastructure with accurate test counting

### Fixed

- Renamed test initialization file for consistency (minimal_init.lua → minimal-init.lua)
- Test script execution in pre-commit hooks
- References to test initialization files in documentation

## [0.3.0] - 2025-03-01

