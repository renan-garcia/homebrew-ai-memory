# Homebrew tap for ai-memory

Personal Homebrew tap for installing
[`akitaonrails/ai-memory`](https://github.com/akitaonrails/ai-memory) from the
official GitHub release archives.

Before publishing, replace `renan-garcia` in the examples below with your real
GitHub username. For Homebrew, the repository should be named
`homebrew-ai-memory`, so:

```text
brew tap renan-garcia/ai-memory
```

maps to:

```text
https://github.com/renan-garcia/homebrew-ai-memory
```

## Install

```sh
brew tap renan-garcia/ai-memory
brew install ai-memory
```

For your GitHub user, that would be:

```sh
brew tap renan-garcia/ai-memory
brew install ai-memory
```

Start the local service:

```sh
brew services start ai-memory
ai-memory status
```

Install Codex integration:

```sh
ai-memory install-mcp --client codex --apply
ai-memory install-hooks --agent codex --apply
```

The service runs:

```sh
ai-memory serve --transport http --bind 127.0.0.1:49374 --enable-web
```

with:

```text
AI_MEMORY_LLM_PROVIDER=openai-oauth
AI_MEMORY_LLM_MODEL=gpt-5.4-mini
```

## Formula layout

The formula is:

```text
Formula/ai-memory.rb
```

It uses fixed versioned release URLs and fixed SHA256 values. It does not use
`latest/download`.

The upstream release artifacts are:

```text
ai-memory-macos-aarch64.tar.gz
ai-memory-macos-x86_64.tar.gz
```

## Hooks layout

The official release archive includes `hooks/codex`.

Homebrew installs the hook bundle under `pkgshare`, for example:

```text
/opt/homebrew/Cellar/ai-memory/<version>/share/ai-memory/hooks
```

`ai-memory install-hooks` currently auto-discovers a sibling `hooks/` directory
beside the real binary, then falls back to paths such as
`/usr/local/share/ai-memory/hooks` and `/usr/share/ai-memory/hooks`. On Apple
Silicon Homebrew, the prefix is usually `/opt/homebrew`, so that fallback does
not find `pkgshare`.

This tap installs the real upstream binary in `libexec` and exposes a wrapper at
`bin/ai-memory`. Normal commands are delegated unchanged. For:

```sh
ai-memory install-hooks --agent codex --apply
```

the wrapper adds:

```sh
--hooks-dir <pkgshare>/hooks
```

unless the user already supplied `--hooks-dir`.

## Automatic updates

The workflow in `.github/workflows/bump-ai-memory.yml` runs once a day and can
also be started manually with `workflow_dispatch`.

It:

1. reads the latest release from `akitaonrails/ai-memory`;
2. downloads `ai-memory-macos-aarch64.tar.gz`;
3. downloads `ai-memory-macos-x86_64.tar.gz`;
4. calculates both SHA256 values;
5. updates `Formula/ai-memory.rb`;
6. commits directly to the repository default branch if the formula changed.

After the workflow commits the new formula, users get the new version through
normal Homebrew update flow:

```sh
brew update
brew upgrade ai-memory
```

or simply:

```sh
brew update && brew upgrade
```

For the commit step to work, enable GitHub Actions write permissions in the tap
repository settings:

```text
Settings -> Actions -> General -> Workflow permissions -> Read and write
permissions
```

## Manual bump

The workflow uses:

```sh
scripts/bump-formula.sh
```

You can run it locally when needed:

```sh
scripts/bump-formula.sh
git diff -- Formula/ai-memory.rb
```

It only updates the formula file. It does not publish, push, install, start
services, or touch your `ai-memory` data directory.

## Local validation

```sh
brew style ./Formula/ai-memory.rb
brew audit --strict --new local/ai-memory/ai-memory
brew test local/ai-memory/ai-memory
```

Homebrew 6 rejects direct path installs for formulae that are not in a tap. If
you need to validate locally before publishing, register this checkout as a
local tap:

```sh
brew tap local/ai-memory "$(pwd)"
brew install local/ai-memory/ai-memory
brew test local/ai-memory/ai-memory
```

On older Homebrew versions that still accept path formulae, this equivalent
direct-path flow may work:

```sh
brew install ./Formula/ai-memory.rb
brew test ./Formula/ai-memory.rb
```
