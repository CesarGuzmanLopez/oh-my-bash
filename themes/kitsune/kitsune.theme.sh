#! bash oh-my-bash.module
# kitsune theme — dynamic bg colors from kitty wallpaper palette

_omb_module_require plugin:battery

_RST='\[\e[0m\]'
_FG_WHITE='\[\e[97;1m\]'
_FG_GREEN='\[\e[92;1m\]'
_FG_TEAL='\[\e[96;1m\]'
_FG_RED='\[\e[91;1m\]'
_FG_YELLOW='\[\e[93;1m\]'
_FG_TEAL_D='\[\e[38;5;30m\]'
_FG_OLIVE_D='\[\e[38;5;100m\]'

# Load dynamic background colors from kitty palette
function _omb_theme_load_colors {
  local conf="$HOME/.config/kitty/current-theme.conf"
  [[ -f "$conf" ]] || return

  # Extract color1-6 hex values (dark versions → good for bg)
  local colors=()
  local i c hex r g b
  for ((i=1; i<=6; i++)); do
    hex=$(grep -m1 "^color${i}" "$conf" 2>/dev/null | grep -oE '#[0-9a-fA-F]{6}' | tail -1)
    if [[ -n "$hex" ]]; then
      r=$((16#${hex:1:2}))
      g=$((16#${hex:3:2}))
      b=$((16#${hex:5:2}))
      # Darken to 30% for bg
      r=$((r * 30 / 100))
      g=$((g * 30 / 100))
      b=$((b * 30 / 100))
      colors+=("\e[48;2;${r};${g};${b}m")
    fi
  done

  # Fallback defaults if colors not found
  local _defaults=('\e[48;5;22m' '\e[48;5;52m' '\e[48;5;23m' '\e[48;5;53m' '\e[48;5;58m' '\e[48;5;24m')

  for ((i=0; i<6; i++)); do
    [[ -z "${colors[$i]}" ]] && colors[$i]="${_defaults[$i]}"
  done

  # time=green(color2), SCM=purple(color5), error=red(color1), python=blue(color4), npm=orange(color3), env=teal(color6)
  _BG_TIME="\[${colors[1]}\]"       # color2 darkened
  _BG_SCM="\[${colors[4]}\]"        # color5 darkened
  _BG_ERROR="\[${colors[0]}\]"      # color1 darkened
  _BG_PYTHON="\[${colors[3]}\]"     # color4 darkened
  _BG_NPM="\[${colors[2]}\]"        # color3 darkened
  _BG_ENV="\[${colors[5]}\]"        # color6 darkened
}

# Initialize colors
_omb_theme_load_colors

function __powerline_python_venv_prompt {
  local v=""
  [[ -n "${CONDA_DEFAULT_ENV}" ]] && v="${CONDA_DEFAULT_ENV}"
  [[ -n "${VIRTUAL_ENV}" ]] && v=$(basename "${VIRTUAL_ENV}")
  [[ -n "$v" ]] && echo " ${_BG_PYTHON:-\[\e[48;5;24m\]}${_FG_WHITE} 🐍 $v ${_RST}"
}

function __npm_env_prompt {
  [[ -n "${npm_package_name}" ]] && echo " ${_BG_NPM:-\[\e[48;5;58m\]}${_FG_YELLOW} 📦 ${npm_package_name} ${_RST}"
}

function _user_info {
  [[ -n "${SSH_CLIENT}" ]] && echo "${USER}|🌎@${HOSTNAME%%.*}" || echo "${USER}|💻"
}

function get_symbol_user_info {
  [[ "$(id -u)" == 0 ]] && printf "💀" || printf "🌟"
}

function _omb_theme_PROMPT_COMMAND() {
  local status=$?
  local TITLEBAR=""
  case $TERM in
    xterm*|screen) TITLEBAR=$'\1\e]0;'$USER@${HOSTNAME%%.*}:${PWD/#$HOME/~}$'\e\\\2' ;;
  esac

  local SC=""
  ((status != 0)) && SC=" ${_BG_ERROR:-\[\e[48;5;52m\]}${_FG_WHITE} ✗ $status ${_RST}"

  local bpct=$(battery_percentage 2>/dev/null)
  local BC=""
  if [[ -n "$bpct" && "$bpct" != "no" && "$bpct" != "-1" && "$bpct" != "100%" && "$bpct" != "0%" ]]; then
    BC=" ${_FG_TEAL_D}($bpct)${_RST}"
  fi

  PS1=$TITLEBAR
  PS1+="${_FG_TEAL_D}┌─${_FG_WHITE}[$(_user_info)]"
  PS1+=" ${_BG_TIME:-\[\e[48;5;22m\]}${_FG_WHITE}[\A]${_RST}"
  PS1+="$(__powerline_python_venv_prompt)"
  PS1+="$(__npm_env_prompt)"
  PS1+=" ${_FG_OLIVE_D}(\w)${_RST}"

  local scm_out=$(scm_prompt_info)
  if [[ -n "$scm_out" ]]; then
    PS1+=" ${_BG_SCM:-\[\e[48;5;53m\]}${_FG_WHITE}(${scm_out})${_RST}"
  fi

  PS1+="\n${_FG_TEAL_D}└─${_RST}$SC$BC"
  PS1+=" ${_FG_GREEN}$(get_symbol_user_info)${_FG_TEAL_D}${_FG_WHITE} "
}

SCM_THEME_PROMPT_DIRTY=" ✗"
SCM_THEME_PROMPT_CLEAN=" ✓"
SCM_THEME_PROMPT_PREFIX=""
SCM_THEME_PROMPT_SUFFIX=""

_omb_util_add_prompt_command _omb_theme_PROMPT_COMMAND
