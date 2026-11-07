class AiMemory < Formula
  desc "Persistent memory server and lifecycle hooks for AI coding agents"
  homepage "https://github.com/akitaonrails/ai-memory"
  version "3.4.3"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/akitaonrails/ai-memory/releases/download/v3.4.3/ai-memory-macos-aarch64.tar.gz"
      sha256 "e34d2252954a9e28f651d6631e3428e4a47766233add72f2d1e8a3491d1838e3"
    elsif Hardware::CPU.intel?
      url "https://github.com/akitaonrails/ai-memory/releases/download/v3.4.3/ai-memory-macos-x86_64.tar.gz"
      sha256 "94245b4618ec79c1b921c95e6a9a4553a034279d00e95ad8e1a531d9d1870721"
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
