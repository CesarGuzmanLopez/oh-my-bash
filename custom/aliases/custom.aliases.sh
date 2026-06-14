#!/bin/bash
# Custom aliases — todos en git, sin rutas absolutas hardcodeadas

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
alias note="$HOME/oh-my-bash-fork/tardis.sh"
alias nota=note
alias dos2unixAll="find . -type f -print0 | xargs -0 dos2unix"
