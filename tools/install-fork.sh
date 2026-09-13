#!/usr/bin/env bash
# install-fork.sh — instalador del fork oh-my-bash (CesarGuzmanLopez)
#
# Uso (una línea):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/CesarGuzmanLopez/oh-my-bash/master/tools/install-fork.sh)"
#
# Opciones:
#   --dir DIR     Directorio de instalación (por defecto ~/.oh-my-bash-fork)
#   --no-ble      No instalar/configurar ble.sh (solo el fork)
#   --dry-run     Mostrar lo que haría sin ejecutarlo
#   --help
#
# Comportamiento: verifica todas las dependencias y, si falta alguna opcional,
# NO falla: simplemente esa función no aparecerá en el shell.

set -u

REPO_URL=${OSH_REPOSITORY:-https://github.com/CesarGuzmanLopez/oh-my-bash.git}
OSH_DIR=${OSH_DIR:-$HOME/.oh-my-bash-fork}
BASHRC=${BASHRC:-$HOME/.bashrc}
NO_BLE=0
DRY_RUN=0

function log { printf '\033[36m==>\033[0m %s\n' "$*"; }
function ok { printf '  \033[32m✓\033[0m %-10s %s\n' "$1" "$2"; }
function miss { printf '  \033[33m·\033[0m %-10s %s \033[33m(esa función no aparecerá)\033[0m\n' "$1" "$2"; }
function warn { printf '\033[33m[!]\033[0m %s\n' "$*" >&2; }
function die {
  printf '\033[31m[x]\033[0m %s\n' "$*" >&2
  exit 1
}
function do_cmd {
  if ((DRY_RUN)); then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

function usage {
  cat <<'EOF'
Uso (una línea):
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/CesarGuzmanLopez/oh-my-bash/master/tools/install-fork.sh)"

Opciones:
  --dir DIR     Directorio de instalación (por defecto ~/.oh-my-bash-fork)
  --no-ble      No instalar/configurar ble.sh (solo el fork)
  --dry-run     Mostrar lo que haría sin ejecutarlo
  --help
EOF
}

function parse_args {
  while (($#)); do
    case $1 in
      --dir)
        OSH_DIR=$2
        shift
        ;;
      --dir=*) OSH_DIR=${1#*=} ;;
      --no-ble | --minimal) NO_BLE=1 ;;
      --dry-run) DRY_RUN=1 ;;
      -h | --help)
        usage
        exit 0
        ;;
      *) warn "opción desconocida: $1" ;;
    esac
    shift
  done
}

# Muestra el estado de cada dependencia. Las que faltan NO son un error: solo
# desactivan la función correspondiente (degradación elegante).
function check_dependencies {
  log "Dependencias"
  local missing=()

  # ── Obligatorias ──
  command -v git >/dev/null 2>&1 || die "falta 'git' (obligatorio para instalar)."
  ok git "clonar/actualizar el fork"

  if [[ ${BASH_VERSINFO[0]} -lt 4 || (${BASH_VERSINFO[0]} -eq 4 && ${BASH_VERSINFO[1]} -lt 3) ]]; then
    warn "bash ${BASH_VERSION:-?}: ble.sh 0.4 requiere bash >= 4.3 (el resto sí funciona)."
  fi

  # ── Opcionales (cada una enciende una función) ──
  local cmd feature
  while IFS='|' read -r cmd feature; do
    [[ -z $cmd ]] && continue
    if command -v "$cmd" >/dev/null 2>&1; then
      ok "$cmd" "$feature"
    else
      miss "$cmd" "$feature"
      missing+=("$cmd")
    fi
  done <<'DEPS'
curl|descargar ble.sh y actualizar
fzf|Ctrl+F / Ctrl+T y menús difusos
atuin|historia SQLite y Ctrl+R
aichat|IA (comando ai / C-x i)
jq|parsear JSON (hoy, IA)
rg|búsqueda rápida en Ctrl+F
bat|previsualización (cat, fzf)
eza|ls con iconos y git
zoxide|salto inteligente de directorios (z)
make|compilar ble.sh
gawk|compilar ble.sh
kitten|integración SSH de kitty
python3|tardis
DEPS

  if ((${#missing[@]})); then
    echo
    warn "Faltan ${#missing[@]} opcionales; se instalarán igual y esas funciones quedan desactivadas."
    warn "Puedes añadirlas luego (ej.: sudo pacman -S ${missing[*]}) y abrir un shell nuevo."
  fi
}

function install_fork {
  log "Fork en $OSH_DIR"
  if [[ -d $OSH_DIR/.git ]]; then
    do_cmd git -C "$OSH_DIR" pull --ff-only --quiet || warn "no se pudo actualizar el fork (siguiendo con lo que hay)"
  else
    do_cmd git clone --depth=1 "$REPO_URL" "$OSH_DIR"
  fi
}

function patch_bashrc {
  [[ -f $BASHRC ]] || {
    warn "no existe $BASHRC (lo creo vacío)"
    ((DRY_RUN)) || : >"$BASHRC"
  }
  if grep -q 'oh-my-bash-fork' "$BASHRC" 2>/dev/null; then
    log "$BASHRC ya carga el fork"
    return
  fi
  log "Añadiendo el fork a ~/.bashrc"
  ((DRY_RUN)) || cp -a "$BASHRC" "$BASHRC.bak.$(date +%Y%m%d%H%M%S)"
  if ((DRY_RUN)); then
    printf '[dry-run] append fork source lines\n'
    return
  fi
  {
    printf '\n%s\n' '# >>> oh-my-bash-fork >>>'
    printf '%s\n' 'export OSH="$HOME/.oh-my-bash-fork"'
    printf '%s\n' 'export OSH_THEME="${OSH_THEME:-kitsune}"'
    printf '%s\n' 'source "$OSH/oh-my-bash.sh"'
    printf '%s\n' '# <<< oh-my-bash-fork <<<'
  } >>"$BASHRC"
}

function setup_ble {
  ((NO_BLE)) && {
    log "ble.sh omitido (--no-ble)"
    return
  }
  log "Configurando ble.sh + atuin + IA"
  if ((DRY_RUN)); then
    bash "$OSH_DIR/tools/setup-shell-extras.sh" --dry-run
  else
    bash "$OSH_DIR/tools/setup-shell-extras.sh" || warn "setup-shell-extras falló; el fork sigue funcionando"
  fi
}

function summary {
  echo
  log "Listo. Próximos pasos:"
  printf '  1. Abre una terminal nueva (o `exec bash -l`)\n'
  printf '  2. Prueba: ghost (escribe un prefijo), Ctrl+R (atuin), ai <Tab>, ai "...", C-x i\n'
  printf '  3. Documentación: %s/README.md\n' "$OSH_DIR"
}

function main {
  parse_args "$@"
  ((DRY_RUN)) && log "Modo dry-run (no se cambia nada)"
  log "bash ${BASH_VERSION:-desconocido} · $OSH_DIR"
  check_dependencies
  echo
  install_fork
  patch_bashrc
  setup_ble
  summary
}

main "$@"
