#!/bin/bash
# Custom FZF configuration — migrated from .bash_vim

# ═══ FZF Environment ═══
export FZF_DEFAULT_OPTS="--height='30%' --layout='reverse'"
export FZF_DEFAULT_COMMAND="find . -type f -not -path '*/\.git/*'"

# ═══ FZF Ctrl+T Preview ═══
FZF_CTRL_T_OPTS="--preview 'bat --style=full --color=always --line-range :500 {}' --preview-window '~3' --bind='F2:toggle-preview,shift-up:preview-up,shift-down:preview-down' --color --height='90%'"

# ═══ FZF Compgen ═══
_fzf_compgen_path() {
    echo "$1"
    command find -L "$1" \
        -name .git -prune -o -name .hg -prune -o -name .svn -prune -o \( -type d -o -type f -o -type l \) \
        -a -not -path "$1" -print 2> /dev/null | sed 's@^\./@@'
}

_fzf_compgen_dir() {
    command find -L "$1" \
        -name .git -prune -o -name .hg -prune -o -name .svn -prune -o -type d \
        -a -not -path "$1" -print 2> /dev/null | sed 's@^\./@@'
}

_fzf_comprun() {
    local command=$1
    shift
    case "$command" in
        cd)           find . -type d -not -path '*/\.git/*' | fzf --preview 'tree -C {} -I ".git"| head -200' --color --height='40%' ;;
        export|unset) fzf --preview "eval 'echo \$'{}" --height='40%' ;;
        " " | "")     echo error ;;
        *)            find . | fzf --preview 'bat --style=full --color=always --line-range :500 {}' \
                            --preview-window '~3' --bind='F2:toggle-preview,shift-up:preview-up,shift-down:preview-down' \
                            --color --height='50%' ;;
    esac
}

# ═══ FZF Key Bindings ═══
__get_first_arg() {
    echo "$1"
}

insertar_texto() {
    local result
    result="$(_fzf_comprun $(__get_first_arg $READLINE_LINE))"
    READLINE_LINE=$(echo "$READLINE_LINE" | awk -v texto="$result" -v posicion="$READLINE_POINT" '{print substr($0,1,posicion-1) " " texto " " substr($0,posicion)}')
    READLINE_POINT=$(( READLINE_POINT + ${#result} + 1 ))
}

custom_fzf_search() {
    local selected
    selected=$(rg --color=always --line-number --no-heading --smart-case \
        -g '!node_modules/**' \
        -g '!.git/**' \
        -g '!LibreChat/**' \
        -g '!.cache/**' \
        -g '!vendor/**' \
        -g '!*.wt' -g '!*.bson' -g '!storage.bson' \
        "${*:-}" |
    fzf --ansi \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --delimiter : \
        --preview 'bat --color=always {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --exit-0 \
        --expect=ctrl-v) || return 0

    if [[ -z "$selected" ]]; then return 0; fi

    local file_path
    file_path=$(echo "$selected" | sed -n '2s/\([^:]*\):.*/\1/p')

    if [[ -n "$file_path" && -f "$file_path" ]]; then
        echo "$file_path" | xargs nvim
    fi
}

# Bindings
bind -x '"\C-f": custom_fzf_search'
bind -x '"\C-t": insertar_texto'
