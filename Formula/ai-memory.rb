class AiMemory < Formula
  desc "Persistent memory server and lifecycle hooks for AI coding agents"
  homepage "https://github.com/akitaonrails/ai-memory"
  version "1.9.1"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/akitaonrails/ai-memory/releases/download/v1.9.1/ai-memory-macos-aarch64.tar.gz"
      sha256 "5d7d58233afbbea84625aa2f064b73c0f6fb2855387b4da30bb28a0d9026ff47"
    elsif Hardware::CPU.intel?
      url "https://github.com/akitaonrails/ai-memory/releases/download/v1.9.1/ai-memory-macos-x86_64.tar.gz"
      sha256 "a48c8fb983d759ef60fd58e27ccc1be5629b3760d5b52b9f7653fe79be3c7b8f"
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
