class Omni < Formula
  desc "Semantic Distillation Engine for the Agentic Era"
  homepage "https://github.com/fajarhide/omni"
  url "https://github.com/fajarhide/omni/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "fa89be5e5797fa0c66e12527eea93e4d61d49faba98d60d377b88500d6c521bf"
  license "MIT"

  depends_on "zig" => :build
  depends_on "node"

  def install
    # Build Native Binary
    system "zig", "build-exe", "core/src/main.zig", "--name", "omni"
    bin.install "omni"

    # Build Wasm Binary
    system "zig", "build-exe", "core/src/wasm.zig", "-target", "wasm32-wasi", "-O", "ReleaseSmall", "-rdynamic", "--name", "omni-wasm"
    (lib/"omni").install "core/omni-wasm.wasm"

    # Install MCP Server
    system "npm", "install"
    system "npm", "run", "build"
    
    # Create a wrapper for the MCP server
    (bin/"omni-mcp").write <<~EOS
      #!/bin/bash
      export OMNI_WASM_PATH="#{lib}/omni/omni-wasm.wasm"
      node "#{prefix}/libexec/dist/index.js" "$@"
    EOS
    
    libexec.install Dir["dist/*"]
    libexec.install "package.json"
    libexec.install "node_modules"
  end

  test do
    assert_match "omni", shell_output("#{bin}/omni --help", 1)
  end
end
