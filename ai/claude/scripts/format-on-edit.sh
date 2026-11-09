#!/usr/bin/env bash
# PostToolUse (Edit|Write): formata o arquivo que o agente acabou de editar, usando a ferramenta do próprio projeto.
# Só procura config/binário até a raiz do repo git (fora de repo, só na pasta do arquivo).
# Ferramenta escolhida pelo repo (prettier do node_modules + prettier.config.js, SDK do .fvmrc) só roda em repo que
# está dentro de uma pasta confiável: uma por linha em ~/.config/claude-hooks/trusted-roots (padrão: ~/development).
# Repo clonado só para olhar fica fora da lista e não executa nada dele ao ser editado.
f=$(jq -r '.tool_response.filePath // .tool_input.file_path // empty')
[[ -n $f && -f $f ]] || exit 0
dir=$(cd "$(dirname "$f")" && pwd -P) || exit 0
top=$(git -c core.fsmonitor=false -C "$dir" rev-parse --show-toplevel 2>/dev/null) || top=$dir
# `core.worktree` no .git/config do repo pode apontar a "raiz" para qualquer lugar: só vale se contém o arquivo.
[[ $dir == "$top" || $dir == "$top"/* ]] || top=$dir
up() {
  local d=$dir
  while :; do
    [[ -e $d/$1 ]] && { echo "$d"; return; }
    [[ $d == "$top" || $d == / ]] && return 1
    d=$(dirname "$d")
  done
}
trusted_repo() {
  local roots=${XDG_CONFIG_HOME:-$HOME/.config}/claude-hooks/trusted-roots r
  { [[ -f $roots ]] && cat "$roots" || echo "$HOME/development"; } | {
    while IFS= read -r r; do
      r=${r/#\~/$HOME}; [[ -n $r && $r != \#* ]] || continue
      r=$(cd "$r" 2>/dev/null && pwd -P) || continue
      [[ $top == "$r" || $top == "$r"/* ]] && [[ $dir == "$r"/* ]] && exit 0
    done
    exit 1
  }
}
trusted_bin() { [[ -x $1 && -O $1 ]] && ! find -L "$1" \( -perm -0020 -o -perm -0002 \) 2>/dev/null | grep -q .; }
case $f in
  *.g.dart|*.freezed.dart) ;;
  *.dart)
    if trusted_repo && root=$(up .fvmrc); then (cd "$root" && fvm dart format "$f" >/dev/null)
    else dart format "$f" >/dev/null 2>&1; fi ;;
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.json|*.css|*.scss|*.md)
    trusted_repo && root=$(up node_modules/.bin/prettier) && bin=$root/node_modules/.bin/prettier && trusted_bin "$bin" &&
      "$bin" --write --ignore-unknown "$f" >/dev/null ;;
  *.py)
    # --no-config: o pyproject/uv.toml do repo não escolhe de onde o ruff é baixado.
    up pyproject.toml >/dev/null &&
      uvx --no-config --default-index https://pypi.org/simple ruff format -q "$f" ;;
esac
exit 0
