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
