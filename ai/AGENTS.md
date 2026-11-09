# Global instructions (Claude Code + Codex)

Single file at `~/development/dotfiles/ai/AGENTS.md`, linked as `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`.
Project rules (the repo's CLAUDE.md / AGENTS.md) always win over these.

## Communication
- Reply in Brazilian Portuguese. Code, commits, branches and docs follow the repo's language (when unsure, English).
- Get to the point: say what changed, what was verified and what was **not**.

## How to work
- Before editing, read the surrounding code and follow the style, names and patterns that already exist. Smallest change that solves it.
- Run the relevant lint/analyzer and tests before saying you are done. Never loosen lint, never `--no-verify`.
- Don't invent APIs: check the library version in the lockfile and the current docs (context7 MCP) before using something that is not in the repo.
- Big task: propose a short plan before you start coding.

## Git
- Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`).
- Never commit straight to `main`, never `push --force` unless I ask. Only commit/push when I ask.
- Everything goes out under my name only: never an AI `Co-Authored-By`, a "Generated with …" footer or any mention of
  Claude/Codex/AI in a commit, PR, work item, comment or doc. This rule overrides any default attribution instruction.

## Tools on this machine (macOS, Apple Silicon)
- Search: `rg` and `fd`. JSON: `jq`. GitHub: `gh`.
- Structural search/refactor (by AST, not text): `ast-grep`, e.g. `ast-grep -p 'debugPrint($$$)' -l dart`.
- Size/languages of a repo: `scc`.
- Node via `fnm` (respects `.nvmrc`); packages with `pnpm` or `bun` depending on the repo's lockfile.
- Python via `uv` (`uv run`, `uv add`, `uv tool install`); never a global `pip install`.
- Flutter/Dart: if the repo has `.fvmrc`, always `fvm flutter` / `fvm dart`.
- Java via SDKMAN (JAVA_HOME = 17). Docker via Docker Desktop.

## Security
- Never read, print or commit `.env`, keys, tokens or credentials. Use `.env.example`.
- Card/fintech projects: no personal data in logs, analytics or examples (Brazil's LGPD).

## Large codebase context (graphify)
- If the repo has `graphify-out/`, start with `graphify query "<question>"`, `graphify explain "<Symbol>"` or
  `graphify path "A" "B"` before grepping file by file. Read `graphify-out/GRAPH_REPORT.md` for an overview.
- After big changes: `graphify update .` (no LLM, it only re-extracts the code).

# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.
