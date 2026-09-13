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
