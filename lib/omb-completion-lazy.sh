#! bash oh-my-bash.module
# ── Lazy (on-demand) completions ──
# Register a completion whose content is generated/sourced only the first time
# the command is completed (Tab). This avoids spawning tools like `npm`
# (~75 ms) or `uv` at shell startup, and never blocks when there is no network.
# The generated output is cached for the following sessions.
#
#   _omb_util_lazy_completion CMD CACHEFILE 'generator command'
#
function _omb_util_lazy_completion {
  local cmd=$1 cache=$2 generator=$3
  local fname="_omb_lazy_completion_${cmd//[^a-zA-Z0-9_]/_}"

  # Cache from a previous session: source it now (fast, no subprocess).
  if [[ -s $cache ]]; then
    source "$cache"
    return 0
  fi

  eval "function $fname {
    if [[ ! -s '$cache' ]]; then
      command mkdir -p '${cache%/*}' 2> /dev/null
      { $generator ; } >| '$cache.tmp' 2> /dev/null && command mv '$cache.tmp' '$cache'
    fi
    if [[ -s '$cache' ]]; then
      unset -f $fname
      source '$cache'
      local spec real
      spec=\$(complete -p '$cmd' 2> /dev/null)
      real=\${spec##*-F }
      real=\${real%% *}
      [[ -n \$real && \$real != $fname ]] && \"\$real\" \"\$@\"
    fi
  }"
  complete -F "$fname" "$cmd"
}
