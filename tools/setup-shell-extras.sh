#!/usr/bin/env bash
# setup-shell-extras.sh — instala y configura ble.sh + atuin + IA (Groq/aichat)
#
# Uso:
#   tools/setup-shell-extras.sh [--dry-run]
#
# Idempotente: se puede ejecutar varias veces sin duplicar líneas.
# No instala atuin ni aichat (esos van por pacman); solo los configura.

set -u

OSH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BLESH_DIR=${BLESH_DIR:-$HOME/.local/share/blesh}
BLESH_SRC=${BLESH_SRC:-$HOME/.local/src/ble.sh}
BASHRC=${BASHRC:-$HOME/.bashrc}
FZF_BASH=${FZF_BASH:-$HOME/.fzf.bash}
BLERC=${BLERC:-$HOME/.blerc}
AICHAT_CONF=${AICHAT_CONF:-$HOME/.config/aichat/config.yaml}

DRY_RUN=0
[[ ${1-} == --dry-run ]] && DRY_RUN=1

function log { printf '\033[36m==>\033[0m %s\n' "$*"; }
function warn { printf '\033[33m[!]\033[0m %s\n' "$*" >&2; }
function do_cmd {
  if ((DRY_RUN)); then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

function install_blesh {
  if [[ -f $BLESH_DIR/ble.sh ]]; then
    log "ble.sh ya instalado en $BLESH_DIR"
    return
  fi
  log "Instalando ble.sh (0.4-devel) en ~/.local ..."
  if [[ ! -d $BLESH_SRC/.git ]]; then
    do_cmd mkdir -p "$(dirname "$BLESH_SRC")"
    do_cmd git clone --recursive --depth 1 --shallow-submodules \
      https://github.com/akinomyoga/ble.sh.git "$BLESH_SRC"
  fi
  do_cmd make -C "$BLESH_SRC" install PREFIX="$HOME/.local"
}

function write_blerc {
  if [[ -f $BLERC ]]; then
    log "$BLERC ya existe (no lo toco)"
    return
  fi
  log "Creando ~/.blerc desde templates/blerc.example"
  do_cmd cp "$OSH_DIR/templates/blerc.example" "$BLERC"
}

function patch_bashrc {
  [[ -f $BASHRC ]] || {
    warn "No existe $BASHRC"
    return
  }
  if ! ((DRY_RUN)); then
    cp -a "$BASHRC" "$BASHRC.bak.$(date +%Y%m%d%H%M%S)"
  fi

  if ! grep -q 'ble\.sh' "$BASHRC"; then
    log "Añadiendo el source de ble.sh al inicio de ~/.bashrc"
    if ((DRY_RUN)); then
      printf '[dry-run] prepend source ble.sh\n'
    else
      local tmp
      tmp=$(mktemp)
      {
        printf '%s\n' '# >>> oh-my-bash-fork: ble.sh >>>'
        printf '%s\n' '[[ $- == *i* ]] && source -- "$HOME/.local/share/blesh/ble.sh" --attach=none'
        printf '%s\n\n' '# <<< oh-my-bash-fork: ble.sh <<<'
        cat "$BASHRC"
      } >"$tmp"
      mv "$tmp" "$BASHRC"
    fi
  else
    log "ble.sh ya está en ~/.bashrc"
  fi

  if ! grep -q 'ble-attach' "$BASHRC"; then
    log "Añadiendo ble-attach + atuin al final de ~/.bashrc"
    if ((DRY_RUN)); then
      printf '[dry-run] append ble-attach + atuin init\n'
    else
      {
        printf '\n%s\n' '# >>> oh-my-bash-fork: ble.sh attach >>>'
        printf '%s\n' '[[ ! ${BLE_VERSION-} ]] || ble-attach'
        printf '%s\n' 'command -v atuin > /dev/null 2>&1 && eval -- "$(atuin init bash)"'
        printf '%s\n' '# <<< oh-my-bash-fork: ble.sh attach <<<'
      } >>"$BASHRC"
    fi
  elif ! grep -q 'atuin init bash' "$BASHRC"; then
    log "Añadiendo atuin init tras ble-attach"
    if ((DRY_RUN)); then
      printf '[dry-run] append atuin init\n'
    else
      printf '%s\n' 'command -v atuin > /dev/null 2>&1 && eval -- "$(atuin init bash)"' >>"$BASHRC"
    fi
  fi
}

function patch_fzf {
  [[ -f $FZF_BASH ]] || return
  grep -q 'BLE_VERSION' "$FZF_BASH" && return
  grep -q 'eval "$(fzf --bash)"' "$FZF_BASH" || return
  log "Protegiendo la integración de fzf en ~/.fzf.bash para ble.sh"
  if ((DRY_RUN)); then
    printf '[dry-run] wrap eval fzf --bash\n'
    return
  fi
  local tmp line
  tmp=$(mktemp)
  while IFS= read -r line; do
    if [[ $line == *'eval "$(fzf --bash)"'* ]]; then
      printf '%s\n' '# Con ble.sh, fzf se integra vía blesh-contrib (ver ~/.blerc)'
      printf '%s\n' 'if [[ -z ${BLE_VERSION-} ]]; then'
      printf '%s\n' '  eval "$(fzf --bash)"'
      printf '%s\n' 'fi'
    else
      printf '%s\n' "$line"
    fi
  done <"$FZF_BASH" >"$tmp"
  mv "$tmp" "$FZF_BASH"
}

function write_aichat_config {
  if [[ -f $AICHAT_CONF ]]; then
    log "Config de aichat ya existe (no la toco)"
    return
  fi
  log "Creando config de aichat para Groq (openai/gpt-oss-20b)"
  do_cmd mkdir -p "$(dirname "$AICHAT_CONF")"
  if ((DRY_RUN)); then
    printf '[dry-run] write %s\n' "$AICHAT_CONF"
    return
  fi
  cat >"$AICHAT_CONF" <<'YAML'
# aichat — Groq (OpenAI-compatible) con openai/gpt-oss-20b
# La api_key se resuelve de $GROQ_API_KEY (el .env del fork la exporta).
model: groq:openai/gpt-oss-20b
stream: true
highlight: true
wrap: auto

clients:
  - type: openai-compatible
    name: groq
    api_base: https://api.groq.com/openai/v1
    models:
      - name: openai/gpt-oss-20b
        max_input_tokens: 131072
        max_output_tokens: 32768
        supports_function_calling: true
    # Groq: ocultar el bloque de razonamiento de gpt-oss
    patch:
      chat_completions:
        '.*':
          body:
            reasoning_format: hidden
YAML
}

function main {
  log "osh dir: $OSH_DIR"
  install_blesh
  write_blerc
  patch_bashrc
  patch_fzf
  write_aichat_config

  echo
  log "Siguiente:"
  printf '  1. Asegúrate de tener atuin y aichat instalados:\n'
  printf '       sudo pacman -S atuin aichat\n'
  printf '  2. GROQ_API_KEY en %s/.env (ya debería estar)\n' "$OSH_DIR"
  printf '  3. Abre una terminal nueva (o `exec bash -l`) para cargar ble.sh\n'
}

main "$@"
