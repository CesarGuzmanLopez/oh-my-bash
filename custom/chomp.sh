#! bash oh-my-bash.module
# ── ILoveCandy: convierte la 'C' amarilla en el icono REAL de Pac-Man ──
# Usa el glifo U+F0BAF (md-pac_man) de JetBrainsMono Nerd Font, conservando
# el color amarillo. Intercepta SOLO la secuencia que imprime pacman, así que
# no afecta a ninguna otra 'C' del texto.
#
#   Uso manual:   chomp yay -Syu
#   Automático:   export OSH_CHOMP=1     (envuelve yay/pacman/sudo pacman)
#   Desactivar:   export OSH_CHOMP=0     (por defecto)
#
# Guardas: solo Arch, solo si existe el filtro y python3. Si no, no define nada.
[[ -x $HOME/.local/bin/chomp-filter ]] || return 0
_omb_util_command_exists python3 || return 0
[[ -f /etc/arch-release || -f /etc/pacman.conf ]] || return 0

# Ejecuta cualquier comando con el filtro (útil también fuera de pacman).
function chomp {
  "$HOME/.local/bin/chomp-filter" "$@"
}

[[ ${OSH_CHOMP:-0} == 1 ]] || return 0

# Gating: solo transacciones (no búsquedas/consultas).
_chomp_txn() {
  local a
  for a in "$@"; do
    case $a in
      -S | -Sy | -Syy | -Su | -Syu | -Syyu) return 0 ;;
      -Sy* | -Su* | -Sw* | --sync | --sysupgrade) return 0 ;;
      -U* | --upgrade) return 0 ;;
      -R* | --remove) return 0 ;;
    esac
  done
  return 1
}

if _omb_util_command_exists yay && [[ -x $(type -P yay) ]]; then
  yay() {
    if _chomp_txn "$@"; then chomp "$(type -P yay)" "$@"; else command yay "$@"; fi
  }
fi

if [[ -x $(type -P pacman) ]]; then
  pacman() {
    if _chomp_txn "$@"; then chomp "$(type -P pacman)" "$@"; else command pacman "$@"; fi
  }
fi

if [[ ${OSH_CHOMP_SUDO:-1} != 0 ]] && [[ -x $(type -P sudo) ]]; then
  sudo() {
    if [[ ${1:-} == pacman ]] && _chomp_txn "${@:2}"; then
      chomp "$(type -P sudo)" "$@"
    else
      command sudo "$@"
    fi
  }
fi
