#!/usr/bin/env bash
# PreToolUse (Bash|Read|Grep|Glob|Edit|Write|MultiEdit|NotebookEdit): barra o que as regras do AGENTS.md proíbem.
# Exit 2 bloqueia e devolve o motivo ao agente.
in=$(cat)
tool=$(jq -r '.tool_name // empty' <<<"$in")
block() { echo "Bloqueado pelo guard.sh: $1. Se for intencional, peça para o Daniel rodar manualmente." >&2; exit 2; }

# .env de verdade (não .env.example/.sample/.template) e arquivos de chave
secret='(^|[/[:space:]"'\''=])\.env(\.[a-z0-9_-]+)*($|[[:space:]"'\'';|&)])|[^/[:space:]"'\''.]\.(pem|key|p12|jks|keystore)($|[[:space:]"'\'';|&)])|id_(rsa|ed25519|ecdsa)|key\.properties|\.ssh/|\.aws/credentials|\.codex/auth\.json'
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
max_alts=64 max_len=512 # tetos baixos: o hook tem 10s e estourar o tempo libera a ferramenta
secret_exts=(.pem .key .p12 .jks .keystore)
secret_names=(id_rsa id_ed25519 id_ecdsa key.properties)
secret_dirs=(.ssh .aws .gnupg .codex)
expand_braces() { # imprime as alternativas; passou do teto, imprime __CAP__ e para
  if (( ${#1} > max_len )); then echo __CAP__; exit; fi
  if [[ $1 =~ ^(.*)\{([^{}]*)\}(.*)$ ]]; then
    local pre=${BASH_REMATCH[1]} post=${BASH_REMATCH[3]} alts a
    IFS=, read -ra alts <<<"${BASH_REMATCH[2]},"
    for a in "${alts[@]}"; do expand_braces "$pre$a$post"; done
  else
    (( ++n_alts > max_alts )) && { echo __CAP__; exit; }
    printf '%s\n' "$1"
  fi
}
# Pedaço de glob com curinga: falha fechado. `?` ou `[` → bloqueia sempre. Só com `*`, olha os trechos literais:
#  - começa literal (`abc*`): só casa segredo se `abc` puder começar um (ex.: `.e*`, `id_*`, `.*`);
#  - termina literal (`*abc`): só casa se `abc` puder terminar um (ex.: `*nv`, `*nv.local`, `*.pem`, `*em`);
#  - `*abc*`: só casa se `abc` puder estar dentro de um (ex.: `*env*`, `*.k*`).
# Curinga puro (`*`, `**`, `*.*`) passa: não aponta para segredo, e o rg já pula ocultos/ignorados.
# Limite aceito: `*.test.*` casaria um `.env.test.local`; a barreira forte para isso é o /sandbox.
could_match() { # $1 = pedaço do glob, demais = segredos ("@env" = família .env/.env.<algo>)
  local g=$1 s L first last runs i A B; shift
  [[ $g == *[\?\[]* ]] && return 0
  [[ $g == '*' || $g == '**' || $g == '*.*' ]] && return 1
  IFS='*' read -ra runs <<<"$g"
  first=${runs[0]}; last=${runs[${#runs[@]}-1]}; [[ $g == *'*' ]] && last=''
  for s in "$@"; do
    local stem=${s/#@env/.env}
    if [[ $s == .* && $s != @env && " ${secret_exts[*]} " == *" $s "* ]]; then
      # extensão (`x.pem`): o começo pode ser qualquer coisa, só o fim decide (`s*.key`, `*.p*` → barra)
      if [[ -n $last ]]; then [[ $stem == *"$last" || $last == *"$stem" ]] && return 0
      else for L in "${runs[@]:1}"; do [[ -n $L && ( $stem == *"$L"* || $L == *"$stem"* ) ]] && return 0; done; fi
    elif [[ -n $first ]]; then # ancorado no começo
      [[ $stem == "$first"* || ( $s == @env && $first == "$stem"* ) || $first == "$stem" ]] && return 0
    elif [[ -n $last ]]; then # ancorado no fim
      [[ $stem == *"$last" || $last == *"$stem" ]] && return 0
      if [[ $s == @env ]]; then # *nv.local casa .env.local: um sufixo de ".env" seguido de ".algo"
        for (( i = 1; i < ${#last}; i++ )); do A=${last:0:i}; B=${last:i}
          [[ $stem == *"$A" && $B == .* ]] && return 0; done
      fi
    else # *abc*
      for L in "${runs[@]}"; do [[ -n $L && ( $stem == *"$L"* || $L == *"$stem"* ) ]] && return 0; done
    fi
  done
  return 1
}
file_could_be_secret() { could_match "$1" @env "${secret_exts[@]}" "${secret_names[@]}"; }
dir_could_be_secret() { [[ $1 == *[\*\?\[]* ]] || { local d; for d in "${secret_dirs[@]}"; do [[ $1 == "$d" ]] && return 0; done; return 1; }
  could_match "$1" "${secret_dirs[@]}"; }
globs_secret() {
  local p alt parts i
  p=$(tr '[:upper:]' '[:lower:]' <<<"$1")
  (( ${#p} > max_len )) && return 0
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
