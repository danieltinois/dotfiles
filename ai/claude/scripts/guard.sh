#!/usr/bin/env bash
# PreToolUse (Bash|Read|Grep|Glob|Edit|Write|MultiEdit|NotebookEdit): blocks what the AGENTS.md rules forbid.
# Exit 2 blocks the tool call and sends the reason back to the agent.
in=$(cat)
tool=$(jq -r '.tool_name // empty' <<<"$in")
block() { echo "Blocked by guard.sh: $1. If this is intentional, ask Daniel to run it by hand." >&2; exit 2; }

# Real .env files (not .env.example/.sample/.template) and key files
secret='(^|[/[:space:]"'\''=])\.env(\.[a-z0-9_-]+)*($|[[:space:]"'\'';|&)])|[^/[:space:]"'\''.]\.(pem|key|p12|jks|keystore)($|[[:space:]"'\'';|&)])|id_(rsa|ed25519|ecdsa)|key\.properties|\.ssh/|\.aws/credentials|\.codex/auth\.json'
example='\.env\.(example|sample|template|dist)'

touches_secret() { tr '[:upper:]' '[:lower:]' <<<"$1" | sed -E "s/$example//g" | grep -qE "$secret"; }

# Lint/format/git-hook configs: "never loosen lint". Creating a new one is fine; changing an existing one is not.
lint_names='analysis_options\.yaml|\.?eslintrc|eslint\.config\.|\.prettierrc|prettier\.config\.|biome\.jsonc?|\.stylelintrc|stylelint\.config\.|commitlint\.config\.|\.commitlintrc|lefthook(-local)?\.ya?ml|\.pre-commit-config\.yaml|ruff\.toml|\.markdownlint|\.swiftlint\.yml|\.husky/'
is_lint_cfg() { grep -qE "(^|/)($lint_names)" <<<"$1"; }
lint_block() { block "change to a lint/hook config ($1). Fix the code instead of loosening the rule"; }

if [[ $tool =~ ^(Edit|Write|MultiEdit|NotebookEdit)$ ]]; then
  f=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$in")
  [[ -e $f ]] && is_lint_cfg "$f" && lint_block "${f##*/}"
  exit 0
fi

if [[ $tool == Read ]]; then
  f=$(jq -r '.tool_input.file_path // empty' <<<"$in")
  touches_secret "$f" && block "reading a secret ($f)"
  exit 0
fi

# Grep reads contents and Glob lists files. A regex over the glob text is easy to dodge (`?`, `[]`, `{}`), so:
# 1) expand the braces of the whole glob (no eval, with a cap); 2) every literal alternative goes through Read's
#    `secret` check; 3) with wildcards, ask bash's own pattern matching whether it COULD match a secret, by family
#    rather than by list: `.env` or `.env.<anything>`, `<anything>.pem/.key/…`, and the fixed names/folders.
max_alts=64 max_len=512 # low caps: the hook has 10s, and timing out lets the tool through
secret_exts=(.pem .key .p12 .jks .keystore)
secret_names=(id_rsa id_ed25519 id_ecdsa key.properties)
secret_dirs=(.ssh .aws .gnupg .codex)
expand_braces() { # prints the alternatives; past the cap, prints __CAP__ and stops
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
# Glob piece with wildcards: fail closed. `?` or `[` → always block. With `*` only, look at the literal runs:
#  - starts with a literal (`abc*`): matches a secret only if `abc` can start one (e.g. `.e*`, `id_*`, `.*`);
#  - ends with a literal (`*abc`): matches only if `abc` can end one (e.g. `*nv`, `*nv.local`, `*.pem`, `*em`);
#  - `*abc*`: matches only if `abc` can sit inside one (e.g. `*env*`, `*.k*`).
# Pure wildcards (`*`, `**`, `*.*`) pass: they don't point at a secret, and rg already skips hidden/ignored files.
# Accepted limit: `*.test.*` would match a `.env.test.local`; the strong barrier for that is the /sandbox.
could_match() { # $1 = glob piece, the rest = secrets ("@env" = the .env/.env.<anything> family)
  local g=$1 s L first last runs i A B; shift
  [[ $g == *[\?\[]* ]] && return 0
  [[ $g == '*' || $g == '**' || $g == '*.*' ]] && return 1
  IFS='*' read -ra runs <<<"$g"
  first=${runs[0]}; last=${runs[${#runs[@]}-1]}; [[ $g == *'*' ]] && last=''
  for s in "$@"; do
    local stem=${s/#@env/.env}
    if [[ $s == .* && $s != @env && " ${secret_exts[*]} " == *" $s "* ]]; then
      # extension (`x.pem`): the start can be anything, only the end decides (`s*.key`, `*.p*` → block)
      if [[ -n $last ]]; then [[ $stem == *"$last" || $last == *"$stem" ]] && return 0
      else for L in "${runs[@]:1}"; do [[ -n $L && ( $stem == *"$L"* || $L == *"$stem"* ) ]] && return 0; done; fi
    elif [[ -n $first ]]; then # anchored at the start
      [[ $stem == "$first"* || ( $s == @env && $first == "$stem"* ) || $first == "$stem" ]] && return 0
    elif [[ -n $last ]]; then # anchored at the end
      [[ $stem == *"$last" || $last == *"$stem" ]] && return 0
      if [[ $s == @env ]]; then # *nv.local matches .env.local: a suffix of ".env" followed by ".something"
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
    [[ $alt == __CAP__ ]] && return 0 # expansion too big: treat as suspicious instead of hitting the timeout
    touches_secret "$alt" && return 0
    IFS=/ read -ra parts <<<"$alt"
    for i in "${!parts[@]}"; do
      dir_could_be_secret "${parts[i]}" && return 0 # catches `~/.ssh` without a trailing slash and `.s?h`
      # a literal file name already went through touches_secret (which honors .env.example); here only wildcards
      (( i == ${#parts[@]} - 1 )) && [[ ${parts[i]} == *[\*\?\[]* ]] && file_could_be_secret "${parts[i]}" && return 0
    done
  done < <(n_alts=0; expand_braces "$p")
  return 1
}
if [[ $tool == Grep || $tool == Glob ]]; then
  while IFS= read -r p; do
    [[ -n $p ]] || continue
    globs_secret "$p" && block "searching a secret ($p)"
  done < <(jq -r --arg t "$tool" '.tool_input | .path, .glob, (if $t == "Glob" then .pattern else empty end) | values' <<<"$in")
  exit 0
fi

cmd=$(jq -r '.tool_input.command // empty' <<<"$in")
[[ -n $cmd ]] || exit 0
touches_secret "$cmd" && block "command touches a .env/key/credential"

grep -qE 'git[[:space:]].*push.*([[:space:]](-f|--force|--force-with-lease)([[:space:]=]|$)|[[:space:]]\+[^[:space:]]+)' <<<"$cmd" && block "forced git push"
grep -qE 'git[[:space:]].*(commit|push|merge|rebase).*--no-verify' <<<"$cmd" && block "--no-verify skips hooks/lint"
grep -qiE 'co-authored-by:.*(claude|codex|anthropic|openai|copilot|gpt)|generated (with|by) .*(claude|codex|chatgpt|ai\b)|🤖' <<<"$cmd" && block "AI attribution in a commit/PR (everything goes out under Daniel's name only)"
grep -qE 'rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*[[:space:]]+(/|~|\$HOME|/Users/[^/[:space:]]+)/?([[:space:]]|$)' <<<"$cmd" && block "rm -rf on the root or home"
grep -qE "((^|[[:space:];&|(])(sed[[:space:]][^|;&]*-i|perl[[:space:]]+-[a-zA-Z]*i|tee[[:space:]]|rm[[:space:]])|>)[^|;&]*($lint_names)" <<<"$cmd" && lint_block "via shell"
exit 0
