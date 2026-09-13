#!/usr/bin/env bats
# Tests del cargador perezoso de nvm

setup() {
  load 'helpers'
  export NVM_DIR="$BATS_TEST_TMPDIR/nvm"
  mkdir -p "$NVM_DIR/versions/node/v9.9.9/bin" "$NVM_DIR/alias"
  : > "$NVM_DIR/versions/node/v9.9.9/bin/node"
  chmod +x "$NVM_DIR/versions/node/v9.9.9/bin/node"
  printf '9\n' > "$NVM_DIR/alias/default"
  # shellcheck source=/dev/null
  source "$BATS_TEST_DIRNAME/../custom/nvm-lazy.sh"
}

@test "añade el bin de la versión activa al PATH" {
  [[ ":$PATH:" == *":$NVM_DIR/versions/node/v9.9.9/bin:"* ]]
}

@test "define nvm y load_nvm sin cargar nvm.sh" {
  [ "$(type -t nvm)" = function ]
  [ "$(type -t load_nvm)" = function ]
}

@test "OSH_LAZY_NVM=0 no define nada" {
  run bash -c '
    export NVM_DIR="'$NVM_DIR'"
    export OSH_LAZY_NVM=0
    source "'"$BATS_TEST_DIRNAME"'/../custom/nvm-lazy.sh"
    type -t nvm > /dev/null && echo DEFINED || echo NOT_DEFINED
  '
  [ "$output" = "NOT_DEFINED" ]
}
