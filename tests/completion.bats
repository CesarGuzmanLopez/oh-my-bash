#!/usr/bin/env bats
# Tests de las completions perezosas con caché

setup() {
  load 'helpers'
  load_lazy_completion
  CACHE="$BATS_TEST_TMPDIR/foo.bash"
  complete -r foo 2> /dev/null || true
}

@test "registra un wrapper y genera la caché al primer uso" {
  _omb_util_lazy_completion foo "$CACHE" 'printf "_foo(){ COMPREPLY=(bar baz); }\ncomplete -F _foo foo\n"'
  run complete -p foo
  [[ "$output" == *"_omb_lazy_completion_foo"* ]]

  COMP_WORDS=(foo)
  COMP_CWORD=0
  _omb_lazy_completion_foo
  [ "${COMPREPLY[*]}" = "bar baz" ]
  [ -s "$CACHE" ]

  run complete -p foo
  [[ "$output" == *"_foo"* ]]
  [[ "$output" != *"_omb_lazy_completion"* ]]
}

@test "con caché existente registra la completion real sin wrapper" {
  printf '%s\n' '_foo(){ COMPREPLY=(x); }' 'complete -F _foo foo' > "$CACHE"
  _omb_util_lazy_completion foo "$CACHE" 'false'
  run complete -p foo
  [[ "$output" == *"_foo"* ]]
  [[ "$output" != *"_omb_lazy_completion"* ]]
}

@test "genera la caché con noclobber y un .tmp preexistente" {
  rm -f "$CACHE"
  printf 'stale' > "$CACHE.tmp"
  set -o noclobber
  _omb_util_lazy_completion foo "$CACHE" 'printf "_foo(){ COMPREPLY=(z); }\ncomplete -F _foo foo\n"'
  COMP_WORDS=(foo)
  COMP_CWORD=0
  _omb_lazy_completion_foo
  set +o noclobber
  [ -s "$CACHE" ]
  [ "${COMPREPLY[*]}" = z ]
}
