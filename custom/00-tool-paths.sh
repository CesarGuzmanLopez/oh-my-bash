#! bash oh-my-bash.module
# ── PATH de herramientas que se configuran más tarde ──
# fzf (instalado en ~/.fzf) añade su bin al PATH desde ~/.fzf.bash, que se
# carga DESPUÉS de oh-my-bash. Sin esto, los custom que detectan `fzf`
# (fzf-custom.sh, fzf-extras.sh, ai.sh…) se saltarían en el arranque.
# Este archivo se carga primero (prefijo 00), así que deja fzf disponible.
_omb_tool_dir=$HOME/.fzf/bin
if [[ -d $_omb_tool_dir ]]; then
  case ":$PATH:" in
    *":$_omb_tool_dir:"*) ;;
    *) PATH="$_omb_tool_dir:$PATH" ;;
  esac
fi
unset -v _omb_tool_dir
export PATH
