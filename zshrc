# Profile startup with: ZSH_PROFILE=1 zsh -i -c exit
if [[ -n "$ZSH_PROFILE" ]]; then
  zmodload zsh/zprof
fi

# --- Dotfiles location (resolved from symlink) ---
DOTFILES_DIR="${${(%):-%x}:A:h}"

# --- PATH (early, so tools like starship/fzf are available below) ---
export PATH=$HOME/.local/bin:$PATH
export PATH="$HOME/go/bin:$PATH"

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
fpath+=("$HOME/.config/zsh/.zsh_functions")

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
() {
  local zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
  setopt localoptions extendedglob
  if [[ -n $zcompdump(#qNmh-24) ]]; then
    compinit -C -d "$zcompdump"
  else
    compinit -d "$zcompdump" && command touch "$zcompdump"
  fi
}

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
just() {
    command just "$@"
    local ret=$?
    if [[ -z $JUST_COMPLETE ]]; then
        source <(command just --completions zsh)
        JUST_COMPLETE=1
    fi
    return $ret
}
alias j=just
kubectl() {
    command kubectl "$@"
    local ret=$?
    if [[ -z $KUBECTL_COMPLETE ]]; then
        source <(command kubectl completion zsh)
        KUBECTL_COMPLETE=1
    fi
    return $ret
}
alias k=kubectl

# claudectx tab completion (profile names are fetched live at completion time)
(( $+commands[claudectx] )) && eval "$(claudectx completion zsh)"

if [[ "$(uname 2> /dev/null)" == "Linux" ]]; then
    alias pbcopy='xclip -sel clip'
    alias open='xdg-open'
fi

alias make=safemake.sh

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

# --- Kubernetes: per-shell context isolation ---
if [[ -d ~/.kube/configs ]]; then
  setopt localoptions null_glob
  local cfgs=(~/.kube/configs/*.yaml ~/.kube/configs/*.yml)
  if (( ${#cfgs} )); then
    local _kube_shell=$(mktemp ~/.kube/shell.XXXXXX)
    local _ctx="$(cat ~/.kube/last-context 2>/dev/null || echo pirate)"
    printf 'apiVersion: v1\ncurrent-context: %s\nkind: Config\n' "$_ctx" > "$_kube_shell"
    export KUBECONFIG="$_kube_shell:${(j.:.)cfgs}"
    trap "rm -f '$_kube_shell'" EXIT
  fi
fi

kctx() {
  local ctx="${1:-$(kubectl config get-contexts -o name | fzf --height=~50% --prompt='ctx> ')}"
  [[ -n "$ctx" ]] && kubectl config use-context "$ctx" && echo "$ctx" > ~/.kube/last-context
}
kns() {
  local ns="${1:-$(kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | fzf --height=~50% --prompt='ns> ')}"
  [[ -n "$ns" ]] && kubectl config set-context --current --namespace="$ns"
}

kubeimport() {
  local force=0
  if [[ "$1" == "-f" ]]; then
    force=1
    shift
  fi
  if (( $# > 1 )); then
    echo "usage: kubeimport [-f] [name]" >&2
    return 2
  fi

  local name
  if (( $# == 1 )); then
    name="$1"
  else
    local current="$(kubectl config current-context 2>/dev/null)"
    read "name?kubeconfig name [$current]: " || return
    name="${name:-$current}"
  fi
  if [[ -z "$name" || "$name" == *[^A-Za-z0-9._-]* ]]; then
    echo "kubeimport: name must contain only letters, numbers, '.', '_', or '-'" >&2
    return 2
  fi

  local source_context="$(kubectl config current-context 2>/dev/null)"
  if [[ -z "$source_context" ]]; then
    echo "kubeimport: no current context to import" >&2
    return 1
  fi
  local source_server="$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null)"

  local dir="$HOME/.kube/configs"
  local dest="$dir/$name.yaml"
  mkdir -p "$dir" || return
  chmod 700 "$HOME/.kube" "$dir" || return
  if [[ -e "$dest" && $force -eq 0 ]]; then
    local dest_context="$(KUBECONFIG="$dest" command kubectl config current-context 2>/dev/null)"
    local dest_server="$(KUBECONFIG="$dest" command kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null)"
    if [[ "$dest_context" != "$source_context" && "$dest_context" != "$name" ]] ||
       [[ -z "$source_server" || "$dest_server" != "$source_server" ]]; then
      echo "kubeimport: $dest contains context '$dest_context' (use -f to replace it)" >&2
      return 1
    fi
  fi

  local tmp=$(mktemp "$dir/.$name.XXXXXX") || return
  chmod 600 "$tmp"
  if ! kubectl config view --minify --flatten --raw > "$tmp" ||
     ! KUBECONFIG="$tmp" command kubectl config current-context &>/dev/null; then
    rm -f "$tmp"
    echo "kubeimport: could not export the current context" >&2
    return 1
  fi
  if [[ "$source_context" != "$name" ]] &&
     ! KUBECONFIG="$tmp" command kubectl config rename-context "$source_context" "$name" &>/dev/null; then
    rm -f "$tmp"
    echo "kubeimport: could not rename context '$source_context' to '$name'" >&2
    return 1
  fi

  mv -f "$tmp" "$dest" || return
  echo "$name" > "$HOME/.kube/last-context" || return
  if ! kubectl config use-context "$name" &>/dev/null; then
    echo "kubeimport: imported $name, but could not activate it in this shell" >&2
    return 1
  fi
  echo "Imported $source_context as $name into $dest"
}

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
      [[ -n "$VIRTUAL_ENV" ]] && type deactivate &>/dev/null && deactivate
      source "$venv_path/bin/activate"
    fi
  elif [[ -n "$VIRTUAL_ENV" ]]; then
    type deactivate &>/dev/null && deactivate
  fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd _auto_venv
_auto_venv  # Run on shell start
[[ -n "$ZSH_PROFILE" ]] && zprof
