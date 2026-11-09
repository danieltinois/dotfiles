#!/usr/bin/env bash
# PreToolUse (Bash|Read|Grep|Glob|Edit|Write|MultiEdit|NotebookEdit): barra o que as regras do AGENTS.md proíbem.
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

# Grep lê conteúdo e Glob lista arquivos. Em vez de regex sobre o texto do glob (fácil de driblar com `?`, `[]`, `{}`),
# testa se cada parte do caminho/glob CASARIA com um nome de segredo, usando o próprio pattern matching do bash.
secret_files=(.env .env.local .env.production .env.development .env.staging x.pem x.key x.p12 x.jks x.keystore
  id_rsa id_ed25519 id_ecdsa key.properties auth.json)
secret_dirs=(.ssh .aws .gnupg)
# Expande `{a,b}` sem eval (o glob vem do agente, não pode virar código).
expand_braces() {
  if [[ $1 =~ ^(.*)\{([^{}]*)\}(.*)$ ]]; then
    local pre=${BASH_REMATCH[1]} post=${BASH_REMATCH[3]} alts a
    IFS=, read -ra alts <<<"${BASH_REMATCH[2]},"
    for a in "${alts[@]}"; do expand_braces "$pre$a$post"; done
  else printf '%s\n' "$1"; fi
}
part_matches() { # $1 = parte do glob, demais = nomes de segredo
  local part=$1 alt name; shift
  while IFS= read -r alt; do
    [[ $alt == '' || $alt == '*' || $alt == '**' || $alt == '*.*' ]] && continue # curinga puro: não aponta para segredo
    for name in "$@"; do [[ $name == $alt ]] && return 0; done
  done < <(expand_braces "$part")
  return 1
}
globs_secret() {
  local p parts i
  p=$(tr '[:upper:]' '[:lower:]' <<<"$1")
  (( $(tr -cd '{' <<<"$p" | wc -c) > 8 )) && return 0 # brace bomb: trata como suspeito
  touches_secret "$p" && return 0
  IFS=/ read -ra parts <<<"$p"
  for i in "${!parts[@]}"; do
    part_matches "${parts[i]}" "${secret_dirs[@]}" && return 0
    (( i == ${#parts[@]} - 1 )) && part_matches "${parts[i]}" "${secret_files[@]}" && return 0
  done
  return 1
}
if [[ $tool == Grep || $tool == Glob ]]; then
  while IFS= read -r p; do
    [[ -n $p ]] || continue
    globs_secret "$p" && block "busca em segredo ($p)"
  done < <(jq -r --arg t "$tool" '.tool_input | .path, .glob, (if $t == "Glob" then .pattern else empty end) | values' <<<"$in")
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
