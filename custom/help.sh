#! bash oh-my-bash.module
# ── Ayuda rápida / cheatsheet ──
#   helpmeb [atajos|aliases|funciones|ia|temas|ejemplos]   imprime la ayuda
#   F1                                                     abre esta ayuda
#
# Muestra solo lo que está disponible (si falta una herramienta, no aparece).

_omb_help_c() { printf '\033[1;36m%s\033[0m\n' "$*"; }
_omb_help_t() { printf '  \033[1;37m%-14s\033[0m %s\n' "$1" "$2"; }
_omb_help_has() { command -v "$1" >/dev/null 2>&1; }

function _omb_help_header {
  _omb_help_c "══════════════════════════════════════════════════════════════"
  _omb_help_c "  oh-my-bash-fork · ayuda rápida   (F1 / C-x h · helpmeb [sección])"
  _omb_help_c "══════════════════════════════════════════════════════════════"
}

function _omb_help_keys {
  _omb_help_c "▸ ATAJOS DE TECLADO"
  _omb_help_t "Ctrl+F" "Buscar en archivos (rg + fzf) y abrir nvim en la línea"
  _omb_help_t "Ctrl+T" "Insertar ruta/archivo con fzf en la línea"
  _omb_help_t "C-x i" "IA: reemplaza el buffer por el comando generado"
  _omb_help_has atuin && _omb_help_t "Ctrl+R" "Historia difusa (atuin)"
  _omb_help_t "F1 / C-x h" "Esta ayuda"
  _omb_help_t "ai <Tab>" "Completa las banderas de ai"
  _omb_help_t "→ / End" "Aceptar la sugerencia fantasma (ble.sh)"
  _omb_help_t "↑ / ↓" "Navegar sugerencias del historial"
  _omb_help_t "Tab" "Menú de completado (y fzf-completion)"
  echo
}

function _omb_help_aliases {
  _omb_help_c "▸ LISTADOS Y LECTURA"
  if _omb_help_has eza; then
    _omb_help_t "ls ll la l lt lr lo lk l." "eza: iconos + git"
  else
    _omb_help_t "ls ll la l" "listados con color"
  fi
  _omb_help_has bat && _omb_help_t "cat catn catp" "bat (paginado sin paginador)"
  _omb_help_t "c" "clear (limpia pantalla + scrollback en kitty)"
  _omb_help_t "src" "recargar ~/.bashrc"
  _omb_help_t "h" "historial"
  echo
}

function _omb_help_functions {
  _omb_help_c "▸ FUNCIONES ÚTILES"
  _omb_help_t "take DIR" "crear directorio y entrar (mkcd)"
  _omb_help_t "extract ARCH" "descomprimir tar/zip/7z/rar/gz/xz/zst/rpm/deb"
  _omb_help_has git && _omb_help_t "gcof" "cambiar de rama git con fzf (preview)"
  _omb_help_t "killf" "elegir y matar un proceso con fzf"
  _omb_help_t "cdf / editf" "cd / abrir archivo con fzf"
  _omb_help_has kitten && _omb_help_t "img ARCH" "ver la imagen en la terminal (kitten/chafa)"
  [[ -x $HOME/.local/bin/chomp-filter ]] && _omb_help_t "chomp CMD..." "ejecutar con el filtro Pac-Man"
  _omb_help_t "updateAll" "actualizar y limpiar el sistema (Arch)"
  _omb_help_t "git-sync-a-pruebas" "sincronizar ramas origin -> pruebas"
  _omb_help_t "ssh-term-fix HOST" "instalar terminfo xterm-kitty en el remoto"
  _omb_help_t "ssh-term-safe HOST" "forzar TERM=xterm-256color en el remoto"
  _omb_help_t "refreshcolor" "recargar kitty y re-aplicar el tema"
  echo
}

function _omb_help_ai {
  _omb_help_has aichat || return 0
  _omb_help_c "▸ IA (Groq gpt-oss-20b, sin <think>)"
  _omb_help_t "ai \"desc\"" "genera un comando (no lo ejecuta)"
  _omb_help_t "ai -x \"desc\"" "genera y ejecuta (confirmación)"
  _omb_help_t "ai -e \"cmd\"" "explica un comando (o el último)"
  _omb_help_t "ai -m \"pregunta\"" "chat normal (sin contexto)"
  _omb_help_t "ai --nota \"...\"" "nota usada como contexto"
  _omb_help_t "ai <Tab>" "banderas · C-x i inserta en la línea"
  printf '  Contexto (solo generar/explicar): cwd + SO + últimos 3 comandos + archivos\n'
  printf '  (<=600 chars). Cache local en $OSH_CACHE_DIR. Config: OSH_AI_*.\n'
  echo
}

function _omb_help_themes {
  _omb_help_c "▸ TEMA Y ENTORNO"
  _omb_help_t "OSH_THEME_SCHEME" "auto | dark | light | ansi"
  _omb_help_t "OSH_THEME_SCHEME_INTERVAL" "segundos entre re-detecciones (3)"
  printf '  El prompt sigue la paleta de kitty (y KDE si kitty lo sigue).\n'
  _omb_help_t "OSH_PROFILE=1 bash -lic true" "perfil de arranque por fases"
  _omb_help_t "OSH_ONLINE_CHECK=0" "desactivar la sonda de red en background"
  echo
}

function _omb_help_examples {
  _omb_help_c "▸ EJEMPLOS"
  printf '  take proyecto && git init\n'
  printf '  extract backup.tar.gz\n'
  printf '  gcof                       # elegir rama git\n'
  printf '  killf                      # matar proceso\n'
  _omb_help_has aichat && printf '  ai -x "lista los 10 archivos más grandes"\n'
  _omb_help_has aichat && printf '  ai -e "tar -xzf backup.tar.gz"\n'
  printf '  Ctrl+F → escribe TODO → Enter abre nvim en la línea\n'
  printf '  Ctrl+T → elige un archivo → se inserta en la línea\n'
  echo
}

function _omb_help_all {
  _omb_help_header
  echo
  _omb_help_keys
  _omb_help_aliases
  _omb_help_functions
  _omb_help_ai
  _omb_help_themes
  _omb_help_examples
  printf 'Documentación completa: %s/README.md\n' "${OSH:-$HOME/oh-my-bash-fork}"
}

# shellcheck disable=SC2120  # se llama con y sin sección
function helpmeb {
  case ${1-} in
    atajos | keys) _omb_help_keys ;;
    aliases) _omb_help_aliases ;;
    funciones) _omb_help_functions ;;
    ia | ai) _omb_help_ai ;;
    temas | tema) _omb_help_themes ;;
    ejemplos) _omb_help_examples ;;
    "" | all) _omb_help_all ;;
    *)
      echo "helpmeb: sección desconocida '$1' (atajos|aliases|funciones|ia|temas|ejemplos)" >&2
      return 2
      ;;
  esac
}

# F1 (o C-x h) abre la ayuda en un paginador (o la imprime si no hay).
function _omb_help_open {
  if [[ -t 1 ]] && _omb_help_has less; then
    helpmeb | command less -R -F -X
  else
    helpmeb
  fi
}

if [[ -n ${BLE_VERSION-} ]]; then
  # ble.sh nombra las teclas de función en minúscula (f1), no F1
  ble-bind -m emacs -x f1 _omb_help_open
  ble-bind -m vi_imap -x f1 _omb_help_open
  # Alternativa si el terminal captura F1
  ble-bind -m emacs -x 'C-x h' _omb_help_open
  ble-bind -m vi_imap -x 'C-x h' _omb_help_open
elif [[ -t 0 ]]; then
  bind -x '"\eOP": _omb_help_open'   # F1 (xterm)
  bind -x '"\e[11~": _omb_help_open' # F1 (linux/vt)
  bind -x '"\C-xh": _omb_help_open'  # C-x h
fi
