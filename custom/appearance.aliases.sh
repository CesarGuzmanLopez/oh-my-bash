#! bash oh-my-bash.module
# ── Apariencia: color de comandos, paginadores y aliases divertidos ──
# Se carga antes del tema (oh-my-bash.sh), por eso aquí se fijan las
# variables OSH_THEME_* que el tema kitsune consume.
#
#   Desactivar todo:   export OSH_APPEARANCE=0
#   Desactivar grc:    export OSH_APPEARANCE_GRC=0
[[ ${OSH_APPEARANCE:-1} == 0 ]] && return 0

# ── bat: tema acorde a la paleta morado/café/marino (claro/oscuro) ──
# El tema kitsune los aplica en _omb_theme_apply_tool_theme.
export OSH_THEME_BAT_DARK="${OSH_THEME_BAT_DARK:-Catppuccin Mocha}"
export OSH_THEME_BAT_LIGHT="${OSH_THEME_BAT_LIGHT:-Catppuccin Latte}"
export OSH_THEME_BAT_ANSI="${OSH_THEME_BAT_ANSI:-ansi}"

# ── eza: acentos morado/marino manteniendo el resto por defecto ──
if _omb_util_command_exists eza; then
  export EZA_COLORS="di=1;38;5;141:ex=1;38;5;114:ln=1;38;5;117:pi=38;5;141:so=38;5;141:*.md=38;5;183:*.yml=38;5;221:*.yaml=38;5;221:*.json=38;5;114:*.py=38;5;221:*.rs=38;5;209:*.go=38;5;117:*.hs=38;5;141:git=38;5;141"
fi

# ── LS_COLORS con tema vivid (para ls/dircolors y herramientas afines) ──
if _omb_util_command_exists vivid; then
  _osh_appearance_ls=$(vivid generate catppuccin-mocha 2>/dev/null)
  # No pisar LS_COLORS si vivid no devuelve nada
  if [[ -n $_osh_appearance_ls ]]; then
    export LS_COLORS="$_osh_appearance_ls"
  fi
  unset _osh_appearance_ls
fi

# ── Paginadores y `man` a color ──
# --use-color existe en less >= 566; si no, se usa -R a secas.
if command less --help 2>/dev/null | command grep -q -- '--use-color'; then
  export LESS='-R --use-color -Dd+r -Du+b'
else
  export LESS='-R'
fi
export LESS_TERMCAP_mb=$'\e[1;35m'            # negrita parpadeante / inicio
export LESS_TERMCAP_md=$'\e[1;35m'            # negrita (títulos)
export LESS_TERMCAP_me=$'\e[0m'               # fin negrita
export LESS_TERMCAP_so=$'\e[38;5;0;48;5;180m' # caja de estado
export LESS_TERMCAP_se=$'\e[0m'               # fin caja de estado
export LESS_TERMCAP_us=$'\e[1;4;36m'          # subrayado
export LESS_TERMCAP_ue=$'\e[0m'               # fin subrayado
# bat como paginador de man solo si bat y col existen (col = util-linux).
if _omb_util_command_exists bat && _omb_util_command_exists col; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  export MANROFFOPT='-c'
fi

# ── git-delta (personal.sh completa DELTA_FEATURES con line-numbers) ──
if _omb_util_command_exists delta; then
  export DELTA_FEATURES="${DELTA_FEATURES:+$DELTA_FEATURES }decorations navigate"
fi

# ── grep/diff con color cuando salen a terminal ──
# Solo se crea el alias si el binario soporta --color (evita romper BSD/macOS).
if command grep --color=auto '' /dev/null >/dev/null 2>&1; then
  alias grep='grep --color=auto'
fi
if command diff --color=auto /dev/null /dev/null >/dev/null 2>&1; then
  alias diff='diff --color=auto'
fi

# ── grc: coloriza la salida de herramientas comunes ──
# Se evitan a propósito head/tail/diff/id (rompen pipes o ya tienen color).
if [[ ${OSH_APPEARANCE_GRC:-1} != 0 ]] && _omb_util_command_exists grc; then
  alias ping='grc ping'
  alias ping6='grc ping6'
  alias traceroute='grc traceroute'
  alias traceroute6='grc traceroute6'
  alias df='grc df'
  alias du='grc du'
  alias free='grc free'
  alias lsblk='grc lsblk'
  alias lspci='grc lspci'
  alias ss='grc ss'
  alias netstat='grc netstat'
  alias ip='grc ip'
  alias findmnt='grc findmnt'
  alias dig='grc dig'
  alias mtr='grc mtr'
  alias uptime='grc uptime'
  alias sensors='grc sensors'
  alias whois='grc whois'
  alias systemctl='grc systemctl'
  # journalctl/docker/kubectl se omiten a propósito: grcat bufferiza y
  # rompería `journalctl -f` y los `-it` interactivos.
  alias make='grc make'
  alias gcc='grc gcc'
  alias g++='grc g++'
  alias wdiff='grc wdiff'
fi

# ── Aliases divertidos / informativos (a demanda, no en el arranque) ──
_omb_util_command_exists fastfetch && alias ff='fastfetch'
_omb_util_command_exists cmatrix && alias matrix='cmatrix -ba -C magenta'
_omb_util_command_exists asciiquarium && alias aquarium='asciiquarium'
_omb_util_command_exists lolcat && alias rain='lolcat'
_omb_util_command_exists toilet && alias banner='toilet -f bigmono9 -F metal'
_omb_util_command_exists cowsay && alias cow='cowsay'
_omb_util_command_exists nyancat && alias nyan='nyancat'
_omb_util_command_exists tty-clock && alias clock='tty-clock -c -C 5 -s'
_omb_util_command_exists pokemon-colorscripts && alias pokemon='pokemon-colorscripts -r'
_omb_util_command_exists pipes.sh && alias pipes='pipes.sh'
_omb_util_command_exists cbonsai && alias bonsai='cbonsai -li'
_omb_util_command_exists lavat && alias lava='lavat'
_omb_util_command_exists cava && alias music='cava'
_omb_util_command_exists chafa && alias pic='chafa'

# ── Ver imágenes DENTRO de la terminal ──
# Prefiere el protocolo gráfico de kitty (kitten icat); si no, chafa/viu.
function img {
  if [[ ${TERM:-} == xterm-kitty ]] && _omb_util_command_exists kitten; then
    kitten icat -- "$@"
  elif _omb_util_command_exists chafa; then
    chafa -- "$@"
  elif _omb_util_command_exists viu; then
    viu -- "$@"
  else
    echo "img: instala kitty, chafa o viu" >&2
    return 1
  fi
}
