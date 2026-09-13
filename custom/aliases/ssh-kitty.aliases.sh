#! bash oh-my-bash.module
# ssh-kitty — SSH desde kitty sin el error "unknown terminal type"
#
# Contexto: kitty define TERM=xterm-kitty, que no existe en la mayoría de
# servidores. `kitty +kitten ssh` copia la terminfo al $HOME/.terminfo del
# usuario remoto y exporta TERMINFO, pero al hacer `sudo -i` o `su` el HOME
# cambia y root ya no encuentra xterm-kitty →
#   'xterm-kitty': unknown terminal type
#
# Herramientas:
#   ssh                → SSH con TERM=xterm-256color + integración de kitty.
#                        xterm-256color existe en todos los servidores y
#                        sobrevive a `su`/`sudo -i`, así que no hay error.
#   ssh-kitty          → integración completa de kitty (TERM=xterm-kitty).
#   ssh-term-fix host  → instala xterm-kitty en /usr/share/terminfo del remoto
#                        (solución global, útil si quieres TERM=xterm-kitty y
#                        usas root/su/sudo allí).
#   ssh-term-safe host → fuerza TERM=xterm-256color en la sesión remota.
#   kitty-term-info    → comprueba la terminfo local de xterm-kitty.

if [[ -n ${KITTY_PID-} || ${TERM-} == xterm-kitty ]] && _omb_util_command_exists kitty; then
  # Máxima compatibilidad: TERM seguro + integración/reutilización de kitty.
  alias ssh='TERM=xterm-256color kitty +kitten ssh'
fi

# Integración completa (TERM=xterm-kitty). Para root/su usa `ssh-term-fix`.
alias ssh-kitty='kitty +kitten ssh'

# ¿Tenemos la terminfo de xterm-kitty en local?
function kitty-term-info {
  if infocmp xterm-kitty >/dev/null 2>&1; then
    echo "✅ terminfo xterm-kitty disponible: $(infocmp -D xterm-kitty 2>/dev/null | head -1)"
  else
    echo "❌ Falta la terminfo xterm-kitty."
    echo "   Arch:            sudo pacman -S kitty-terminfo"
    echo "   Debian/Ubuntu:   sudo apt install kitty-terminfo"
    echo "   Alternativa:     sudo cp -r /usr/lib/kitty/terminfo/x /usr/share/terminfo/"
  fi
}

# Instala xterm-kitty system-wide en el host remoto (arregla root/su/sudo).
function ssh-term-fix {
  local host=${1:?uso: ssh-term-fix usuario@host}
  _omb_util_command_exists infocmp || {
    echo "Falta 'infocmp' (paquete ncurses)." >&2
    return 1
  }
  echo "→ Instalando terminfo xterm-kitty en $host (se pedirá sudo allí)..."
  local remote_cmd="command -v tic >/dev/null || { echo 'Falta tic (ncurses-bin)'; exit 1; }; sudo sh -c 'mkdir -p /usr/share/terminfo && tic -x -o /usr/share/terminfo -' && echo INSTALADO"
  if infocmp -x xterm-kitty 2>/dev/null | command ssh -t "$host" "$remote_cmd"; then
    echo "✅ Listo. root/su/sudo ya reconocen xterm-kitty en $host."
  else
    echo "⚠️  No se pudo instalar. Alternativa: ssh-term-safe $host" >&2
    return 1
  fi
}

# Fuerza un TERM seguro en la sesión remota (no modifica el servidor).
function ssh-term-safe {
  local host=${1:?uso: ssh-term-safe usuario@host}
  command ssh -t "$host" 'TERM=xterm-256color; export TERM; exec "${SHELL:-/bin/bash}" -l'
}
