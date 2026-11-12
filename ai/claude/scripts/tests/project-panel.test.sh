#!/usr/bin/env bash
# Tests for ../project-panel.sh, against a throwaway vault and dev root under $TMPDIR (never the real vault).
# Usage: bash project-panel.test.sh [name-filter]
set -u
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/project-panel.sh"
BASE=$(cd "$(mktemp -d "${TMPDIR:-/tmp}/pp.XXXX")" && pwd -P)
trap 'rm -rf "$BASE"' EXIT
F='```'
RULE='Rule: this session starts from the panel above. When a piece of work that changed code, a card, a PR or a decision is done, update the panel with the project-panel skill (patch only: tick the checklist, set proxima_acao, add one dated Log line). Questions and short chats do not touch it.'
PASS=0
FAIL=0
FILTER=${1:-}

setup() {
  rm -rf "$BASE"/vault "$BASE"/dev "$BASE"/home "$BASE"/ignore "$BASE"/other
  VAULT=$BASE/vault DEV=$BASE/dev HOME_=$BASE/home IGN=$BASE/ignore MAXC=4000
  mkdir -p "$VAULT/10 Projetos" "$DEV" "$HOME_"
}
mkrepo() {
  mkdir -p "$1"
  git -C "$1" init -q
  git -C "$1" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
}
note() { mkdir -p "$(dirname "$VAULT/$1")"; cat >"$VAULT/$1"; }
run_hook() {
  OUT=$(jq -n --arg cwd "$1" --arg source "${2:-}" 'if $source == "" then {cwd:$cwd} else {cwd:$cwd,source:$source} end' |
    env HOME="$HOME_" CEREBRO_VAULT="$VAULT" PANEL_ROOTS="$DEV" PANEL_IGNORE_FILE="$IGN" PANEL_MAX_CHARS="$MAXC" "$SCRIPT" 2>/dev/null)
  RC=$?
}
ctx() { jq -r '.hookSpecificOutput.additionalContext // empty' <<<"$OUT"; }

ok() { PASS=$((PASS + 1)); echo "  ok    $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL  $1 -- $2"; }
has() { # name text needle
  case $2 in *"$3"*) ok "$1" ;; *) fail "$1" "missing: $3" ;; esac
}
hasnt() {
  case $2 in *"$3"*) fail "$1" "unexpected: $3" ;; *) ok "$1" ;; esac
}
empty() { # name: stdout empty and exit 0
  if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then ok "$1"; else fail "$1" "rc=$RC out=${OUT:0:80}"; fi
}
equal() { if [ "$2" = "$3" ]; then ok "$1"; else fail "$1" "got '$2' want '$3'"; fi; }

# A project note with the given folders block (already formatted) and optional extra frontmatter and body.
project() { # path folders-lines [extra-frontmatter] ; body from stdin
  {
    printf -- '---\ntipo: projeto\n%s\nstatus: ativo\nbranch: main\nproxima_acao: Do the next thing\n%s\n---\n' "$2" "${3:-}"
    cat
  } | note "$1"
}

test_exact_match() {
  setup
  project "10 Projetos/A/A.md" "pastas:
  - $DEV/a" <<<"# A"
  run_hook "$DEV/a"
  has "panel line" "$(ctx)" "Project panel (Obsidian vault): 10 Projetos/A/A.md"
  has "next action" "$(ctx)" "Next action: Do the next thing"
  has "status and branch" "$(ctx)" "Status: ativo · Branch: main"
}
test_longest_wins() {
  setup
  project "10 Projetos/H/H.md" "pastas:
  - $DEV/g" <<<"# H"
  project "10 Projetos/F/F.md" "pastas:
  - $DEV/g/repo" <<<"# F"
  run_hook "$DEV/g/repo/sub"
  has "front wins" "$(ctx)" "10 Projetos/F/F.md"
  hasnt "hub loses" "$(ctx)" "Warning:"
}
test_prefix_is_not_parent() {
  setup
  project "10 Projetos/A/A.md" "pastas:
  - $DEV/app-cms" <<<"# A"
  mkrepo "$DEV/app-cms-old"
  run_hook "$DEV/app-cms-old"
  hasnt "no panel" "$(ctx)" "Project panel (Obsidian vault)"
  has "offer" "$(ctx)" "No project panel"
}
test_spaces_and_quotes() {
  setup
  project "10 Projetos/G/G.md" "pastas:
  - \"$DEV/G - X\"" <<<"# G"
  project "10 Projetos/Y/Y.md" "pastas:
  - '$DEV/Y Z'" <<<"# Y"
  run_hook "$DEV/G - X/sub"
  has "double quotes" "$(ctx)" "10 Projetos/G/G.md"
  run_hook "$DEV/Y Z"
  has "single quotes" "$(ctx)" "10 Projetos/Y/Y.md"
}
test_tilde() {
  setup
  project "10 Projetos/T/T.md" "pastas:
  - ~/dev/t/" <<<"# T"
  run_hook "$HOME_/dev/t"
  has "tilde expanded, trailing slash dropped" "$(ctx)" "10 Projetos/T/T.md"
}
test_list_forms() {
  setup
  project "10 Projetos/B1/B1.md" "pastas:
  - $DEV/p1" <<<"# 1"
  project "10 Projetos/B2/B2.md" "pastas: [$DEV/p2, \"$DEV/p3\"]" <<<"# 2"
  project "10 Projetos/B3/B3.md" "pastas: $DEV/p4" <<<"# 3"
  run_hook "$DEV/p1"; has "block" "$(ctx)" "B1/B1.md"
  run_hook "$DEV/p3"; has "inline" "$(ctx)" "B2/B2.md"
  run_hook "$DEV/p4"; has "scalar" "$(ctx)" "B3/B3.md"
}
test_body_ignored() {
  setup
  mkrepo "$DEV/b"
  note "10 Projetos/N/N.md" <<EOF
---
tipo: projeto
status: ativo
---
texto
---
pastas: $DEV/b
EOF
  run_hook "$DEV/b"
  hasnt "no panel" "$(ctx)" "Project panel (Obsidian vault)"
  has "offer" "$(ctx)" "No project panel"
}
test_external_worktree() {
  setup
  mkrepo "$DEV/r"
  project "10 Projetos/R/R.md" "pastas:
  - $DEV/r" <<<"# R"
  git -C "$DEV/r" worktree add -q -b wt "$DEV/r-wt"
  run_hook "$DEV/r-wt"
  has "panel of the main repo" "$(ctx)" "10 Projetos/R/R.md"
}
test_tie_warns() {
  setup
  project "10 Projetos/B/B.md" "pastas:
  - $DEV/t" <<<"# B"
  project "10 Projetos/A/A.md" "pastas:
  - $DEV/t" <<<"# A"
  run_hook "$DEV/t"
  has "first alphabetically" "$(ctx)" "Project panel (Obsidian vault): 10 Projetos/A/A.md"
  has "warning" "$(ctx)" "Warning: 10 Projetos/B/B.md also claims this folder; using the one above."
}
test_parent() {
  setup
  project "10 Projetos/Hub/Hub.md" "pastas:
  - $DEV/hub" <<EOF
> [!brain] Hoje, na ordem
> 1. do the hub thing
EOF
  project "10 Projetos/Hub/Front.md" "pastas:
  - $DEV/front" 'pai: "[[Hub|the hub]]"' <<<"# Front"
  run_hook "$DEV/front"
  has "parent panel" "$(ctx)" "Parent panel: 10 Projetos/Hub/Hub.md"
  has "parent now" "$(ctx)" "Parent now:
1. do the hub thing"
}
test_sections() {
  setup
  {
    echo "> [!brain] Agora"
    echo "> faça X"
    echo
    for i in 1 2 3 4 5 6 7 8 9 10 11 12; do echo "- [ ] item $i"; done
    echo "- [x] done one"
    echo "${F}"
    echo "- [ ] inside fence"
    echo "${F}"
    echo "## Log"
    for i in 1 2 3 4 5; do echo "- log-$i"; done
  } | project "10 Projetos/S/S.md" "pastas:
  - $DEV/s"
  run_hook "$DEV/s"
  c=$(ctx)
  has "now" "$c" "Now:
faça X"
  equal "ten open items" "$(grep -c -- '^- \[ \] item' <<<"$c")" 10
  hasnt "no ticked" "$c" "- [x]"
  hasnt "no fenced" "$c" "inside fence"
  has "last 3 log" "$c" "- log-3
- log-4
- log-5"
  hasnt "not log 2" "$c" "log-2"
}
test_no_vault() {
  setup
  VAULT=$BASE/nope
  mkrepo "$DEV/n"
  run_hook "$DEV/n"
  empty "silent"
}
test_offer() {
  setup
  mkrepo "$DEV/n"
  run_hook "$DEV/n"
  c=$(ctx)
  case $c in "No project panel"*) ok "starts with offer" ;; *) fail "starts with offer" "${c:0:60}" ;; esac
  has "names toplevel" "$c" "$DEV/n"
  has "names ignore file" "$c" "$IGN"
}
test_ignored() {
  setup
  mkrepo "$DEV/n"
  printf '\n%s/\n' "$DEV/n" >"$IGN"
  run_hook "$DEV/n"
  empty "silent"
}
test_ignore_comments() {
  setup
  mkrepo "$DEV/n"
  printf '# a comment\n\n%s\n' "$DEV/n" >"$IGN"
  run_hook "$DEV/n"
  empty "listed folder still ignored"
  printf '# %s\n' "$DEV/n" >"$IGN"
  run_hook "$DEV/n"
  has "commented-out line does not ignore" "$(ctx)" "No project panel"
}
test_offer_only_on_startup() {
  setup
  mkrepo "$DEV/n"
  run_hook "$DEV/n" compact; empty "compact"
  run_hook "$DEV/n" clear; empty "clear"
  run_hook "$DEV/n" startup; has "startup" "$(ctx)" "No project panel"
  run_hook "$DEV/n" resume; has "resume" "$(ctx)" "No project panel"
  run_hook "$DEV/n"; has "no source" "$(ctx)" "No project panel"
  project "10 Projetos/A/A.md" "pastas:
  - $DEV/n" <<<"# A"
  run_hook "$DEV/n" compact
  has "panel shows on compact" "$(ctx)" "Project panel (Obsidian vault): 10 Projetos/A/A.md"
}
test_non_projeto_ignored() {
  setup
  mkrepo "$DEV/n"
  note "10 Projetos/X/X.md" <<EOF
---
tipo: nota
pastas:
  - $DEV/n
---
texto
EOF
  run_hook "$DEV/n"
  hasnt "not chosen" "$(ctx)" "Project panel (Obsidian vault)"
  has "offer" "$(ctx)" "No project panel"
}
test_folded_scalar() {
  setup
  note "10 Projetos/W/W.md" <<EOF
---
tipo: projeto
pastas:
  - $DEV/w
proxima_acao: Revisão dos PRs 9021 (A) e 9022 (B); decidir SSO (PR C) e se o
  editor vê Usuários; depois PR D
status: ativo
---
# W
EOF
  run_hook "$DEV/w"
  has "joined" "$(ctx)" "Next action: Revisão dos PRs 9021 (A) e 9022 (B); decidir SSO (PR C) e se o editor vê Usuários; depois PR D"
  has "next key still read" "$(ctx)" "Status: ativo"
}
test_folded_list_item() {
  setup
  note "10 Projetos/W/W.md" <<EOF
---
tipo: projeto
pastas:
  - $DEV/long folder name with
    many spaces
  - $DEV/other
status: ativo
---
# W
EOF
  run_hook "$DEV/long folder name with many spaces/sub"
  has "wrapped item matches" "$(ctx)" "10 Projetos/W/W.md"
  run_hook "$DEV/other"
  has "next item still read" "$(ctx)" "10 Projetos/W/W.md"
}
test_block_scalar() {
  setup
  note "10 Projetos/W/W.md" <<EOF
---
tipo: projeto
pastas:
  - $DEV/w
proxima_acao: >-
  first part
  second part
status: ativo
---
# W
EOF
  run_hook "$DEV/w"
  has "joined" "$(ctx)" "Next action: first part second part"
}
test_outside_roots() {
  setup
  mkrepo "$BASE/other"
  run_hook "$BASE/other"
  empty "silent"
}
test_not_git() {
  setup
  mkdir -p "$DEV/plain"
  run_hook "$DEV/plain"
  empty "silent"
}
test_json_and_cap() {
  setup
  {
    echo 'He said "aspas" and \barra 🚀'
    echo "${F}mermaid"
    echo "graph TD; A-->B"
    echo "${F}"
    pad=$(printf "x%.0s" $(seq 1 80)); for i in $(seq 1 300); do echo "- [ ] item $i $pad"; done
  } | project "10 Projetos/J/J.md" "pastas:
  - $DEV/j"
  MAXC=500
  run_hook "$DEV/j"
  if jq -e . <<<"$OUT" >/dev/null 2>&1; then ok "valid json"; else fail "valid json" "${OUT:0:80}"; fi
  c=$(ctx)
  has "truncated marker" "$c" "…(truncated)"
  equal "ends with the whole rule" "$(tail -n 1 <<<"$c")" "$RULE"
  if [ "${#c}" -lt 1000 ]; then ok "short"; else fail "short" "${#c}"; fi
}
test_bad_input() {
  setup
  OUT=$(echo 'não é json' | env HOME="$HOME_" CEREBRO_VAULT="$VAULT" PANEL_ROOTS="$DEV" PANEL_IGNORE_FILE="$IGN" "$SCRIPT" 2>/dev/null)
  RC=$?
  empty "silent"
}

for t in $(compgen -A function | grep '^test_'); do
  case $t in *"$FILTER"*) ;; *) continue ;; esac
  echo "$t"
  $t
done
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
