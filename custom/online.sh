#! bash oh-my-bash.module
# ── Arranque no bloqueante / conectividad ──
# Utilidades para que nada de red retrase el prompt. El chequeo de conexión
# corre en segundo plano (timeout + 3 reintentos) y guarda el resultado en
# $OSH_CACHE_DIR/online.
#
#   _omb_util_bg RETRIES TIMEOUT cmd...   ejecuta en background con reintentos
#   _omb_util_online                      true si el último chequeo fue "online"
#
# Desactiva el chequeo con OSH_ONLINE_CHECK=0.

# Ejecuta un comando en segundo plano con timeout y hasta N reintentos.
# El subshell anidado evita el aviso de job-control ([1] pid / "Hecho").
function _omb_util_bg {
  local retries=${1:-3} seconds=${2:-3}
  shift 2
  ( (
    local i
    for ((i = 0; i < retries; i++)); do
      if command -v timeout >/dev/null 2>&1; then
        timeout "$seconds" "$@" && exit 0
      else
        "$@" && exit 0
      fi
      ((i + 1 < retries)) && sleep "$((i + 1))"
    done
    exit 1
  ) >/dev/null 2>&1 &)
}

# Prueba rápida de conectividad: TCP (bash /dev/tcp) y DNS como respaldo.
function _omb_util_online_probe {
  (exec 3<>/dev/tcp/1.1.1.1/443) 2>/dev/null && return 0
  if command -v getent >/dev/null 2>&1; then
    getent hosts api.groq.com >/dev/null 2>&1 && return 0
  fi
  return 1
}

# Chequeo en segundo plano; nunca bloquea el arranque.
function _omb_util_check_online_bg {
  local cache=${OSH_CACHE_DIR:-$OSH/cache}
  local retries=${OSH_ONLINE_RETRIES:-3}
  command mkdir -p "$cache" 2>/dev/null
  ( (
    local i
    for ((i = 0; i < retries; i++)); do
      if _omb_util_online_probe; then
        printf '1\n' >|"$cache/online"
        exit 0
      fi
      ((i + 1 < retries)) && sleep "$((i + 1))"
    done
    printf '0\n' >|"$cache/online"
    exit 0
  ) >/dev/null 2>&1 &)
}

# Estado cacheado (1 = online).
function _omb_util_online {
  local f=${OSH_CACHE_DIR:-$OSH/cache}/online
  [[ -r $f && $(<"$f") == 1 ]]
}

[[ ${OSH_ONLINE_CHECK:-1} == 1 ]] && _omb_util_check_online_bg
return 0
