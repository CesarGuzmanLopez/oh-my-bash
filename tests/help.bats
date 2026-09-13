#!/usr/bin/env bats
# Tests de la ayuda rápida (helpmeb)

setup() {
  load 'helpers'
  unset BLE_VERSION
  # shellcheck source=/dev/null
  source "$BATS_TEST_DIRNAME/../custom/help.sh"
}

@test "helpmeb imprime las secciones principales" {
  run helpmeb
  [ "$status" -eq 0 ]
  [[ "$output" == *"ATAJOS DE TECLADO"* ]]
  [[ "$output" == *"FUNCIONES ÚTILES"* ]]
  [[ "$output" == *"EJEMPLOS"* ]]
}

@test "helpmeb atajos y funciones muestran su sección" {
  run helpmeb atajos
  [[ "$output" == *"Ctrl+F"* ]]
  run helpmeb funciones
  [[ "$output" == *"take DIR"* ]]
}

@test "helpmeb sección desconocida devuelve 2" {
  run helpmeb nope
  [ "$status" -eq 2 ]
}

@test "helpmeb ia solo muestra si aichat existe" {
  run helpmeb ia
  if command -v aichat > /dev/null 2>&1; then
    [[ "$output" == *"IA (Groq"* ]]
  else
    [ -z "$output" ]
  fi
}
