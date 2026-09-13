#! bash oh-my-bash.module
# ── fzf helpers ──
_omb_util_command_exists fzf || return 0

# gcof: cambiar de rama git con fzf (preview del log)
function fzf-git-checkout {
  local branch
  branch=$(git for-each-ref --format='%(refname:short)' refs/heads refs/remotes/origin 2>/dev/null |
    sed 's#^origin/##' | sort -u |
    fzf --height=40% --reverse --prompt='rama> ' \
      --preview 'git log --oneline --graph --color=always -20 {}' \
      --preview-window 'right:60%') || return 0
  [[ -n $branch ]] && git checkout "$branch"
}
alias gcof='fzf-git-checkout'

# killf: elegir y matar un proceso
function fzf-kill {
  local pid
  pid=$(ps -eo pid,comm --sort=-%cpu | sed 1d |
    fzf --height=40% --reverse --prompt='matar> ' \
      --preview 'ps -p {1} -o pid,user,cmd' |
    awk '{print $1}') || return 0
  [[ -n $pid ]] && kill "$pid" && echo "señal enviada a $pid"
}
alias killf='fzf-kill'

# cdf: cd a un directorio elegido con fzf
function fzf-cd {
  local dir
  dir=$(find . -type d -not -path '*/.git/*' 2>/dev/null |
    fzf --height=40% --reverse --prompt='cd> ') || return 0
  [[ -n $dir ]] && { builtin cd -- "$dir" || return; }
}
alias cdf='fzf-cd'

# editf: abrir un archivo elegido con fzf en $EDITOR
function fzf-edit {
  local file
  file=$(find . -type f -not -path '*/.git/*' 2>/dev/null |
    fzf --height=40% --reverse --prompt='editar> ' \
      --preview 'bat --style=plain --color=always --line-range=:200 {}') || return 0
  [[ -n $file ]] && "${EDITOR:-vim}" "$file"
}
alias editf='fzf-edit'
