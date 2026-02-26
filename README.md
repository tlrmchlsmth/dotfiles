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

## Supported Platforms

- Ubuntu 22.04+
- Fedora (latest)
- Arch Linux
- macOS (Apple Silicon and Intel)
