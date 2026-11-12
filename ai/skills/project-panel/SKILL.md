---
name: project-panel
description: Creates and updates a project panel (a note with `tipo: projeto`) in Daniel's Obsidian vault, so any session can pick the work up where it stopped. Use when Daniel asks "cria/atualiza o painel", "onde eu parei?", "/project-panel", "create the project panel", "update the project panel", or when the session context starts with `Project panel (Obsidian vault)` or `No project panel`.
---

# Project panel

A panel is one vault note per project (or per front of a project) holding the current state: what is happening now,
the next action and open items. The work history lives in one note per day. The SessionStart hook (`ai/claude/scripts/project-panel.sh`) loads it into
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

### Day note

One note per day per panel, in a `Dias/` folder next to the panel (created with the first day note):
`<panel folder>/Dias/YYYY-MM-DD - <panel basename>.md`, e.g. `10 Projetos/X/Front A.md` ->
`10 Projetos/X/Dias/2026-11-12 - Front A.md`.

```
---
tipo: dia
data: YYYY-MM-DD
painel: "[[<panel basename>]]"
tags: [dia]
---
# <panel basename> — YYYY-MM-DD

## HH:MM · <short topic>
- what changed
- Conferido: what was verified
- Falta: what is left
```

One `## HH:MM · <topic>` block per work session, newest last.

## Session starts with a panel

The context shows `Project panel (Obsidian vault): <vault-relative note path>` with `Status`, `Branch`, `Next action`,
`Now`, `Open items` and `Last day (<day note path>)` (the last block of the newest day note; `Recent log` instead when the panel has no day note yet) (plus `Parent panel` and `Parent now` on a front). Work from it. Read the full
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
   - `## Dias`: contains only `![[Dias.base]]` (a vault base listing the panel's day notes). No `## Log`.
   - `## Recursos e links`.
4. **Second front:** the first note becomes the hub. Patch it to add a callout `> [!brain] Hoje, na ordem` (the fronts
   in the order to work on them) and the embed `![[Frentes.base]]` (base: `99 Sistema/Bases/Frentes.base`).
5. Add a link to the new note under "Destaques" in `10 Projetos/Mapa - Projetos.md`, with `patch_note`.
6. Tell Daniel the note path. The hook picks the panel up on the next session start.

## Update

When: a piece of work that changed code, a card, a PR or a decision is done. Not for questions, reading or short chats.

Patch only, one change at a time:

1. Work log: append a `## HH:MM · <topic>` block to today's day note (see **Day note**). Create the note, and the
   `Dias/` folder, from the format above if missing. Never rewrite earlier blocks.
2. Front (or standalone panel): tick finished items `- [x]`, add new ones, set `proxima_acao` and rewrite the `Agora`
   callout. Do not add lines to the panel's Log: a panel that still has `## Log` keeps it read-only until it is migrated.
3. Hub: if the order or the state of the fronts changed, patch `Hoje, na ordem`.
4. Say in one line what changed in the panel.

## Never

- Rewrite or delete a note. Patch the part that changed.
- Put secrets, tokens, dotenv contents or third-party personal data in the vault. Point to the variable or the file.
- Touch cards or PRs because of a panel update. Only the panel changes.
- Update because of a question.
