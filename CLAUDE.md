# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Git

- Always use `--signoff` (`-s`) when creating git commits.

## Overview

This is a personal dotfiles repository for Ubuntu 22.04/Linux development environments. It manages configuration for:
- Neovim (Lua-based config with lazy.nvim)
- Zsh with Oh My Zsh
- Tmux
- Custom shell utilities

## Installation

The repository is designed to be installed via `install.sh`:

```bash
bash install.sh [-g GITHUB_TOKEN] [-h HUGGINGFACE_TOKEN]
```

This script:
1. Installs/updates Neovim stable to `~/.local/opt/nvim`
2. Installs GitHub CLI and authenticates if token provided
3. Sets up Oh My Zsh with zsh-autosuggestions plugin
4. Symlinks dotfiles to home directory
5. Symlinks `config/*` to `~/.config/`
6. Symlinks executables from `bin/` to `~/.local/bin/`
7. Configures Git global settings
8. Installs fzf v0.65.2

## Architecture

### Configuration Structure

- **Root dotfiles**: `zshrc`, `tmux.conf` are symlinked directly to `~/.zshrc` and `~/.tmux.conf`
- **Config directory**: `config/nvim/` is symlinked to `~/.config/nvim/`
- **Executables**: `bin/` contents are symlinked to `~/.local/bin/` (which is on PATH)

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

- **Theme**: af-magic
- **Plugins**: git, zsh-autosuggestions
- **Key settings**: Case-sensitive completion, 100k history, emacs keybindings
- **Aliases**:
  - `vi` → `nvim`
  - `j` → `just`
  - `k` → `kubectl`
  - `make` → `safemake.sh` (limits `-j` to 56 by default via `J_LIMIT` env var)
- **Local overrides**: Sources `~/.zshrc.local` if present

### Tmux Configuration

- **Prefix**: Changed from `C-b` to `C-a`
- **Split bindings**: `|` (vertical), `-` (horizontal)
- **Pane navigation**: Alt+Arrow (no prefix)
- **Window navigation**: Shift+Arrow (no prefix)
- **Copy mode**: Vim keybindings
- **Theme**: Green/yellow color scheme with high scrollback (9999999 lines)
- **Plugins**: tpm, tmux-sensible

## Custom Utilities

### safemake.sh

Wrapper around `/usr/bin/make` that enforces a maximum parallelism limit:
- Default limit: 56 (configurable via `J_LIMIT` environment variable)
- Automatically fixes naked `-j` or caps excessive `-j N` values
- Aliased as `make` in zshrc

## Environment Variables

Key environment variables set in zshrc:
- `CUDA_HOME=/usr/local/cuda` (with PATH and LD_LIBRARY_PATH additions)
- `TERM=screen-256color-bce`
- `EDITOR=nvim`
- `VLLM_LOGGING_LEVEL=debug`
- `CCACHE_NOHASHDIR=true`

## Development Notes

- The Neovim LSP on_attach function notifies when LSP clients attach (visible in `:messages`)
- LSP keybindings use `<leader>` (comma) prefix extensively
- The install script supports passwordless sudo via `sudo -n` or falls back to non-privileged mode
- Git is configured globally with user "Tyler Michael Smith" <tlrmchlsmth@gmail.com>
