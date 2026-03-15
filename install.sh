#!/bin/sh
# OMNI Installer - Semantic Distillation Engine
# https://github.com/fajarhide/omni
# Usage: curl -fsSL https://raw.githubusercontent.com/fajarhide/omni/main/install.sh | sh

set -e

REPO="fajarhide/omni"
INSTALL_DIR="${OMNI_INSTALL_DIR:-$HOME/omni}"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { printf "${GREEN}[INFO]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; exit 1; }

echo "${BLUE}🌌 Welcome to the OMNI Installer${NC}"
echo "════════════════════════════════════════════"

# 1. Dependency Check
info "Checking dependencies..."
if ! command -v zig >/dev/null 2>&1; then
    error "Zig 0.15.2+ is required. Please install it from ziglang.org."
fi

if ! command -v node >/dev/null 2>&1; then
    error "Node.js 18+ is required. Please install it from nodejs.org."
fi

if ! command -v git >/dev/null 2>&1; then
    error "Git is required to clone the repository."
fi

# 2. Clone
if [ -d "$INSTALL_DIR" ]; then
    warn "Directory $INSTALL_DIR already exists. Updating..."
    cd "$INSTALL_DIR" && git pull
else
    info "Cloning OMNI to $INSTALL_DIR..."
    git clone "https://github.com/${REPO}.git" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# 3. Build & Setup
info "Building OMNI Native Core (Zig)..."
zig build -Doptimize=ReleaseFast -p .

info "Building OMNI WebAssembly Edge (Zig)..."
zig build wasm -Doptimize=ReleaseSmall

info "Building OMNI MCP Server (Node.js)..."
npm run build

# 4. Success & Instructions
echo ""
echo "${GREEN}✅ OMNI successfully installed in $INSTALL_DIR${NC}"
echo "════════════════════════════════════════════"

info "1. Integration: Add this to your Claude Code / Antigravity config (~/.claude/config.json):"
echo ""
echo "${YELLOW}{"
echo "  \"mcpServers\": {"
echo "    \"omni\": {"
echo "      \"command\": \"node\","
echo "      \"args\": [\"$INSTALL_DIR/dist/index.js\"]"
echo "    }"
echo "  }"
echo "}${NC}"
echo ""

info "2. Setup: To use the 'omni' CLI anywhere, add this to your shell profile (~/.zshrc or ~/.bashrc):"
echo "${BLUE}alias omni='$INSTALL_DIR/bin/omni'${NC}"
echo ""

info "3. Verify: Run the native setup guide:"
echo "${BLUE}./bin/omni setup${NC}"
echo ""

info "OMNI is mission-ready. 🌌"
