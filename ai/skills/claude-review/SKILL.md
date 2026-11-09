---
name: claude-review
description: Pede uma segunda opinião do Claude Code (outro modelo) sobre o diff atual antes de commitar ou abrir PR. Use quando o Daniel pedir "revisa com o claude", "segunda opinião", ou ao terminar uma mudança grande antes de dizer que está pronto.
---

# Review cruzado com o Claude

Um modelo revisando o código do outro pega bugs que o autor não vê.

1. Monte o diff alvo: `git diff HEAD` (não commitado) ou `git diff <base>...HEAD` (branch).
2. Rode o Claude em modo não interativo e só leitura:
   ```bash
   claude -p "Revise o diff de 'git diff HEAD' neste repo. Foque em bugs de corretude, segurança e dados pessoais (LGPD); ignore estilo. Para cada achado: arquivo:linha, o problema, cenário concreto que quebra." \
     --allowedTools "Bash(git diff*)" "Bash(git log*)" "Read" "Grep" "Glob" \
     --permission-mode dontAsk
   ```
3. Confira cada apontamento no código antes de aceitar; descarte falsos positivos.
4. Responda ao Daniel com uma tabela curta: apontamento → real/falso positivo → o que fazer.
   Só aplique correções se ele pedir.
