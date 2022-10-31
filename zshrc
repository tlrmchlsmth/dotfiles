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

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
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
alias pbcopy='xclip -sel clip'

if [[ "$(uname 2> /dev/null)" == "Linux" ]] 
then
    alias open='xdg-open'
fi

alias make=safemake.sh

#NYANN env variables
export NYANN_ROOT_DIR=/home/tms/code/wand
export NYANN_BIN_DIR=$NYANN_ROOT_DIR/bin
export NYANN_DATA_DIR=$NYANN_ROOT_DIR/test-data
export NYANN_OUT_DIR=/dev/null
export PATH="$PATH:$NYANN_ROOT_DIR/tools"

#NYANN options
export COMPILER=clang++
export USE_LINKER=mold
export NM_LOGGING_LEVEL=4
export LOGGING_LEVEL=0
export NM_VERSION_CHECK=false
export NM_BIND_THREADS_TO_CORES=1

cwd=$PWD
cd $NYANN_ROOT_DIR
#source integration/nm_test/nm_test_env.sh avx512 > /dev/null
cd $cwd

#BOOST env variables
export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH
export LIBRARY_PATH=$HOME/.local/lib:$LIBRARY_PATH
export CPLUS_INCLUDE_PATH=$HOME/.local/include:$CPLUS_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=$HOME/code/wand/external/boost/include:$CPLUS_INCLUDE_PATH

#Building engine faster
#export CCACHE_COMPILER_DIR=/usr/lib/ccache
#export USE_LINKER=lld


export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.local/arcanist/bin:$PATH

#export PYTHONPATH=$HOME/code/neuralmagicml-pytorch:$HOME/code/neuralmagic-base:$PYTHONPATH

export TERM=screen-256color-bce

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

#some ruby stuff
export GEM_HOME="$HOME/gems"
export PATH="$HOME/gems/bin:$PATH"

#alacritty autocomplete stuff
fpath+=~/.config/zsh/.zsh_functions
