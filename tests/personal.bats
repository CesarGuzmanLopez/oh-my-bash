#!/usr/bin/env bats
# Tests de las funciones personales

setup() {
  load 'helpers'
  load_personal
  cd "$BATS_TEST_TMPDIR"
}

@test "take creates and enters the directory" {
  take a/b > /dev/null
  [ -d "$BATS_TEST_TMPDIR/a/b" ]
  [ "$PWD" = "$BATS_TEST_TMPDIR/a/b" ]
}

@test "extract reports a missing file" {
  run extract does-not-exist.tar.gz
  [ "$status" -ne 0 ]
}

@test "extract rejects unsupported formats" {
  touch unknown.xyz
  run extract unknown.xyz
  [ "$status" -ne 0 ]
}
