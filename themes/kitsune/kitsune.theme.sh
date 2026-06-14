#! bash oh-my-bash.module
# kitsune theme — solid bg only on time, git, and envs

_omb_module_require plugin:battery

_RST='\[\e[0m\]'
_BG_GREEN='\[\e[48;5;22m\]'      # time bg
_BG_PURPLE='\[\e[48;5;53m\]'     # SCM bg
_BG_RED='\[\e[48;5;52m\]'        # error bg
_BG_BLUE='\[\e[48;5;24m\]'       # python venv bg
_BG_ORANGE='\[\e[48;5;58m\]'     # npm bg
_FG_WHITE='\[\e[97;1m\]'         # bright white text
_FG_GREEN='\[\e[92;1m\]'         # bright green
_FG_TEAL='\[\e[96;1m\]'          # bright cyan
_FG_RED='\[\e[91;1m\]'           # bright red
_FG_YELLOW='\[\e[93;1m\]'        # bright yellow
_FG_TEAL_D='\[\e[38;5;30m\]'     # dark teal (no bg)
_FG_OLIVE_D='\[\e[38;5;100m\]'   # dark olive (no bg)

function __powerline_python_venv_prompt {
  local v=""
  [[ -n "${CONDA_DEFAULT_ENV}" ]] && v="${CONDA_DEFAULT_ENV}"
  [[ -n "${VIRTUAL_ENV}" ]] && v=$(basename "${VIRTUAL_ENV}")
  [[ -n "$v" ]] && echo " ${_BG_BLUE}${_FG_WHITE} 🐍 $v ${_RST}"
}

function __npm_env_prompt {
  [[ -n "${npm_package_name}" ]] && echo " ${_BG_ORANGE}${_FG_YELLOW} 📦 ${npm_package_name} ${_RST}"
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
  ((status != 0)) && SC=" ${_BG_RED}${_FG_WHITE} ✗ $status ${_RST}"

  # Battery — only show if there's a battery
  local bpct=$(battery_percentage 2>/dev/null)
  local BC=""
  if [[ -n "$bpct" && "$bpct" != "no" && "$bpct" != "-1" && "$bpct" != "100%" && "$bpct" != "0%" ]]; then
    BC=" ${_FG_TEAL_D}($bpct)${_RST}"
  fi

  PS1=$TITLEBAR
  PS1+="${_FG_TEAL_D}┌─${_FG_WHITE}[$(_user_info)]"
  PS1+=" ${_BG_GREEN}${_FG_WHITE}[\A]${_RST}"
  PS1+="$(__powerline_python_venv_prompt)"
  PS1+="$(__npm_env_prompt)"
  PS1+=" ${_FG_OLIVE_D}(\w)${_RST}"
  PS1+=" ${_BG_PURPLE}${_FG_WHITE}($(scm_prompt_info))${_RST}"
  PS1+="\n${_FG_TEAL_D}└─${_RST}$SC$BC"
  PS1+=" ${_FG_GREEN}$(get_symbol_user_info)${_FG_TEAL_D}${_FG_WHITE} "
}

SCM_THEME_PROMPT_DIRTY=" ✗"
SCM_THEME_PROMPT_CLEAN=" ✓"
SCM_THEME_PROMPT_PREFIX=""
SCM_THEME_PROMPT_SUFFIX=""

_omb_util_add_prompt_command _omb_theme_PROMPT_COMMAND
