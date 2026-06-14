# ── Si estamos en Kitty, usar el kitten ssh con TERM universal ──
# Se fuerza TERM=xterm-256color para evitar el error 'unknown terminal type'
# al hacer su/sudo, ya que xterm-256color existe en TODOS los servidores.
if { [ -n "$KITTY_PID" ] || [ "$TERM" = "xterm-kitty" ]; } && command -v kitty &>/dev/null; then
    alias ssh='TERM=xterm-256color kitty +kitten ssh'
fi
