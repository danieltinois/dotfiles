#!/usr/bin/env bash
# PostToolUse (Edit|Write): formata o arquivo que o agente acabou de editar, usando a ferramenta do próprio projeto.
# Só procura config/binário até a raiz do repo git (fora de repo, só na pasta do arquivo) e só roda binário do projeto
# se ele for do Daniel e não for gravável por outros.
f=$(jq -r '.tool_response.filePath // .tool_input.file_path // empty')
[[ -n $f && -f $f ]] || exit 0
dir=$(cd "$(dirname "$f")" && pwd -P) || exit 0
top=$(git -c core.fsmonitor=false -C "$dir" rev-parse --show-toplevel 2>/dev/null) || top=$dir
up() {
  local d=$dir
  while :; do
    [[ -e $d/$1 ]] && { echo "$d"; return; }
    [[ $d == "$top" || $d == / ]] && return 1
    d=$(dirname "$d")
  done
}
trusted_bin() { [[ -x $1 && -O $1 ]] && ! find -L "$1" \( -perm -0020 -o -perm -0002 \) 2>/dev/null | grep -q .; }
case $f in
  *.g.dart|*.freezed.dart) ;;
  *.dart)
    if root=$(up .fvmrc); then (cd "$root" && fvm dart format "$f" >/dev/null); else dart format "$f" >/dev/null; fi ;;
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.json|*.css|*.scss|*.md)
    root=$(up node_modules/.bin/prettier) && bin=$root/node_modules/.bin/prettier && trusted_bin "$bin" &&
      "$bin" --write --ignore-unknown "$f" >/dev/null ;;
  *.py)
    # --no-config: o pyproject/uv.toml do repo não escolhe de onde o ruff é baixado.
    up pyproject.toml >/dev/null &&
      uvx --no-config --default-index https://pypi.org/simple ruff format -q "$f" ;;
esac
exit 0
