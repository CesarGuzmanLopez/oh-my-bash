#! bash oh-my-bash.module
# ── Modern CLI replacements (con fallback) ──
# Usa eza/bat si están instalados; si no, deja los aliases originales.
#   Opt-out total:      export OSH_MODERN_CLI=0
#   Reemplazos de grep/find (semántica distinta): export OSH_MODERN_CLI_AGGRESSIVE=1
[[ ${OSH_MODERN_CLI:-1} == 0 ]] && return 0

# eza (ls)
if _omb_util_command_exists eza; then
  alias ls='eza --group-directories-first --icons=auto'
  alias l='eza -lah --group-directories-first --icons=auto --git'
  alias ll='eza -lh --group-directories-first --icons=auto --git'
  alias la='eza -lah --group-directories-first --icons=auto'
  alias l.='eza -d .* --group-directories-first --icons=auto'
  alias lt='eza -lah --sort=newest --group-directories-first --icons=auto'
  alias lr='eza -lah --tree --level=2 --group-directories-first --icons=auto'
  alias lo='eza -lh --sort=size --reverse --group-directories-first --icons=auto'
  alias lk='eza -lh --sort=size --group-directories-first --icons=auto'
fi

# bat (cat)
if _omb_util_command_exists bat; then
  alias cat='bat --style=plain --pager=never'
  alias catn='bat --style=numbers --pager=never'
  alias catp='bat --style=plain'
fi

# Reemplazos "agresivos" (flags distintos a grep/find). Opcionales.
if [[ ${OSH_MODERN_CLI_AGGRESSIVE:-0} == 1 ]]; then
  _omb_util_command_exists rg && alias grep='rg --color=auto'
  _omb_util_command_exists fd && alias find='fd'
fi
