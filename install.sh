#!/usr/bin/env bash

# Exit on error, treat unset variables as error (unless default is provided),
# and ensure pipe commands fail if any command in the pipe fails.
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
# Leading ':' in optstring enables silent error handling for getopts
# 'g:' and 'h:' expect arguments
while getopts ":g:h:" opt; do
  case ${opt} in
    g )
      ARG_GH_TOKEN="$OPTARG"
      ;;
    h )
      ARG_HF_TOKEN="$OPTARG"
      ;;
    \? ) # Invalid option
      echo "Invalid option: -$OPTARG" 1>&2
      print_usage
      exit 1
      ;;
    : ) # Missing option argument
      echo "Invalid option: -$OPTARG requires an argument" 1>&2
      print_usage
      exit 1
      ;;
  esac
done
shift $((OPTIND -1)) # Remove parsed options and their arguments from $@

# --- Helper: Print section headers ---
print_header() {
    echo ""
    echo "---------------------------------------------------------------------"
    echo "$1"
    echo "---------------------------------------------------------------------"
}

# --- Determine sudo command ---
SUDO_CMD=""
PRIVILEGED_OPERATION_FAILED_MESSAGE="Privileged operations may fail. Ensure you have appropriate permissions or that sudo is configured for passwordless access if running non-interactively."

if [ "$(id -u)" -ne 0 ]; then # If not root
    if command -v sudo >/dev/null 2>&1; then # If sudo is available
        if sudo -n true >/dev/null 2>&1; then # Check if sudo can be run without a password
            SUDO_CMD="sudo -n" # Use non-interactive sudo
            echo "Using 'sudo -n' for privileged operations."
        else
            echo "Warning: sudo is available but requires a password or is not configured for current user's non-interactive use for all commands." >&2
            echo "$PRIVILEGED_OPERATION_FAILED_MESSAGE" >&2
            # SUDO_CMD remains empty, commands will be attempted without sudo.
        fi
    else
        echo "Warning: Running as non-root user and sudo command not found." >&2
        echo "$PRIVILEGED_OPERATION_FAILED_MESSAGE" >&2
        # SUDO_CMD remains empty
    fi
else
    echo "Running as root. Privileged operations will be executed directly."
fi


# --- Setup Directories ---
TARGET_BIN_DIR="$HOME/.local/bin"
mkdir -p $TARGET_BIN_DIR

#==========================================================================================
print_header "Installing/Updating Neovim (Stable)"
#==========================================================================================

NVIM_TARBALL_URL="https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz"
NVIM_INSTALL_DIR="/opt/nvim"                        # final install dir
NVIM_SYMLINK_PATH="${TARGET_BIN_DIR}/nvim"         # e.g. /usr/local/bin/nvim

echo "Downloading Neovim tarball..."
TMP_TARBALL="$(mktemp)"
if command -v curl >/dev/null 2>&1; then
  curl -fsSL -o "${TMP_TARBALL}" "${NVIM_TARBALL_URL}"
else
  wget -qO "${TMP_TARBALL}" "${NVIM_TARBALL_URL}"
fi

# Extract into a staging dir, stripping the top-level folder
STAGE_DIR="$(mktemp -d)"
mkdir -p "${STAGE_DIR}/nvim"
if ! tar -xzf "${TMP_TARBALL}" --strip-components=1 -C "${STAGE_DIR}/nvim"; then
  echo "Failed to extract Neovim tarball."
  rm -rf "${STAGE_DIR}" "${TMP_TARBALL}"
  exit 1
fi
rm -f "${TMP_TARBALL}"

# Atomically replace existing install
$SUDO_CMD rm -rf "${NVIM_INSTALL_DIR}"
$SUDO_CMD mkdir -p "$(dirname "${NVIM_INSTALL_DIR}")"
$SUDO_CMD mv "${STAGE_DIR}/nvim" "${NVIM_INSTALL_DIR}"
rm -rf "${STAGE_DIR}"

# Ensure bin dir exists and symlink
$SUDO_CMD mkdir -p "${TARGET_BIN_DIR}"
echo "Creating symlink ${NVIM_SYMLINK_PATH} -> ${NVIM_INSTALL_DIR}/bin/nvim"
$SUDO_CMD ln -sf "${NVIM_INSTALL_DIR}/bin/nvim" "${NVIM_SYMLINK_PATH}"

# Verify
"${NVIM_SYMLINK_PATH}" --version | head -n1
#==========================================================================================

print_header "Installing pynvim Python package"
pip3 install -U pynvim --break-system-packages # User-level or system-wide if root, no explicit sudo

# --- GitHub CLI Installation & Login ---
print_header "Installing GitHub CLI"
if ! type -p gh > /dev/null; then
    echo "GitHub CLI not found. Installing..."
    DOWNLOAD_TOOL_CMD=""
    if command -v curl >/dev/null 2>&1; then
        DOWNLOAD_TOOL_CMD="curl -fsSL" # Used for piping GPG key
    elif command -v wget >/dev/null 2>&1; then
        DOWNLOAD_TOOL_CMD="wget -qO-" # Used for piping GPG key
    fi

    if [ -n "$DOWNLOAD_TOOL_CMD" ]; then
        KEYRING_DIR="/etc/apt/keyrings"
        KEYRING_PATH="$KEYRING_DIR/githubcli-archive-keyring.gpg"
        SOURCES_LIST_PATH="/etc/apt/sources.list.d/github-cli.list"

        $SUDO_CMD mkdir -p -m 755 "$KEYRING_DIR"
        # shellcheck disable=SC2086 # We want word splitting for $DOWNLOAD_TOOL_CMD
        eval "$DOWNLOAD_TOOL_CMD https://cli.github.com/packages/githubcli-archive-keyring.gpg" | $SUDO_CMD tee "$KEYRING_PATH" > /dev/null
        $SUDO_CMD chmod go+r "$KEYRING_PATH"
        
        echo "deb [arch=$(dpkg --print-architecture) signed-by=$KEYRING_PATH] https://cli.github.com/packages stable main" | $SUDO_CMD tee "$SOURCES_LIST_PATH" > /dev/null
        
        env DEBIAN_FRONTEND=noninteractive $SUDO_CMD apt-get update -qq
        env DEBIAN_FRONTEND=noninteractive $SUDO_CMD apt-get install -y gh
        echo "GitHub CLI installed."
    else
        echo "Error: Neither curl nor wget is available to download GitHub CLI GPG key. Skipping gh installation." >&2
    fi
else
    echo "GitHub CLI is already installed."
fi

print_header "Setting up GitHub authentication"
if command -v gh >/dev/null; then
    if [ -n "$ARG_GH_TOKEN" ]; then # Use parsed argument
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

# --- Dotfiles Setup ---
DOTFILES_REPO_URL="https://github.com/tlrmchlsmth/dotfiles"
DOTFILES_DIR="$PWD"

print_header "Cloning/Updating dotfiles repository"
echo "Dotfiles repository: $DOTFILES_REPO_URL"
echo "Target directory: $DOTFILES_DIR"

if command -v git >/dev/null; then
    if [ -d "$DOTFILES_DIR/.git" ]; then
        echo "$DOTFILES_DIR already exists and is a git repository. Pulling latest changes..."
        (cd "$DOTFILES_DIR" && git pull)
    elif [ -d "$DOTFILES_DIR" ]; then
        BACKUP_DIR="$DOTFILES_DIR.bak.$(date +%Y%m%d%H%M%S)"
        echo "Warning: $DOTFILES_DIR exists but is not a git repository." >&2
        echo "Backing it up to $BACKUP_DIR and cloning anew."
        mv "$DOTFILES_DIR" "$BACKUP_DIR"
        git clone "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
    else
        echo "Cloning repository..."
        git clone -b nvim_lua_setup "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
    fi
else
    echo "Error: git command not found. Cannot clone dotfiles repository." >&2
fi


# --- Oh My Zsh and Plugins ---
OHMYZSH_DIR="$HOME/.oh-my-zsh"
OHMYZSH_INSTALL_SCRIPT_URL="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

print_header "Installing Oh My Zsh"
if [ -d "$OHMYZSH_DIR" ]; then
    echo "Oh My Zsh already installed at $OHMYZSH_DIR. Skipping installation."
    echo "You can update Oh My Zsh manually by running 'omz update' (if using zsh)."
elif ! command -v git > /dev/null; then
    echo "Error: git command not found. Oh My Zsh installation requires git. Skipping." >&2
elif ! command -v zsh > /dev/null; then
    echo "Error: zsh command not found. Oh My Zsh installation requires zsh. Skipping." >&2
else
    INSTALL_CMD_BASE=""
    if command -v curl >/dev/null 2>&1; then
        INSTALL_CMD_BASE="curl -fsSL $OHMYZSH_INSTALL_SCRIPT_URL"
    elif command -v wget >/dev/null 2>&1; then
        INSTALL_CMD_BASE="wget -qO- $OHMYZSH_INSTALL_SCRIPT_URL"
    fi

    if [ -n "$INSTALL_CMD_BASE" ]; then
        echo "Installing Oh My Zsh..."
        # CHSH=yes attempts to change shell, RUNZSH=no prevents it from starting zsh after install
        # The "" --unattended arguments are passed to the install script
        # Using sh -c "..." to execute the downloaded script content
        env CHSH=no RUNZSH=no sh -c "$(eval "$INSTALL_CMD_BASE")" "" --unattended || echo "Oh My Zsh installer finished, possibly with non-critical errors (e.g., chsh failure in some environments)." >&2
    else
        echo "Error: curl or wget not found for Oh My Zsh installation. Skipping." >&2
    fi
fi

print_header "Installing zsh-autosuggestions plugin"
if [ ! -d "$OHMYZSH_DIR" ]; then
    echo "Oh My Zsh is not installed at $OHMYZSH_DIR. Skipping zsh-autosuggestions plugin." >&2
elif ! command -v git > /dev/null; then
    echo "Error: git command not found. zsh-autosuggestions installation requires git. Skipping." >&2
else
    ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}" # ZSH_CUSTOM usually set by Oh My Zsh sourcing
    AUTOSUGGESTIONS_PLUGIN_DIR="$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
    AUTOSUGGESTIONS_REPO_URL="https://github.com/zsh-users/zsh-autosuggestions"

    if [ -d "$AUTOSUGGESTIONS_PLUGIN_DIR/.git" ]; then
        echo "zsh-autosuggestions already installed. Pulling latest changes..."
        (cd "$AUTOSUGGESTIONS_PLUGIN_DIR" && git pull)
    else
        echo "Cloning zsh-autosuggestions to $AUTOSUGGESTIONS_PLUGIN_DIR..."
        mkdir -p "$ZSH_CUSTOM_DIR/plugins" # Ensure parent plugins directory exists
        git clone "$AUTOSUGGESTIONS_REPO_URL" "$AUTOSUGGESTIONS_PLUGIN_DIR"
    fi
fi


# --- Symlinking Dotfiles ---
print_header "Symlinking dotfiles from $DOTFILES_DIR"

# Symlinking .zshrc (this part remains the same)
echo "Symlinking .zshrc..."
echo "Source: $DOTFILES_DIR/zshrc -> Target: $HOME/.zshrc"
ln -sfn "$DOTFILES_DIR/zshrc" "$HOME/.zshrc" # -sfn is generally fine for single files like .zshrc
touch "$HOME/.zshrc.local" # Create an empty local zshrc

echo ""
echo "Symlinking configurations from $DOTFILES_DIR/config to $HOME/.config/..."
CONFIG_SOURCE_PARENT_DIR="$DOTFILES_DIR/config"
CONFIG_TARGET_PARENT_DIR="$HOME/.config"

# Ensure the parent target directory (e.g., $HOME/.config) exists
mkdir -p "$CONFIG_TARGET_PARENT_DIR"

# Find all top-level items (files and directories) in the source config directory
# and symlink them directly to the target config directory.
find "$CONFIG_SOURCE_PARENT_DIR" -mindepth 1 -maxdepth 1 -print0 | while IFS= read -r -d '' source_item_abspath; do
    item_basename=$(basename "$source_item_abspath")
    target_item_abspath="$CONFIG_TARGET_PARENT_DIR/$item_basename"

    echo "  Symlinking: $source_item_abspath -> $target_item_abspath"
    # Use -sfT to ensure the target is treated as the link name itself,
    # and force overwrite if it exists (even if it's a directory).
    ln -sfT "$source_item_abspath" "$target_item_abspath"
done

echo ""
# Updated section for symlinking executables (this should be fine from previous change)
print_header "Symlinking executables from $DOTFILES_DIR/bin to $HOME/.local/bin"

SOURCE_BIN_DIR="$DOTFILES_DIR/bin"

if [ -d "$SOURCE_BIN_DIR" ]; then
    echo "Source directory for executables: $SOURCE_BIN_DIR"

    echo "Symlinking contents of $SOURCE_BIN_DIR into $TARGET_BIN_DIR..."
    find "$SOURCE_BIN_DIR" -mindepth 1 -maxdepth 1 -print0 | while IFS= read -r -d '' source_script_abspath; do
        script_basename=$(basename "$source_script_abspath")
        target_script_abspath="$TARGET_BIN_DIR/$script_basename"

        echo "  Symlinking: $source_script_abspath -> $target_script_abspath"
        ln -sfn "$source_script_abspath" "$target_script_abspath" # -sfn is usually fine here as individual files are targeted within an existing dir
    done
else
    echo "Source directory for executables $SOURCE_BIN_DIR not found. Skipping executable symlinking."
fi



# --- Git Configuration ---
print_header "Configuring Git global settings"
if command -v git >/dev/null; then
    echo "Setting git user email: tysmith@redhat.com"
    git config --global user.email "tysmith@redhat.com"
    echo "Setting git user name: Tyler Michael Smith"
    git config --global user.name "Tyler Michael Smith"
    echo "Setting git pull rebase behavior: false"
    git config --global pull.rebase false
else
    echo "Warning: git command not found. Skipping Git global configuration." >&2
fi

print_header "Setup script finished!"
echo "Review any warnings above."
echo "If Oh My Zsh was installed or zshrc was updated, please restart your shell or source your .zshrc (e.g., 'source ~/.zshrc') for changes to take full effect."
echo "If Oh My Zsh changed your default shell (and chsh succeeded), you might need to log out and log back in or start a new zsh shell."
