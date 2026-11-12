#!/usr/bin/env bash
# SessionStart: loads the project panel (an Obsidian note with `tipo: projeto`) that claims the session's folder.
# Looks in $CEREBRO_VAULT/10 Projetos/**/*.md for the note whose frontmatter `pastas` is the longest prefix of `.cwd`
# (falling back to the main repo of an external git worktree) and injects its state as additionalContext.
# With no panel, offers to create one, but only inside $PANEL_ROOTS and outside $PANEL_IGNORE_FILE.
# Fails open: any error ends in exit 0 with empty stdout. Bash 3.2 + BSD tools only (macOS).
set -u
trap 'exit 0' ERR
export LC_CTYPE=en_US.UTF-8

VAULT=${CEREBRO_VAULT:-$HOME/Obsidian/Cerebro}
ROOTS=${PANEL_ROOTS:-$HOME/development}
IGNORE=${PANEL_IGNORE_FILE:-$HOME/.config/claude-hooks/panel-ignore}
MAX=${PANEL_MAX_CHARS:-4000}
case $MAX in '' | *[!0-9]*) MAX=4000 ;; esac
DIR="$VAULT/10 Projetos"
RULE='Rule: this session starts from the panel above. When a piece of work that changed code, a card, a PR or a decision is done, update it with the project-panel skill: add a block to today'"'"'s day note (Dias/YYYY-MM-DD - <panel name>.md next to the panel) and patch the panel (tick the checklist, set proxima_acao). Questions and short chats do not touch it.'
BEST=""
TIE=""
CACHE=""
CACHE_LOADED=""

strip_slash() { # drops trailing slashes (keeps a lone "/")
  local p=$1
  while [[ $p == */ && $p != / ]]; do p=${p%/}; done
  printf '%s' "$p"
}
under() { [[ $1 == "$2" || $1 == "$2"/* ]]; } # $1 is $2 or inside it

frontmatter() { # only the block between the --- on line 1 and the next ---
  awk 'NR == 1 { if ($0 !~ /^---[ \t\r]*$/) exit; next } /^---[ \t\r]*$/ { exit } { print }' "$1"
}
body() { # everything after the frontmatter
  awk 'NR == 1 && /^---[ \t\r]*$/ { fm = 1; next } fm && /^---[ \t\r]*$/ { fm = 0; next } fm { next } { print }' "$1"
}
fm_field() { # file key -> scalar without quotes; wrapped and `>` / `|` block values are joined with single spaces
  frontmatter "$1" | awk -v k="$2" -v q="'" '
    $0 ~ ("^" k ":") && !on {
      v = $0; sub("^" k ":[ \t]*", "", v); gsub(/[ \t\r]+$/, "", v)
      if (v ~ /^[>|][-+]?$/) v = ""
      on = 1; found = 1; next
    }
    on && /^[ \t]*$/ { next }
    on && /^[ \t]+[^ \t]/ { s = $0; gsub(/^[ \t]+|[ \t\r]+$/, "", s); v = (v == "" ? s : v " " s); next }
    on { exit }
    END {
      if (!found) exit
      gsub("^[\"" q "]|[\"" q "]$", "", v)
      print v
    }'
}
fm_list() { # file key -> one item per line (block, inline or scalar; wrapped items joined), quotes off, ~ expanded, no trailing /
  frontmatter "$1" | awk -v k="$2" -v q="'" -v home="$HOME" '
    function clean(s) {
      gsub(/^[ \t]+|[ \t\r]+$/, "", s)
      gsub("^[\"" q "]|[\"" q "]$", "", s)
      if (s ~ /^~(\/|$)/) s = home substr(s, 2)
      sub(/\/+$/, "", s)
      if (s != "") print s
    }
    function add(s) { gsub(/^[ \t]+|[ \t\r]+$/, "", s); cur = (cur == "" ? s : cur " " s) }
    function flush(  v, n, i, a) {
      if (st == 1 && cur ~ /^\[/) {
        v = cur; sub(/^\[/, "", v); sub(/\][ \t]*$/, "", v)
        n = split(v, a, ",")
        for (i = 1; i <= n; i++) clean(a[i])
      } else if (st) clean(cur)
      st = 0; cur = ""
    }
    $0 ~ ("^" k ":") {
      flush()
      v = $0; sub("^" k ":[ \t]*", "", v); gsub(/[ \t\r]+$/, "", v)
      if (v == "") { st = 2; next }
      st = 1
      if (v !~ /^[>|][-+]?$/) add(v)
      next
    }
    st && /^[ \t]*$/ { next }
    st == 2 && /^[ \t]*-[ \t]+/ { flush(); st = 2; v = $0; sub(/^[ \t]*-[ \t]+/, "", v); add(v); next }
    st && /^[ \t]+[^ \t]/ { add($0); next }
    st { flush() }
    END { flush() }'
}

callout() { # first "Agora" / "Hoje, na ordem" callout of the body, without the title line or the leading ">"
  body "$1" | awk '
    /^[ \t]*```/ { fence = !fence; if (on) exit; next }
    fence { next }
    on { if ($0 ~ /^>/) { sub(/^> ?/, ""); if ($0 != "") print; next } exit }
    /^> \[![a-z-]+\][+-]? *(Agora|Hoje, na ordem)/ { on = 1 }'
}
open_items() { # up to 10 "- [ ] ..." lines outside fenced blocks
  body "$1" | awk '/^[ \t]*```/ { fence = !fence; next } fence { next } /^- \[ \] / { if (n < 10) { print; n++ } }'
}
recent_log() { # last 3 "- " lines of "## Log"
  body "$1" | awk '
    /^[ \t]*```/ { fence = !fence; next }
    fence { next }
    /^## / { inlog = ($0 ~ /^## Log[ \t]*$/); next }
    inlog && /^- / { buf[++n] = $0 }
    END { for (i = (n > 3 ? n - 2 : 1); i <= n; i++) print buf[i] }'
}
day_note() { # panel -> path of its newest day note (<panel dir>/Dias/YYYY-MM-DD - <panel basename>.md), or nothing
  local f=$1 dir base d name suffix stamp best
  dir=$(dirname "$f")
  base=$(basename "$f" .md)
  d="$dir/Dias"
  [ -d "$d" ] || return 0
  suffix=" - $base.md"
  best=$(
    for name in "$d"/*; do
      [ -f "$name" ] || continue
      name=${name##*/}
      [[ $name == *"$suffix" ]] || continue
      stamp=${name%"$suffix"}
      [[ $stamp =~ ^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$ ]] || continue
      printf '%s\n' "$stamp"
    done | LC_ALL=C sort | tail -n 1
  )
  [ -n "$best" ] && printf '%s' "$d/$best$suffix"
  return 0
}
last_block() { # day note -> its last "## " block (heading and following lines), at most 15 lines, trailing blanks dropped
  body "$1" | awk '
    /^[ \t]*```/ { fence = !fence }
    !fence && /^## / { n = 0 }
    { buf[++n] = $0 }
    END {
      while (n > 0 && buf[n] ~ /^[ \t\r]*$/) n--
      if (n > 15) n = 15
      for (i = 1; i <= n; i++) print buf[i]
    }'
}
parent_note() { # file -> absolute path of the note `pai: "[[Name]]"` points to (first in path order), or nothing
  local pai name first
  pai=$(fm_field "$1" pai)
  [[ $pai == '[['* ]] || return 0
  name=$(printf '%s' "$pai" | sed -E 's/^\[\[//; s/\]\].*$//; s/[|#].*$//')
  [ -n "$name" ] || return 0
  first=$(find "$DIR" -name "$name.md" -type f -print0 2>/dev/null | LC_ALL=C sort -z | { IFS= read -r -d '' f; printf '%s' "$f"; })
  printf '%s' "$first"
}

load_cache() { # CACHE: "<note>\t<folder>" lines for every project note, in path order
  [ -z "$CACHE_LOADED" ] || return 0
  CACHE_LOADED=1
  local f p tab=$'\t' nl=$'\n'
  while IFS= read -r -d '' f; do
    [ "$(fm_field "$f" tipo)" = projeto ] || continue
    while IFS= read -r p; do
      [ -n "$p" ] && CACHE="$CACHE$f$tab$p$nl"
    done < <(fm_list "$f" pastas)
  done < <(find "$DIR" -name '*.md' ! -name '.*' -type f -print0 2>/dev/null | LC_ALL=C sort -z)
  return 0
}
best_note() { # dir -> BEST (winning note or empty), TIE (the other note of a length tie or empty)
  BEST=""
  TIE=""
  local c=$1 bl=-1 f p
  load_cache
  while IFS=$'\t' read -r f p; do
    [ -n "$f" ] && [ -n "$p" ] || continue
    under "$c" "$p" || continue
    if [ "${#p}" -gt "$bl" ]; then
      BEST=$f
      TIE=""
      bl=${#p}
    elif [ "${#p}" -eq "$bl" ] && [ "$f" != "$BEST" ] && [ -z "$TIE" ]; then
      TIE=$f
    fi
  done <<<"$CACHE"
  return 0
}

section() { # title content -> blank line, title, content (nothing when content is empty)
  [ -n "$2" ] && printf '\n\n%s\n%s' "$1" "$2"
  return 0
}
render() { # note -> context text for BEST/TIE
  local f=$1 st br na line="" pf t head dn
  st=$(fm_field "$f" status)
  br=$(fm_field "$f" branch)
  na=$(fm_field "$f" proxima_acao)
  [ -n "$st" ] && line="Status: $st"
  [ -n "$br" ] && line="${line:+$line · }Branch: $br"
  [ -n "$na" ] && line="${line:+$line · }Next action: $na"
  pf=$(parent_note "$f")
  head="Project panel (Obsidian vault): ${f#"$VAULT"/}"
  [ -n "$pf" ] && head="$head"$'\n'"Parent panel: ${pf#"$VAULT"/}"
  [ -n "$line" ] && head="$head"$'\n'"$line"
  [ -n "$TIE" ] && head="$head"$'\n'"Warning: ${TIE#"$VAULT"/} also claims this folder; using the one above."
  head="$head$(section 'Now:' "$(callout "$f")")"
  [ -n "$pf" ] && head="$head$(section 'Parent now:' "$(callout "$pf")")"
  head="$head$(section 'Open items:' "$(open_items "$f")")"
  dn=$(day_note "$f")
  if [ -n "$dn" ]; then
    head="$head$(section "Last day (${dn#"$VAULT"/}):" "$(last_block "$dn")")"
  else
    head="$head$(section 'Recent log:' "$(recent_log "$f")")"
  fi
  if [ "${#head}" -gt "$MAX" ]; then
    head="${head:0:MAX}…(truncated)"
  fi
  t="$head"$'\n\n'"$RULE"
  printf '%s' "$t"
}

offer() { # toplevel -> offer text, or nothing when the folder is out of scope or ignored
  local top=$1 common mainrepo="" r p in_roots=""
  common=$(git -c core.fsmonitor=false -C "$top" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || common=""
  [ -n "$common" ] && mainrepo=$(strip_slash "$(dirname "$common")")
  while IFS= read -r r; do
    r=$(strip_slash "$r")
    [ -n "$r" ] && under "$top" "$r" && in_roots=1
  done < <(printf '%s\n' "$ROOTS" | tr ':' '\n')
  [ -n "$in_roots" ] || return 0
  if [ -f "$IGNORE" ]; then
    while IFS= read -r p || [ -n "$p" ]; do
      p=${p%$'\r'}
      case $p in '' | '#'*) continue ;; esac
      case $p in '~' | '~/'*) p="$HOME${p#\~}" ;; esac
      p=$(strip_slash "$p")
      [ -n "$p" ] || continue
      under "$top" "$p" && return 0
      [ -n "$mainrepo" ] && under "$mainrepo" "$p" && return 0
    done <"$IGNORE"
  fi
  printf 'No project panel in the Obsidian vault for %s. Offer once to create one with the project-panel skill (a new project, or a front of an existing one). If Daniel declines, append %s to %s.' "$top" "$top" "$IGNORE"
}

main() {
  local in cwd src common top text
  in=$(cat)
  cwd=$(jq -r '.cwd // empty' <<<"$in" 2>/dev/null) || return 0
  src=$(jq -r '.source // empty' <<<"$in" 2>/dev/null) || src=""
  [ -n "$cwd" ] || return 0
  [ -d "$DIR" ] || return 0
  cwd=$(strip_slash "$cwd")
  best_note "$cwd"
  if [ -z "$BEST" ]; then
    common=$(git -c core.fsmonitor=false -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || common=""
    [ -n "$common" ] && best_note "$(strip_slash "$(dirname "$common")")"
  fi
  if [ -n "$BEST" ]; then
    text=$(render "$BEST")
  else
    case $src in '' | startup | resume) ;; *) return 0 ;; esac # offer once per session, not after /clear or /compact
    top=$(git -c core.fsmonitor=false -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || top=""
    [ -n "$top" ] || return 0
    text=$(offer "$(strip_slash "$top")")
  fi
  [ -n "$text" ] || return 0
  # Drop any invalid UTF-8 (a cut in the middle of a character) so jq always gets clean text.
  text=$(printf '%s' "$text" | iconv -c -f UTF-8 -t UTF-8 2>/dev/null) || return 0
  jq -nc --arg ctx "$text" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
}

out=$(main 2>/dev/null) || out=""
[ -n "$out" ] && printf '%s\n' "$out"
exit 0
