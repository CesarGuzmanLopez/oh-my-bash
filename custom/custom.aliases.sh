#!/bin/bash
# Custom aliases + functions — todo en git, sin rutas absolutas hardcodeadas

# ═══ Aliases ═══
alias tardis="python3 $HOME/oh-my-bash-fork/tardis.sh"
alias updateAll='
  echo "📦 Actualizando paquetes (yay + pacman)..." &&
  yay -Syu --noconfirm --combinedupgrade &&
  echo "🧹 Limpiando cache..." &&
  yay -Sc --noconfirm &&
  echo "🔄 Actualizando Flatpak..." &&
  flatpak update -y &&
  echo "🗑️  Removiendo Flatpak no usados..." &&
  flatpak uninstall --unused -y &&
  echo "🧹 Limpiando paquetes huérfanos..." &&
  yay -Qdtq | xargs -r sudo pacman -Rns --noconfirm &&
  echo "✅ Todo actualizado y limpio"
'
alias refreshcolor="kitten @ set-colors $HOME/.config/kitty/current-theme.conf"
alias proyectos="cd $HOME/Documents/Proyectos"
alias agenda="firefox agenda.guzman-lopez.com"
alias note="$HOME/oh-my-bash-fork/note.sh"
alias nota=note
alias hoy="$HOME/oh-my-bash-fork/hoy.sh"
alias dos2unixAll="find . -type f -print0 | xargs -0 dos2unix"
alias a-grep='grep -lirs --exclude-dir=".git;.svn" --color=always'

# ═══ Functions ═══

function Afind() {
    find "$1" -type f -not -path "*/.git/*"
}
export -f Afind

function wallpaper_color() {
    local bg_color
    bg_color=$(echo "$COLORFGBG" | cut -d ";" -f2)
    if [[ $bg_color -ge 8 ]]; then
        echo "dark"
    else
        echo "light"
    fi
}
