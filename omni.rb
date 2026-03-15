class Omni < Formula
  desc "Semantic Distillation Engine for the Agentic Era"
  homepage "https://github.com/fajarhide/omni"
  url "https://github.com/fajarhide/omni/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "0cab3ff44e0830ec56da87977fb9c8ce9282a9b0e62508016e318fc03d30b805"
  license "MIT"

  depends_on "zig" => :build
  depends_on "node"

  def install
    # Run builds from the 'core' directory
    Dir.chdir("core") do
      # Native binary -> bin/omni
      system "zig", "build", "-Doptimize=ReleaseFast", "-Dversion=#{version}", "-p", "../"
      # Wasm binary -> bin/omni-wasm.wasm
      system "zig", "build", "wasm", "-Doptimize=ReleaseSmall", "-Dversion=#{version}", "-p", "../"
    end

    # Install Native Binary
    bin.install "bin/omni"

    # Install Wasm Binary
    (lib/"omni").install "bin/omni-wasm.wasm"

    # Install MCP Server
    system "npm", "install", *std_npm_args(libexec: libexec)
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
