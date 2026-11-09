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

# Grep lê conteúdo e Glob lista arquivos. Regex sobre o texto do glob é fácil de driblar (`?`, `[]`, `{}`), então:
# 1) expande as chaves do glob inteiro (sem eval, com teto); 2) cada alternativa literal passa pelo `secret` do Read;
# 3) com curinga, pergunta ao próprio pattern matching do bash se ela CASARIA com algum segredo — por família, não
#    por lista: `.env` ou `.env.<qualquer coisa>`, `<qualquer coisa>.pem/.key/…`, e os nomes/pastas fixos.
max_alts=256
secret_exts=(.pem .key .p12 .jks .keystore)
secret_names=(id_rsa id_ed25519 id_ecdsa key.properties auth.json)
secret_dirs=(.ssh .aws .gnupg)
expand_braces() { # imprime as alternativas; passou do teto, imprime __CAP__ e para
  if (( ${#1} > 1024 )); then echo __CAP__; exit; fi
  if [[ $1 =~ ^(.*)\{([^{}]*)\}(.*)$ ]]; then
    local pre=${BASH_REMATCH[1]} post=${BASH_REMATCH[3]} alts a
    IFS=, read -ra alts <<<"${BASH_REMATCH[2]},"
    for a in "${alts[@]}"; do expand_braces "$pre$a$post"; done
  else
    (( ++n_alts > max_alts )) && { echo __CAP__; exit; }
    printf '%s\n' "$1"
  fi
}
# "Específico": o pedaço do glob casa com o segredo E não casa com nenhum nome-isca de formato parecido.
# Assim `*`, `.*`, `*.*`, `*.dart` (que casam com qualquer coisa) passam, e `.en?`, `*nv.q?`, `*.p?m` são barrados.
decoys=(zzzz zzzz. .zzzz .zzzz. zz.zz .zz.zz zz_zz)
specific() { # $1 segredo, $2 glob
  local d
  [[ $1 == $2 ]] || return 1
  for d in "${decoys[@]}"; do [[ $d == $2 ]] && return 1; done
  return 0
}
file_could_be_secret() { # $1 = último pedaço do glob, com curinga
  local g=$1 k e n
  specific .env "$g" && return 0
  for (( k = 1; k <= ${#g}; k++ )); do
    specific .env. "${g:0:k}" && return 0                            # prefixo casa ".env." → casa .env.<algo>
    for e in "${secret_exts[@]}"; do specific "$e" "${g:k-1}" && return 0; done # sufixo casa ".pem" etc.
  done
  for n in "${secret_names[@]}"; do specific "$n" "$g" && return 0; done
  return 1
}
dir_could_be_secret() { local d; for d in "${secret_dirs[@]}"; do specific "$d" "$1" && return 0; done; return 1; }
globs_secret() {
  local p alt parts i
  p=$(tr '[:upper:]' '[:lower:]' <<<"$1")
  while IFS= read -r alt; do
    [[ $alt == __CAP__ ]] && return 0 # expansão grande demais: trata como suspeito em vez de estourar o timeout
    touches_secret "$alt" && return 0
    IFS=/ read -ra parts <<<"$alt"
    for i in "${!parts[@]}"; do
      dir_could_be_secret "${parts[i]}" && return 0 # pega `~/.ssh` sem barra e `.s?h`
      # arquivo literal já passou pelo touches_secret (que respeita .env.example); aqui só o que tem curinga
      (( i == ${#parts[@]} - 1 )) && [[ ${parts[i]} == *[\*\?\[]* ]] && file_could_be_secret "${parts[i]}" && return 0
    done
  done < <(n_alts=0; expand_braces "$p")
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
