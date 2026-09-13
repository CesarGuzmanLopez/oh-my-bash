#! bash oh-my-bash.module
# ── Personal helpers ──
# Funciones que antes vivían solo en ~/.bashrc, ahora versionadas en el fork.

# take: crea un directorio y entra en él (mkcd)
function take {
  [[ -n ${1-} ]] || {
    echo "uso: take <directorio>" >&2
    return 2
  }
  mkdir -p -- "$1" && builtin cd -- "$1" || return
}
alias mkcd='take'

# extract: descomprime casi cualquier formato
function extract {
  local f=${1-}
  [[ -n $f ]] || {
    echo "uso: extract <archivo>" >&2
    return 2
  }
  [[ -f $f ]] || {
    echo "extract: no existe '$f'" >&2
    return 1
  }

  case $f in
    *.tar.bz2 | *.tbz2) tar xjf "$f" ;;
    *.tar.gz | *.tgz) tar xzf "$f" ;;
    *.tar.xz | *.txz) tar xJf "$f" ;;
    *.tar.zst) tar --zstd -xf "$f" ;;
    *.tar) tar xf "$f" ;;
    *.bz2) _omb_util_command_exists bunzip2 && bunzip2 "$f" ;;
    *.gz) _omb_util_command_exists gunzip && gunzip "$f" ;;
    *.xz) _omb_util_command_exists unxz && unxz "$f" ;;
    *.zst) _omb_util_command_exists unzstd && unzstd "$f" ;;
    *.zip) _omb_util_command_exists unzip && unzip "$f" ;;
    *.7z) _omb_util_command_exists 7z && 7z x "$f" ;;
    *.rar) _omb_util_command_exists unrar && unrar x "$f" ;;
    *.deb) _omb_util_command_exists ar && ar x "$f" ;;
    *.rpm) _omb_util_command_exists rpm2cpio && rpm2cpio "$f" | cpio -idmv ;;
    *)
      echo "extract: formato no soportado: $f" >&2
      return 1
      ;;
  esac
}

# Sincroniza las ramas de 'origin' hacia el remoto 'pruebas'
function git-sync-a-pruebas {
  echo "📥 Fetching ramas desde origin..."
  git fetch origin --prune || return
  echo "🔁 Sincronizando ramas de 'origin' a 'pruebas'..."
  local full_branch
  while IFS= read -r full_branch; do
    [[ $full_branch == HEAD ]] && continue
    echo "⏩ Pushing rama '$full_branch' a 'pruebas'..."
    git push pruebas "origin/$full_branch:refs/heads/$full_branch" || return
  done < <(git for-each-ref --format='%(refname:strip=3)' refs/remotes/origin/)
  echo "🏷️  Sincronizando etiquetas..."
  git push pruebas --tags || return
  echo "✅ Sincronización completa."
}

# updateAll: actualiza y limpia el sistema (solo Arch)
function updateAll {
  if ! _omb_util_command_exists pacman && ! _omb_util_command_exists yay; then
    echo "updateAll: solo soportado en Arch (pacman/yay)." >&2
    return 1
  fi
  echo "📦 Actualizando paquetes (yay + pacman)..."
  if _omb_util_command_exists yay; then
    yay -Syu --noconfirm --combinedupgrade || return
  else
    sudo pacman -Syu --noconfirm || return
  fi
  echo "🧹 Limpiando cache..."
  if _omb_util_command_exists yay; then
    yay -Sc --noconfirm || return
  else
    sudo pacman -Sc --noconfirm || return
  fi
  echo "🔄 Actualizando Flatpak..."
  _omb_util_command_exists flatpak && { flatpak update -y || return; }
  echo "🗑️  Removiendo Flatpak no usados..."
  _omb_util_command_exists flatpak && { flatpak uninstall --unused -y || return; }
  echo "🧹 Limpiando paquetes huérfanos..."
  if _omb_util_command_exists pacman; then
    pacman -Qdtq 2>/dev/null | xargs -r sudo pacman -Rns --noconfirm
  fi
  echo "✅ Todo actualizado y limpio"
}

# clear: limpia pantalla + scrollback en kitty
if [[ -n ${KITTY_WINDOW_ID-} || ${TERM-} == xterm-kitty ]]; then
  alias clear='printf "\033[H\033[2J\033[3J"'
fi

# No cerrar la sesión al pulsar Ctrl+D diez veces
IGNOREEOF=${IGNOREEOF:-10}

# delta: mejor paginador de diffs de git (si está instalado)
if _omb_util_command_exists delta; then
  export GIT_PAGER='delta'
  export DELTA_FEATURES="${DELTA_FEATURES:+$DELTA_FEATURES }line-numbers"
fi
