#! bash oh-my-bash.module
# ── LSP para OpenCode (jdtls + clangd + resto) ──
# - Exporta OPENCODE_EXPERIMENTAL_LSP_TOOL=true (una vez, sin duplicar).
# - Define `opencode-lsp-check`: verifica que cada servidor LSP configurado
#   en opencode.jsonc esté disponible (binario + JDK 27 para jdtls).
#   Rápido (solo `command -v`), sin red, sin arrancar servidores.
# - `opencode-web` / `opencode-tui` lo llaman al arrancar y NO avanzan si
#   falta algo (ver gate en custom/opencode.sh).
#
# Knobs:
#   OSH_LSP=0       → no exporta el flag ni define nada (silencio total)
#   OSH_LSP_CHECK=0 → el gate avisa pero no bloquea el arranque
#   OSH_LSP_QUIET=0 → muestra mensajes también al cargar la shell

[[ ${OSH_LSP:-1} == 1 ]] || return 0

# Flag experimental del LSP (respeta valor previo, no duplica).
export OPENCODE_EXPERIMENTAL_LSP_TOOL=${OPENCODE_EXPERIMENTAL_LSP_TOOL:-true}

# ~/.local/bin al PATH (aquí vive jdtls); si ya está, no toca nada.
[[ :$PATH: == *:"$HOME"/.local/bin:* ]] || export PATH="$HOME/.local/bin:$PATH"

# Servidores que opencode.jsonc espera, como "nombre:ruta-o-bin".
# Las rutas fijas cubren los que viven en node_modules (no necesitan PATH).
_OSH_LSP_SERVERS=(
  "java:$HOME/.local/bin/jdtls"
  "typescript:$HOME/.config/opencode/node_modules/.bin/typescript-language-server"
  "python:pylsp"
  "cpp:clangd"
  "rust:rust-analyzer"
  "shell:bash-language-server"
  "json:$HOME/.config/opencode/node_modules/.bin/vscode-json-language-server"
  "yaml:yaml-language-server"
  "css:$HOME/.config/opencode/node_modules/.bin/vscode-css-language-server"
  "html:$HOME/.config/opencode/node_modules/.bin/vscode-html-language-server"
  "php:$HOME/.config/opencode/node_modules/.bin/intelephense"
  "lua:lua-language-server"
)
_OSH_LSP_JAVA=/usr/lib/jvm/java-27-openjdk/bin/java

# opencode-lsp-check [--quiet]
# 0 si todo el stack LSP está disponible; 1 + aviso si falta algo.
function opencode-lsp-check {
  local quiet=0
  [[ ${1:-} == --quiet ]] && quiet=1
  [[ ${OSH_LSP_QUIET:-1} == 1 ]] || quiet=0
  local missing=() entry name bin
  for entry in "${_OSH_LSP_SERVERS[@]}"; do
    name=${entry%%:*}
    bin=${entry#*:}
    if [[ $bin == */* ]]; then
      [[ -x $bin ]] || missing+=("$name ($bin)")
    else
      command -v "$bin" >/dev/null 2>&1 || missing+=("$name")
    fi
  done
  # jdtls exige JDK 25+ para correr (sus bundles lo piden por osgi.ee).
  if [[ -x ${_OSH_LSP_JAVA} ]]; then
    :
  else
    missing+=("java27 (${_OSH_LSP_JAVA})")
  fi
  if ((${#missing[@]} > 0)); then
    ((quiet == 0)) && {
      echo "opencode-lsp-check: falta stack LSP, no arranco:" >&2
      printf '  - %s\n' "${missing[@]}" >&2
      echo "opencode-lsp-check: instala lo que falte o pon OSH_LSP_CHECK=0 para solo avisar." >&2
    }
    return 1
  fi
  ((quiet == 0)) && echo "opencode-lsp-check: stack LSP completo (jdtls + ${#_OSH_LSP_SERVERS[@]} servidores)."
  return 0
}

# Gate para los lanzadores: avisa siempre; bloquea salvo OSH_LSP_CHECK=0.
function _osh_lsp_gate {
  opencode-lsp-check --quiet || {
    opencode-lsp-check
    if [[ ${OSH_LSP_CHECK:-1} == 1 ]]; then
      echo "lsp-gate: arranque bloqueado (faltan servidores LSP)." >&2
      return 1
    fi
    echo "lsp-gate: OSH_LSP_CHECK=0 → sigo aunque falte LSP." >&2
    return 0
  }
}
