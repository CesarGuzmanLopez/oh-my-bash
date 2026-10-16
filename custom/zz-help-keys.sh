#! bash oh-my-bash.module
# ── Tecla F1 (ayuda) ──
#
# Por qué este archivo existe: los `custom/` se cargan en orden alfabético, así
# que cualquier archivo anterior a `zz-*` puede pisar el keymap después
# (intelli-shell hace `bind -x` de readline y se come `f1` de ble.sh). Aquí el
# binding se aplica al final y se re-aplica en cada prompt.
#
# El binding debe ser de tipo widget (`ble-bind -f`), no `-c` (SHELL_COMMAND) ni
# `-x` (macro de edición): con `-c` el keymap se degrada en cuanto la función
# lanza otro proceso y F1 deja de responder para siempre; con `-x` el macro se
# consume. Un widget de ble.sh sobrevive a ambos casos.

# Widgets: las llamadas a helpmeb lanzan procesos, así que se aíslan con
# `ble/widget` para que ble.sh no mezcle el modo edición con la ejecución.
if [[ -n ${BLE_VERSION-} ]]; then
  function ble/widget/omb_help { _omb_help_open; }
  function ble/widget/omb_help_alt { _omb_help_open; }
fi

function _omb_help_bind {
  if [[ -n ${BLE_VERSION-} ]]; then
    # ble.sh nombra las teclas de función en minúscula (f1), no F1.
    ble-bind -m emacs -f f1 omb_help
    ble-bind -m vi_imap -f f1 omb_help
    ble-bind -m emacs -f 'C-x h' omb_help_alt
    ble-bind -m vi_imap -f 'C-x h' omb_help_alt
    # kitty y otros terminales no siempre mandan la misma secuencia para F1
    # (\eOP, \e[11~ o \e[[A según el modo de teclado).
    # OJO: \e[1~ NO se enlaza porque en varios terminales es la tecla Inicio.
    local kmap seq
    for kmap in emacs vi_imap; do
      for seq in '\eOP' '\e[11~' '\e[[A'; do
        # `keyseq:` obliga a ble-bind a leer la secuencia tal cual (en `kspec`
        # un `\e` suelto no siempre se interpreta como Escape).
        ble-bind -m "$kmap" -f "keyseq:$seq" omb_help
      done
    done
  elif [[ -t 0 ]]; then
    bind -x '"\eOP": _omb_help_open'   # F1 (xterm/kitty)
    bind -x '"\e[11~": _omb_help_open' # F1 (linux/vt)
    bind -x '"\e[[A": _omb_help_open'  # F1 (rxvt)
    bind -x '"\C-xh": _omb_help_open'  # C-x h
  fi
}

if [[ $(type -t _omb_help_open) == function ]]; then
  _omb_help_bind
  # PROMPT_COMMAND se engancha directamente: cuando se cargan los custom aún no
  # existe _omb_util_add_prompt_command, así que ese hook nunca se registra.
  # Un hook real en el prompt es lo que sobrevive a readline/intelli-shell.
  case ${PROMPT_COMMAND-} in
  *_omb_help_bind*) ;;
  *)
    PROMPT_COMMAND="_omb_help_bind${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
    ;;
  esac
fi
