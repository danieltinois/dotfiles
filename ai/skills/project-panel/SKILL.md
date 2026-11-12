---
name: project-panel
description: Creates and updates a project panel (a note with `tipo: projeto`) in Daniel's Obsidian vault, so any session can pick the work up where it stopped. Use when Daniel asks "cria/atualiza o painel", "onde eu parei?", "/project-panel", "create the project panel", "update the project panel", or when the session context starts with `Project panel (Obsidian vault)` or `No project panel`.
---

# Project panel

A panel is one vault note per project (or per front of a project) holding the current state: what is happening now,
the next action, open items and a short log. The SessionStart hook (`ai/claude/scripts/project-panel.sh`) loads it into
the session. This skill creates it and keeps it current.

## Before writing

1. Read `CLAUDE.md` at the vault root (`~/Obsidian/Cerebro`, or `$CEREBRO_VAULT`) and follow the `cerebro` skill for the
   general vault rules.
2. Write through the `obsidian` MCP: `read_note`, `write_note`, `patch_note`, `update_frontmatter`. If it is not
   available, fall back to direct Read/Write/Edit on the vault files.
3. Notes are in pt-BR, use `[[wikilinks]]` and dates as `YYYY-MM-DD`.

## Fields

Frontmatter follows the template `99 Sistema/Templates/Projeto.md`, plus:

| Field | Holds |
| --- | --- |
| `pastas` | Folders the panel claims, absolute or starting with `~`, one list item per folder. The hook matches the longest one that is a prefix of the session's folder |
| `repo` | Repository name or remote |
| `branch` | Branch the work is on |
| `proxima_acao` | One line: the next concrete step |
| `pai` | `"[[Main note]]"`, only on a front (see below) |

## Session starts with a panel

The context shows `Project panel (Obsidian vault): <vault-relative note path>` with `Status`, `Branch`, `Next action`,
`Now`, `Open items` and `Recent log` (plus `Parent panel` and `Parent now` on a front). Work from it. Read the full
note only when you need more than the injected summary.

## Session starts with no panel

The context says `No project panel in the Obsidian vault for <toplevel>.` Offer once, in one sentence, to create one.

- Daniel accepts: follow **Create**.
- Daniel declines: append `<toplevel>` as one line to the ignore file, `~/.config/claude-hooks/panel-ignore`, or
  `$PANEL_IGNORE_FILE` when set. Create the file and its folder if missing. Never offer again for that folder.

## Create

1. Ask whether it is a new project or a front of a project that already has a panel.
   - **New project:** `10 Projetos/<Name>/<Name>.md`.
   - **Front:** a sibling note in the same folder, with `pai: "[[Main note]]"`.
2. Start from the template `Projeto.md` and fill in `pastas`, `repo`, `branch` and `proxima_acao` from the current
   folder and `git`. Ask only for what you cannot read.
3. Body sections, in this order:
   - Callout `> [!brain] Agora`: two or three lines on where things stand.
   - A commands table (build, test, lint, run), only if it is a repo. Take the commands from the repo's own docs.
   - `## Próximas ações`: `- [ ]` items, the first one matching `proxima_acao`.
   - `## Log`: starts empty or with one `- YYYY-MM-DD — created` style line.
   - `## Recursos e links`.
4. **Second front:** the first note becomes the hub. Patch it to add a callout `> [!brain] Hoje, na ordem` (the fronts
   in the order to work on them) and the embed `![[Frentes.base]]` (base: `99 Sistema/Bases/Frentes.base`).
5. Add a link to the new note under "Destaques" in `10 Projetos/Mapa - Projetos.md`, with `patch_note`.
6. Tell Daniel the note path. The hook picks the panel up on the next session start.

## Update

When: a piece of work that changed code, a card, a PR or a decision is done. Not for questions, reading or short chats.

Patch only, one change at a time:

1. Front (or standalone panel): tick finished items `- [x]`, add new ones, set `proxima_acao`, rewrite the `Agora`
   callout, and add one line `- YYYY-MM-DD — what happened and why it matters` at the end of `## Log`.
2. Hub: if the order or the state of the fronts changed, patch `Hoje, na ordem`.
3. Say in one line what changed in the panel.

## Never

- Rewrite or delete a note. Patch the part that changed.
- Put secrets, tokens, dotenv contents or third-party personal data in the vault. Point to the variable or the file.
- Touch cards or PRs because of a panel update. Only the panel changes.
- Update because of a question.
