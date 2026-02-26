# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Git

- Always use `--signoff` (`-s`) when creating git commits.

## Build / Run

- Prefer to use Justfile commands when available.

## Overview

This is a personal dotfiles repository for cross-platform development environments (Ubuntu, Fedora, Arch, macOS). It manages configuration for:
- Neovim (Lua-based config with lazy.nvim)
- Zsh (standalone, no framework — custom prompt, git aliases, zsh-autosuggestions)
- Tmux
- Custom shell utilities

## Installation

```bash
git clone https://github.com/tlrmchlsmth/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && bash install.sh
```

Options: `bash install.sh [-g GITHUB_TOKEN] [-h HUGGINGFACE_TOKEN]`

The script detects the OS/distro and uses the appropriate package manager (apt/dnf/pacman/brew).

## Architecture

### Configuration Structure

- **Root dotfiles**: `zshrc`, `tmux.conf` are symlinked directly to `~/.zshrc` and `~/.tmux.conf`
- **Zsh modules**: `zsh/prompt.zsh` (af-magic-style prompt using vcs_info), `zsh/git-aliases.zsh`
- **Config directory**: `config/nvim/` is symlinked to `~/.config/nvim/`
- **Executables**: `bin/` contents are symlinked to `~/.local/bin/` (which is on PATH)
- **Container**: `container/Dockerfile` layers dotfiles on vLLM nightly image

### Neovim Configuration

Neovim uses a Lua-based configuration with lazy.nvim plugin manager:

- **Entry point**: `config/nvim/init.lua` (sets leader to `,`, bootstraps lazy.nvim)
- **Core modules**: `lua/core/{options,autocmds,keymaps}.lua`
- **Plugins**: `lua/plugins/init.lua` (single file with all plugin specs)

Key plugins:
- **LSP**: mason.nvim, mason-lspconfig.nvim, nvim-lspconfig (servers: lua_ls, ty, rust_analyzer)
- **UI**: gruvbox theme, lualine, trouble.nvim, nvim-tree
- **Fuzzy finding**: fzf-lua (uses `fd` or `find`, excludes `.git`, `.venv`, `__pycache__`, etc.)
- **Utilities**: vim-fugitive, vim-surround, vim-oscyank

### Zsh Configuration

- **Prompt**: Custom af-magic-style prompt in `zsh/prompt.zsh` (uses zsh's built-in `vcs_info`)
- **Git aliases**: Extracted from OMZ git plugin in `zsh/git-aliases.zsh`
- **Plugins**: zsh-autosuggestions (installed standalone to `~/.zsh/plugins/`)
- **Key settings**: 100k history, emacs keybindings
- **Aliases**: `vi` → `nvim`, `j` → `just`, `k` → `kubectl`, `make` → `safemake.sh`
- **Local overrides**: Sources `~/.zshrc.local` if present
- **Auto-venv**: Automatically activates/deactivates `.venv` when changing directories
- **CUDA**: Environment variables set only if `/usr/local/cuda` exists

### Tmux Configuration

- **Prefix**: `C-Space`
- **Split bindings**: `|` (vertical), `-` (horizontal)
- **Pane navigation**: Alt+Arrow (no prefix)
- **Window navigation**: Shift+Arrow (no prefix)
- **Copy mode**: Vim keybindings, OS-aware clipboard (pbcopy/xclip/xsel)
- **Theme**: Green/yellow color scheme with high scrollback (9999999 lines)

## CI

GitHub Actions workflow (`.github/workflows/ci.yml`) tests install.sh on:
- Ubuntu (latest + 22.04)
- Fedora (container)
- Arch Linux (container)
- macOS (latest)

## Custom Utilities

### safemake.sh

Wrapper around `make` that enforces a maximum parallelism limit:
- Default limit: 56 (configurable via `J_LIMIT` environment variable)
- Automatically fixes naked `-j` or caps excessive `-j N` values
- Aliased as `make` in zshrc

## Development Notes

- The Neovim LSP on_attach function notifies when LSP clients attach (visible in `:messages`)
- LSP keybindings use `<leader>` (comma) prefix extensively
- The install script supports passwordless sudo via `sudo -n` or falls back to non-privileged mode
- Git is configured globally with user "Tyler Michael Smith" <tlrmchlsmth@gmail.com>
