# OMNI Roadmap

Project OMNI is on a mission to redefine how AI models consume information. This roadmap outlines our phased approach to becoming the universal semantic compression layer for all AI agents.

## Phase 1: Foundation (Completed)
- [x] High-performance Zig core with Wasm target.
- [x] Initial semantic filters: Git, Build, Docker, SQL.
- [x] **Unified Native CLI**: Subcommand architecture (report, bench, generate).
- [x] MCP Server integration for Claude Code & Antigravity.
- [x] Tiered LRU + TTL caching layer.
- [x] Universal one-line installer.

## Phase 2: Intelligence Expansion (In-Progress)
- [ ] **Native Filter DSL**: Move from hardcoded filters to a lightweight declarative format.
- [ ] **Advanced Language Filters**:
  - Python (summarizing imports, class structures, and docstrings).
  - JavaScript/TypeScript (minification of runtime error traces).
  - Rust (distilling cargo build noise).
- [ ] **Adaptive Compression**: Dynamic compression ratios based on the model's remaining context window.
- [ ] **Local LLM Integration**: Use tiny local models (like Llama-3-8B) to generate ultra-dense semantic summaries for high-complexity text.

## Phase 3: Edge Scaling
- [ ] **Distributed Caching**: Shared cache across multiple agents on the same local network.
- [ ] **Streaming Distillation**: Process massive file streams in real-time without blocking the main agent execution.
- [ ] **Mobile & Browser Targets**: Compiling OMNI to pure browser Wasm for web-based IDE integration.

## Phase 4: Visuals & Ecosystem
- [ ] **OMNI Dashboard**: A lightweight local web UI to visualize token savings, latency, and system health in real-time.
- [ ] **Plugin SDK**: A standardized way for developers to write their own filters in Zig or TypeScript.
- [ ] **Vscode/JetBrains Extensions**: Bringing OMNI directly into the editor context.

---

*The window to the future is narrow; OMNI makes it wider.* 🌌
