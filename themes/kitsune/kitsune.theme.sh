#! bash oh-my-bash.module
# This is combination of works from two different people which I combined for my requirement.
# Original PS1 was from reddit user /u/Allevil669 which I found in thread: https://www.reddit.com/r/linux/comments/1z33lj/linux_users_whats_your_favourite_bash_prompt/
# I used that PS1 to the bash-it theme 'morris', and customized it to my liking. All credits to /u/Allevil669 and morris.
#
# prompt theming

_omb_module_require plugin:battery

function __powerline_python_venv_prompt {
  local python_venv=""
  if [[ -n "${CONDA_DEFAULT_ENV}" ]]; then
    python_venv="${CONDA_DEFAULT_ENV}"
    PYTHON_VENV_CHAR=${CONDA_PYTHON_VENV_CHAR}
  elif [[ -n "${VIRTUAL_ENV}" ]]; then
    python_venv=$(basename "${VIRTUAL_ENV}")
  fi
  [[ -n "${python_venv}" ]] && echo "$_omb_prompt_teal$_omb_prompt_bold_green${_omb_prompt_bold_black}(${python_venv})$_omb_prompt_bold_green"
}

USER_INFO_SSH_CHAR=${I_USER_INFO_SSH_CHAR:=""}
function __ssh_client {
  if [[ -n "${SSH_CLIENT}" ]]; then
    echo "$_omb_prompt_teal$_omb_prompt_bold_green${_omb_prompt_bold_white}[${USER_INFO_SSH_CHAR}]$_omb_prompt_bold_green"
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
  local user_symbol=
  if [ "$(id -u)" = 0 ]; then
    printf "💀"
  else
      printf "🌟"
  fi
}


HOST_INFO_HOST=${I_HOST_INFO_HOST:="⊥"}
function _omb_theme_PROMPT_COMMAND() {
  local status=$?

  # added TITLEBAR for updating the tab and window titles with the pwd
  local TITLEBAR
  case $TERM in
    xterm* | screen)
      TITLEBAR=$'\1\e]0;'$USER@${HOSTNAME%%.*}:${PWD/#$HOME/~}$'\e\\\2' ;;
    *)
      TITLEBAR= ;;
  esac
  local SC
  if ((status == 0)); then
    SC="" #SC="$_omb_prompt_teal-$_omb_prompt_bold_green(${_omb_prompt_green}✳️$_omb_prompt_bold_green)";
  else
    SC="$_omb_prompt_teal-$_omb_prompt_bold_green(${_omb_prompt_red}! $status $_omb_prompt_bold_green)";#pb_error
  fi
  local BC=$(battery_percentage)
  [[ $BC == no && $BC == -1 ]] && BC=
  BC=${BC:+${_omb_prompt_teal}-${_omb_prompt_green}($BC%)}
  PS1=$TITLEBAR"${_omb_prompt_teal}┌─${_omb_prompt_teal}${_omb_prompt_bold_white}[$(_user_info)]"
  PS1+="${_omb_prompt_bold_green}[\A]$(__powerline_python_venv_prompt)"
  PS1+="${_omb_prompt_teal}${_omb_prompt_bold_olive}(\w)$(scm_prompt_info)\n"
  PS1+="${_omb_prompt_teal}└─${_omb_prompt_bold_teal}$(__ssh_client)$BC${_omb_prompt_green}"
  PS1+="$SC${_omb_prompt_bold_green}$(get_symbol_user_info)${_omb_prompt_bold_teal}${_omb_prompt_bold_purple} "

}
# scm theming
SCM_THEME_PROMPT_DIRTY=" ${_omb_prompt_red}✗"
SCM_THEME_PROMPT_CLEAN=" ${_omb_prompt_bold_green}✓"
SCM_THEME_PROMPT_PREFIX="${_omb_prompt_bold_teal}("
SCM_THEME_PROMPT_SUFFIX="${_omb_prompt_bold_teal})${_omb_prompt_reset_color}"

_omb_util_add_prompt_command _omb_theme_PROMPT_COMMAND
