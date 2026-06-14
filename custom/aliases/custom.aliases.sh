#!/bin/bash
# Custom aliases from .bash_vim that were removed during migration

alias tardis="python3 $HOME/oh-my-bash-fork/tardis.sh"
alias updateAll="yay -Syu --noconfirm --combinedupgrade && yay -Sc --noconfirm && flatpak update -y && flatpak uninstall --unused -y && yay -Qdtq | xargs sudo pacman -Rns --noconfirm 2>/dev/null"
alias proyectos="cd $HOME/Documents/Proyectos"
alias agenda="firefox agenda.guzman-lopez.com"
alias note="$HOME/oh-my-bash-fork/tardis.sh"
alias nota=note
alias dos2unixAll="find . -type f -print0 | xargs -0 dos2unix"
