---
name: claude-review
description: Asks Claude Code (another model) for a second opinion on the current diff before committing or opening a PR. Use when Daniel asks for "revisa com o claude", "segunda opinião", "review with claude", "second opinion", or when finishing a big change before saying it is ready.
---

# Cross-review with Claude

One model reviewing the other's code catches bugs the author does not see.

1. Build the target diff: `git diff HEAD` (uncommitted) or `git diff <base>...HEAD` (branch).
2. Run Claude non-interactively and read-only:
   ```bash
   claude -p "Review the diff from 'git diff HEAD' in this repo. Focus on correctness bugs, security and personal data (LGPD); ignore style. For each finding: file:line, the problem, a concrete scenario that breaks." \
     --allowedTools "Bash(git diff*)" "Bash(git log*)" "Read" "Grep" "Glob" \
     --permission-mode dontAsk
   ```
3. Check every finding in the code before accepting it; drop false positives.
4. Answer Daniel with a short table: finding → real/false positive → what to do.
   Only apply fixes if he asks.
