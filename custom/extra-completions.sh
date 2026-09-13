#! bash oh-my-bash.module
# ── Completions extra ──
# Carga completions para herramientas instaladas que no están en la lista
# por defecto. Si el comando no existe, no se carga nada.
_omb_extra_completions=(docker-compose gh uv kubectl terraform)
for _omb_extra in "${_omb_extra_completions[@]}"; do
  [[ -f $OSH/completions/$_omb_extra.completion.sh ]] || continue
  _omb_util_command_exists "$_omb_extra" || continue
  # `|| true`: algunos completions de bash-completion devuelven 1 al cargar;
  # no queremos que eso aborte un shell con `set -e`.
  source "$OSH/completions/$_omb_extra.completion.sh" 2>/dev/null || true
done
unset -v _omb_extra _omb_extra_completions
