# Installing OMNI

OMNI is designed to be installed locally and integrated into your MCP environment.

## One-Line Installation (Universal)

If you have **Zig 0.15.2** and **Node.js 18+** installed, you can set up OMNI in one step:

```bash
curl -fsSL https://raw.githubusercontent.com/fajarhide/omni/main/install.sh | sh
```

## Homebrew

Install OMNI via Homebrew:

```bash
brew install fajarhide/tap/omni
```

## Manual Installation

If you prefer to install manually:

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/fajarhide/omni.git
   cd omni
   ```

2. **Compile OMNI**:
   The project uses a `Makefile` to simplify the build process.
   ```bash
   make build
   ```
   *This compiles both the native Zig CLI, the Wasm engine, and the TypeScript MCP server.*

3. **Verify via Native CLI**:
   ```bash
   ./bin/omni --version
   ./bin/omni setup
   ```

## Update

Check for the latest version:
```bash
omni update
```
OMNI will auto-detect your installation method and suggest the right update command.

## Uninstall

Cleanly remove OMNI and all its configurations:
```bash
omni uninstall
```
This removes `~/.omni` and cleans the `omni` entry from all known MCP agent configs (Antigravity, Claude Code CLI, Claude Desktop).

## Configuration Setup

OMNI uses an additive configuration hierarchy.

1.  **Global Config**: Located at `~/.omni/omni_config.json`. This is where you should keep your general rules.
2.  **Local Config**: Create an `omni_config.json` in your project root for project-specific overrides.

Example `omni_config.json`:
```json
{
  "rules": [
    { "name": "mask_prod_db", "match": "prod-db-01", "action": "mask" }
  ]
}
```

## Integration with AI Agents

OMNI is compatible with any tool that supports the **Model Context Protocol (MCP)**.

### Claude Code / Antigravity
Use the built-in generators to auto-configure MCP:
```bash
omni generate claude-code     # For Claude Code / Claude CLI
omni generate antigravity      # For Google Antigravity
omni setup                     # Full interactive guide
```

> [!NOTE]
> When starting, you might see an `ExperimentalWarning: WASI`. This is expected! OMNI uses high-performance WebAssembly (WASI) at its core, which Node.js currently labels as experimental. It is completely safe to use.

### Cursor / Windsurf / VS Code Agents
1. Go to **Settings** or **MCP Configuration**.
2. Add a new server with the following details:
   - **Name**: `omni`
   - **Type**: `stdio` or `command`
   - **Command**: `omni-mcp`

### Generic MCP Agents
For any other agent, ensure the `node` environment is available and point the transport to OMNI's entry point: `/path/to/omni/dist/index.js`.

## Dependencies

- **Zig 0.15.2+**: Required for the high-performance core.
- **Node.js 18+**: Required for the MCP gateway.
- **Git**: Required for the installer script.
