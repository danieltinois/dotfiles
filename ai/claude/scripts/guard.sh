#!/usr/bin/env bash
# PreToolUse (Bash|Read|Edit|Write|MultiEdit|NotebookEdit): barra o que as regras do AGENTS.md proíbem.
# Exit 2 bloqueia e devolve o motivo ao agente.
in=$(cat)
tool=$(jq -r '.tool_name // empty' <<<"$in")
block() { echo "Bloqueado pelo guard.sh: $1. Se for intencional, peça para o Daniel rodar manualmente." >&2; exit 2; }

# .env de verdade (não .env.example/.sample/.template) e arquivos de chave
secret='(^|[/[:space:]"'\''=])\.env(\.[a-z0-9_-]+)*($|[[:space:]"'\'';|&)])|\.(pem|p12|jks|keystore)($|[[:space:]"'\'';|&)])|id_(rsa|ed25519|ecdsa)|key\.properties|\.ssh/|\.aws/credentials|\.codex/auth\.json'
example='\.env\.(example|sample|template|dist)'

touches_secret() { tr '[:upper:]' '[:lower:]' <<<"$1" | sed -E "s/$example//g" | grep -qE "$secret"; }

# Configs de lint/format/git hooks: "nunca afrouxe lint". Criar um novo pode; alterar um que já existe, não.
lint_names='analysis_options\.yaml|\.?eslintrc|eslint\.config\.|\.prettierrc|prettier\.config\.|biome\.jsonc?|\.stylelintrc|stylelint\.config\.|commitlint\.config\.|\.commitlintrc|lefthook(-local)?\.ya?ml|\.pre-commit-config\.yaml|ruff\.toml|\.markdownlint|\.swiftlint\.yml|\.husky/'
is_lint_cfg() { grep -qE "(^|/)($lint_names)" <<<"$1"; }
lint_block() { block "alteração de config de lint/hook ($1). Corrija o código em vez de afrouxar a regra"; }

if [[ $tool =~ ^(Edit|Write|MultiEdit|NotebookEdit)$ ]]; then
  f=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$in")
  [[ -e $f ]] && is_lint_cfg "$f" && lint_block "${f##*/}"
  exit 0
fi

if [[ $tool == Read ]]; then
  f=$(jq -r '.tool_input.file_path // empty' <<<"$in")
  touches_secret "$f" && block "leitura de segredo ($f)"
  exit 0
fi

cmd=$(jq -r '.tool_input.command // empty' <<<"$in")
[[ -n $cmd ]] || exit 0
touches_secret "$cmd" && block "comando toca em .env/chave/credencial"

grep -qE 'git[[:space:]].*push.*([[:space:]](-f|--force|--force-with-lease)([[:space:]=]|$)|[[:space:]]\+[^[:space:]]+)' <<<"$cmd" && block "git push forçado"
grep -qE 'git[[:space:]].*(commit|push|merge|rebase).*--no-verify' <<<"$cmd" && block "--no-verify pula hooks/lint"
grep -qiE 'co-authored-by:.*(claude|codex|anthropic|openai|copilot|gpt)|generated (with|by) .*(claude|codex|chatgpt|ai\b)|🤖' <<<"$cmd" && block "atribuição de IA em commit/PR (tudo sai só no nome do Daniel)"
grep -qE 'rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*[[:space:]]+(/|~|\$HOME|/Users/[^/[:space:]]+)/?([[:space:]]|$)' <<<"$cmd" && block "rm -rf na raiz ou na home"
grep -qE "((^|[[:space:];&|(])(sed[[:space:]][^|;&]*-i|perl[[:space:]]+-[a-zA-Z]*i|tee[[:space:]]|rm[[:space:]])|>)[^|;&]*($lint_names)" <<<"$cmd" && lint_block "via shell"
exit 0
