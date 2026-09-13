#!/bin/bash
# Custom aliases + functions — all paths use $OSH (auto-detected)

# ═══ Aliases ═══
alias tardis="bash $OSH/tardis.sh"
alias refreshcolor='if command -v kitten >/dev/null 2>&1; then kitten @ load-config; fi; if [[ $(type -t _omb_theme_reload_colors) == function ]]; then _omb_theme_reload_colors; fi'
alias proyectos="cd $HOME/Documents/Proyectos"
alias agenda="firefox agenda.guzman-lopez.com"
alias note="$OSH/note.sh"
alias nota=note
alias hoy="$OSH/hoy.sh"
alias dos2unixAll="find . -type f -print0 | xargs -0 dos2unix"
alias a-grep='grep -lirs --exclude-dir=".git;.svn" --color=always'

# ═══ Functions ═══

function Afind() {
    find "${1:-.}" -type f -not -path "*/.git/*"
}
export -f Afind

function wallpaper_color() {
    local bg_color
    bg_color=$(echo "${COLORFGBG:-}" | cut -d ";" -f2)
    if [[ ${bg_color:-0} -ge 8 ]]; then
        echo "dark"
    else
        echo "light"
    fi
}
