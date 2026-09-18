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

## Local GB200 tunnel

The `vllm-gb200` context can repair its SSH tunnel when the API is unreachable.
Create an executable `~/.config/kctx/gb200-tunnel.sh` with your own bastion and
forwarding settings. For example:

```bash
#!/usr/bin/env bash
exec "$HOME/.dotfiles/bin/tunnel.sh" gb200 "${1:-start}" user@bastion -D 1080
```

The kubeconfig's `proxy-url` must point to the same local SOCKS port. Set
`KCTX_GB200_TUNNEL_SCRIPT` to use another wrapper path. The wrapper is local
machine configuration and is not tracked in this repository.

## Supported Platforms

- Ubuntu 22.04+
- Fedora (latest)
- Arch Linux
- macOS (Apple Silicon and Intel)
