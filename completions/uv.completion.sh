#! bash oh-my-bash.module

# uv (Python package and project manager) completion
# https://docs.astral.sh/uv/reference/cli/#uv-generate-shell-completion
#
# Generated lazily (on first Tab) and cached: running `uv generate-shell-completion`
# at startup spawns uv and slows the shell.
if _omb_util_command_exists uv; then
  _omb_util_lazy_completion uv "$OSH_CACHE_DIR/completions/uv.bash" 'uv generate-shell-completion bash'
fi
