#! bash oh-my-bash.module
# ── bat inteligente ──
# Sombrea `bat`: directorio → listado, binario → ficha + volcado hex,
# texto → `bat` normal. Opciones de bat se pasan tal cual si el primer
# argumento no es una ruta existente.
#   Desactívalo con OSH_SMART_BAT=0.
[[ ${OSH_SMART_BAT:-1} == 1 ]] || return 0
_omb_util_command_exists bat || return 0

function bat {
  local target=""
  local arg
  for arg in "$@"; do
    case $arg in
    -*) continue ;;
    *)
      target=$arg
      break
      ;;
    esac
  done
  if [[ -n $target && -e $target ]]; then
    if [[ -d $target ]]; then
      if _omb_util_command_exists eza; then
        eza --group-directories-first --icons=auto -- "$target"
      else
        command ls -- "$target"
      fi
      return
    fi
    if [[ ! -s $target ]]; then
      echo "bat: '$target' está vacío." >&2
      return 0
    fi
    if ! grep -qI . -- "$target" 2>/dev/null; then
      command file --brief -- "$target"
      command stat -c 'Tamaño: %s bytes' -- "$target"
      command xxd -- "$target" | command head -n 20
      return
    fi
  fi
  command bat "$@"
}
