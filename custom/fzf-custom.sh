#!/bin/bash
# Custom FZF configuration — migrated from .bash_vim

# Degradación elegante: sin fzf, este archivo no hace nada (ni da error).
command -v fzf >/dev/null 2>&1 || return 0

# ═══ FZF Environment ═══
# `esc:abort` cierra fzf SIEMPRE (con `esc:cancel` primero limpia la consulta
# y solo aborta si ya estaba vacía → parecía que "a veces no cierra").
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --bind=esc:abort,ctrl-c:abort"
export FZF_DEFAULT_COMMAND="find . -type f -not -path '*/\.git/*'"

# ═══ FZF Ctrl+T Preview ═══
FZF_CTRL_T_OPTS="--preview 'bat --style=full --color=always --line-range :500 {}' --preview-window '~3' --bind='F2:toggle-preview,shift-up:preview-up,shift-down:preview-down' --color --height=90%"

# ═══ FZF Compgen ═══
_fzf_compgen_path() {
  echo "$1"
  command find -L "$1" \
    -name .git -prune -o -name .hg -prune -o -name .svn -prune -o \( -type d -o -type f -o -type l \) \
    -a -not -path "$1" -print 2>/dev/null | sed 's@^\./@@'
}

_fzf_compgen_dir() {
  command find -L "$1" \
    -name .git -prune -o -name .hg -prune -o -name .svn -prune -o -type d \
    -a -not -path "$1" -print 2>/dev/null | sed 's@^\./@@'
}

_fzf_comprun() {
  local command=$1
  shift
  case "$command" in
    cd) command find . -mindepth 1 \( -name .git -o -name node_modules -o -name .cache -o -name vendor \) -prune -o -type d -print |
      fzf --bind=esc:abort,ctrl-c:abort --preview 'tree -C {} -I ".git" | head -200' --height=40% ;;
    export | unset) fzf --bind=esc:abort,ctrl-c:abort --preview "eval 'echo \$'{}" --height=40% ;;
    " ") echo error ;;
    *) command find . -mindepth 1 \( -name .git -o -name node_modules -o -name .cache -o -name vendor \) -prune -o -print |
      fzf --bind=esc:abort,ctrl-c:abort --preview 'bat --style=plain --color=always --line-range :200 {}' \
        --preview-window '~3' --bind='F2:toggle-preview,shift-up:preview-up,shift-down:preview-down' \
        --height=50% ;;
  esac
}

# ═══ FZF Key Bindings ═══
__get_first_arg() {
  echo "$1"
}

insertar_texto() {
  local cmd result point tmp
  # Primer palabra de la línea actual (el comando en el que estamos)
  cmd="${READLINE_LINE-}"
  cmd="${cmd%% *}"
  point=${READLINE_POINT:-${#cmd}}
  # Salida a fichero temporal (no `$(...)`: si un hijo retiene la tubería de
  # la sustitución, el shell se queda esperando → "trabado"). El subshell
  # resetea INT/QUIT para que Ctrl+C/Esc cierren fzf correctamente.
  tmp=$(command mktemp "${TMPDIR:-/tmp}/omb-fzf.XXXXXX") || return 0
  (
    trap - INT QUIT
    _fzf_comprun "$cmd"
  ) >|"$tmp"
  result=$(command cat "$tmp" 2>/dev/null)
  command rm -f "$tmp"
  [[ -n "$result" ]] || return 0
  # Inserta en la posición del cursor sin alterar el resto de la línea
  READLINE_LINE="${READLINE_LINE:0:point} $result ${READLINE_LINE:point}"
  READLINE_POINT=$((point + ${#result} + 2))
}

custom_fzf_search() {
  local selected tmp file_path line
  tmp=$(command mktemp "${TMPDIR:-/tmp}/omb-fzf.XXXXXX") || return 0

  # Live grep: fzf arranca vacío e instantáneo; rg se ejecuta al teclear
  # (`--disabled` + `reload`), en vez de volcar TODAS las líneas al abrir.
  local rg_cmd="rg --color=always --line-number --no-heading --smart-case --no-messages -g '!node_modules/**' -g '!.git/**' -g '!LibreChat/**' -g '!.cache/**' -g '!vendor/**' -g '!*.wt' -g '!*.bson' -g '!storage.bson'"
  local grep_cmd="grep -rn --color=always --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.cache --exclude-dir=vendor"
  # Preview acotado (bat tarda ~110 ms y más en archivos grandes)
  local preview="bat --style=plain --color=always --highlight-line {2} --line-range {2}:+60 {1} 2>/dev/null"

  if _omb_util_command_exists rg; then
    (
      trap - INT QUIT
      fzf --ansi --disabled --prompt 'rg> ' \
        --bind "change:reload:$rg_cmd {q}" \
        --bind=esc:abort,ctrl-c:abort \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --delimiter : \
        --preview "$preview" \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --expect=ctrl-v </dev/null
    ) >|"$tmp"
  else
    (
      trap - INT QUIT
      fzf --ansi --disabled --prompt 'grep> ' \
        --bind "change:reload:$grep_cmd {q} ." \
        --bind=esc:abort,ctrl-c:abort --delimiter : \
        --preview "$preview" \
        --expect=ctrl-v </dev/null
    ) >|"$tmp"
  fi
  selected=$(command cat "$tmp" 2>/dev/null)
  command rm -f "$tmp"

  [[ -n $selected ]] || return 0
  # Con --expect la primera línea es la tecla (vacía con Enter)
  local body=${selected#*$'\n'}
  file_path=$(printf '%s\n' "$body" | command sed -n '1s/^\([^:]*\):.*/\1/p')
  line=$(printf '%s\n' "$body" | command sed -n '1s/^[^:]*:\([0-9]*\):.*/\1/p')

  if [[ -n $file_path && -f $file_path ]]; then
    # Abre nvim en la línea del resultado (si la hay)
    nvim ${line:+"+$line"} -- "$file_path"
  fi
}

# Bindings
# OJO: ~/.fzf.bash se suele cargar DESPUÉS de oh-my-bash y su
# `eval "$(fzf --bash)"` re-bindea \C-t. Con ble.sh se usa `ble-bind`.
# Re-aplicamos el binding antes de cada prompt para ganar siempre.
function _omb_fzf_rebind {
  if [[ -n ${BLE_VERSION-} ]]; then
    ble-bind -m emacs -x 'C-f' custom_fzf_search
    ble-bind -m emacs -x 'C-t' insertar_texto
    ble-bind -m vi_imap -x 'C-f' custom_fzf_search
    ble-bind -m vi_imap -x 'C-t' insertar_texto
  elif [[ -t 0 ]]; then
    # Sin terminal interactiva no hay readline que enlazar
    bind -x '"\C-f": custom_fzf_search'
    bind -x '"\C-t": insertar_texto'
  fi
}
_omb_fzf_rebind
if [[ $(type -t _omb_util_add_prompt_command) == function ]]; then
  _omb_util_add_prompt_command _omb_fzf_rebind
fi
