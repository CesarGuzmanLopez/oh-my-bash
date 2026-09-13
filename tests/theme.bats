#!/usr/bin/env bats
# Tests del tema kitsune (detección de esquema y paleta)

setup() {
  load 'helpers'
  unset KITTY_WINDOW_ID SSH_CLIENT SSH_CONNECTION SSH_TTY COLORFGBG
  unset KDE_FULL_SESSION KDE_SESSION_VERSION XDG_CURRENT_DESKTOP DESKTOP_SESSION
  unset DISPLAY WAYLAND_DISPLAY
}

@test "explicit override is honored" {
  load_theme
  OSH_THEME_SCHEME=dark _omb_theme_load_colors
  [ "$OSH_THEME_SCHEME_ACTIVE" = dark ]
  OSH_THEME_SCHEME=light _omb_theme_load_colors
  [ "$OSH_THEME_SCHEME_ACTIVE" = light ]
  OSH_THEME_SCHEME=ansi _omb_theme_load_colors
  [ "$OSH_THEME_SCHEME_ACTIVE" = ansi ]
}

@test "ansi mode has no RGB background blocks" {
  load_theme
  OSH_THEME_SCHEME=ansi _omb_theme_load_colors
  [ -z "$_BG_TIME" ]
  [ -z "$_BG_ERROR" ]
  [ -z "$_BG_SCM" ]
}

@test "dark and light use different foreground families" {
  load_theme
  OSH_THEME_SCHEME=dark _omb_theme_load_colors
  local dark_fg=$_FG_WHITE
  OSH_THEME_SCHEME=light _omb_theme_load_colors
  [ "$dark_fg" != "$_FG_WHITE" ]
}

@test "bat theme follows the scheme" {
  load_theme
  OSH_THEME_SCHEME=light _omb_theme_load_colors
  [ "$BAT_THEME" = "Monokai Extended Light" ]
  OSH_THEME_SCHEME=dark _omb_theme_load_colors
  [ "$BAT_THEME" = "Monokai Extended" ]
}

@test "kde is not considered active without a session" {
  load_theme
  run _omb_theme_kde_active
  [ "$status" -ne 0 ]
}

@test "scheme derivado del fondo de kitty" {
  load_theme
  _omb_theme_in_kitty() { return 0; }
  _omb_theme_kitten_colors() { printf 'background #0f0b16\ncolor1 #ff6b81\n'; }
  _omb_theme_load_colors
  [ "$OSH_THEME_SCHEME_ACTIVE" = dark ]
}

@test "override explícito gana al fondo de kitty" {
  load_theme
  _omb_theme_in_kitty() { return 0; }
  _omb_theme_kitten_colors() { printf 'background #0f0b16\ncolor1 #ff6b81\n'; }
  OSH_THEME_SCHEME=light _omb_theme_load_colors
  [ "$OSH_THEME_SCHEME_ACTIVE" = light ]
  [[ "$_FG_WHITE" == *"30;1"* ]]
}

@test "kitty manda sobre KDE (el prompt sigue al terminal)" {
  load_theme
  _omb_theme_in_kitty() { return 0; }
  _omb_theme_kitten_colors() { printf 'background #0f0b16\n'; }
  _omb_theme_kde_active() { return 0; }
  _omb_theme_kde_scheme() { printf 'light\n'; }
  _omb_theme_load_colors
  [ "$OSH_THEME_SCHEME_ACTIVE" = dark ]
}

@test "el watcher aplica un cambio de color de kitty" {
  load_theme
  export OSH_CACHE_DIR="$BATS_TEST_TMPDIR/cache"
  mkdir -p "$OSH_CACHE_DIR"
  _omb_theme_in_kitty() { return 0; }
  _omb_theme_kitten_fetch() { printf 'background %s\n' "$KITTY_BG"; }

  KITTY_BG='#0f0b16'
  _omb_theme_load_colors
  [ "$OSH_THEME_SCHEME_ACTIVE" = dark ]

  # Cambia kitty a claro y el watcher debe detectarlo
  KITTY_BG='#ffffff'
  _omb_theme_scheme_checked=$((SECONDS - 10))
  _omb_theme_scheme_watch
  sleep 0.5
  _omb_theme_scheme_checked=$((SECONDS - 10))
  _omb_theme_scheme_watch
  [ "$OSH_THEME_SCHEME_ACTIVE" = light ]
}
