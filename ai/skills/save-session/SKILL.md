---
name: save-session
description: Saves the session state to a handoff file (what worked with evidence, what failed and why, what is left, the exact next step) so the work can continue later in a clean session, and resumes from it. Use when Daniel asks for "salva a sessão", "faz o resumo da sessão", "handoff", "/save-session", "save the session", when the context is close to its limit, or "retoma a sessão", "continua de onde parei", "resume the session".
---

# Session handoff

A new session with a good summary gets more done than an old compacted one.
The value is in "what did not work": it is what stops the next session from repeating the mistake.

## Save

1. Gather context: `git status`, `git diff --stat`, `git log --oneline` for the session's commits,
   and what was tried, decided and verified in the conversation. If the last test/lint result is not
   clear, run it again. Do not record as "worked" anything you did not see working.
2. Where to save:
   - Inside a git repo: `<root>/.claude/sessions/YYYY-MM-DD-<short-topic>.md`
     (`.claude/sessions/` is in the global gitignore, it never goes into the repo).
   - Outside a repo: `~/.claude/session-data/YYYY-MM-DD-<short-topic>.md`.
   - Same day and same topic: update the existing file instead of creating another one.
3. Fill in the template below, in the language Daniel uses with you, without skipping sections
   (an empty section gets "nothing").
4. No secrets or personal data (LGPD): no tokens, passwords, CPF, card numbers, or customer e-mails or
   phone numbers. Point to the file or the variable, never the value.
5. Show Daniel the path and the content and ask whether anything is missing.

```markdown
# Session: <topic> (YYYY-MM-DD)

**Repo / branch:** <repo> / <branch> · **Last commit:** <short sha> <message>

## Goal
<1–3 paragraphs: what it is, why, where it fits. Someone with no memory of this session must understand it.>

## What worked (with evidence)
- **<item>** — evidence: <test X passed / `fvm flutter analyze` clean / tested on the simulator / API returned 200>
<Without evidence, it goes to "Not tested".>

## What did not work (and why)
- **<approach>** — failed because: <exact error or concrete reason>

## Not tested / not tried yet
- <pending idea or check, specific enough to run>

## File status
| File | Status | Note |
| --- | --- | --- |
| `path/to/file` | done · in progress · broken · not started | <what is left> |

## Decisions
- **<decision>** — reason: <why this one and not the alternative>

## Blockers and open questions
- <what depends on someone else or on an answer>

## Exact next step
<The first thing to do when resuming, with no need to think about where to start.>
```

## Resume

1. No path given: use the most recent file in the current repo's `.claude/sessions/`; if there is none,
   the most recent one in `~/.claude/session-data/`. Path given: read exactly that file.
2. Before touching code, check that the state matches: branch, `git status`, `git log` since the
   recorded commit, the files in the table. Say what changed since the handoff.
3. Summarize in 3–5 lines: goal, where it stopped, next step. Do not retry anything listed under
   "What did not work" without a new reason.
4. If Daniel only asked to resume, wait for his go-ahead; if he asked to continue, take the next step.
