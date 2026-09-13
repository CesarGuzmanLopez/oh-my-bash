#!/usr/bin/env bats
# Tests del arranque no bloqueante y del chequeo de conexión

setup() {
  load 'helpers'
  load_online
}

@test "_omb_util_bg ejecuta en segundo plano" {
  _omb_util_bg 1 2 bash -c 'printf done > "$OSH_CACHE_DIR/bg"'
  local i
  for ((i = 0; i < 60; i++)); do
    [[ -s $OSH_CACHE_DIR/bg ]] && break
    sleep 0.05
  done
  [ "$(cat "$OSH_CACHE_DIR/bg")" = done ]
}

@test "online: probe correcto escribe 1 y _omb_util_online devuelve true" {
  _omb_util_online_probe() { return 0; }
  OSH_ONLINE_RETRIES=1 _omb_util_check_online_bg
  local i
  for ((i = 0; i < 60; i++)); do
    [[ -s $OSH_CACHE_DIR/online ]] && break
    sleep 0.05
  done
  [ "$(cat "$OSH_CACHE_DIR/online")" = 1 ]
  run _omb_util_online
  [ "$status" -eq 0 ]
}

@test "online: probe fallido escribe 0 y _omb_util_online devuelve false" {
  _omb_util_online_probe() { return 1; }
  OSH_ONLINE_RETRIES=1 _omb_util_check_online_bg
  local i
  for ((i = 0; i < 60; i++)); do
    [[ -s $OSH_CACHE_DIR/online ]] && break
    sleep 0.05
  done
  [ "$(cat "$OSH_CACHE_DIR/online")" = 0 ]
  run _omb_util_online
  [ "$status" -ne 0 ]
}

@test "online: sin cache no está online" {
  rm -f "$OSH_CACHE_DIR/online"
  run _omb_util_online
  [ "$status" -ne 0 ]
}
