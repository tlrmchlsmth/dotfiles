# --- Dotfiles location (resolved from symlink) ---
DOTFILES_DIR="${${(%):-%x}:A:h}"

# --- Prompt ---
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
else
  source "$DOTFILES_DIR/zsh/prompt.zsh"
fi

# --- Git aliases ---
source "$DOTFILES_DIR/zsh/git-aliases.zsh"

# --- Plugins ---
# Extra completions (must be added to fpath before compinit)
[[ -d "$HOME/.zsh/plugins/zsh-completions/src" ]] && \
  fpath=("$HOME/.zsh/plugins/zsh-completions/src" $fpath)

# fzf-tab (must be sourced before compinit-dependent plugins)
[[ -f "$HOME/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh" ]] && \
  source "$HOME/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh"

# Inline history suggestions
[[ -f "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
  source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

# --- Editor ---
export EDITOR='nvim'

# --- History ---
setopt histignorealldups sharehistory

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history

# --- Completion system ---
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

autoload -Uz compinit
compinit

# --- fzf integration (Ctrl-R: history, Ctrl-T: files, Alt-C: cd) ---
source <(fzf --zsh) 2>/dev/null

# fzf-tab styling
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always $realpath 2>/dev/null || ls -1 $realpath'
zstyle ':fzf-tab:*' fzf-flags --height=~50%

# --- Colors ---
if (( $+commands[dircolors] )); then
    eval "$(dircolors -b)"
elif (( $+commands[gdircolors] )); then
    eval "$(gdircolors -b)"
fi

if ls --color=auto / &>/dev/null; then
    alias ls='ls --color=auto'
else
    alias ls='ls -G'
fi

# --- Aliases ---
alias vi=nvim
alias j=just
alias k=kubectl

if [[ "$(uname 2> /dev/null)" == "Linux" ]]; then
    alias pbcopy='xclip -sel clip'
    alias open='xdg-open'
fi

alias make=safemake.sh

# --- PATH ---
export PATH=$HOME/.local/bin:$PATH
export PATH="$HOME/go/bin:$PATH"

# --- CUDA (only if present) ---
if [[ -d /usr/local/cuda ]]; then
    export CUDA_HOME=/usr/local/cuda
    export CUDA_TOOLKIT_ROOT_DIR=$CUDA_HOME
    export PATH=$PATH:$CUDA_HOME/bin
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$CUDA_HOME/lib64
    export CPLUS_INCLUDE_PATH=${CPLUS_INCLUDE_PATH:+$CPLUS_INCLUDE_PATH:}$CUDA_HOME/include
fi

# --- TERM fix ---
# Fix TERM if set to something invalid (e.g., screen-* outside of tmux/screen,
# or a terminfo that doesn't exist on this machine)
if [[ -z "$TMUX" && -z "$STY" ]]; then
    if [[ "$TERM" == screen-* || "$TERM" == tmux-* ]] || ! infocmp "$TERM" &>/dev/null; then
        export TERM=xterm-256color
    fi
fi

# Set TERM inside tmux/screen, preferring bce variant if available
if [[ -n "$TMUX" ]]; then
    if infocmp screen-256color-bce &>/dev/null; then
        export TERM=screen-256color-bce
    elif infocmp screen-256color &>/dev/null; then
        export TERM=screen-256color
    fi
fi

# --- Extra paths ---
fpath+=~/.config/zsh/.zsh_functions

# --- Local overrides ---
local_rc="$HOME/.zshrc.local"
[[ -f $local_rc ]] && source "$local_rc"

# --- Build settings ---
CCACHE_NOHASHDIR="true"
export VLLM_LOGGING_LEVEL="debug"

# --- Auto-activate/deactivate Python virtualenvs ---
function _find_venv() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.venv/bin/activate" ]]; then
      echo "$dir/.venv"
      return
    fi
    dir="${dir:h}"
  done
}

function _auto_venv() {
  local venv_path=$(_find_venv)

  if [[ -n "$venv_path" ]]; then
    if [[ "$VIRTUAL_ENV" != "$venv_path" ]]; then
      [[ -n "$VIRTUAL_ENV" ]] && deactivate
      source "$venv_path/bin/activate"
    fi
  elif [[ -n "$VIRTUAL_ENV" ]]; then
    deactivate
  fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd _auto_venv
_auto_venv  # Run on shell start
