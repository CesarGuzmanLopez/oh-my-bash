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

@test "cachea los colores de kitty y los reutiliza" {
  load_theme
  export OSH_CACHE_DIR="$BATS_TEST_TMPDIR/cache"
  mkdir -p "$OSH_CACHE_DIR"
  _omb_theme_kitten_fetch() { printf 'background #0f0b16\ncolor1 #ff6b81\n'; }
  run _omb_theme_kitten_colors
  [[ "$output" == *"background #0f0b16"* ]]
  [ -s "$OSH_CACHE_DIR/kitty-colors" ]

  # Aunque el fetch falle, la caché se sigue sirviendo
  _omb_theme_kitten_fetch() { return 1; }
  run _omb_theme_kitten_colors
  [[ "$output" == *"background #0f0b16"* ]]
}

@test "KDE activo manda sobre kitty (cambio de tema KDE)" {
  load_theme
  _omb_theme_in_kitty() { return 0; }
  _omb_theme_kitten_colors() { printf 'background #0f0b16\n'; }
  _omb_theme_kde_active() { return 0; }
  _omb_theme_kde_scheme() { printf 'light\n'; }
  _omb_theme_load_colors
  [ "$OSH_THEME_SCHEME_ACTIVE" = light ]
  [[ "$_FG_WHITE" == *"30;1"* ]]
}
