# Helpers compartidos por los tests

# Carga el tema kitsune con stubs mínimos de oh-my-bash
load_theme() {
  _omb_module_require() { :; }
  _omb_util_command_exists() { command -v "$1" > /dev/null 2>&1; }
  _omb_util_add_prompt_command() { :; }
  battery_percentage() { :; }
  scm_prompt_info() { :; }
  # shellcheck source=/dev/null
  source "$BATS_TEST_DIRNAME/../themes/kitsune/kitsune.theme.sh"
}

# Carga las funciones personales aisladas
load_personal() {
  _omb_util_command_exists() { command -v "$1" > /dev/null 2>&1; }
  # shellcheck source=/dev/null
  source "$BATS_TEST_DIRNAME/../custom/personal.sh"
}

# Carga el helper de IA (custom/ai.sh) aislado.
# custom/ai.sh solo define `ai` si existe `aichat`, así que creamos un stub.
load_ai() {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  if [[ ! -x $BATS_TEST_TMPDIR/bin/aichat ]]; then
    printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$BATS_TEST_TMPDIR/bin/aichat"
    chmod +x "$BATS_TEST_TMPDIR/bin/aichat"
  fi
  PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  _omb_util_command_exists() { command -v "$1" > /dev/null 2>&1; }
  # shellcheck source=/dev/null
  source "$BATS_TEST_DIRNAME/../custom/ai.sh"
}

# Carga custom/online.sh sin lanzar el probe de arranque
load_online() {
  OSH_ONLINE_CHECK=0
  export OSH_CACHE_DIR="$BATS_TEST_TMPDIR/cache"
  mkdir -p "$OSH_CACHE_DIR"
  _omb_util_command_exists() { command -v "$1" > /dev/null 2>&1; }
  # shellcheck source=/dev/null
  source "$BATS_TEST_DIRNAME/../custom/online.sh"
}
