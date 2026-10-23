#!/usr/bin/env bats
# Tests de proyectos (cd a base/subcarpeta, open, completion)

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME/Documents/Proyectos/foo bar" "$HOME/Documents/Proyectos/baz"
  unset KITTY_WINDOW_ID KITTY_LISTEN_ON SSH_CONNECTION SSH_TTY SSH_CLIENT WAYLAND_DISPLAY DISPLAY
  _omb_util_command_exists() { command -v "$1" >/dev/null 2>&1; }
  # shellcheck source=/dev/null
  source "$BATS_TEST_DIRNAME/../custom/custom.aliases.sh"
  # espiar el dispatch sin abrir nada real
  _proyectos_open_tab() { echo "TAB:$1:$2"; }
  _proyectos_open_window() { echo "WINDOW:$1:$2"; }
  _proyectos_open_nvim() { echo "NVIM:$1"; }
  kitty() { echo "kitty-stub $*"; return 0; }
  cd "$BATS_TEST_TMPDIR" || return 1
}

@test "sin args entra a la base" {
  proyectos
  [ "$PWD" = "$HOME/Documents/Proyectos" ]
}

@test "con nombre entra a la subcarpeta" {
  proyectos baz
  [ "$PWD" = "$HOME/Documents/Proyectos/baz" ]
}

@test "acepta nombres con espacios" {
  proyectos foo bar
  [ "$PWD" = "$HOME/Documents/Proyectos/foo bar" ]
}

@test "nombre inexistente falla" {
  run proyectos no-existe
  [ "$status" -ne 0 ]
}

@test "open sin nombre falla con uso" {
  run proyectos open
  [ "$status" -eq 2 ]
}

@test "open inexistente falla" {
  run proyectos open no-existe
  [ "$status" -ne 0 ]
}

@test "open por ssh va a nvim" {
  export SSH_CONNECTION="1 2 3 4"
  export KITTY_WINDOW_ID=1
  run proyectos open baz
  [ "$status" -eq 0 ]
  [[ "$output" == "NVIM:$HOME/Documents/Proyectos/baz" ]]
}

@test "open en kitty abre pestana" {
  export KITTY_WINDOW_ID=1
  run proyectos open baz
  [ "$status" -eq 0 ]
  [[ "$output" == "TAB:$HOME/Documents/Proyectos/baz:baz" ]]
}

@test "open con display abre ventana" {
  export DISPLAY=":0"
  run proyectos open baz
  [ "$status" -eq 0 ]
  [[ "$output" == "WINDOW:$HOME/Documents/Proyectos/baz:baz" ]]
}

@test "open sin kitty ni display va a nvim" {
  _omb_util_command_exists() { [[ $1 != kitty ]] && command -v "$1" >/dev/null 2>&1; }
  run proyectos open baz
  [ "$status" -eq 0 ]
  [[ "$output" == "NVIM:$HOME/Documents/Proyectos/baz" ]]
}


@test "open en kitty usa la ruta absoluta de opencode" {
  export KITTY_WINDOW_ID=1
  # shellcheck source=/dev/null
  source "$BATS_TEST_DIRNAME/../custom/custom.aliases.sh"
  local calls="$BATS_TEST_TMPDIR/kitty-calls"
  kitty() {
    printf '%s\n' "$*" >> "$calls"
    case "$*" in
    *"@ launch"*) echo 42 ;;
    *) return 0 ;;
    esac
  }
  run proyectos open baz
  [ "$status" -eq 0 ]
  local want
  want=$(command -v opencode)
  grep -F -- "$want" "$calls"
}

@test "open con display escribe opencode absoluto en la session" {
  export DISPLAY=":0"
  # shellcheck source=/dev/null
  source "$BATS_TEST_DIRNAME/../custom/custom.aliases.sh"
  kitty() { echo "kitty-stub $*"; return 0; }
  run proyectos open baz
  [ "$status" -eq 0 ]
  local want
  want=$(command -v opencode)
  grep -F -- "$want" "$HOME/.cache/oh-my-bash-fork/proyectos/baz.session"
}


@test "completion lista los proyectos" {
  COMP_WORDS=(proyectos "")
  COMP_CWORD=1
  COMPREPLY=()
  _proyectos_completion
  [[ " ${COMPREPLY[*]} " == *" baz "* ]]
  [[ " ${COMPREPLY[*]} " == *"foo bar"* ]]
}

@test "completion filtra por prefijo" {
  COMP_WORDS=(proyectos "ba")
  COMP_CWORD=1
  COMPREPLY=()
  _proyectos_completion
  [ "${#COMPREPLY[@]}" -eq 1 ]
  [ "${COMPREPLY[0]}" = "baz" ]
}

@test "completion sugiere open como subcomando" {
  COMP_WORDS=(proyectos "o")
  COMP_CWORD=1
  COMPREPLY=()
  _proyectos_completion
  [[ " ${COMPREPLY[*]} " == *" open "* ]]
}

@test "completion tras open lista proyectos" {
  COMP_WORDS=(proyectos open "ba")
  COMP_CWORD=2
  COMPREPLY=()
  _proyectos_completion
  [ "${#COMPREPLY[@]}" -eq 1 ]
  [ "${COMPREPLY[0]}" = "baz" ]
}
