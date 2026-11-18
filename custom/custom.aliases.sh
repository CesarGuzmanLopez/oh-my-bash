#!/bin/bash
# Custom aliases + functions — all paths use $OSH (auto-detected)

# ═══ Aliases ═══
alias tardis='bash "$OSH"/tardis.sh'
alias refreshcolor='if command -v kitten >/dev/null 2>&1; then kitten @ load-config; fi; if [[ $(type -t _omb_theme_reload_colors) == function ]]; then _omb_theme_reload_colors; fi'
# proyectos: sin args -> ~/Documents/Proyectos; con nombre -> esa subcarpeta (Tab completa);
#   open <nombre> -> 2 ventanas OS kitty separadas (una: opencode, otra: nvim en la raiz)
#   o solo nvim si no hay kitty usable (ssh, sin display).
unalias proyectos 2>/dev/null || true
function proyectos {
  local base="$HOME/Documents/Proyectos"
  if [[ ${1:-} == open ]]; then
    shift
    _proyectos_open "$base" "$@"
    return $?
  fi
  if [[ $# -eq 0 ]]; then
    cd -- "$base" || return 1
    return 0
  fi
  local target="$base/$*"
  if [[ -d $target ]]; then
    cd -- "$target" || return 1
  else
    echo "proyectos: '$*' no existe en $base" >&2
    return 1
  fi
}
# ¿kitty real? Por ssh KITTY_WINDOW_ID no existe aunque el binario este instalado.
function _proyectos_in_kitty {
  [[ -n ${KITTY_WINDOW_ID:-} ]] && _omb_util_command_exists kitty
}
function _proyectos_open {
  local base=$1
  shift
  if [[ $# -eq 0 ]]; then
    echo "uso: proyectos open <proyecto>" >&2
    return 2
  fi
  local name="$*"
  local target="$base/$name"
  if [[ ! -d $target ]]; then
    echo "proyectos: '$name' no existe en $base" >&2
    return 1
  fi
  if [[ -z ${SSH_CONNECTION:-} && -z ${SSH_TTY:-} && -z ${SSH_CLIENT:-} ]]; then
    if _proyectos_in_kitty && kitty @ ls >/dev/null 2>&1; then
      _proyectos_open_tab "$target" "$name"
      return $?
    fi
    if _omb_util_command_exists kitty && [[ -n ${WAYLAND_DISPLAY:-}${DISPLAY:-} ]]; then
      _proyectos_open_window "$target" "$name"
      return $?
    fi
  fi
  _proyectos_open_nvim "$target"
}
# Dos ventanas OS separadas en el kitty actual: una con opencode, otra con nvim. Sin splits.
function _proyectos_open_tab {
  local target=$1 name=$2
  # Ruta absoluta: la ventana nueva hereda el PATH de kitty (sesion grafica),
  # sin ~/.opencode/bin, y resolveria /usr/bin/opencode (mas viejo).
  local opencode_bin
  opencode_bin=$(command -v opencode 2>/dev/null) || {
    echo "proyectos: opencode no esta instalado" >&2
    return 1
  }
  kitty @ launch --type=os-window --tab-title="$name-opencode" --cwd="$target" --title=opencode "$opencode_bin" >/dev/null || return 1
  kitty @ launch --type=os-window --tab-title="$name-nvim" --cwd="$target" --title=nvim nvim . >/dev/null || return 1
}
# Dos ventanas OS separadas (display disponible pero fuera de kitty): una con opencode, otra con nvim.
function _proyectos_open_window {
  local target=$1 name=$2
  # Ruta absoluta por lo mismo que en _proyectos_open_tab (PATH de kitty != PATH interactivo).
  local opencode_bin
  opencode_bin=$(command -v opencode 2>/dev/null) || {
    echo "proyectos: opencode no esta instalado" >&2
    return 1
  }
  local sess_dir="${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-bash-fork/proyectos"
  command mkdir -p "$sess_dir" 2>/dev/null || return 1
  local sess="$sess_dir/$name.session"
  local qtarget=${target//\"/\\\"}
  {
    printf 'new_os_window\n'
    printf 'launch --title opencode --cwd "%s" "%s"\n' "$qtarget" "$opencode_bin"
    printf 'new_os_window\n'
    printf 'launch --title nvim --cwd "%s" nvim .\n' "$qtarget"
  } >|"$sess" || return 1
  kitty --detach --session "$sess"
}
# Sin kitty usable (ssh, sin display): solo nvim en la raiz del proyecto.
function _proyectos_open_nvim {
  local target=$1
  _omb_util_command_exists nvim || {
    echo "proyectos: nvim no esta instalado" >&2
    return 1
  }
  cd -- "$target" || return 1
  nvim .
}
function _proyectos_complete_dirs {
  local base=$1 cur=$2 d
  while IFS= read -r d; do
    d=${d#"$base"/}
    [[ -n $d ]] && COMPREPLY+=("$d")
  done < <(compgen -d -- "$base/$cur")
}
function _proyectos_completion {
  local base cur
  base=$HOME/Documents/Proyectos
  cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=()
  if [[ ${COMP_WORDS[1]:-} == open ]]; then
    if ((COMP_CWORD == 2)); then
      _proyectos_complete_dirs "$base" "$cur"
    fi
    return 0
  fi
  if ((COMP_CWORD == 1)); then
    _proyectos_complete_dirs "$base" "$cur"
    local w
    while IFS= read -r w; do
      [[ -n $w ]] && COMPREPLY+=("$w")
    done < <(compgen -W "open" -- "$cur")
  elif ((COMP_CWORD == 2)) && [[ -d "$base/${COMP_WORDS[1]}" ]]; then
    # subrutas dentro del proyecto: proyectos agalano src/<Tab>
    local d pre="$base/${COMP_WORDS[1]}/"
    while IFS= read -r d; do
      d=${d#"$base"/}
      [[ -n $d ]] && COMPREPLY+=("$d")
    done < <(compgen -d -- "$pre$cur")
  fi
  compopt -o filenames 2>/dev/null || true
}
complete -F _proyectos_completion -o filenames proyectos
alias agenda="firefox agenda.guzman-lopez.com"
alias note='"$OSH"/note.sh'
alias nota=note
alias hoy='"$OSH"/hoy.sh'
alias dos2unixAll="find . -type f -print0 | xargs -0 dos2unix"
alias a-grep='grep -lirs --exclude-dir=".git;.svn" --color=always'

# ═══ Functions ═══

function Afind() {
  find "${1:-.}" -type f -not -path "*/.git/*"
}
export -f Afind

function wallpaper_color() {
  local bg_color
  bg_color=$(echo "${COLORFGBG:-}" | cut -d ";" -f2)
  if [[ ${bg_color:-0} -ge 8 ]]; then
    echo "dark"
  else
    echo "light"
  fi
}
