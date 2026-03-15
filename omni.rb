class Omni < Formula
  desc "Semantic Distillation Engine for the Agentic Era"
  homepage "https://github.com/fajarhide/omni"
  url "https://github.com/fajarhide/omni/archive/refs/tags/v0.1.3.tar.gz"
  sha256 "0df756d09147a2e5f510816f5257b5fa896c2587431a2dda1978b15338a79747"
  license "MIT"

  depends_on "zig" => :build
  depends_on "node"

  def install
    # Build Native Binary
    system "zig", "build-exe", "core/src/main.zig", "--name", "omni"
    bin.install "omni"

    # Build Wasm Binary
    system "zig", "build-exe", "core/src/wasm.zig", "-target", "wasm32-wasi", "-O", "ReleaseSmall", "-rdynamic", "--name", "omni-wasm"
    (lib/"omni").install "omni-wasm.wasm"

    # Install MCP Server
    system "npm", "install"
    system "npm", "run", "build"
    
    # Create a wrapper for the MCP server
    (bin/"omni-mcp").write <<~EOS
      #!/bin/bash
      export OMNI_WASM_PATH="#{lib}/omni/omni-wasm.wasm"
      node "#{libexec}/dist/index.js" "$@"
    EOS
    
    libexec.install "dist", "package.json", "node_modules"
  end

  test do
    assert_match "omni", shell_output("#{bin}/omni --help", 1)
  end
end
