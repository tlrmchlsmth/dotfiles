# dotfiles

Personal dotfiles for Linux and macOS development environments.

## Quick Install

```bash
git clone https://github.com/tlrmchlsmth/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && bash install.sh
```

### Options

```bash
bash install.sh [-g GITHUB_TOKEN] [-h HUGGINGFACE_TOKEN]
```

## What's Included

- **Neovim** — Lua config with lazy.nvim, LSP, fzf-lua, gruvbox
- **Zsh** — Lightweight setup with custom prompt, git aliases, zsh-autosuggestions (no OMZ)
- **Tmux** — C-Space prefix, vim copy mode, green/yellow theme
- **fzf** — v0.65.2
- **safemake.sh** — `make` wrapper that caps `-j` parallelism
- **tunnel.sh** — manages named SSH forwards; host and port settings stay in local config

## Kubernetes

The installer builds [kcfg](https://github.com/tlrmchlsmth/kcfg) into
`~/.local/bin` and loads its Zsh integration. It uses Go 1.23+ if available,
or downloads a Go toolchain with SHA-256 verification. Set `KCFG_VERSION` to
install a specific tag or commit instead of the latest version. To install or
update only kcfg, run `bash scripts/install-kcfg.sh`.

Use `kcfg import [name]` to import configs. The shell aliases `kctx [name]` and
`kns [name]` select a context and namespace. `kcfg delete NAME` removes a managed
config; `kcfg refresh NAME` logs in again with `oc`, or use
`kcfg refresh NAME -- COMMAND ARGS...` for another credential refresh command.
Existing `~/.kube/configs` files and local `~/.config/kctx` hooks are supported.
The prompt uses `kcfg status` for background connectivity checks.

## Supported Platforms

- Ubuntu 22.04+
- Fedora (latest)
- Arch Linux
- macOS (Apple Silicon and Intel)

## Private local inference (Apple Silicon macOS)

An opt-in service, separate from any free cloud inference provider. Gemma 4
26B-A4B 4-bit runs with vllm-metal, four concurrent sequences and a 256k
per-request context limit. Defaults live in `config/local-ai.json`; optional
machine overrides live in `~/.config/local-ai.local.json` (not tracked). The
default runtime location is `~/.local/share/local-ai`. Installation downloads
Python, serving packages and approximately 15 GB of model weights.

```sh
bash ~/.dotfiles/scripts/install-local-ai.sh
local-ai status
local-ai url
local-ai stop
local-ai start
local-ai restart
```

Re-running the installer downloads the configured model before restarting the
service. Existing model caches are retained.

The LaunchAgent starts at login and restarts after crashes. `stop` unloads it
until the next login or explicit `start`. Logs are in the runtime's
`artifacts/launchd.log`. Serving uses pinned cached weights with Hugging Face
offline mode and vLLM usage reporting disabled. It binds only to 127.0.0.1
and has no cloud fallback. Installation downloads packages and weights;
model inference and the documentation MCP stay local.

For the memorable endpoint, install the loopback alias once:

```sh
sudo python3 ~/.dotfiles/scripts/local-ai.py hosts
```

API: `http://ai.localhost:55348/v1`, model `local-coder`, API key placeholder
`EMPTY`. Numeric fallback: `http://127.0.0.1:55348/v1`.

## Local dotfiles documentation MCP

A separate, optional, read-only MCP server exposes this repository's docs,
local AI defaults and commands, and service health. It runs locally over stdio;
it sends no documentation queries online and cannot start or stop services.
An explicit document allowlist excludes credentials and machine overrides.

```sh
bash ~/.dotfiles/scripts/install-docs-mcp.sh
```

The installer downloads the Python MCP SDK once and registers `dotfiles-docs`
in Codex. Restart Codex to load it. Tools: `list_docs`, `read_doc`, `search_docs`,
and `local_ai_status`. Resource URIs: `dotfiles://docs/{name}`.
The documentation MCP does not require installing the inference model.
