#! bash oh-my-bash.module
# kitsune theme — dynamic palette with dark/light/ansi fallback
#
# Color modes (OSH_THEME_SCHEME):
#   auto  (default) detect at runtime
#   dark  force dark family (dark blocks + bright text)
#   light force light family (pastel blocks + dark text)
#   ansi  use only the terminal's own ANSI colors (no RGB blocks). This is the
#         fallback for sessions where the local desktop palette is unknown,
#         e.g. SSH from Windows/macOS or a non-KDE/kitty terminal. It adapts to
#         whatever light/dark theme the terminal has.
#
# Detection order in `auto`:
#   1. kitty live colors (`kitten @ get-colors background`)
#   2. remote session without kitty (SSH)   → ansi
#   3. KDE Plasma (`kreadconfig6`/`kreadconfig5`)
#   4. GNOME / freedesktop (`gsettings`)
#   5. $COLORFGBG
#   6. fallback                              → ansi

_omb_module_require plugin:battery

_RST='\[\e[0m\]'

# ── helpers ────────────────────────────────────────────────────

function _omb_theme_in_kitty {
  [[ -n ${KITTY_WINDOW_ID-} ]] && _omb_util_command_exists kitten
}

# Run an external command with a short timeout, so a hung socket/dbus/kdeglobals
# can never block the prompt.
function _omb_theme_run_timeout {
  local seconds=$1
  shift
  if _omb_util_command_exists timeout; then
    timeout "$seconds" "$@" 2>/dev/null
  else
    "$@" 2>/dev/null
  fi
}

# `kitten @ get-colors` with a timeout so it can never hang a remote shell
function _omb_theme_kitten_colors {
  _omb_theme_run_timeout 0.5 kitten @ get-colors
}

# Is a KDE/Plasma session actually active? (kdeglobals may exist even
# without a running Plasma, e.g. after switching DE or in a stale config.)
function _omb_theme_kde_active {
  [[ -n ${KDE_FULL_SESSION-} ]] && return 0
  [[ -n ${KDE_SESSION_VERSION-} ]] && return 0
  case ${XDG_CURRENT_DESKTOP-} in *[Kk][Dd][Ee]*) return 0 ;; esac
  case ${DESKTOP_SESSION-} in *[Pp]lasma* | *[Kk][Dd][Ee]*) return 0 ;; esac
  # Fallback: only trust a running Plasma/KWin if we actually have a display
  [[ -n ${DISPLAY-}${WAYLAND_DISPLAY-} ]] || return 1
  if _omb_util_command_exists pgrep; then
    pgrep -x plasmashell >/dev/null 2>&1 && return 0
    pgrep -x kwin_wayland >/dev/null 2>&1 && return 0
    pgrep -x kwin_x11 >/dev/null 2>&1 && return 0
  fi
  return 1
}

# Is a GNOME/Unity session actually active? `gsettings` can hang for seconds
# without a session (headless, SSH, KDE), so only query it when GNOME runs.
function _omb_theme_gnome_active {
  [[ -n ${GNOME_DESKTOP_SESSION_ID-} ]] && return 0
  [[ -n ${GNOME_SHELL_SESSION_MODE-} ]] && return 0
  case ${XDG_CURRENT_DESKTOP-} in *[Gg][Nn][Oo][Mm][Ee]* | *[Uu]nity*) return 0 ;; esac
  return 1
}

# Is there a source whose value can change while the shell is alive?
function _omb_theme_has_dynamic_source {
  _omb_theme_in_kitty && return 0
  _omb_theme_kde_active && return 0
  _omb_theme_gnome_active && _omb_util_command_exists gsettings && return 0
  return 1
}

# Print "dark" or "light" from a color spec (#rrggbb or r,g,b).
function _omb_theme_luminance {
  local spec=$1 r g b
  if [[ $spec == \#* ]]; then
    r=$((16#${spec:1:2}))
    g=$((16#${spec:3:2}))
    b=$((16#${spec:5:2}))
  elif [[ $spec =~ ^([0-9]+),([0-9]+),([0-9]+)$ ]]; then
    r=${BASH_REMATCH[1]}
    g=${BASH_REMATCH[2]}
    b=${BASH_REMATCH[3]}
  else
    return 1
  fi
  # Perceived luminance (ITU-R BT.601)
  local lum=$(((r * 299 + g * 587 + b * 114) / 1000))
  if ((lum < 128)); then printf 'dark\n'; else printf 'light\n'; fi
}

# Print the active scheme: dark | light | ansi
function _omb_theme_detect_scheme {
  # 1) Explicit override
  case ${OSH_THEME_SCHEME:-auto} in
    dark | light | ansi)
      printf '%s\n' "$OSH_THEME_SCHEME"
      return
      ;;
  esac

  # 2) kitty live colors
  if _omb_theme_in_kitty; then
    local bg
    bg=$(_omb_theme_kitten_colors | awk '$1 == "background" { print $2; exit }')
    [[ -n $bg ]] && _omb_theme_luminance "$bg" && return
  fi

  # 3) Remote session without kitty: the local desktop palette does not
  #    describe the client terminal (Windows/macOS/other), so just use the
  #    terminal's own colors.
  if [[ -n ${SSH_CLIENT-}${SSH_CONNECTION-}${SSH_TTY-} ]]; then
    printf 'ansi\n'
    return
  fi

  # 4) KDE Plasma — only when a Plasma session is actually active
  if _omb_theme_kde_active; then
    local kread=kreadconfig6
    _omb_util_command_exists "$kread" || kread=kreadconfig5
    if _omb_util_command_exists "$kread"; then
      local cs
      cs=$(_omb_theme_run_timeout 0.5 "$kread" --file kdeglobals --group General --key ColorScheme)
      case $cs in
        *[Dd]ark*)
          printf 'dark\n'
          return
          ;;
        *[Ll]ight*)
          printf 'light\n'
          return
          ;;
      esac
      local bg
      bg=$(_omb_theme_run_timeout 0.5 "$kread" --file kdeglobals --group Colors:Window --key BackgroundNormal)
      [[ -n $bg ]] && _omb_theme_luminance "$bg" && return
    fi
  fi

  # 5) GNOME / freedesktop portal preference (only with a real GNOME session)
  if _omb_theme_gnome_active && _omb_util_command_exists gsettings; then
    local cs
    cs=$(_omb_theme_run_timeout 0.5 gsettings get org.gnome.desktop.interface color-scheme)
    case $cs in
      *prefer-dark*)
        printf 'dark\n'
        return
        ;;
      *prefer-light*)
        printf 'light\n'
        return
        ;;
    esac
    cs=$(_omb_theme_run_timeout 0.5 gsettings get org.gnome.desktop.interface gtk-theme)
    case $cs in
      *[Dd]ark*)
        printf 'dark\n'
        return
        ;;
      *[Ll]ight*)
        printf 'light\n'
        return
        ;;
    esac
  fi

  # 6) $COLORFGBG (e.g. "15;0" → background index 0 = dark)
  if [[ -n ${COLORFGBG-} ]]; then
    local bgidx=${COLORFGBG##*;}
    if [[ $bgidx =~ ^[0-9]+$ ]]; then
      if ((bgidx < 8)); then printf 'dark\n'; else printf 'light\n'; fi
      return
    fi
  fi

  # 7) fallback: respect the terminal's own color family
  printf 'ansi\n'
}

# ── palette ────────────────────────────────────────────────────

# Keep bat (and fzf) in sync with the detected scheme. Override the theme
# names with OSH_THEME_BAT_DARK / OSH_THEME_BAT_LIGHT / OSH_THEME_BAT_ANSI.
function _omb_theme_apply_tool_theme {
  case $OSH_THEME_SCHEME_ACTIVE in
    light) export BAT_THEME="${OSH_THEME_BAT_LIGHT:-Monokai Extended Light}" ;;
    ansi) export BAT_THEME="${OSH_THEME_BAT_ANSI:-ansi}" ;;
    *) export BAT_THEME="${OSH_THEME_BAT_DARK:-Monokai Extended}" ;;
  esac

  if [[ -n ${FZF_DEFAULT_OPTS-} ]]; then
    local base preset
    base=${FZF_DEFAULT_OPTS//--color=[! ]*/}
    base=${base//  / }
    case $OSH_THEME_SCHEME_ACTIVE in
      light) preset=light ;;
      ansi) preset=16 ;;
      *) preset=dark ;;
    esac
    export FZF_DEFAULT_OPTS="${base% } --color=$preset"
  fi
}

function _omb_theme_load_colors {
  local scheme='' kitty_colors=''
  local -a hex_src=()
  local i val conf

  # Live kitty palette (fetched once). Needed for the palette even when the
  # scheme is forced, so fetch it before deciding the scheme.
  if _omb_theme_in_kitty; then
    kitty_colors=$(_omb_theme_kitten_colors)
  fi

  # Explicit override always wins.
  case ${OSH_THEME_SCHEME:-auto} in
    dark | light | ansi) scheme=$OSH_THEME_SCHEME ;;
  esac

  # Otherwise derive the scheme from the live kitty background; if that is
  # not possible, fall back to the full detection.
  if [[ -z $scheme && -n $kitty_colors ]]; then
    local bg
    bg=$(printf '%s\n' "$kitty_colors" | awk '$1 == "background" { print $2; exit }')
    [[ -n $bg ]] && scheme=$(_omb_theme_luminance "$bg")
  fi
  scheme=${scheme:-$(_omb_theme_detect_scheme)}
  OSH_THEME_SCHEME_ACTIVE=$scheme

  # ansi / fallback: no RGB blocks, terminal palette defines everything.
  if [[ $scheme == ansi ]]; then
    _BG_TIME='' _BG_SCM='' _BG_ERROR='' _BG_PYTHON='' _BG_NPM='' _BG_ENV=''
    _FG_WHITE='\[\e[39m\]' # default foreground (adapts to terminal)
    _FG_GREEN='\[\e[32m\]'
    _FG_TEAL='\[\e[36m\]'
    _FG_RED='\[\e[31m\]'
    _FG_YELLOW='\[\e[33m\]'
    _FG_TEAL_D='\[\e[36m\]'
    _FG_OLIVE_D='\[\e[33m\]'
    _omb_theme_apply_tool_theme
    return
  fi

  # 1) live kitty colors (already captured above, no second `kitten` call)
  if [[ -n $kitty_colors ]]; then
    local -a live=()
    while IFS= read -r val; do
      live+=("$val")
    done <<<"$kitty_colors"
    for ((i = 1; i <= 6; i++)); do
      hex_src[$((i - 1))]=$(printf '%s\n' "${live[@]}" | awk -v k="color$i" '$1 == k { print $2; exit }')
    done
  fi

  # 2) kitty theme files (scheme-specific auto conf, then legacy current-theme)
  for conf in \
    "$HOME/.config/kitty/${scheme}-theme.auto.conf" \
    "$HOME/.config/kitty/current-theme.conf"; do
    [[ -f $conf ]] || continue
    for ((i = 1; i <= 6; i++)); do
      if [[ -z ${hex_src[$((i - 1))]} ]]; then
        hex_src[$((i - 1))]=$(grep -m1 -E "^color${i}[[:space:]]" "$conf" 2>/dev/null |
          grep -oE '#[0-9a-fA-F]{6}' | tail -1)
      fi
    done
    [[ -n ${hex_src[5]} ]] && break
  done

  # 3) defaults (kitty dark palette)
  local -a defaults=('#ff6b81' '#7ee0a0' '#ffc061' '#7aa2ff' '#c9a6ff' '#6fe0e0')
  for ((i = 0; i < 6; i++)); do
    [[ -z ${hex_src[$i]} ]] && hex_src[$i]=${defaults[$i]}
  done

  # Derive backgrounds (solid blocks)
  local -a bg=()
  local hex r g b
  for ((i = 0; i < 6; i++)); do
    hex=${hex_src[$i]}
    r=$((16#${hex:1:2}))
    g=$((16#${hex:3:2}))
    b=$((16#${hex:5:2}))
    if [[ $scheme == light ]]; then
      # Pastel: blend accent with white (75% keeps blocks visible on white)
      r=$((r + (255 - r) * 75 / 100))
      g=$((g + (255 - g) * 75 / 100))
      b=$((b + (255 - b) * 75 / 100))
    else
      # Dark: keep 30% of the accent
      r=$((r * 30 / 100))
      g=$((g * 30 / 100))
      b=$((b * 30 / 100))
    fi
    bg[$i]="\e[48;2;${r};${g};${b}m"
  done

  _BG_TIME="\[${bg[1]}\]"   # color2
  _BG_SCM="\[${bg[4]}\]"    # color5
  _BG_ERROR="\[${bg[0]}\]"  # color1
  _BG_PYTHON="\[${bg[3]}\]" # color4
  _BG_NPM="\[${bg[2]}\]"    # color3
  _BG_ENV="\[${bg[5]}\]"    # color6

  # Foreground family
  if [[ $scheme == light ]]; then
    _FG_WHITE='\[\e[30;1m\]'
    _FG_GREEN='\[\e[38;5;28m\]'
    _FG_TEAL='\[\e[38;5;30m\]'
    _FG_RED='\[\e[31;1m\]'
    _FG_YELLOW='\[\e[38;5;130m\]'
    _FG_TEAL_D='\[\e[38;5;24m\]'
    _FG_OLIVE_D='\[\e[38;5;94m\]'
  else
    _FG_WHITE='\[\e[97;1m\]'
    _FG_GREEN='\[\e[92;1m\]'
    _FG_TEAL='\[\e[96;1m\]'
    _FG_RED='\[\e[91;1m\]'
    _FG_YELLOW='\[\e[93;1m\]'
    _FG_TEAL_D='\[\e[38;5;30m\]'
    _FG_OLIVE_D='\[\e[38;5;100m\]'
  fi
  _omb_theme_apply_tool_theme
}

# Initialize
_omb_theme_load_colors

function __powerline_python_venv_prompt {
  local v=""
  [[ -n "${CONDA_DEFAULT_ENV}" ]] && v="${CONDA_DEFAULT_ENV}"
  [[ -n "${VIRTUAL_ENV}" ]] && v=$(basename "${VIRTUAL_ENV}")
  [[ -n "$v" ]] && echo " ${_BG_PYTHON-}${_FG_WHITE} 🐍 $v ${_RST}"
}

function __npm_env_prompt {
  [[ -n "${npm_package_name}" ]] && echo " ${_BG_NPM-}${_FG_YELLOW} 📦 ${npm_package_name} ${_RST}"
}

function _user_info {
  [[ -n "${SSH_CLIENT}" ]] && echo "${USER}|🌎@${HOSTNAME%%.*}" || echo "${USER}|💻"
}

function get_symbol_user_info {
  [[ "$(id -u)" == 0 ]] && printf "💀" || printf "🌟"
}

# ── SCM prompt info ──
# Caches "is this a git repo?" per directory so non-repo dirs never spawn git.
# Optionally computes the branch in the background (OSH_PROMPT_ASYNC_GIT=1),
# showing the previous value so a slow repo never blocks the prompt.
# _omb_theme_scm_refresh() runs in the parent shell (from PROMPT_COMMAND) so
# this cached state persists across prompts.
_omb_theme_scm_dir=
_omb_theme_scm_is_repo=0
_omb_theme_scm_async_dir=
_omb_theme_scm_async_pid=

function _omb_theme_scm_check_repo {
  if [[ ${PWD-} != "$_omb_theme_scm_dir" ]]; then
    _omb_theme_scm_dir=$PWD
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      _omb_theme_scm_is_repo=1
    else
      _omb_theme_scm_is_repo=0
    fi
  fi
  ((_omb_theme_scm_is_repo))
}

# Runs in the parent shell: updates the repo cache and, in async mode,
# launches the background worker (so the pid survives to the next prompt).
function _omb_theme_scm_refresh {
  _omb_theme_scm_check_repo || return 0
  [[ ${OSH_PROMPT_ASYNC_GIT:-0} == 1 ]] || return 0
  [[ -n $_omb_theme_scm_async_dir ]] ||
    _omb_theme_scm_async_dir=${TMPDIR:-/tmp}/omb-prompt-$$
  [[ -d $_omb_theme_scm_async_dir ]] || mkdir -p "$_omb_theme_scm_async_dir" 2>/dev/null
  local key f
  key=$(printf '%s' "$PWD" | cksum | awk '{print $1}')
  f="$_omb_theme_scm_async_dir/$key"
  if [[ -z $_omb_theme_scm_async_pid ]] || ! kill -0 "$_omb_theme_scm_async_pid" 2>/dev/null; then
    (scm_prompt_info >"$f.tmp" 2>/dev/null && mv "$f.tmp" "$f") >/dev/null 2>&1 &
    _omb_theme_scm_async_pid=$!
  fi
}

# Emits the SCM info (runs inside a command substitution).
function _omb_theme_scm_prompt_info {
  if [[ ${OSH_PROMPT_ASYNC_GIT:-0} == 1 ]]; then
    [[ -n $_omb_theme_scm_async_dir ]] || return 0
    local key f
    key=$(printf '%s' "$PWD" | cksum | awk '{print $1}')
    f="$_omb_theme_scm_async_dir/$key"
    [[ -r $f ]] && cat "$f"
  else
    scm_prompt_info 2>/dev/null
  fi
}

function _omb_theme_PROMPT_COMMAND() {
  local status=$?
  local TITLEBAR=""
  _omb_theme_scm_refresh
  case $TERM in
    xterm* | screen) TITLEBAR=$'\1\e]0;'$USER@${HOSTNAME%%.*}:${PWD/#$HOME/~}$'\e\\\2' ;;
  esac

  local SC=""
  ((status != 0)) && SC=" ${_BG_ERROR-}${_FG_WHITE} ✗ $status ${_RST}"

  local bpct
  bpct=$(battery_percentage 2>/dev/null)
  local BC=""
  if [[ -n "$bpct" && "$bpct" != "no" && "$bpct" != "-1" && "$bpct" != "100%" && "$bpct" != "0%" ]]; then
    BC=" ${_FG_TEAL_D}($bpct)${_RST}"
  fi

  PS1=$TITLEBAR
  PS1+="${_FG_TEAL_D}┌─${_FG_WHITE}[$(_user_info)]"
  PS1+=" ${_BG_TIME-}${_FG_WHITE}[\A]${_RST}"
  PS1+="$(__powerline_python_venv_prompt)"
  PS1+="$(__npm_env_prompt)"
  PS1+=" ${_FG_OLIVE_D}(\w)${_RST}"

  local scm_out=""
  ((_omb_theme_scm_is_repo)) && scm_out=$(_omb_theme_scm_prompt_info)
  if [[ -n "$scm_out" ]]; then
    PS1+=" ${_BG_SCM-}${_FG_WHITE}(${scm_out})${_RST}"
  fi

  PS1+="\n${_FG_TEAL_D}└─${_RST}$SC$BC"
  PS1+=" ${_FG_GREEN}$(get_symbol_user_info)${_FG_TEAL_D}${_FG_WHITE} "
}

SCM_THEME_PROMPT_DIRTY=" ✗"
SCM_THEME_PROMPT_CLEAN=" ✓"
SCM_THEME_PROMPT_PREFIX=""
SCM_THEME_PROMPT_SUFFIX=""

# ═══════════════════════════════════════════════════════════════
#  React to scheme changes at runtime
# ═══════════════════════════════════════════════════════════════
# Registered BEFORE the prompt builder: when the scheme changes, the very
# next prompt is already drawn with the new color family. Only runs when a
# source can actually change (kitty / KDE / GNOME) and when the scheme was
# not forced. In a plain SSH session it stays `ansi` and polls nothing.

_omb_theme_scheme_checked=0
_omb_theme_scheme_bg_pid=

function _omb_theme_scheme_cache_file {
  printf '%s/theme-scheme' "${OSH_CACHE_DIR:-$OSH/cache}"
}

function _omb_theme_scheme_watch {
  # A forced scheme never changes on its own
  case ${OSH_THEME_SCHEME:-auto} in
    dark | light | ansi) return 0 ;;
  esac
  _omb_theme_has_dynamic_source || return 0
  local interval=${OSH_THEME_SCHEME_INTERVAL:-3}
  ((interval > 0)) || return 0
  ((SECONDS - _omb_theme_scheme_checked < interval)) && return
  _omb_theme_scheme_checked=$SECONDS

  # Apply the cached scheme if it changed. No external command runs on the
  # prompt path (detection happens in the background below).
  local cache scheme
  cache=$(_omb_theme_scheme_cache_file)
  if [[ -r $cache ]]; then
    scheme=$(<"$cache")
    if [[ -n $scheme && $scheme != "${OSH_THEME_SCHEME_ACTIVE:-}" ]]; then
      _omb_theme_load_colors
    fi
  fi

  # Refresh the cache in the background; never blocks the prompt.
  if [[ -z $_omb_theme_scheme_bg_pid ]] || ! kill -0 "$_omb_theme_scheme_bg_pid" 2>/dev/null; then
    (
      local s
      s=$(_omb_theme_detect_scheme 2>/dev/null)
      if [[ -n $s ]]; then
        mkdir -p "${cache%/*}" 2>/dev/null
        printf '%s\n' "$s" >"$cache.tmp" && mv "$cache.tmp" "$cache"
      fi
    ) >/dev/null 2>&1 &
    _omb_theme_scheme_bg_pid=$!
  fi
}

_omb_util_add_prompt_command _omb_theme_scheme_watch
_omb_util_add_prompt_command _omb_theme_PROMPT_COMMAND

# Manual reload (used by `refreshcolor` and to apply a change immediately)
function _omb_theme_reload_colors {
  _omb_theme_scheme_checked=$SECONDS
  _omb_theme_load_colors
  _omb_theme_PROMPT_COMMAND
}
