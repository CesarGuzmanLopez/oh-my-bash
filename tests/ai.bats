#!/usr/bin/env bats
# Tests del helper de IA (Groq vía aichat)

setup() {
  load 'helpers'
  load_ai
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

@test "falla sin GROQ_API_KEY" {
  cat > "$BATS_TEST_TMPDIR/bin/aichat" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/aichat"
  unset GROQ_API_KEY
  run ai "algo"
  [ "$status" -ne 0 ]
  [[ "$output" == *"GROQ_API_KEY"* ]]
}

@test "falla si no existe aichat" {
  export GROQ_API_KEY=dummy
  _omb_util_command_exists() { return 1; }
  run ai "algo"
  [ "$status" -ne 0 ]
  [[ "$output" == *"aichat"* ]]
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
