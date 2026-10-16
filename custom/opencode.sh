#! bash oh-my-bash.module
# ── opencode-web: sirve opencode en background con screen ──
# Uso:
#   opencode-web [puerto] [hostname]
#   opencode-web              → 0.0.0.0:4096
#   opencode-web 8080         → 0.0.0.0:8080
#   OSH_OPENCODE_PORT=5000 opencode-web
#
# Equivale a:
#   screen -S Opencode-web -L -Logfile /tmp/opencode-web.log -dm \
#     opencode serve --hostname 0.0.0.0 --port 4096
#   sleep 3; cat /tmp/opencode-web.log; screen -ls
#
# Comportamiento de display (SSH vs escritorio):
#   - Busca tu sesión gráfica (Wayland/X11, cualquier asiento, pantalla o
#     nombre de socket: wayland-0/wayland-1, :0/:1…).
#   - Si la encuentra: hereda el display → Playwright con ventana (headed).
#   - Si está bloqueada y OSH_OPENCODE_AUTO_UNLOCK=1 (default): te pide tu
#     contraseña por polkit y la desbloquea. La contraseña NO se guarda.
#   - Si NO hay sesión gráfica: arranca igual pero en HEADLESS.
#
# Helpers:
#   opencode-weblog    → cat del log
#   opencode-webstop   → mata la sesión screen
#   opencode-webunlock → desbloquea la sesión gráfica a mano
#
# Knobs:
#   OSH_OPENCODE_AUTO_UNLOCK=0 → no intentar desbloquear (solo avisa)

OSH_OPENCODE_SESSION=${OSH_OPENCODE_SESSION:-Opencode-web}
OSH_OPENCODE_LOG=${OSH_OPENCODE_LOG:-/tmp/opencode-web.log}
OSH_OPENCODE_PORT=${OSH_OPENCODE_PORT:-4096}
OSH_OPENCODE_HOST=${OSH_OPENCODE_HOST:-0.0.0.0}
OSH_OPENCODE_AUTO_UNLOCK=${OSH_OPENCODE_AUTO_UNLOCK:-1}

# Busca una sesión gráfica del usuario (cualquier seat, display o nombre).
# Imprime el id y devuelve 0; si no hay ninguna, devuelve 1.
# Prefiere la activa; si ninguna está activa, devuelve la primera encontrada.
function _osh_opencode_graphical_session {
  local ids sid line type class state active
  local fallback=
  ids=$(loginctl list-sessions --no-legend 2>/dev/null | command awk '{ print $1 }')
  [[ -n $ids ]] || return 1
  for sid in $ids; do
    type=
    class=
    state=
    active=
    while IFS= read -r line; do
      case $line in
      Type=*) type=${line#Type=} ;;
      Class=*) class=${line#Class=} ;;
      State=*) state=${line#State=} ;;
      Active=*) active=${line#Active=} ;;
      esac
    done < <(loginctl show-session "$sid" -p Type -p Class -p State -p Active 2>/dev/null)
    case $type in
    wayland | x11 | mir) ;;
    *) continue ;;
    esac
    [[ $class == user ]] || continue
    if [[ $state == active && $active == yes ]]; then
      printf '%s\n' "$sid"
      return 0
    fi
    [[ -n $fallback ]] || fallback=$sid
  done
  [[ -n $fallback ]] || return 1
  printf '%s\n' "$fallback"
}

# Reengancha el display Wayland/X11 de tu sesión gráfica cuando vienes por SSH.
# Por SSH no existen WAYLAND_DISPLAY/DISPLAY y Playwright cae a headless;
# el user manager de systemd sí los conserva (los alimenta SDDM/KDE), así
# que los reimportamos y validamos los sockets (cubren otro nombre/pantalla).
# Si ya hay display válido (terminal en el escritorio), solo lo valida.
# Sin sesión gráfica: limpia las vars, marca HEADED=0 y devuelve 1 para que
# el llamador arranque en HEADLESS en vez de fallar.
function _osh_opencode_desktop_env {
  local runtime
  runtime=/run/user/$(id -u)
  export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-$runtime}
  export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}

  # 1) Importa del user manager de systemd (KDE/SDDM lo alimentan).
  if command -v systemctl >/dev/null 2>&1; then
    local line k v
    while IFS= read -r line; do
      k=${line%%=*}
      v=${line#*=}
      case $k in
      WAYLAND_DISPLAY | DISPLAY | XAUTHORITY | ICEAUTHORITY | SESSION_MANAGER | \
        XDG_SESSION_TYPE | XDG_CURRENT_DESKTOP | DESKTOP_SESSION | XDG_SESSION_DESKTOP | \
        KDE_SESSION_VERSION | KDE_FULL_SESSION | QT_QPA_PLATFORM | QT_WAYLAND_RECONNECT)
        export "$k=$v"
        ;;
      esac
    done < <(systemctl --user show-environment 2>/dev/null)
  fi

  # 2) Valida/corrige Wayland (cubre otro nombre: wayland-0, wayland-1…).
  if [[ -n ${WAYLAND_DISPLAY-} && ! -S $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY ]]; then
    unset WAYLAND_DISPLAY
  fi
  if [[ -z ${WAYLAND_DISPLAY-} ]]; then
    local sock
    for sock in "$XDG_RUNTIME_DIR"/wayland-*; do
      [[ -S $sock ]] || continue
      [[ $sock == *.lock ]] && continue
      WAYLAND_DISPLAY=$(basename "$sock")
      export WAYLAND_DISPLAY
      break
    done
  fi

  # 3) Valida/corrige X11 (cubre otra pantalla: :0, :1…).
  if [[ -n ${DISPLAY-} ]]; then
    local dnum
    dnum=${DISPLAY##*:}
    dnum=${dnum%%.*}
    [[ -S /tmp/.X11-unix/X$dnum ]] || unset DISPLAY
  fi
  if [[ -z ${DISPLAY-} ]]; then
    local xd
    for xd in /tmp/.X11-unix/X*; do
      [[ -S $xd ]] || continue
      DISPLAY=:${xd#/tmp/.X11-unix/X}
      export DISPLAY
      break
    done
  fi

  # 4) xauth (rota de nombre en cada login: xauth_XXXXXX).
  if [[ -z ${XAUTHORITY-} || ! -f $XAUTHORITY ]]; then
    unset XAUTHORITY
    local xa
    for xa in "$XDG_RUNTIME_DIR"/xauth_*; do
      [[ -f $xa ]] || continue
      XAUTHORITY=$xa
      export XAUTHORITY
      break
    done
  fi

  # 5) Veredicto.
  if [[ -z ${WAYLAND_DISPLAY-} && -z ${DISPLAY-} ]]; then
    unset WAYLAND_DISPLAY DISPLAY
    export OSH_OPENCODE_HEADED=0
    echo "opencode-web: sin sesión gráfica → arranco en HEADLESS." >&2
    return 1
  fi
  export OSH_OPENCODE_HEADED=1
  return 0
}

# Desbloquea la sesión gráfica (te pide TU contraseña por polkit, no se guarda).
# Uso: opencode-webunlock [id-sesión]
function opencode-webunlock {
  local sid=${1:-}
  if [[ -z $sid ]]; then
    sid=$(_osh_opencode_graphical_session) || {
      echo "opencode-webunlock: no hay sesión gráfica que desbloquear." >&2
      return 1
    }
  fi
  local locked
  locked=$(loginctl show-session "$sid" -p LockedHint 2>/dev/null)
  if [[ ${locked#LockedHint=} != yes ]]; then
    echo "opencode-webunlock: sesión $sid ya desbloqueada."
    return 0
  fi
  echo "opencode-webunlock: sesión $sid bloqueada → pido desbloqueo."
  echo "opencode-webunlock: polkit te pedirá TU contraseña (no se guarda en ningún lado)."
  if loginctl unlock-session "$sid" 2>/dev/null; then
    :
  elif command -v pkttyagent >/dev/null 2>&1; then
    echo "opencode-webunlock: sin agente polkit en esta terminal, uso pkttyagent…"
    pkttyagent -p $$ >/dev/null 2>&1 &
    local agent
    agent=$!
    loginctl unlock-session "$sid"
    local st
    st=$?
    kill "$agent" 2>/dev/null
    if ((st != 0)); then
      echo "opencode-webunlock: no se pudo desbloquear (¿contraseña incorrecta?)." >&2
      return $st
    fi
  else
    echo "opencode-webunlock: loginctl necesita agente polkit y no hay pkttyagent." >&2
    return 1
  fi
  local i
  i=0
  while ((i < 30)); do
    locked=$(loginctl show-session "$sid" -p LockedHint 2>/dev/null)
    if [[ ${locked#LockedHint=} != yes ]]; then
      echo "opencode-webunlock: sesión $sid desbloqueada."
      return 0
    fi
    sleep 2
    ((i++))
  done
  echo "opencode-webunlock: sigue bloqueada tras 60s." >&2
  return 1
}

function opencode-web {
  local port=${1:-$OSH_OPENCODE_PORT}
  local host=${2:-$OSH_OPENCODE_HOST}
  local session=${OSH_OPENCODE_SESSION:-Opencode-web}
  local log=${OSH_OPENCODE_LOG:-/tmp/opencode-web.log}

  if ! command -v opencode >/dev/null 2>&1; then
    echo "opencode-web: no encuentro 'opencode' en el PATH." >&2
    return 127
  fi
  if ! command -v screen >/dev/null 2>&1; then
    echo "opencode-web: falta 'screen' (sudo pacman -S screen)." >&2
    return 127
  fi

  # Hereda el escritorio (no-op en local, rescate por SSH).
  # screen hereda el entorno al crear la sesión, así el serve ve el display.
  # Sin sesión gráfica no falla: marca HEADED=0 y sigue en headless.
  _osh_opencode_desktop_env || true

  # Si hay display pero la sesión está bloqueada, intenta desbloquearla
  # (pide tu contraseña por polkit). OSH_OPENCODE_AUTO_UNLOCK=0 lo desactiva.
  if [[ ${OSH_OPENCODE_HEADED:-0} == 1 && ${OSH_OPENCODE_AUTO_UNLOCK:-1} != 0 ]]; then
    local sid locked
    sid=$(_osh_opencode_graphical_session 2>/dev/null) || sid=
    if [[ -n $sid ]]; then
      locked=$(loginctl show-session "$sid" -p LockedHint 2>/dev/null)
      if [[ ${locked#LockedHint=} == yes ]]; then
        opencode-webunlock "$sid" || {
          echo "opencode-web: sin desbloqueo → Playwright puede salir headless." >&2
        }
      fi
    fi
  fi

  # Purga sockets muertos: un screen colgado (p.ej. tras corte abrupto)
  # aparece en `screen -ls` pero ya no sirve; sin esto el chequeo de
  # "ya existe" da falso positivo y webstop falla.
  screen -wipe >/dev/null 2>&1 || true

  if screen -ls 2>/dev/null | command grep -q "[.]$session[[:space:]]"; then
    echo "opencode-web: la sesión '$session' ya existe, no la duplico."
    echo "opencode-web: modo actual: $([[ ${OSH_OPENCODE_HEADED:-0} == 1 ]] && echo HEADED || echo HEADLESS) (WAYLAND_DISPLAY=${WAYLAND_DISPLAY-<vacío>} DISPLAY=${DISPLAY-<vacío>})"
    echo "opencode-web: si ese screen se creó sin display y Playwright sale headless,"
    echo "opencode-web: haz 'opencode-webstop' y relanza 'opencode-web' para heredar el escritorio."
  else
    echo "opencode-web: modo $([[ ${OSH_OPENCODE_HEADED:-0} == 1 ]] && echo HEADED || echo HEADLESS) (WAYLAND_DISPLAY=${WAYLAND_DISPLAY-<vacío>} DISPLAY=${DISPLAY-<vacío>})"
    # Log fresco en cada arranque: borra el anterior para no mezclar sesiones.
    rm -f -- "$log"
    screen -S "$session" -L -Logfile "$log" -dm \
      opencode serve --hostname "$host" --port "$port" || return
    sleep 3
  fi

  if [[ -s $log ]]; then
    command cat -- "$log"
  else
    echo "opencode-web: aún no hay log en $log." >&2
  fi
  screen -ls
}

function opencode-weblog {
  local log=${OSH_OPENCODE_LOG:-/tmp/opencode-web.log}
  [[ -f $log ]] || {
    echo "opencode-weblog: no existe $log" >&2
    return 1
  }
  command cat -- "$log"
}

function opencode-webstop {
  local session=${OSH_OPENCODE_SESSION:-Opencode-web}
  screen -S "$session" -X quit || {
    echo "opencode-webstop: no existe la sesión '$session'." >&2
    return 1
  }
  echo "opencode-webstop: sesión '$session' cerrada."
}

# Atajo rápido para abrir opencode
alias ocweb='opencode-web'

# ── opencode-tui: TUI con navegador REAL (headed), mismo rescate de display que opencode-web ──
# Uso: opencode-tui [--standalone extra args...]
# Usa --standalone para que los MCP/Chromium sean hijos de esta shell y hereden
# WAYLAND_DISPLAY/DISPLAY (el TUI normal usa el background service, que suele
# estar headless si se arrancó por SSH).
function opencode-tui {
  # Rescate de display (igual que opencode-web: no-op en local, rescate por SSH).
  _osh_opencode_desktop_env || true
  if [[ ${OSH_OPENCODE_HEADED:-0} == 1 && ${OSH_OPENCODE_AUTO_UNLOCK:-1} != 0 ]]; then
    local sid locked
    sid=$(_osh_opencode_graphical_session 2>/dev/null) || sid=
    if [[ -n $sid ]]; then
      locked=$(loginctl show-session "$sid" -p LockedHint 2>/dev/null)
      if [[ ${locked#LockedHint=} == yes ]]; then
        opencode-webunlock "$sid" || {
          echo "opencode-tui: sin desbloqueo → Playwright puede salir headless." >&2
        }
      fi
    fi
  fi
  echo "opencode-tui: modo $([[ ${OSH_OPENCODE_HEADED:-0} == 1 ]] && echo HEADED || echo HEADLESS) (WAYLAND_DISPLAY=${WAYLAND_DISPLAY-<vacío>} DISPLAY=${DISPLAY-<vacío>})"
  if [[ ${OSH_OPENCODE_HEADED:-0} != 1 ]]; then
    echo "opencode-tui: sin sesión gráfica → Chromium saldrá headless." >&2
  fi
  # Forward de args idéntico al opencode real; --standalone solo donde crea
  # server (TUI interactivo, run, mini). Gestión (serve/service/mcp/auth/…)
  # pasa tal cual, sin inventar flags. Dir por defecto: facebook-agent.
  local default_dir=/home/cesar/facebook-agent
  if [[ $# -gt 0 ]]; then
    case $1 in
    serve | service | mcp | auth | plugin | models | stats | session | pair | reload | upgrade | update | uninstall | api | acp | debug)
      if [[ $1 == serve && $# -eq 1 ]]; then set -- "$@" --hostname 0.0.0.0 --port "${OSH_OPENCODE_PORT:-4096}"; fi
      exec opencode "$@"
      ;;
    run | mini)
      exec opencode "$1" --standalone "${@:2}"
      ;;
    -*)
      # flags del TUI interactivo: opencode --standalone [flags] [dir]
      if [[ -n ${OSH_OPENCODE_TUI_DIR-} ]]; then cd "${OSH_OPENCODE_TUI_DIR}" || return; else cd "$default_dir" || return; fi
      exec opencode --standalone "$@"
      ;;
    *)
      if [[ -d $1 ]]; then
        cd "$1" || return
        shift
        exec opencode --standalone "$@"
      else
        if [[ -n ${OSH_OPENCODE_TUI_DIR-} ]]; then cd "${OSH_OPENCODE_TUI_DIR}" || return; else cd "$default_dir" || return; fi
        exec opencode --standalone "$@"
      fi
      ;;
    esac
  else
    if [[ -n ${OSH_OPENCODE_TUI_DIR-} ]]; then cd "${OSH_OPENCODE_TUI_DIR}" || return; else cd "$default_dir" || return; fi
    exec opencode --standalone "$@"
  fi
}
