#!/usr/bin/env bats
# Tests de los bindings de fzf (Ctrl+F / Ctrl+T)

setup() {
  load 'helpers'
  command -v fzf > /dev/null 2>&1 || skip "fzf no instalado"
  _omb_util_command_exists() { command -v "$1" > /dev/null 2>&1; }
  # shellcheck source=/dev/null
  source "$BATS_TEST_DIRNAME/../custom/fzf-custom.sh"
}

@test "con ble.sh enlaza C-f y C-t con ble-bind (emacs y vi)" {
  BLE_VERSION=0.4
  ble-bind() { printf '%s\n' "$*" >> "$BATS_TEST_TMPDIR/ble"; }
  _omb_fzf_rebind
  run command cat "$BATS_TEST_TMPDIR/ble"
  [[ "$output" == *"-m emacs -x C-f custom_fzf_search"* ]]
  [[ "$output" == *"-m emacs -x C-t insertar_texto"* ]]
  [[ "$output" == *"-m vi_imap -x C-f custom_fzf_search"* ]]
  [[ "$output" == *"-m vi_imap -x C-t insertar_texto"* ]]
}

@test "insertar_texto inserta en la posición del cursor" {
  _fzf_comprun() { printf '%s' "archivo.txt"; }
  READLINE_LINE="cat "
  READLINE_POINT=4
  insertar_texto
  [[ "$READLINE_LINE" == *"archivo.txt"* ]]
  [ "$READLINE_POINT" -gt 4 ]
}

@test "insertar_texto no toca la línea si no hay selección" {
  _fzf_comprun() { return 0; }
  READLINE_LINE="cmd "
  READLINE_POINT=4
  insertar_texto
  [ "$READLINE_LINE" = "cmd " ]
}

@test "custom_fzf_search ya no usa --exit-0 (siempre despliega)" {
  run declare -f custom_fzf_search
  [[ "$output" != *"--exit-0"* ]]
}
