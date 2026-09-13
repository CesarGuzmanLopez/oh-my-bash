#! bash oh-my-bash.module

# npm (Node Package Manager) completion
# https://docs.npmjs.com/cli/completion
#
# Generated lazily (on first Tab) and cached: running `npm completion` at
# startup spawns Node (~75 ms) and can hang with no network.
if _omb_util_command_exists npm; then
  _omb_util_lazy_completion npm "$OSH_CACHE_DIR/completions/npm.bash" 'npm completion'
fi
