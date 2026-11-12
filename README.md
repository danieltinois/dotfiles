# dotfiles

Daniel's dev setup (macOS, Apple Silicon), with a focus on running AI coding agents (Claude Code and Codex)
safely. Paths assume the repo lives at `~/development/dotfiles`; adjust them if you copy anything.

Guide and docs page, in English and Brazilian Portuguese: https://danieltinois.github.io/dotfiles/

| File | What it is | Where it is linked |
| --- | --- | --- |
| `Brewfile` | CLIs and apps | `brew bundle --file ~/development/dotfiles/Brewfile` |
| `macos.sh` | macOS preferences (Dock, Finder, keyboard) | run with `bash macos.sh` |
| `ghostty.config` | Terminal | `~/.config/ghostty/config` |
| `aerospace.toml` | Tiling window manager (also starts JankyBorders); modifier is ctrl+alt | `~/.config/aerospace/aerospace.toml` |
| `ai/AGENTS.md` | Global rules for the agents | `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` |
| `ai/claude/scripts/` | Claude Code hooks and status line | `~/.claude/scripts` |
| `ai/claude/sandbox.json` | Claude Code sandbox config | copy into `~/.claude/settings.json` |
| `ai/skills/codex-review` | Claude asks Codex for a review | `~/.claude/skills/codex-review` |
| `ai/skills/claude-review` | Codex asks Claude for a review | `~/.codex/skills/claude-review` |
| `ai/skills/save-session` | Session handoff (save and resume) | `~/.claude/skills/save-session` and `~/.codex/skills/save-session` |
| `ai/skills/project-panel` | Creates and updates the project panel in the Obsidian vault | `~/.claude/skills/project-panel` |

## Claude Code hooks (`~/.claude/settings.json`)

- `guard.sh` (PreToolUse, Bash/Read/Grep/Glob/Edit/Write/MultiEdit/NotebookEdit): blocks reading or searching
  `.env`/key files, `push --force`, `--no-verify`, AI attribution in commits/PRs, `rm -rf` on the root or home,
  and changing an existing lint/format/git-hook config (`analysis_options.yaml`, eslint, prettier, biome,
  lefthook, husky, ruff…). Creating a new config is fine; changing a lint rule is for a human to do by hand.
  For Grep/Glob it expands braces (with a cap) and tests whether each part of the glob could match a secret family
  (`.env`/`.env.<anything>`, `*.pem`/`.key`/…, `id_rsa`, `~/.ssh`, `~/.codex`…). It fails closed: `?` or `[` in a
  file name blocks, and with `*` only pieces that cannot form a secret pass (`*.dart` passes; `.*`, `.e*`,
  `*nv.local`, `s*.key` and `*.k*` do not). Known limit: `*.test.*` would match a `.env.test.local`; the strong
  barrier for that is the sandbox below.
- `format-on-edit.sh` (PostToolUse): formats the edited file with the project's own formatter. It only looks up
  to the repo root, and `uvx ruff` runs with `--no-config` (the repo does not choose where ruff comes from).
  Tools chosen by the repo (prettier from `node_modules`, the SDK from `.fvmrc`) only run for repos inside a
  trusted folder listed in `~/.config/claude-hooks/trusted-roots` (one per line; without the file,
  `~/development`). A repo cloned just to look at stays outside and nothing from it runs.
- `project-panel.sh` (SessionStart, matcher `startup|resume|clear|compact`, timeout 5 s): finds the vault note
  (`10 Projetos/**/*.md` with `tipo: projeto`) whose `pastas` is the longest prefix of the session folder and
  injects its state (next action, open items, the last block of the newest day note `Dias/YYYY-MM-DD - <panel>.md` next to the panel, or the panel's Log when there is none) as context, capped at `PANEL_MAX_CHARS` (default 4000).
  With no panel it asks the session to offer creating one, only inside `PANEL_ROOTS` and outside the folders
  listed in `PANEL_IGNORE_FILE`. Paths come from three environment variables: `CEREBRO_VAULT` (default
  `~/Obsidian/Cerebro`), `PANEL_ROOTS` (colon-separated, default `~/development`) and `PANEL_IGNORE_FILE`
  (default `~/.config/claude-hooks/panel-ignore`). It fails open: any error exits 0 with no output, so a
  session never breaks because of it. The `project-panel` skill creates and updates the panel. The "no panel"
  offer shows only on `startup` and `resume`, not after `/clear` or `/compact`. Register it under `hooks` in
  `~/.claude/settings.json`:

  ```json
  "SessionStart": [{ "matcher": "startup|resume|clear|compact",
    "hooks": [{ "type": "command", "command": "~/.claude/scripts/project-panel.sh", "timeout": 5 }] }]
  ```
- `statusline.sh`: `git` runs with `core.fsmonitor=false` and `--no-optional-locks` (a third-party `.git/config`
  executes nothing) and control characters are stripped from folder/branch names. If the repo itself defines
  clean/smudge filters (`filter.*` outside global/system config), it skips `git status` and shows `?` instead of `*`.

## Claude Code sandbox (`ai/claude/sandbox.json`)

The strong barrier. The hooks above filter text (which can be bypassed); the sandbox runs every Bash command
inside macOS Seatbelt and the OS itself denies access. Copy the `sandbox` block into `~/.claude/settings.json`.

- **Writes:** only the project folder, the temp dir and `~/.npm/_cacache` (content-addressed, checked on read).
  Deliberately left out: `~/.cache` (the zsh p10k prompt sources a script from there in every terminal),
  `~/.pub-cache`, `~/Library/pnpm` (on `PATH`, and the store is hardlinked into every project), `~/fvm` (the
  Flutter SDK), `~/.gradle`, `~/.bun`, Xcode's DerivedData and `~/.npm/_npx` (used by MCP servers via `npx`).
  Allowing writes there would let a sandboxed command plant something that later runs **outside** the sandbox.
- **Flutter and pnpm:** they need to write to those places, so they fail inside the sandbox and Claude asks to run
  them outside, one command at a time. To stop being asked, add `"fvm *", "flutter *", "dart *"` (or `"pnpm *"`)
  to `excludedCommands`; they then run with full access, as before the sandbox.
- **Reads:** everything except credentials: `~/.ssh`, `~/.aws`, `~/.gnupg`, `~/.docker`, `~/.kube`, `~/.azure`,
  `~/.config/gcloud`, `~/.npmrc`, `~/.netrc`, `~/.git-credentials`, `~/.codex/auth.json`, `~/.config/gh/hosts.yml`,
  Gradle and pub credentials. The `Read(...)` deny rules in `permissions` are added too (`.env`, `*.pem`,
  `*.key`…), so not even a script can read those files.
- **Network:** goes through a proxy with a domain list (GitHub, npm, PyPI, Azure DevOps). Outside manual mode, a
  host not on the list can still be approved by the auto-mode classifier; to always refuse, set
  `"network": {"strictAllowlist": true}`.
- **Outside the sandbox:** `docker` and `gh` (TLS issues on macOS), as the official docs recommend. Hooks, MCP
  servers and the status line also run outside (the sandbox only covers shell commands).
- Known limit: git credentials stored in the macOS Keychain are still reachable from inside the sandbox
  (`git push`/`fetch` over HTTPS needs them).
- `autoAllowBashIfSandboxed: false`: the sandbox does not change permission prompts, it only limits what a command
  can reach.

## New machine

```bash
brew bundle --file ~/development/dotfiles/Brewfile
bash ~/development/dotfiles/macos.sh
D=~/development/dotfiles
ln -sfn $D/ai/AGENTS.md ~/.claude/CLAUDE.md
ln -sfn $D/ai/AGENTS.md ~/.codex/AGENTS.md
ln -sfn $D/ai/claude/scripts ~/.claude/scripts
ln -sfn $D/ai/skills/codex-review ~/.claude/skills/codex-review
ln -sfn $D/ai/skills/claude-review ~/.codex/skills/claude-review
ln -sfn $D/ai/skills/save-session ~/.claude/skills/save-session
ln -sfn $D/ai/skills/save-session ~/.codex/skills/save-session
ln -sfn $D/ai/skills/project-panel ~/.claude/skills/project-panel
ln -sfn $D/ghostty.config ~/.config/ghostty/config
mkdir -p ~/.config/aerospace && ln -sfn $D/aerospace.toml ~/.config/aerospace/aerospace.toml
```

AeroSpace asks for Accessibility permission on first launch (System Settings > Privacy & Security > Accessibility).

`~/.claude/settings.json` is not symlinked because Claude Code rewrites that file itself.

## License

MIT
