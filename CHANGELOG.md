# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-03-15

### Added
- **Unified Native CLI**: Replaced shell scripts with high-performance native subcommands.
- Subcommands: `omni distill`, `omni density`, `omni report`, `omni bench`, `omni generate`, `omni setup`.
- **Agent Templates**: Support for generating Antigravity and Claude Code input templates.
- **Zig Build System**: Fully integrated `build.zig` for cross-platform native and Wasm builds.

### Changed
- Moved all legacy shell scripts to `scripts/legacy/`.
- Updated `install.sh` to use the native build pipeline.

## [0.1.3] - 2026-03-15

### Fixed
- Zig 0.15.2 IO API transition: Replaced removed `std.io.getStdOut/getStdIn` with `std.fs.File` equivalents.
- Native build failure on Homebrew environment.

## [0.1.2] - 2026-03-15

## [0.1.1] - 2026-03-15

## [0.1.0] - 2026-03-14

### Added
- Initial Zig core engine implementation.
- Basic Git and Build log filters.
- MCP Server gateway in TypeScript.
- Custom JSON-based rules for masking/removal.

---
*Follow the 🌌 OMNI vision.*
