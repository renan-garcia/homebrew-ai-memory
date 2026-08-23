class AiMemory < Formula
  desc "Persistent memory server and lifecycle hooks for AI coding agents"
  homepage "https://github.com/akitaonrails/ai-memory"
  version "1.31.0"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/akitaonrails/ai-memory/releases/download/v1.31.0/ai-memory-macos-aarch64.tar.gz"
      sha256 "5f3044ab80b59c1ee15b3c20467fb1ce3f4714a6f305436698b4fa3e4b6d7b38"
    elsif Hardware::CPU.intel?
      url "https://github.com/akitaonrails/ai-memory/releases/download/v1.31.0/ai-memory-macos-x86_64.tar.gz"
      sha256 "593c0c69c53e2f2f3b7096c27b7c9b65126a720e03f073fd7dd7a84c34819ff0"
    end
  end

  def install
    libexec.install "ai-memory"
    pkgshare.install "hooks" if (buildpath/"hooks").exist?

    (bin/"ai-memory").write <<~BASH
      #!/bin/bash
      set -e

      if [[ "$1" == "install-hooks" ]]; then
        hooks_dir_present=0
        for arg in "$@"; do
          if [[ "$arg" == "--hooks-dir" || "$arg" == --hooks-dir=* ]]; then
            hooks_dir_present=1
            break
          fi
        done

        if [[ "$hooks_dir_present" == "0" && -d "#{pkgshare}/hooks" ]]; then
          exec "#{libexec}/ai-memory" install-hooks --hooks-dir "#{pkgshare}/hooks" "${@:2}"
        fi
      fi

      exec "#{libexec}/ai-memory" "$@"
    BASH
    chmod 0755, bin/"ai-memory"
  end

  service do
    run [
      opt_bin/"ai-memory",
      "serve",
      "--transport",
      "http",
      "--bind",
      "127.0.0.1:49374",
      "--enable-web",
    ]
    environment_variables AI_MEMORY_LLM_PROVIDER: "openai-oauth",
                          AI_MEMORY_LLM_MODEL:    "gpt-5.4-mini"
    keep_alive true
    log_path var/"log/ai-memory.log"
    error_log_path var/"log/ai-memory.log"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ai-memory --version")
  end
end
