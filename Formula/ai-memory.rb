class AiMemory < Formula
  desc "Persistent memory server and lifecycle hooks for AI coding agents"
  homepage "https://github.com/akitaonrails/ai-memory"
  version "2.4.2"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/akitaonrails/ai-memory/releases/download/v2.4.2/ai-memory-macos-aarch64.tar.gz"
      sha256 "b4ca2bc3b1f3b4daba7a2fb2b9a87c54b4fd25adf21e58a1edf4500067737907"
    elsif Hardware::CPU.intel?
      url "https://github.com/akitaonrails/ai-memory/releases/download/v2.4.2/ai-memory-macos-x86_64.tar.gz"
      sha256 "be5a180adf86e402921310242d5d29da7eff13ba38672f36f0441e587a81ced0"
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
