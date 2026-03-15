class Omni < Formula
  desc "Semantic Distillation Engine for the Agentic Era"
  homepage "https://github.com/fajarhide/omni"
  url "https://github.com/fajarhide/omni/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "6548b139246d4553094b9bf8a840819103e2ae1caa526e07a9397e92946f17be"
  license "MIT"

  depends_on "zig" => :build
  depends_on "node"

  def install
    # Build Native Binary and Wasm Binary using Zig build system
    system "zig", "build", "-Doptimize=ReleaseFast", "-p", "."
    system "zig", "build", "wasm", "-Doptimize=ReleaseSmall"

    # Install Native Binary
    bin.install "bin/omni"

    # Install Wasm Binary
    (lib/"omni").install "core/omni-wasm.wasm"

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
    assert_match "omni", shell_output("#{bin}/omni --help")
  end
end
