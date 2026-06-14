#! bash oh-my-bash.module
# kitsune theme — powerline with solid background blocks

_omb_module_require plugin:battery

_RST='\[\e[0m\]'
_BG_TEAL='\[\e[48;5;23m\]'       # user info bg
_BG_GREEN='\[\e[48;5;22m\]'      # time bg
_BG_OLIVE='\[\e[48;5;58m\]'      # path bg
_BG_PURPLE='\[\e[48;5;53m\]'     # SCM bg
_BG_RED='\[\e[48;5;52m\]'        # error bg
_FG_WHITE='\[\e[97;1m\]'         # bright white text
_FG_GREEN='\[\e[92;1m\]'         # bright green text
_FG_TEAL='\[\e[96;1m\]'          # bright cyan text
_FG_RED='\[\e[91;1m\]'           # bright red text
_FG_YELLOW='\[\e[93;1m\]'        # bright yellow text
_BOX='\[\e[38;5;30m\]'           # box chars (no bg)

_BG_BLUE='\[\e[48;5;24m\]'       # python venv bg
_BG_ORANGE='\[\e[48;5;58m\]'     # npm bg
_BG_CYAN='\[\e[48;5;23m\]'       # battery bg

function __powerline_python_venv_prompt {
  local v=""
  [[ -n "${CONDA_DEFAULT_ENV}" ]] && v="${CONDA_DEFAULT_ENV}"
  [[ -n "${VIRTUAL_ENV}" ]] && v=$(basename "${VIRTUAL_ENV}")
  [[ -n "$v" ]] && echo "${_BG_BLUE}${_FG_WHITE} 🐍 $v ${_RST}"
}

function __npm_env_prompt {
  [[ -n "${npm_package_name}" ]] && echo "${_BG_ORANGE}${_FG_YELLOW} 📦 ${npm_package_name} ${_RST}"
}

USER_INFO_SSH_CHAR=${I_USER_INFO_SSH_CHAR:=""}
function __ssh_client {
  [[ -n "${SSH_CLIENT}" ]] && echo "${_FG_TEAL}[${USER_INFO_SSH_CHAR}]"
}

function _user_info {
  if [[ -n "${SSH_CLIENT}" ]]; then
    echo "${USER}|🌎@${HOSTNAME%%.*}"
  else
    echo "${USER}|💻"
  fi
}

function get_symbol_user_info {
  [[ "$(id -u)" == 0 ]] && printf "💀" || printf "🌟"
}

function _omb_theme_PROMPT_COMMAND() {
  local status=$?

  local TITLEBAR=""
  case $TERM in
    xterm* | screen)
      TITLEBAR=$'\1\e]0;'$USER@${HOSTNAME%%.*}:${PWD/#$HOME/~}$'\e\\\2' ;;
  esac

  local SC=""
  ((status != 0)) && SC="${_BG_RED}${_FG_WHITE} ✗ $status ${_RST}"

  local BC=""
  local bpct=$(battery_percentage)
  [[ "$bpct" != no && "$bpct" != -1 ]] && BC="${_BG_CYAN}${_FG_WHITE} 🔋 ${bpct}% ${_RST}"

  PS1=$TITLEBAR
  PS1+="${_BOX}┌─${_RST}"
  PS1+="${_BG_TEAL}${_FG_WHITE} $(_user_info) ${_RST}"
  PS1+="${_BG_GREEN}${_FG_WHITE} \A ${_RST}"
  PS1+="$(__powerline_python_venv_prompt)"
  PS1+="$(__npm_env_prompt)"
  PS1+="${_BG_OLIVE}${_FG_WHITE} \w ${_RST}"
  PS1+="${_BG_PURPLE}${_FG_WHITE} $(scm_prompt_info) ${_RST}"
  PS1+="\n"
  PS1+="${_BOX}└─${_RST}"
  PS1+="$SC"
  PS1+="$BC"
  PS1+="${_FG_GREEN}$(get_symbol_user_info)${_RST} "
}

SCM_THEME_PROMPT_DIRTY=" ✗"
SCM_THEME_PROMPT_CLEAN=" ✓"
SCM_THEME_PROMPT_PREFIX=""
SCM_THEME_PROMPT_SUFFIX="${_RST}"

_omb_util_add_prompt_command _omb_theme_PROMPT_COMMAND
