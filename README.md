# Homebrew tap for ai-memory

Installs [ai-memory](https://github.com/akitaonrails/ai-memory) on macOS from
the official GitHub release archives.

## Install

```sh
brew tap renan-garcia/ai-memory
brew install ai-memory
brew services start ai-memory
ai-memory status
```

The service listens at `http://127.0.0.1:49374` (MCP + web UI).

## LLM provider

By default, the service uses:

```text
AI_MEMORY_LLM_PROVIDER=openai-oauth
AI_MEMORY_LLM_MODEL=gpt-5.4-mini
```

With `openai-oauth`, sign in once before use:

```sh
ai-memory auth login openai-oauth
```

### Change the provider

Homebrew stores these variables in the background service file. To change them:

```sh
brew services stop ai-memory
open -e ~/Library/LaunchAgents/homebrew.mxcl.ai-memory.plist
```

In the `EnvironmentVariables` block, update `AI_MEMORY_LLM_PROVIDER` and
`AI_MEMORY_LLM_MODEL`. If the provider uses an API key, add the matching
variable in the same block (for example `ANTHROPIC_API_KEY` or
`OPENAI_API_KEY`).

Then restart:

```sh
brew services start ai-memory
```

Common values for `AI_MEMORY_LLM_PROVIDER`:

| Value | Authentication |
| --- | --- |
| `openai-oauth` | `ai-memory auth login openai-oauth` |
| `anthropic` | `ANTHROPIC_API_KEY` in the plist |
| `openai` | `OPENAI_API_KEY` in the plist |
| `anthropic-oauth` | `ANTHROPIC_OAUTH_TOKEN` in the plist |
| `copilot` | `ai-memory auth login copilot` |

Full provider list and recommended models:
[docs/install.md](https://github.com/akitaonrails/ai-memory/blob/main/docs/install.md)

> A `brew upgrade ai-memory` may recreate the plist with the tap defaults.
> Reapply your changes if that happens.

To test without the background service:

```sh
brew services stop ai-memory
AI_MEMORY_LLM_PROVIDER=anthropic \
AI_MEMORY_LLM_MODEL=claude-haiku-4-5 \
ANTHROPIC_API_KEY=sk-ant-... \
  ai-memory serve --transport http --bind 127.0.0.1:49374 --enable-web
```

## Agent hooks

```sh
ai-memory install-hooks --agent codex --apply
```

This tap automatically points to the hooks installed by Homebrew.

## Upgrade

```sh
brew update && brew upgrade ai-memory
```

---

## Tap maintenance

For maintainers of this repository.

### Automatic updates

The workflow in `.github/workflows/bump-ai-memory.yml` runs once a day (or via
`workflow_dispatch`), downloads the official release artifacts, recalculates
SHA256 values, and updates `Formula/ai-memory.rb` on the default branch.

For automatic commits, enable **Settings → Actions → General → Workflow
permissions → Read and write permissions**.

### Manual bump

```sh
scripts/bump-formula.sh
git diff -- Formula/ai-memory.rb
```

### Local validation

```sh
brew style ./Formula/ai-memory.rb
brew tap local/ai-memory "$(pwd)"
brew install local/ai-memory/ai-memory
brew audit --strict local/ai-memory/ai-memory
brew test local/ai-memory/ai-memory
```
