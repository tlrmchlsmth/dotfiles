# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="af-magic"
#ZSH_THEME="robbyrussell"
#ZSH_THEME="agnoster"

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# ZSH update stuff
# DISABLE_AUTO_UPDATE="true"
# DISABLE_UPDATE_PROMPT="true"
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Disable auto-setting terminal title. (doesnt work -tms)
DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# Fix af-magic dash calculation for venvs (uses displayed name, not full path)
function afmagic_dashes {
  if [[ -n "$VIRTUAL_ENV" && -z "$VIRTUAL_ENV_DISABLE_PROMPT" && -n "$VIRTUAL_ENV_PROMPT" ]]; then
    echo $(( COLUMNS - ${#VIRTUAL_ENV_PROMPT} ))
  elif [[ -n "$VIRTUAL_ENV" && -z "$VIRTUAL_ENV_DISABLE_PROMPT" ]]; then
    echo $(( COLUMNS - ${#${VIRTUAL_ENV:t}} - 3 ))
  elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
    echo $(( COLUMNS - ${#CONDA_DEFAULT_ENV} - 3 ))
  else
    echo $COLUMNS
  fi
}

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
#if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
#fi
export EDITOR='nvim'

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

setopt histignorealldups sharehistory

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Keep 100000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history

# Use modern completion system
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
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

#This works well if using solarized
#ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666,italic" ##ff00ff,bg=cyan,bold,underline"

#Tyler's aliases
alias vi=nvim
alias j=just
alias k=kubectl

if [[ "$(uname 2> /dev/null)" == "Linux" ]] 
then
    alias pbcopy='xclip -sel clip'
    alias open='xdg-open'
fi

alias make=safemake.sh

export PATH=$HOME/.local/bin:$PATH
export PATH="$HOME/go/bin:$PATH"

export CUDA_HOME=/usr/local/cuda
export CUDA_TOOLKIT_ROOT_DIR=$CUDA_HOME
export PATH=$PATH:$CUDA_HOME/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CUDA_HOME/lib64
export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:$CUDA_HOME/include

export TERM=screen-256color-bce

#alacritty autocomplete stuff
fpath+=~/.config/zsh/.zsh_functions

# Source env local to this machine
local_rc="$HOME/.zshrc.local"
[[ -f $local_rc ]] && source "$local_rc"

# Faster vLLM builds
CCACHE_NOHASHDIR="true"
export VLLM_LOGGING_LEVEL="debug"

# Auto-activate/deactivate Python virtualenvs
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
