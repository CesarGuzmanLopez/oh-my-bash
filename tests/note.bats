#!/usr/bin/env bats
# Tests de note.sh

@test "note.sh has a valid shebang on line 1" {
  local first
  IFS= read -r first < "$BATS_TEST_DIRNAME/../note.sh"
  [ "$first" = '#!/bin/bash' ]
}

@test "note.sh is executable" {
  [ -x "$BATS_TEST_DIRNAME/../note.sh" ]
}
