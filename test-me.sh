#!/bin/bash
# ============================================================
# TEST: Oh-My-Bash Fork con tema Kitsune
# ============================================================
# Para probar: source ~/oh-my-bash-fork/test-me.sh
# Para salir: exit (vuelve a tu shell original)
# ============================================================

# OSH se auto-detecta en oh-my-bash.sh, pero forzamos la ruta por claridad
export OSH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuración de oh-my-bash
OSH_THEME="kitsune"
HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="dd/mm/yyyy"
OMB_DEFAULT_ALIASES="check"
OMB_USE_SUDO=true

# Completions
completions=(
  git
  composer
  ssh
)

# Aliases
aliases=(
  general
  chmod
  ls
  misc
)

# Plugins
plugins=(
  git
  bashmarks
)

# Source oh-my-bash fork
source "$OSH/oh-my-bash.sh"

# ============================================================
# FUNCIÓN: TARDIS - Información del sistema
# ============================================================
function tardis() {
    local script="$OSH/tardis.sh"
    if [[ ! -f "$script" ]]; then
        echo "❌ tardis.sh no encontrado en $OSH"
        return 1
    fi
    clear
    bash "$script"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🚀 Presiona ESC para salir"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    # Esperar ESC o 'q' para salir (no confundir con flechas que empiezan con ESC)
    while true; do
        read -rs -N1 key
        if [[ $key == 'q' ]]; then
            break
        fi
        if [[ $key == $'\e' ]]; then
            # Si es solo ESC (no una secuencia como flechas), salir
            read -rs -N2 -t 0.001 && continue
            break
        fi
    done
    clear
}

# Atajo de teclado: Ctrl+G para mostrar TARDIS
bind -x '"\C-g": tardis'

echo ""
echo "🚀 Oh-My-Bash FORK cargado con tema Kitsune"
echo "   OSH: $OSH"
echo "   Tema: $OSH_THEME"
echo "   Rama: $(cd $OSH && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'N/A')"
echo ""
echo "🆕 Atajos disponibles:"
echo "   Ctrl+G  → Mostrar TARDIS (info del sistema)"
echo "   Ctrl+F  → Buscar archivos con fzf"
echo "   Ctrl+T  → Insertar texto con fzf"
echo "   Ctrl+D  → Salir del test (volver a shell original)"
echo ""
