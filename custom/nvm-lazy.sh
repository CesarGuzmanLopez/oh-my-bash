#! bash oh-my-bash.module
# ── NVM perezoso ──
# Cargar nvm.sh en cada shell cuesta ~74-150 ms. Aquí dejamos node/npm en el
# PATH (resolviendo el alias por defecto) y cargamos nvm sólo la primera vez
# que se invoca `nvm`.
#
# Desactívalo con OSH_LAZY_NVM=0.
[[ ${OSH_LAZY_NVM:-1} == 1 ]] || return 0

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ -d $NVM_DIR ]] || NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
[[ -d $NVM_DIR/versions/node ]] || return 0

# Devuelve el bin de la versión de node activa (1 lectura + 1 glob).
function _omb_nvm_active_bin {
  local alias ver
  alias=$(command cat "$NVM_DIR/alias/default" 2>/dev/null)
  alias=${alias#v}
  if [[ -n $alias && -x $NVM_DIR/versions/node/v$alias/bin/node ]]; then
    printf '%s' "$NVM_DIR/versions/node/v$alias/bin"
    return 0
  fi
  if [[ -n $alias ]]; then
    ver=$(command ls -1d "$NVM_DIR"/versions/node/v"$alias"*/bin 2>/dev/null | sort -V | tail -1)
    if [[ -n $ver ]]; then
      printf '%s' "$ver"
      return 0
    fi
  fi
  ver=$(command ls -1d "$NVM_DIR"/versions/node/v*/bin 2>/dev/null | sort -V | tail -1)
  [[ -n $ver ]] && printf '%s' "$ver"
}

function _omb_nvm_add_active_bin {
  local bin
  bin=$(_omb_nvm_active_bin)
  [[ -n $bin ]] || return 0
  case ":$PATH:" in
    *":$bin:"*) ;;
    *) PATH="$bin:$PATH" ;;
  esac
}
_omb_nvm_add_active_bin
unset -f _omb_nvm_active_bin _omb_nvm_add_active_bin

# Carga nvm (y su completion) la primera vez que se invoca `nvm`.
function load_nvm {
  unset -f nvm 2>/dev/null
  [[ -e $NVM_DIR/nvm.sh ]] || ln -s /usr/share/nvm/nvm.sh "$NVM_DIR/nvm.sh" 2>/dev/null
  [[ -e $NVM_DIR/nvm-exec ]] || ln -s /usr/share/nvm/nvm-exec "$NVM_DIR/nvm-exec" 2>/dev/null
  [[ -s $NVM_DIR/nvm.sh ]] && . "$NVM_DIR/nvm.sh"
  [[ -s /usr/share/nvm/bash_completion ]] && . /usr/share/nvm/bash_completion
  return 0
}
function nvm {
  load_nvm
  nvm "$@"
}
