#! bash oh-my-bash.module
# ── Herramientas CLI para terminal ──
# thefuck  corrige el último comando fallido
# navi     cheatsheet interactivo
# Desactívalo con OSH_SHELL_TOOLS=0.
[[ ${OSH_SHELL_TOOLS:-1} == 1 ]] || return 0

if _omb_util_command_exists thefuck; then
  # `thefuck -a` tarda ~100 ms (arranca Python) y es la mitad del arranque del
  # shell, así que se carga la primera vez que se usa `fuck`, no al inicio.
  # OSH_THEFUCK_EAGER=1 vuelve al comportamiento anterior.
  function _omb_thefuck_load {
    unset -f _omb_thefuck_load
    local init
    init=$(thefuck -a 2>/dev/null) || return 1
    [[ -n $init ]] || return 1
    command mkdir -p "$HOME/.config/thefuck"
    eval "$init"
    alias fucko='thefuck -y'
  }
  function fuck {
    # Si la carga falla, se usa el binario directo (sin recursión: `command`
    # salta la función).
    _omb_thefuck_load 2>/dev/null || {
      command thefuck "$@"
      return
    }
    fuck "$@"
  }
  function fucko {
    _omb_thefuck_load 2>/dev/null || true
    thefuck -y "$@"
  }
  if [[ ${OSH_THEFUCK_EAGER:-0} == 1 ]]; then
    # Al evaluar, el `fuck` real de thefuck sustituye al envoltorio.
    _omb_thefuck_load 2>/dev/null || true
  fi
fi

# intelli-shell: sugerencias de comandos desde el historial.
# El instalador lo añade a ~/.bash_profile; aquí solo se carga si la terminal
# no es de login (así también funciona en shells no-login).
if ! declare -F _intelli__shell >/dev/null 2>&1 && _omb_util_command_exists intelli-shell; then
  export INTELLI_HOME="${INTELLI_HOME:-$HOME/.local/share/intelli-shell}"
  eval "$(intelli-shell init bash)" 2>/dev/null
fi

if _omb_util_command_exists navi; then
  command mkdir -p "$HOME/.config/navi"
  # `navi --print` imprime el snippet elegido (útil para insertarlo en la línea);
  # `navi --path ~` añade las cheats del home a las del sistema.
  _omb_nav_show() { navi --path '~'; }
  _omb_nav_print() { navi --path '~' --print; }
  alias navis='navi --path ~'
  if [[ -n ${BLE_VERSION-} ]]; then
    ble-bind -m emacs -x 'C-g' _omb_nav_show
    ble-bind -m vi_imap -x 'C-g' _omb_nav_show
    ble-bind -m emacs -x 'C-x n' _omb_nav_print
    ble-bind -m vi_imap -x 'C-x n' _omb_nav_print
  fi
fi
