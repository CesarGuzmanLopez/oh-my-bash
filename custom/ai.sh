#! bash oh-my-bash.module
# ── IA en el shell (Groq vía aichat) ──
# Requiere `aichat` y GROQ_API_KEY (el .env del fork la exporta).
#
#   ai "descripción"      Genera un comando de shell (no lo ejecuta)
#   ai -x "descripción"   Genera y ejecuta (pide confirmación)
#   ai -e [comando]       Explica un comando (o el último)
#   ai -m "pregunta"      Chat normal con el modelo (sin contexto de shell)
#   ai --nota [texto]     Guarda/muestra una nota breve usada como contexto
#   ai <Tab>              Completa las banderas
#   C-x i                 Reemplaza el buffer por el comando generado
#
# Contexto (solo para generar/explicar, <= OSH_AI_CONTEXT_MAX chars):
#   c=<cwd> h=<últimos comandos·ok|x> f=<archivos> n=<nota>
# Cachea el contexto y las respuestas para no repetir trabajo/llamadas.
#
# Degradación elegante: si `aichat` no está instalado, `ai` no aparece.

if ! command -v aichat >/dev/null 2>&1; then
  return 0
fi

OSH_AI_MODEL=${OSH_AI_MODEL:-groq:openai/gpt-oss-20b}
OSH_AI_SYSTEM=${OSH_AI_SYSTEM:-'Eres un experto en bash en Linux. Devuelve UNICAMENTE un comando de shell valido en una sola linea, sin explicaciones ni bloques de codigo.'}
OSH_AI_EXPLAIN_SYSTEM=${OSH_AI_EXPLAIN_SYSTEM:-'Explica brevemente en español qué hace este comando.'}

OSH_AI_CONTEXT=${OSH_AI_CONTEXT:-1}
OSH_AI_CONTEXT_MAX=${OSH_AI_CONTEXT_MAX:-600}
OSH_AI_LS_MAX=${OSH_AI_LS_MAX:-20}
OSH_AI_HISTORY_N=${OSH_AI_HISTORY_N:-3}
OSH_AI_CONTEXT_TTL=${OSH_AI_CONTEXT_TTL:-60}
OSH_AI_RESPONSE_CACHE=${OSH_AI_RESPONSE_CACHE:-1}
OSH_AI_RESPONSE_TTL=${OSH_AI_RESPONSE_TTL:-60}
OSH_AI_SHOW_HIDDEN=${OSH_AI_SHOW_HIDDEN:-0}

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

function _osh_ai_cache_dir {
  local d=${OSH_CACHE_DIR:-${OSH:-$HOME}/cache}
  [[ -d $d ]] || command mkdir -p "$d" 2>/dev/null
  printf '%s' "$d"
}

function _osh_ai_notes_file {
  printf '%s/ai-notes' "$(_osh_ai_cache_dir)"
}

function _osh_ai_now {
  printf '%s' "${EPOCHSECONDS:-$(date +%s)}"
}

function _osh_ai_mtime {
  case $(uname) in
    Darwin) command stat -f '%m' "$1" 2>/dev/null ;;
    *) command stat -c '%Y' "$1" 2>/dev/null ;;
  esac
}

function _osh_ai_hash {
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$1" | sha256sum | command awk '{ print $1 }'
  elif command -v md5sum >/dev/null 2>&1; then
    printf '%s' "$1" | md5sum | command awk '{ print $1 }'
  else
    printf '%s' "$1" | cksum | command awk '{ print $1 }'
  fi
}

# gpt-oss razona en bloques <think>...</think>; los descartamos.
function _osh_ai_strip_think {
  command sed -e '/<think>/,/<\/think>/d' -e '/<\/think>/d'
}

# Enmascara secretos antes de enviarlos o cachearlos.
function _osh_ai_redact {
  command sed -E \
    -e 's/((KEY|TOKEN|SECRET|PASSWORD|PASSWD|AUTH|BEARER|COOKIE|API)[A-Za-z0-9_]*=)[^ ]*/\1***/gI' \
    -e 's/(Bearer )[A-Za-z0-9._-]+/\1***/gI' \
    -e 's/gsk_[A-Za-z0-9]+/gsk_***/g' \
    -e 's/ghp_[A-Za-z0-9]+/ghp_***/g' \
    -e 's/sk-[A-Za-z0-9_-]{10,}/sk-***/g' \
    -e 's/xox[abprs]-[A-Za-z0-9-]+/xox***/g'
}

# ── Rastreador de la sesión: últimos comandos + ok/x ──
_osh_ai_cmds=()
_osh_ai_oks=()
_osh_ai_last_histcmd=${HISTCMD:-0}

function _osh_ai_record_line {
  local status=$1 hc=$2 line=$3
  [[ -n $hc && $hc != "$_osh_ai_last_histcmd" ]] || return 0
  _osh_ai_last_histcmd=$hc
  [[ -n $line ]] || return 0
  line=${line#"${line%%[![:space:]]*}"}                                                     # quita espacios iniciales
  line=${line#*[[:space:]]}                                                                 # quita el número de historial
  line=${line#"${line%%[![:space:]]*}"}                                                     # quita espacios otra vez
  line=${line#[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9] } # quita fecha
  [[ -n $line && $line != ai && $line != ai\ * ]] || return 0

  _osh_ai_cmds+=("$line")
  if ((status != 0)); then
    _osh_ai_oks+=("x")
  else
    _osh_ai_oks+=("ok")
  fi

  local n=${#_osh_ai_cmds[@]}
  if ((n > OSH_AI_HISTORY_N)); then
    _osh_ai_cmds=("${_osh_ai_cmds[@]:$((n - OSH_AI_HISTORY_N))}")
    _osh_ai_oks=("${_osh_ai_oks[@]:$((n - OSH_AI_HISTORY_N))}")
  fi
}

function _osh_ai_record {
  local status=$?
  # HISTTIMEFORMAT= evita que `history` incluya la fecha (ahorra presupuesto)
  _osh_ai_record_line "$status" "${HISTCMD-}" "$(HISTTIMEFORMAT='' history 1 2>/dev/null)"
}

# ── Contexto: ls compacto (máx N, sin ocultos) ──
function _osh_ai_ls_context {
  local -a files=() out=()
  local f i=0
  if [[ $OSH_AI_SHOW_HIDDEN == 1 ]]; then
    while IFS= read -r f; do files+=("$f"); done < <(command ls -1AF 2>/dev/null)
  else
    while IFS= read -r f; do files+=("$f"); done < <(command ls -1F 2>/dev/null)
  fi
  for f in "${files[@]}"; do
    ((i >= OSH_AI_LS_MAX)) && break
    ((${#f} > 12)) && f="${f:0:11}…"
    out+=("$f")
    ((i++))
  done
  local IFS=,
  printf '%s' "${out[*]}"
}

function _osh_ai_hist_context {
  local n=${#_osh_ai_cmds[@]}
  local -a out=()
  local i start
  ((n > OSH_AI_HISTORY_N)) && start=$((n - OSH_AI_HISTORY_N)) || start=0
  for ((i = start; i < n; i++)); do
    local c=${_osh_ai_cmds[i]}
    ((${#c} > 40)) && c="${c:0:39}…"
    out+=("$c·${_osh_ai_oks[i]}")
  done
  local IFS='|'
  printf '%s' "${out[*]}"
}

# Bloque compacto respetando el límite duro de caracteres.
function _osh_ai_context {
  local max=$OSH_AI_CONTEXT_MAX
  local budget=$max
  local -a parts=()
  local piece hist files

  piece="c=${PWD/#$HOME/~}"
  parts+=("$piece")
  budget=$((budget - ${#piece} - 1))

  local notes
  notes=$(_osh_ai_notes_file)
  if [[ -s $notes ]]; then
    piece="n=$(command cat "$notes" 2>/dev/null)"
    if ((${#piece} <= budget)); then
      parts+=("$piece")
      budget=$((budget - ${#piece} - 1))
    fi
  fi

  hist=$(_osh_ai_hist_context)
  if [[ -n $hist ]]; then
    piece="h=$hist"
    if ((${#piece} > budget)); then
      if ((budget > 4)); then piece="h=${hist:0:budget-4}…"; else piece=''; fi
    fi
    if [[ -n $piece ]]; then
      parts+=("$piece")
      budget=$((budget - ${#piece} - 1))
    fi
  fi

  files=$(_osh_ai_ls_context)
  if [[ -n $files && $budget -gt 4 ]]; then
    parts+=("f=${files:0:budget-3}")
  fi

  local IFS=' '
  local ctx="${parts[*]}"
  ctx=$(_osh_ai_redact <<<"$ctx")
  ((${#ctx} > max)) && ctx="${ctx:0:max}"
  printf '%s' "$ctx"
}

# Contexto cacheado (se reutiliza si cwd/comandos no cambian y no expiró).
function _osh_ai_context_cached {
  [[ $OSH_AI_CONTEXT == 1 ]] || return 0
  local cache
  cache=$(_osh_ai_cache_dir)/ai-context
  local now hc cwd
  now=$(_osh_ai_now)
  hc=${HISTCMD:-0}
  cwd=${PWD/#$HOME/~}

  if [[ -s $cache ]]; then
    local c_hc c_ts c_cwd
    IFS='|' read -r c_cwd c_hc c_ts <"$cache"
    if [[ $c_cwd == "$cwd" && $c_hc == "$hc" ]] && ((now - c_ts < OSH_AI_CONTEXT_TTL)); then
      command sed '1d' "$cache"
      return 0
    fi
  fi

  local ctx
  ctx=$(_osh_ai_context)
  [[ -n $ctx ]] || return 0
  command mkdir -p "$(_osh_ai_cache_dir)" 2>/dev/null
  printf '%s|%s|%s\n%s\n' "$cwd" "$hc" "$now" "$ctx" >|"$cache" 2>/dev/null
  command chmod 600 "$cache" 2>/dev/null
  printf '%s' "$ctx"
}

# Ejecuta el modelo con contexto + cache de respuestas (generar/explicar).
function _osh_ai_run {
  local system=$1 user=$2
  _osh_ai_check || return 1

  local ctx=''
  [[ $OSH_AI_CONTEXT == 1 ]] && ctx=$(_osh_ai_context_cached)
  if [[ -n $ctx ]]; then
    user=$'[Contexto] '"$ctx"$'\n[Petición] '"$user"
  fi

  local key='' dir
  if [[ $OSH_AI_RESPONSE_CACHE == 1 ]]; then
    dir=$(_osh_ai_cache_dir)
    key=$dir/ai-resp-$(_osh_ai_hash "$OSH_AI_MODEL|$system|$user")
    if [[ -s $key ]]; then
      local mtime
      mtime=$(_osh_ai_mtime "$key")
      if [[ -n $mtime ]] && (($(_osh_ai_now) - mtime < OSH_AI_RESPONSE_TTL)); then
        command cat "$key"
        return 0
      fi
    fi
  fi

  local out
  out=$(aichat -c --no-stream -m "$OSH_AI_MODEL" --prompt "$system" "$user" 2>/dev/null |
    _osh_ai_strip_think)
  if [[ -n $key && -n $out ]]; then
    command mkdir -p "$dir" 2>/dev/null
    printf '%s\n' "$out" >|"$key" 2>/dev/null
    command chmod 600 "$key" 2>/dev/null
  fi
  printf '%s' "$out"
}

function _osh_ai_command {
  _osh_ai_run "$OSH_AI_SYSTEM" "$1"
}

function ai {
  case ${1-} in
    -h | --help)
      cat <<'EOF'
ai "descripción"      Genera un comando de shell (no lo ejecuta)
ai -x "descripción"   Genera y ejecuta (con confirmación)
ai -e [comando]       Explica un comando (o el último)
ai -m "pregunta"      Chat normal con el modelo (sin contexto)
ai --nota [texto]     Guarda/muestra una nota de contexto
ai <Tab>              Completa las banderas

Contexto (solo generar/explicar): OSH_AI_CONTEXT_MAX (600), OSH_AI_LS_MAX (20),
OSH_AI_HISTORY_N (3), OSH_AI_CONTEXT_TTL (60), OSH_AI_SHOW_HIDDEN (0).
Response cache: OSH_AI_RESPONSE_CACHE=1, OSH_AI_RESPONSE_TTL=60.
EOF
      return 0
      ;;
    --nota)
      shift
      local notes
      notes=$(_osh_ai_notes_file)
      if (($#)); then
        command mkdir -p "$(_osh_ai_cache_dir)" 2>/dev/null
        printf '%s' "$*" >|"$notes" 2>/dev/null
        command chmod 600 "$notes" 2>/dev/null
        echo "Nota guardada."
      elif [[ -s $notes ]]; then
        command cat "$notes"
      else
        echo "(sin nota)"
      fi
      ;;
    -e | --explain)
      shift
      local target=${*:-$(fc -ln -1)}
      _osh_ai_run "$OSH_AI_EXPLAIN_SYSTEM" "$target"
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
  READLINE_LINE=$cmd
  READLINE_POINT=${#cmd}
}

# Keybinding C-x i (ble.sh o readline)
if [[ -n ${BLE_VERSION-} ]]; then
  ble-bind -x 'C-x i' ai-insert
elif [[ -t 0 ]]; then
  bind -x '"\C-x i": ai-insert'
fi

# Registra el rastreador de comandos de la sesión
if [[ $(type -t _omb_util_add_prompt_command 2>/dev/null) == function ]]; then
  _omb_util_add_prompt_command _osh_ai_record
fi

# ── Completado de banderas: `ai <Tab>` ──
function _osh_ai_completion {
  local cur=${COMP_WORDS[COMP_CWORD]}
  if [[ -n $cur && $cur != -* ]]; then
    COMPREPLY=()
    return 0
  fi
  local opts='-x -e -m -h --nota --execute --explain --message --help'
  local IFS=$' \t\n'
  # shellcheck disable=SC2207  # división intencional de las banderas
  COMPREPLY=($(compgen -W "$opts" -- "$cur"))
}
complete -F _osh_ai_completion ai
