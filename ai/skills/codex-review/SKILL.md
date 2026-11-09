---
name: codex-review
description: Asks Codex (another model) for a second opinion on the current diff before committing or opening a PR. Use when Daniel asks for "revisa com o codex", "segunda opinião", "/codex-review", "review with codex", "second opinion", or when finishing a big change before saying it is ready.
---

# Cross-review with Codex

One model reviewing the other's code catches bugs the author does not see.

1. Pick the target:
   - Uncommitted changes → `codex review --uncommitted`
   - Whole branch → `codex review --base <base-branch>` (usually `main` or `develop`; check with `git branch -a`)
   - One commit → `codex review --commit <sha>`
2. Run it in the background (it can take a few minutes) and wait for the notification, without polling:
   `codex review --uncommitted "Focus on correctness bugs, security and personal data (LGPD). Ignore style." > "$TMPDIR/codex-review.md" 2>&1`
3. Read the result and treat each finding rigorously (skill `superpowers:receiving-code-review`):
   confirm in the code that it is real before accepting it; don't agree just to agree.
4. Answer Daniel with a short table: finding → real/false positive → what to do.
   Only apply fixes if he asks.
