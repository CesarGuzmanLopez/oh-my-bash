#! bash oh-my-bash.module
# ── IA en el shell (Groq vía aichat) ──
# Requiere `aichat` y GROQ_API_KEY (el .env del fork la exporta).
#
#   ai "descripción"      Genera un comando de shell (no lo ejecuta)
#   ai -x "descripción"   Genera y ejecuta (pide confirmación)
#   ai -e [comando]       Explica un comando (o el último)
#   ai -m "pregunta"      Chat normal con el modelo
#   C-x i                 Reemplaza el buffer por el comando generado
#
# El modelo se puede cambiar con OSH_AI_MODEL (por defecto Groq gpt-oss-20b).

OSH_AI_MODEL=${OSH_AI_MODEL:-groq:openai/gpt-oss-20b}
OSH_AI_SYSTEM=${OSH_AI_SYSTEM:-'Eres un experto en bash en Linux. Devuelve UNICAMENTE un comando de shell valido en una sola linea, sin explicaciones ni bloques de codigo.'}

function _osh_ai_check {
  if ! _omb_util_command_exists aichat; then
    echo "ai: falta el binario 'aichat'." >&2
    return 1
  fi
  if [[ -z ${GROQ_API_KEY-} ]]; then
    echo "ai: falta GROQ_API_KEY (defínela en ~/oh-my-bash-fork/.env)." >&2
    return 1
  fi
}

# gpt-oss razona en bloques <think>...</think>; los descartamos de la salida.
function _osh_ai_strip_think {
  sed -e '/<think>/,/<\/think>/d' -e '/<\/think>/d'
}

# Genera SOLO el comando (aichat -c extrae el bloque de código y descarta el
# razonamiento del modelo).
function _osh_ai_command {
  _osh_ai_check || return 1
  aichat -c --no-stream -m "$OSH_AI_MODEL" --prompt "$OSH_AI_SYSTEM" "$1" 2>/dev/null |
    _osh_ai_strip_think
}

function ai {
  case ${1-} in
    -h | --help)
      cat <<'EOF'
ai "descripción"      Genera un comando de shell (no lo ejecuta)
ai -x "descripción"   Genera y ejecuta (con confirmación)
ai -e [comando]       Explica un comando (o el último)
ai -m "pregunta"      Chat normal con el modelo
EOF
      return 0
      ;;
    -e | --explain)
      _osh_ai_check || return 1
      shift
      local target=${*:-$(fc -ln -1)}
      aichat --no-stream -m "$OSH_AI_MODEL" \
        --prompt 'Explica brevemente en español qué hace este comando.' "$target" |
        _osh_ai_strip_think
      ;;
    -m | --message)
      _osh_ai_check || return 1
      shift
      aichat --no-stream -m "$OSH_AI_MODEL" "$*" | _osh_ai_strip_think
      ;;
    -x | --execute)
      shift
      local cmd answer
      cmd=$(_osh_ai_command "$*") || return 1
      [[ -n $cmd ]] || {
        echo "ai: sin sugerencia." >&2
        return 1
      }
      printf 'Propuesta: %s\n' "$cmd"
      read -r -p '¿Ejecutar? [y/N] ' answer
      [[ $answer == [yY]* ]] && eval -- "$cmd"
      ;;
    *)
      _osh_ai_command "$*"
      ;;
  esac
}

# Widget: reemplaza el buffer de edición por el comando generado.
function ai-insert {
  local desc=${READLINE_LINE-} cmd
  [[ -n $desc ]] || return 0
  cmd=$(_osh_ai_command "$desc") || return 1
  cmd=${cmd%$'\n'}
  if [[ -n ${BLE_VERSION-} ]]; then
    ble-edit/content/reset-and-check-dirty "$cmd"
  else
    READLINE_LINE=$cmd
    READLINE_POINT=${#cmd}
  fi
}

# Keybinding C-x i (ble.sh o readline)
if [[ -n ${BLE_VERSION-} ]]; then
  ble-bind -x 'C-x i' ai-insert
elif [[ -t 0 ]]; then
  bind -x '"\C-x i": ai-insert'
fi
