.PHONY: all build build-wasm build-ts test verify clean report check-version help

# Default target: Verify everything
all: verify

help:
	@echo "OMNI Command Interface"
	@echo "----------------------"
	@echo "make build       - Build Wasm core + TypeScript server"
	@echo "make test        - Run semantic routing verification tests"
	@echo "make report      - Run system integrity & performance report"
	@echo "make verify      - Full suite: version check + build + test + report"
	@echo "make clean       - Remove build artifacts"
	@echo "make check-version - Verify version consistency across all files"

# Version Verification
check-version:
	@echo "Checking version consistency..."
	@V_PKG=$$(grep '"version":' package.json | head -1 | awk -F'"' '{print $$4}'); \
	V_ZIG=$$(grep '"' core/build.zig.zon | grep -v 'minimum_zig_version' | grep '.version =' | awk -F'"' '{print $$2}'); \
	V_SRC=$$(grep 'version:' src/index.ts | head -1 | awk -F'"' '{print $$2}'); \
	V_RB=$$(grep 'url "https://github.com/fajarhide/omni/archive/refs/tags/v' omni.rb | sed 's/.*\/tags\/v\(.*\)\.tar\.gz.*/\1/'); \
	echo "package.json:      $$V_PKG"; \
	echo "core/build.zig.zon: $$V_ZIG"; \
	echo "src/index.ts:       $$V_SRC"; \
	echo "omni.rb:            $$V_RB"; \
	if [ "$$V_PKG" != "$$V_ZIG" ] || [ "$$V_PKG" != "$$V_SRC" ] || [ "$$V_PKG" != "$$V_RB" ]; then \
		echo "✗ Version mismatch detected!"; exit 1; \
	fi
	@echo "✓ Versions are consistent ($$V_PKG)"

# Phase 1: Build Validation
build: check-version build-wasm build-ts
	@echo "✓ Build validation successful."

build-wasm:
	@echo "Building OMNI Core (core/zig-out/bin/omni-wasm.wasm)..."
	cd core && zig build -Doptimize=ReleaseSmall
	@if [ -f core/zig-out/bin/omni-wasm.wasm ]; then \
		echo "✓ Wasm binary generated successfully ($$(du -h core/zig-out/bin/omni-wasm.wasm | cut -f1))"; \
	else \
		echo "✗ Failed to generate Wasm binary"; exit 1; \
	fi

build-ts:
	@echo "Building OMNI MCP Server (dist/index.js)..."
	@npm run build > /dev/null
	@if [ -f dist/index.js ]; then \
		echo "✓ TypeScript server compiled successfully"; \
	else \
		echo "✗ Failed to compile TypeScript server"; exit 1; \
	fi

# Phase 2: Functional Testing
test:
	@echo "Running Semantic Core Verification Suite..."
	@node test-semantic.mjs || { echo "✗ Semantic testing failed"; exit 1; }
	@echo "✓ Semantic routing logic verified."

# Phase 3: System Reporting
report:
	@echo "Generating System Report..."
	@core/zig-out/bin/omni report || { echo "✗ System report failed"; exit 1; }

# Phase 4: Integrity Verification (Full Suite)
verify: check-version build test report
	@echo "========================================"
	@echo "🏆 OMNI SYSTEM INTEGRITY: VERIFIED"
	@echo "========================================"

clean:
	@echo "Cleaning artifacts..."
	rm -rf core/zig-out core/.zig-cache dist
	@echo "✓ Environment cleaned."
