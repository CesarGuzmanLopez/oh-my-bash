#!/bin/bash
# Custom FZF configuration — migrated from .bash_vim

# ═══ FZF Environment ═══
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --bind=esc:cancel"
export FZF_DEFAULT_COMMAND="find . -type f -not -path '*/\.git/*'"

# ═══ FZF Ctrl+T Preview ═══
FZF_CTRL_T_OPTS="--preview 'bat --style=full --color=always --line-range :500 {}' --preview-window '~3' --bind='F2:toggle-preview,shift-up:preview-up,shift-down:preview-down' --color --height=90%"

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
        cd)           find . -type d -not -path '*/\.git/*' | fzf --preview 'tree -C {} -I ".git"| head -200' --height=40% ;;
        export|unset) fzf --preview "eval 'echo \$'{}" --height=40% ;;
        " ")          echo error ;;
        *)            find . | fzf --preview 'bat --style=full --color=always --line-range :500 {}' \
                            --preview-window '~3' --bind='F2:toggle-preview,shift-up:preview-up,shift-down:preview-down' \
                            --height=50% ;;
    esac
}

# ═══ FZF Key Bindings ═══
__get_first_arg() {
    echo "$1"
}

insertar_texto() {
    local cmd result
    # Primer palabra de la línea actual (el comando en el que estamos)
    cmd="${READLINE_LINE-}"
    cmd="${cmd%% *}"
    result=$(_fzf_comprun "$cmd") || return 0
    [[ -n "$result" ]] || return 0
    # Inserta en la posición del cursor sin alterar el resto de la línea
    READLINE_LINE="${READLINE_LINE:0:READLINE_POINT} $result ${READLINE_LINE:READLINE_POINT}"
    READLINE_POINT=$(( READLINE_POINT + ${#result} + 2 ))
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
# OJO: ~/.fzf.bash se suele cargar DESPUÉS de oh-my-bash, y su
# `eval "$(fzf --bash)"` re-bindea \C-t y pisa el nuestro. Registramos el
# re-bind como hook de prompt para que el custom gane siempre.
function _omb_fzf_rebind {
    # Sin terminal interactiva no hay readline que enlazar
    [[ -t 0 ]] || return 0
    bind -x '"\C-f": custom_fzf_search'
    bind -x '"\C-t": insertar_texto'
}
_omb_fzf_rebind
if [[ $(type -t _omb_util_add_prompt_command) == function ]]; then
    _omb_util_add_prompt_command _omb_fzf_rebind
fi
