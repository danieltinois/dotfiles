#!/usr/bin/env bash
# Status line do Claude Code (2 linhas)
#  1: modelo · pasta · branch (* = alterações) · ◆ se o repo tem grafo do graphify
#  2: barra de contexto · limite de 5h · linhas +/−
input=$(cat)
j() { jq -r "$1" <<<"$input"; }
R=$'\e[0m' DIM=$'\e[2m' CYAN=$'\e[36m' MAG=$'\e[35m' GRN=$'\e[32m' YEL=$'\e[33m' RED=$'\e[31m'

# Repo de terceiros não executa nada daqui: sem fsmonitor do .git/config, sem lock no índice.
g() { git --no-optional-locks -c core.fsmonitor=false -C "$dir" "$@" 2>/dev/null; }
# Nome de pasta/branch pode trazer sequência de escape de terminal.
clean() { tr -d '[:cntrl:]' <<<"$1"; }

model=$(clean "$(j '.model.display_name // "?"')")
dir=$(j '.workspace.current_dir // .cwd // ""')
line1="${MAG}${model}${R} ${DIM}·${R} ${CYAN}$(clean "${dir##*/}")${R}"
if branch=$(g symbolic-ref --short HEAD); then
  branch=$(clean "$branch")
  [[ -n $(g status --porcelain | head -1) ]] && branch="$branch*"
  line1+=" ${DIM}·${R} ${GRN} ${branch}${R}"
  root=$(g rev-parse --show-toplevel)
  [[ -f $root/graphify-out/graph.json ]] && line1+=" ${YEL}◆${R}"
fi

color() { (( $1 >= 80 )) && echo "$RED" || { (( $1 >= 50 )) && echo "$YEL" || echo "$GRN"; }; }
pct=$(j '.context_window.used_percentage // 0' | cut -d. -f1)
filled=$(( pct / 10 )); bar=""
for i in {1..10}; do (( i <= filled )) && bar+="█" || bar+="░"; done
line2="$(color "$pct")${bar} ${pct}%${R} ctx"

five=$(j '.rate_limits.five_hour.used_percentage // empty' | cut -d. -f1)
[[ -n $five ]] && line2+=" ${DIM}·${R} $(color "$five")5h ${five}%${R}"
add=$(j '.cost.total_lines_added // 0'); del=$(j '.cost.total_lines_removed // 0')
(( add + del > 0 )) && line2+=" ${DIM}·${R} ${GRN}+${add}${R} ${RED}-${del}${R}"

printf '%s\n%s' "$line1" "$line2"
