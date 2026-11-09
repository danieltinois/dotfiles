---
name: codex-review
description: Pede uma segunda opinião do Codex (outro modelo) sobre o diff atual antes de commitar ou abrir PR. Use quando o Daniel pedir "revisa com o codex", "segunda opinião", "/codex-review", ou ao terminar uma mudança grande antes de dizer que está pronto.
---

# Review cruzado com o Codex

Um modelo revisando o código do outro pega bugs que o autor não vê.

1. Descubra o alvo:
   - Mudanças não commitadas → `codex review --uncommitted`
   - Branch inteira → `codex review --base <branch-base>` (normalmente `main` ou `develop`; confira com `git branch -a`)
   - Um commit → `codex review --commit <sha>`
2. Rode em background (pode levar alguns minutos) e espere a notificação, sem ficar consultando:
   `codex review --uncommitted "Foque em bugs de corretude, segurança e dados pessoais (LGPD). Ignore estilo." > "$TMPDIR/codex-review.md" 2>&1`
3. Leia o resultado e trate cada apontamento com rigor (skill `superpowers:receiving-code-review`):
   confirme no código se é real antes de aceitar; não concorde só por concordar.
4. Responda ao Daniel com uma tabela curta: apontamento → real/falso positivo → o que fazer.
   Só aplique correções se ele pedir.
