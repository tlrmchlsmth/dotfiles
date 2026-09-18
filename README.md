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

## Kubernetes connectivity hooks

The prompt checks each Kubernetes context in the background. When an API is
unreachable, it runs an optional executable at `~/.config/kctx/connect-hook`
with the context name and `restart` as arguments. The hook can repair a local
VPN, proxy, or SSH tunnel and should return a nonzero status for contexts it
does not handle. Set `KCTX_CONNECT_HOOK` to use another path. Keep context
names, endpoints, and credentials in local configuration outside this repo.

An optional `~/.config/kctx/default-context` file selects the initial context
when no context has been saved; otherwise the first available current context
from the managed kubeconfigs is used. `XDG_CONFIG_HOME` can change the local
config directory.

## Supported Platforms

- Ubuntu 22.04+
- Fedora (latest)
- Arch Linux
- macOS (Apple Silicon and Intel)
