#! bash oh-my-bash.module
# kitsune theme — dark solid accents, bright text
# Solid decorative elements use 256-color dark palette
# Text elements use bright ANSI colors

_omb_module_require plugin:battery

# ── Dark solid colors for decorative elements (256-color palette) ──
_KIT_DARK_TEAL='\[\e[38;5;30m\]'      # dark cyan/teal for box chars
_KIT_DARK_GREEN='\[\e[38;5;22m\]'     # dark green for time brackets
_KIT_DARK_OLIVE='\[\e[38;5;100m\]'    # dark yellow/olive for path
_KIT_DARK_RED='\[\e[38;5;124m\]'      # dark red for errors
_KIT_DARK_PURPLE='\[\e[38;5;91m\]'    # dark purple for accent
_KIT_DARK_BLUE='\[\e[38;5;24m\]'      # dark blue for SCM

# ── Bright text colors (from kitty palette) ──
_KIT_BRIGHT_WHITE='\[\e[97;1m\]'      # color15 bold white - typed text
_KIT_BRIGHT_GREEN='\[\e[92;1m\]'      # color10 bold green - status
_KIT_BRIGHT_TEAL='\[\e[96;1m\]'       # color14 bold cyan - SSH, battery
_KIT_BRIGHT_RED='\[\e[91m\]'          # color9 red - error

function __powerline_python_venv_prompt {
  local python_venv=""
  if [[ -n "${CONDA_DEFAULT_ENV}" ]]; then
    python_venv="${CONDA_DEFAULT_ENV}"
    PYTHON_VENV_CHAR=${CONDA_PYTHON_VENV_CHAR}
  elif [[ -n "${VIRTUAL_ENV}" ]]; then
    python_venv=$(basename "${VIRTUAL_ENV}")
  fi
  [[ -n "${python_venv}" ]] && echo "${_KIT_DARK_TEAL}${_KIT_DARK_GREEN}${python_venv}${_KIT_BRIGHT_GREEN}"
}

USER_INFO_SSH_CHAR=${I_USER_INFO_SSH_CHAR:=""}
function __ssh_client {
  if [[ -n "${SSH_CLIENT}" ]]; then
    echo "${_KIT_DARK_TEAL}${_KIT_BRIGHT_TEAL}[${USER_INFO_SSH_CHAR}]${_KIT_BRIGHT_GREEN}"
  fi
}

function _user_info {
  local user_info=
  if [[ -n "${SSH_CLIENT}" ]]; then
    user_info="${USER}|🌎@${HOSTNAME%%.*}"
  else
    user_info="${USER}|💻"
  fi
  [[ -n "${user_info}" ]] && echo "${user_info}"
}

function get_symbol_user_info {
  if [ "$(id -u)" = 0 ]; then
    printf "💀"
  else
    printf "🌟"
  fi
}

function _omb_theme_PROMPT_COMMAND() {
  local status=$?

  local TITLEBAR
  case $TERM in
    xterm* | screen)
      TITLEBAR=$'\1\e]0;'$USER@${HOSTNAME%%.*}:${PWD/#$HOME/~}$'\e\\\2' ;;
    *)
      TITLEBAR= ;;
  esac

  local SC=""
  if ((status != 0)); then
    SC="${_KIT_DARK_TEAL}-${_KIT_DARK_GREEN}(${_KIT_BRIGHT_RED}! $status ${_KIT_BRIGHT_GREEN})"
  fi

  local BC=$(battery_percentage)
  [[ $BC == no && $BC == -1 ]] && BC=
  BC=${BC:+${_KIT_DARK_TEAL}-${_KIT_DARK_GREEN}($BC%)}

  PS1=$TITLEBAR
  PS1+="${_KIT_DARK_TEAL}┌─${_KIT_DARK_TEAL}${_KIT_BRIGHT_WHITE}[$(_user_info)]"
  PS1+="${_KIT_DARK_GREEN}[\A]$(__powerline_python_venv_prompt)"
  PS1+="${_KIT_DARK_TEAL}${_KIT_DARK_OLIVE}(\w)$(scm_prompt_info)\n"
  PS1+="${_KIT_DARK_TEAL}└─${_KIT_DARK_TEAL}$(__ssh_client)$BC${_KIT_DARK_GREEN}"
  PS1+="$SC${_KIT_BRIGHT_GREEN}$(get_symbol_user_info)${_KIT_DARK_TEAL}${_KIT_BRIGHT_WHITE} "
}

SCM_THEME_PROMPT_DIRTY=" ${_KIT_DARK_RED}✗"
SCM_THEME_PROMPT_CLEAN=" ${_KIT_BRIGHT_GREEN}✓"
SCM_THEME_PROMPT_PREFIX="${_KIT_DARK_TEAL}("
SCM_THEME_PROMPT_SUFFIX="${_KIT_DARK_TEAL})${_omb_prompt_reset_color}"

_omb_util_add_prompt_command _omb_theme_PROMPT_COMMAND
