# Standalone af-magic-inspired prompt (no OMZ dependency)
# Uses zsh's built-in vcs_info for git branch/status display

autoload -Uz vcs_info
autoload -Uz add-zsh-hook

# Configure vcs_info for git
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:git:*' stagedstr '+'
zstyle ':vcs_info:git:*' formats ' %F{blue}(%F{078}%b%F{214}%u%c%F{blue})%f'
zstyle ':vcs_info:git:*' actionformats ' %F{blue}(%F{078}%b%F{blue}|%F{red}%a%F{214}%u%c%F{blue})%f'

# Run vcs_info before each prompt
add-zsh-hook precmd vcs_info

setopt PROMPT_SUBST

# Dashed separator that accounts for virtualenv/conda prompt width
function _afmagic_dashes {
  local width=$COLUMNS
  if [[ -n "$VIRTUAL_ENV" && -z "$VIRTUAL_ENV_DISABLE_PROMPT" ]]; then
    if [[ -n "$VIRTUAL_ENV_PROMPT" ]]; then
      width=$(( COLUMNS - ${#VIRTUAL_ENV_PROMPT} ))
    else
      width=$(( COLUMNS - ${#${VIRTUAL_ENV:t}} - 3 ))
    fi
  elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
    width=$(( COLUMNS - ${#CONDA_DEFAULT_ENV} - 3 ))
  fi
  printf '%*s' "$width" '' | tr ' ' '-'
}

# af-magic style prompt:
# Line 1: dashed separator (accounts for venv)
# Line 2: directory in green, git info in blue/green, >> prompt in purple
PS1='%F{237}$(_afmagic_dashes)%f
%F{032}%~%f${vcs_info_msg_0_} %(!.%F{red}#.%F{105}>>)%f '
PS2='%F{red}\ %f'
RPS1='%(?..%F{red}%? ↵%f)'
