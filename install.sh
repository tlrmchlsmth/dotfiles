#!/usr/bin/env bash
set -euo pipefail

# --- Initialize argument-based token variables ---
ARG_GH_TOKEN=""
ARG_HF_TOKEN=""

# --- Helper: Print usage ---
print_usage() {
    echo "Usage: $0 [-g GITHUB_TOKEN] [-h HUGGINGFACE_TOKEN]"
    echo "  -g GITHUB_TOKEN       Your GitHub Personal Access Token."
    echo "  -h HUGGINGFACE_TOKEN  Your HuggingFace User Access Token."
}

# --- Parse command-line arguments for tokens ---
while getopts ":g:h:" opt; do
  case ${opt} in
    g )
      ARG_GH_TOKEN="$OPTARG"
      ;;
    h )
      ARG_HF_TOKEN="$OPTARG"
      ;;
    \? )
      echo "Invalid option: -$OPTARG" 1>&2
      print_usage
      exit 1
      ;;
    : )
      echo "Invalid option: -$OPTARG requires an argument" 1>&2
      print_usage
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

# --- Helper: Print section headers ---
print_header() {
    echo ""
    echo "---------------------------------------------------------------------"
    echo "$1"
    echo "---------------------------------------------------------------------"
}

# --- OS / Distro Detection ---
OS=""
DISTRO=""

case "$(uname -s)" in
  Linux)
    OS="linux"
    if [ -f /etc/os-release ]; then
      # shellcheck disable=SC1091
      . /etc/os-release
      case "$ID" in
        ubuntu|debian) DISTRO="ubuntu" ;;
        fedora)        DISTRO="fedora" ;;
        arch|manjaro)  DISTRO="arch" ;;
        *)
          echo "Warning: Unsupported Linux distro '$ID'. Will attempt Ubuntu-style commands." >&2
          DISTRO="ubuntu"
          ;;
      esac
    else
      echo "Warning: /etc/os-release not found. Assuming Ubuntu-like system." >&2
      DISTRO="ubuntu"
    fi
    ;;
  Darwin)
    OS="darwin"
    DISTRO="macos"
    ;;
  *)
    echo "Unsupported OS: $(uname -s)" >&2
    exit 1
    ;;
esac

echo "Detected OS: $OS, Distro: $DISTRO"

# --- Determine sudo command (Linux only, macOS uses Homebrew as user) ---
SUDO_CMD=""

if [ "$OS" = "linux" ]; then
    if [ "$(id -u)" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
            if sudo -n true >/dev/null 2>&1; then
                SUDO_CMD="sudo -n"
                echo "Using 'sudo -n' for privileged operations."
            else
                echo "Warning: sudo requires a password. Privileged operations may fail." >&2
            fi
        else
            echo "Warning: Running as non-root user and sudo not found." >&2
        fi
    else
        echo "Running as root. Privileged operations will be executed directly."
    fi
fi

# --- Setup Directories ---
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_BIN_DIR="$HOME/.local/bin"
mkdir -p "$TARGET_BIN_DIR"

echo "Dotfiles directory: $DOTFILES_DIR"

#==========================================================================================
print_header "Installing prerequisites"
#==========================================================================================

case "$DISTRO" in
  ubuntu)
    if [ -n "$SUDO_CMD" ] || [ "$(id -u)" -eq 0 ]; then
      env DEBIAN_FRONTEND=noninteractive $SUDO_CMD apt-get update -qq
      env DEBIAN_FRONTEND=noninteractive $SUDO_CMD apt-get install -y \
        git curl zsh ripgrep bat python3-pip python3-venv tmux
    else
      echo "Skipping apt package installation (no sudo access)."
    fi
    ;;
  fedora)
    if [ -n "$SUDO_CMD" ] || [ "$(id -u)" -eq 0 ]; then
      $SUDO_CMD dnf install -y \
        git curl zsh ripgrep bat python3-pip tmux
    else
      echo "Skipping dnf package installation (no sudo access)."
    fi
    ;;
  arch)
    if [ -n "$SUDO_CMD" ] || [ "$(id -u)" -eq 0 ]; then
      $SUDO_CMD pacman -Sy --noconfirm \
        git curl zsh ripgrep bat python-pip tmux
    else
      echo "Skipping pacman package installation (no sudo access)."
    fi
    ;;
  macos)
    if ! command -v brew >/dev/null 2>&1; then
      echo "Error: Homebrew not found. Install from https://brew.sh" >&2
      exit 1
    fi
    brew install git curl zsh ripgrep bat python3 tmux 2>/dev/null || true
    ;;
esac

#==========================================================================================
print_header "Installing/Updating Neovim (Stable)"
#==========================================================================================

install_neovim_tarball() {
    # Used for Ubuntu (and macOS if Homebrew is unavailable)
    local nvim_os="$1"

    ARCH=$(uname -m)
    case "$ARCH" in
      x86_64)  NVIM_ARCH="x86_64" ;;
      aarch64) NVIM_ARCH="arm64" ;;
      arm64)   NVIM_ARCH="arm64" ;;
      *)       echo "Unsupported architecture: $ARCH" >&2; return 1 ;;
    esac

    local tarball_url="https://github.com/neovim/neovim/releases/download/stable/nvim-${nvim_os}-${NVIM_ARCH}.tar.gz"
    local install_dir="$HOME/.local/opt/nvim"
    local symlink_path="${TARGET_BIN_DIR}/nvim"

    echo "Downloading Neovim tarball from $tarball_url ..."
    local tmp_tarball
    tmp_tarball="$(mktemp)"
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL -o "${tmp_tarball}" "${tarball_url}"
    else
      wget -qO "${tmp_tarball}" "${tarball_url}"
    fi

    local stage_dir
    stage_dir="$(mktemp -d)"
    mkdir -p "${stage_dir}/nvim"
    if ! tar -xzf "${tmp_tarball}" --strip-components=1 -C "${stage_dir}/nvim"; then
      echo "Failed to extract Neovim tarball."
      rm -rf "${stage_dir}" "${tmp_tarball}"
      return 1
    fi
    rm -f "${tmp_tarball}"

    rm -rf "${install_dir}"
    mkdir -p "$(dirname "${install_dir}")"
    mv "${stage_dir}/nvim" "${install_dir}"
    rm -rf "${stage_dir}"

    mkdir -p "${TARGET_BIN_DIR}"
    echo "Creating symlink ${symlink_path} -> ${install_dir}/bin/nvim"
    ln -sf "${install_dir}/bin/nvim" "${symlink_path}"

    "${symlink_path}" --version | head -n1
}

case "$DISTRO" in
  ubuntu)
    install_neovim_tarball "linux"
    ;;
  fedora)
    if [ -n "$SUDO_CMD" ] || [ "$(id -u)" -eq 0 ]; then
      $SUDO_CMD dnf install -y neovim
    else
      install_neovim_tarball "linux"
    fi
    ;;
  arch)
    if [ -n "$SUDO_CMD" ] || [ "$(id -u)" -eq 0 ]; then
      $SUDO_CMD pacman -S --noconfirm neovim
    else
      install_neovim_tarball "linux"
    fi
    ;;
  macos)
    brew install neovim 2>/dev/null || brew upgrade neovim 2>/dev/null || true
    ;;
esac

# Verify neovim is available
if command -v nvim >/dev/null 2>&1; then
    echo "Neovim installed: $(nvim --version | head -n1)"
else
    echo "Warning: nvim not found on PATH after installation." >&2
fi

#==========================================================================================
print_header "Installing pynvim Python package"
#==========================================================================================

PIP_EXTRA_ARGS=""
if pip3 install --help 2>&1 | grep -q -- --break-system-packages; then
  PIP_EXTRA_ARGS="--break-system-packages"
fi
# shellcheck disable=SC2086
pip3 install -U pynvim $PIP_EXTRA_ARGS || echo "Warning: pip3 install pynvim failed." >&2

#==========================================================================================
print_header "Installing GitHub CLI"
#==========================================================================================

if ! type -p gh > /dev/null; then
    echo "GitHub CLI not found. Installing..."
    case "$DISTRO" in
      ubuntu)
        DOWNLOAD_TOOL_CMD=""
        if command -v curl >/dev/null 2>&1; then
            DOWNLOAD_TOOL_CMD="curl -fsSL"
        elif command -v wget >/dev/null 2>&1; then
            DOWNLOAD_TOOL_CMD="wget -qO-"
        fi

        if [ -n "$DOWNLOAD_TOOL_CMD" ] && { [ -n "$SUDO_CMD" ] || [ "$(id -u)" -eq 0 ]; }; then
            KEYRING_DIR="/etc/apt/keyrings"
            KEYRING_PATH="$KEYRING_DIR/githubcli-archive-keyring.gpg"
            SOURCES_LIST_PATH="/etc/apt/sources.list.d/github-cli.list"

            $SUDO_CMD mkdir -p -m 755 "$KEYRING_DIR"
            # shellcheck disable=SC2086
            eval "$DOWNLOAD_TOOL_CMD https://cli.github.com/packages/githubcli-archive-keyring.gpg" | $SUDO_CMD tee "$KEYRING_PATH" > /dev/null
            $SUDO_CMD chmod go+r "$KEYRING_PATH"

            echo "deb [arch=$(dpkg --print-architecture) signed-by=$KEYRING_PATH] https://cli.github.com/packages stable main" | $SUDO_CMD tee "$SOURCES_LIST_PATH" > /dev/null

            env DEBIAN_FRONTEND=noninteractive $SUDO_CMD apt-get update -qq
            env DEBIAN_FRONTEND=noninteractive $SUDO_CMD apt-get install -y gh
            echo "GitHub CLI installed."
        else
            echo "Skipping GitHub CLI installation (no download tool or no sudo access)." >&2
        fi
        ;;
      fedora)
        if [ -n "$SUDO_CMD" ] || [ "$(id -u)" -eq 0 ]; then
          $SUDO_CMD dnf install -y gh
        else
          echo "Skipping GitHub CLI installation (no sudo access)." >&2
        fi
        ;;
      arch)
        if [ -n "$SUDO_CMD" ] || [ "$(id -u)" -eq 0 ]; then
          $SUDO_CMD pacman -S --noconfirm github-cli
        else
          echo "Skipping GitHub CLI installation (no sudo access)." >&2
        fi
        ;;
      macos)
        brew install gh 2>/dev/null || true
        ;;
    esac
else
    echo "GitHub CLI is already installed."
fi

#==========================================================================================
print_header "Setting up GitHub authentication"
#==========================================================================================

if command -v gh >/dev/null; then
    if [ -n "$ARG_GH_TOKEN" ]; then
        echo "GitHub token provided via -g argument. Attempting to log in with token..."
        if echo "$ARG_GH_TOKEN" | gh auth login --with-token; then
            gh auth setup-git
            echo "GitHub CLI authenticated successfully and git credential helper configured."
        else
            echo "GitHub login with token failed. Please check your token or log in manually later." >&2
        fi
    else
        echo "GitHub token not provided via -g argument."
        echo "To authenticate with GitHub CLI, manually run: "
        echo "  gh auth login"
        echo "  gh auth setup-git"
        echo "Or re-run this script with the -g YOUR_TOKEN option."
    fi
else
    echo "Warning: gh command not found. Skipping GitHub authentication setup." >&2
fi

#==========================================================================================
print_header "Installing zsh-autosuggestions plugin"
#==========================================================================================

ZSH_PLUGINS_DIR="$HOME/.zsh/plugins"
AUTOSUGGESTIONS_DIR="$ZSH_PLUGINS_DIR/zsh-autosuggestions"
AUTOSUGGESTIONS_REPO_URL="https://github.com/zsh-users/zsh-autosuggestions"

if ! command -v git > /dev/null; then
    echo "Error: git not found. Skipping zsh-autosuggestions." >&2
elif [ -d "$AUTOSUGGESTIONS_DIR/.git" ]; then
    echo "zsh-autosuggestions already installed. Pulling latest..."
    (cd "$AUTOSUGGESTIONS_DIR" && git pull) || true
else
    echo "Cloning zsh-autosuggestions to $AUTOSUGGESTIONS_DIR..."
    mkdir -p "$ZSH_PLUGINS_DIR"
    git clone "$AUTOSUGGESTIONS_REPO_URL" "$AUTOSUGGESTIONS_DIR"
fi

#==========================================================================================
print_header "Symlinking dotfiles from $DOTFILES_DIR"
#==========================================================================================

echo "Symlinking .zshrc, .tmux.conf, ..."
echo "Source: $DOTFILES_DIR/zshrc -> Target: $HOME/.zshrc"
ln -sfn "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
touch "$HOME/.zshrc.local"

echo "Source: $DOTFILES_DIR/tmux.conf -> Target: $HOME/.tmux.conf"
ln -sfn "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"

echo ""
echo "Symlinking configurations from $DOTFILES_DIR/config to $HOME/.config/..."
CONFIG_SOURCE_PARENT_DIR="$DOTFILES_DIR/config"
CONFIG_TARGET_PARENT_DIR="$HOME/.config"
mkdir -p "$CONFIG_TARGET_PARENT_DIR"

find "$CONFIG_SOURCE_PARENT_DIR" -mindepth 1 -maxdepth 1 -print0 | while IFS= read -r -d '' source_item_abspath; do
    item_basename=$(basename "$source_item_abspath")
    target_item_abspath="$CONFIG_TARGET_PARENT_DIR/$item_basename"

    echo "  Symlinking: $source_item_abspath -> $target_item_abspath"
    rm -rf "$target_item_abspath" 2>/dev/null || true
    ln -sfn "$source_item_abspath" "$target_item_abspath"
done

echo ""
print_header "Symlinking executables from $DOTFILES_DIR/bin to $HOME/.local/bin"

SOURCE_BIN_DIR="$DOTFILES_DIR/bin"

if [ -d "$SOURCE_BIN_DIR" ]; then
    echo "Source directory for executables: $SOURCE_BIN_DIR"
    echo "Symlinking contents of $SOURCE_BIN_DIR into $TARGET_BIN_DIR..."
    find "$SOURCE_BIN_DIR" -mindepth 1 -maxdepth 1 -print0 | while IFS= read -r -d '' source_script_abspath; do
        script_basename=$(basename "$source_script_abspath")
        target_script_abspath="$TARGET_BIN_DIR/$script_basename"

        echo "  Symlinking: $source_script_abspath -> $target_script_abspath"
        ln -sfn "$source_script_abspath" "$target_script_abspath"
    done
else
    echo "Source directory for executables $SOURCE_BIN_DIR not found. Skipping."
fi

#==========================================================================================
print_header "Setting up Claude Code configuration"
#==========================================================================================

mkdir -p "$HOME/.claude"

CLAUDE_MD_SOURCE="$DOTFILES_DIR/claude/CLAUDE.md"
if [ -f "$CLAUDE_MD_SOURCE" ]; then
    echo "  Symlinking: $CLAUDE_MD_SOURCE -> $HOME/.claude/CLAUDE.md"
    ln -sfn "$CLAUDE_MD_SOURCE" "$HOME/.claude/CLAUDE.md"
fi

echo "Symlinking Claude Code skills from $DOTFILES_DIR/claude-skills to $HOME/.claude/skills"

CLAUDE_SKILLS_SOURCE="$DOTFILES_DIR/claude-skills"
CLAUDE_SKILLS_TARGET="$HOME/.claude/skills"

if [ -d "$CLAUDE_SKILLS_SOURCE" ]; then
    mkdir -p "$CLAUDE_SKILLS_TARGET"
    find "$CLAUDE_SKILLS_SOURCE" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' skill_dir; do
        skill_name=$(basename "$skill_dir")
        echo "  Symlinking: $skill_dir -> $CLAUDE_SKILLS_TARGET/$skill_name"
        ln -sfn "$skill_dir" "$CLAUDE_SKILLS_TARGET/$skill_name"
    done
else
    echo "No claude-skills directory found. Skipping."
fi

#==========================================================================================
print_header "Configuring Git global settings"
#==========================================================================================

if command -v git >/dev/null; then
    echo "Setting git user email: tlrmchlsmth@gmail.com"
    git config --global user.email "tlrmchlsmth@gmail.com"
    echo "Setting git user name: Tyler Michael Smith"
    git config --global user.name "Tyler Michael Smith"
    echo "Setting git pull rebase behavior: false"
    git config --global pull.rebase false
else
    echo "Warning: git command not found. Skipping Git global configuration." >&2
fi

#==========================================================================================
print_header "Installing fzf"
#==========================================================================================

FZF_DIR="$HOME/.fzf"
if [ -d "$FZF_DIR" ]; then
    echo "FZF already installed at $FZF_DIR. Skipping installation."
else
    git clone --depth 1 --branch v0.65.2 https://github.com/junegunn/fzf.git "$FZF_DIR"
fi
"$FZF_DIR/install" --bin
ln -sf "$FZF_DIR/bin/fzf" "$TARGET_BIN_DIR/fzf"

#==========================================================================================
print_header "Setup script finished!"
#==========================================================================================

echo "Review any warnings above."
echo "Restart your shell or run 'source ~/.zshrc' for changes to take effect."
