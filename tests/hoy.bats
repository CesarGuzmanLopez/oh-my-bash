#!/usr/bin/env bats
# Tests de hoy.sh

@test "hoy fails fast without WEATHERAPI_KEY" {
  run env -u WEATHERAPI_KEY -u API_WHWATHERAPI_KEY bash "$BATS_TEST_DIRNAME/../hoy.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *WEATHERAPI_KEY* ]]
}
