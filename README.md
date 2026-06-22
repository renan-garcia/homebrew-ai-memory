# Local Homebrew tap for ai-memory

This repository is a local Homebrew tap used to test installing
[`akitaonrails/ai-memory`](https://github.com/akitaonrails/ai-memory) from the
official GitHub release archives. It does not publish a tap and does not modify
`homebrew-core`.

## Formula

The formula lives at:

```sh
Formula/ai-memory.rb
```

It currently targets `ai-memory` version `1.1.3`.

Release artifacts:

```text
macOS Apple Silicon:
https://github.com/akitaonrails/ai-memory/releases/download/v1.1.3/ai-memory-macos-aarch64.tar.gz
sha256: 814c1fa1609a17309585a0c56e9938f56e20c3078c2a3738b9e4d882c57ad8a3

macOS Intel:
https://github.com/akitaonrails/ai-memory/releases/download/v1.1.3/ai-memory-macos-x86_64.tar.gz
sha256: 85c6cd362e394370e19caca860e91fd768a10bfc6f5af6afaf1cbd819e81828d
```

To recalculate checksums manually:

```sh
curl -L --fail --output /tmp/ai-memory-macos-aarch64.tar.gz \
  https://github.com/akitaonrails/ai-memory/releases/download/v1.1.3/ai-memory-macos-aarch64.tar.gz

curl -L --fail --output /tmp/ai-memory-macos-x86_64.tar.gz \
  https://github.com/akitaonrails/ai-memory/releases/download/v1.1.3/ai-memory-macos-x86_64.tar.gz

shasum -a 256 /tmp/ai-memory-macos-aarch64.tar.gz
shasum -a 256 /tmp/ai-memory-macos-x86_64.tar.gz
```

## Local test commands

From this directory:

```sh
brew install ./Formula/ai-memory.rb
brew test ./Formula/ai-memory.rb
brew services start ai-memory
ai-memory status
ai-memory install-mcp --client codex --apply
ai-memory install-hooks --agent codex --apply
```

Useful formula checks:

```sh
brew style ./Formula/ai-memory.rb
brew audit --strict --new ./Formula/ai-memory.rb
```

## Hooks layout

The official release archive includes a `hooks/` directory, including
`hooks/codex`.

Homebrew installs those hook sources under `pkgshare`, which resolves to a path
like:

```text
/opt/homebrew/Cellar/ai-memory/1.1.3/share/ai-memory/hooks
```

`ai-memory install-hooks` currently auto-discovers a sibling `hooks/` directory
beside the real binary, then falls back to paths such as
`/usr/local/share/ai-memory/hooks` and `/usr/share/ai-memory/hooks`. On Apple
Silicon Homebrew, the prefix is usually `/opt/homebrew`, so the fallback does
not find `pkgshare`.

The local formula avoids that by installing the real binary in `libexec` and a
small wrapper at `bin/ai-memory`. For normal commands the wrapper delegates
unchanged. For:

```sh
ai-memory install-hooks --agent codex --apply
```

the wrapper adds:

```sh
--hooks-dir <pkgshare>/hooks
```

unless the user already supplied `--hooks-dir`.

## Upstream suggestion

A clean upstream improvement would be for `ai-memory install-hooks` to also look
for Homebrew-style hook roots, for example:

```text
<resolved executable prefix>/../share/ai-memory/hooks
HOMEBREW_PREFIX/opt/ai-memory/share/ai-memory/hooks
HOMEBREW_PREFIX/share/ai-memory/hooks
```

That would let a Homebrew formula install the binary directly to `bin` without a
wrapper while keeping hooks in `pkgshare`.
