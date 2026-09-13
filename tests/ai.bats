#!/usr/bin/env bats
# Tests del helper de IA (Groq vía aichat)

setup() {
  load 'helpers'
  load_ai
}

@test "sin aichat no define ai y no da error" {
  run bash -c '
    _omb_util_command_exists() { command -v "$1" > /dev/null 2>&1; }
    PATH=/nonexistent
    source "'"$BATS_TEST_DIRNAME"'/../custom/ai.sh"
    type -t ai > /dev/null && echo DEFINED || echo NOT_DEFINED
  '
  [ "$status" -eq 0 ]
  [ "$output" = "NOT_DEFINED" ]
}

@test "con aichat pero sin GROQ_API_KEY avisa" {
  unset GROQ_API_KEY
  run ai "algo"
  [ "$status" -ne 0 ]
  [[ "$output" == *"GROQ_API_KEY"* ]]
}

@test "genera un comando con aichat (stub)" {
  export GROQ_API_KEY=dummy
  cat > "$BATS_TEST_TMPDIR/bin/aichat" <<'EOF'
#!/usr/bin/env bash
printf 'df -h\n'
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/aichat"
  run _osh_ai_command "uso de disco"
  [ "$status" -eq 0 ]
  [ "$output" = "df -h" ]
}

@test "_osh_ai_strip_think elimina el bloque de razonamiento" {
  run _osh_ai_strip_think <<< $'<think>\nrazonando\n</think>\n\ndf -h'
  [[ "$output" == *"df -h"* ]]
  [[ "$output" != *"<think>"* ]]
}

@test "ai --help muestra la ayuda" {
  run ai --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"ai -x"* ]]
}

@test "ai-insert no hace nada con el buffer vacío" {
  READLINE_LINE=""
  run ai-insert
  [ "$status" -eq 0 ]
}

@test "ai <Tab> ofrece las banderas" {
  COMP_WORDS=(ai -)
  COMP_CWORD=1
  _osh_ai_completion
  [[ " ${COMPREPLY[*]} " == *" -x "* ]]
  [[ " ${COMPREPLY[*]} " == *" --execute "* ]]
}

@test "ai --e<Tab> filtra las banderas" {
  COMP_WORDS=(ai --e)
  COMP_CWORD=1
  _osh_ai_completion
  [[ " ${COMPREPLY[*]} " == *" --execute "* ]]
  [[ " ${COMPREPLY[*]} " != *" -m "* ]]
}

@test "ai <descripción><Tab> no ofrece banderas" {
  COMP_WORDS=(ai algo)
  COMP_CWORD=1
  _osh_ai_completion
  [ "${#COMPREPLY[@]}" -eq 0 ]
}

@test "rastreador: registra ok/x, excluye ai y el historial viejo" {
  _osh_ai_last_histcmd=0
  _osh_ai_record_line 0 1 "   1  ls -la"
  _osh_ai_record_line 1 2 "   2  npm test"
  _osh_ai_record_line 0 3 "   3  ai algo"
  [ "${#_osh_ai_cmds[@]}" -eq 2 ]
  [ "${_osh_ai_cmds[*]}" = "ls -la npm test" ]
  [ "${_osh_ai_oks[*]}" = "ok x" ]
}

@test "rastreador: conserva solo los últimos N" {
  OSH_AI_HISTORY_N=3
  _osh_ai_last_histcmd=0
  for i in 1 2 3 4 5; do _osh_ai_record_line 0 "$i" "   $i  cmd$i"; done
  [ "${#_osh_ai_cmds[@]}" -eq 3 ]
  [ "${_osh_ai_cmds[*]}" = "cmd3 cmd4 cmd5" ]
}

@test "ls de contexto omite ocultos y respeta el máximo" {
  cd "$BATS_TEST_TMPDIR"
  touch .env .ssh a.sh b.sh
  run _osh_ai_ls_context
  [[ "$output" != *".env"* ]]
  [[ "$output" != *".ssh"* ]]
  [[ "$output" == *"a.sh"* ]]

  OSH_AI_LS_MAX=1
  run _osh_ai_ls_context
  local IFS=,
  read -r -a entries <<< "$output"
  [ "${#entries[@]}" -eq 1 ]
}

@test "el contexto nunca supera OSH_AI_CONTEXT_MAX" {
  cd "$BATS_TEST_TMPDIR"
  local i
  for ((i = 0; i < 30; i++)); do touch "archivo_con_nombre_largo_$i"; done
  _osh_ai_cmds=("ls -la")
  _osh_ai_oks=(ok)
  OSH_AI_CONTEXT_MAX=60
  local ctx
  ctx=$(_osh_ai_context)
  [ "${#ctx}" -le 60 ]
  [[ "$ctx" == c=* ]]
}

@test "el contexto incluye el sistema operativo" {
  local osfile="$BATS_TEST_TMPDIR/os-release"
  printf 'ID=ubuntu\n' > "$osfile"
  OSH_AI_OS_RELEASE="$osfile"
  local ctx
  ctx=$(_osh_ai_context)
  [[ "$ctx" == *"os=ubuntu"* ]]
}

@test "redacta secretos" {
  run _osh_ai_redact <<< "export TOKEN=abc123 gsk_ZZZ ghp_ABC sk-1234567890abcd"
  [[ "$output" != *"abc123"* ]]
  [[ "$output" != *"gsk_ZZZ"* ]]
  [[ "$output" != *"ghp_ABC"* ]]
  [[ "$output" == *"***"* ]]
}

@test "el response cache evita la segunda llamada a aichat" {
  export GROQ_API_KEY=dummy
  local count="$BATS_TEST_TMPDIR/count"
  cat > "$BATS_TEST_TMPDIR/bin/aichat" <<EOF
#!/usr/bin/env bash
printf 'call\n' >> "$count"
printf 'df -h\n'
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/aichat"
  OSH_AI_CONTEXT=0
  OSH_AI_RESPONSE_CACHE=1
  run _osh_ai_run "sys" "misma petición"
  [ "$output" = "df -h" ]
  run _osh_ai_run "sys" "misma petición"
  [ "$output" = "df -h" ]
  [ "$(command wc -l < "$count")" -eq 1 ]
}

@test "ai -m no incluye contexto de shell" {
  export GROQ_API_KEY=dummy
  export CAPTURE="$BATS_TEST_TMPDIR/capture"
  cat > "$BATS_TEST_TMPDIR/bin/aichat" <<'EOF'
#!/usr/bin/env bash
printf '%s' "$*" > "$CAPTURE"
printf 'respuesta\n'
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/aichat"
  run ai -m "hola"
  local captured
  captured=$(command cat "$CAPTURE")
  [[ "$captured" != *"[Contexto]"* ]]
  [[ "$captured" == *"hola"* ]]
}
