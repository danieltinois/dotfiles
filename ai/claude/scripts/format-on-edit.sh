#!/usr/bin/env bash
# PostToolUse (Edit|Write): formata o arquivo que o agente acabou de editar, usando a ferramenta do próprio projeto.
f=$(jq -r '.tool_response.filePath // .tool_input.file_path // empty')
[[ -n $f && -f $f ]] || exit 0
dir=$(dirname "$f")
up() { local d=$dir; while [[ $d != / ]]; do [[ -e $d/$1 ]] && { echo "$d"; return; }; d=$(dirname "$d"); done; return 1; }
case $f in
  *.g.dart|*.freezed.dart) ;;
  *.dart)
    if root=$(up .fvmrc); then (cd "$root" && fvm dart format "$f" >/dev/null); else dart format "$f" >/dev/null; fi ;;
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.json|*.css|*.scss|*.md)
    root=$(up node_modules/.bin/prettier) && "$root/node_modules/.bin/prettier" --write --ignore-unknown "$f" >/dev/null ;;
  *.py)
    up pyproject.toml >/dev/null && uvx ruff format -q "$f" ;;
esac
exit 0
