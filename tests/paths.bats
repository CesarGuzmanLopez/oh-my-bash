#!/usr/bin/env bats
# Tests del PATH de herramientas (custom/00-tool-paths.sh)

@test "añade ~/.fzf/bin al PATH cuando existe" {
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME/.fzf/bin"
  run bash -c '
    export HOME="'"$HOME"'"
    export PATH="/usr/bin:/bin"
    source "'"$BATS_TEST_DIRNAME"'/../custom/00-tool-paths.sh"
    case ":$PATH:" in
      *":$HOME/.fzf/bin:"*) echo WITH ;;
      *) echo MISSING ;;
    esac
  '
  [ "$output" = "WITH" ]
}

@test "no duplica ~/.fzf/bin si ya está en el PATH" {
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME/.fzf/bin"
  run bash -c '
    export HOME="'"$HOME"'"
    export PATH="$HOME/.fzf/bin:/usr/bin:/bin"
    source "'"$BATS_TEST_DIRNAME"'/../custom/00-tool-paths.sh"
    count=0
    IFS=:
    for d in $PATH; do [[ $d == "$HOME/.fzf/bin" ]] && ((count++)); done
    echo "$count"
  '
  [ "$output" = "1" ]
}
