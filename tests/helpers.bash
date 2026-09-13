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
