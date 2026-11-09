---
name: save-session
description: Salva o estado da sessão num arquivo de handoff (o que funcionou com evidência, o que falhou e por quê, o que falta, próximo passo exato) para continuar depois numa sessão limpa, e retoma a partir dele. Use quando o Daniel pedir "salva a sessão", "faz o resumo da sessão", "handoff", "/save-session", quando o contexto estiver perto do limite, ou "retoma a sessão", "continua de onde parei".
---

# Handoff de sessão

Uma sessão nova com um bom resumo rende mais que uma sessão velha compactada.
O valor está em "o que não funcionou": é o que impede a próxima sessão de repetir o erro.

## Salvar

1. Junte o contexto: `git status`, `git diff --stat`, `git log --oneline` dos commits da sessão,
   e o que foi tentado, decidido e verificado na conversa. Se o último resultado de teste/lint não
   estiver claro, rode de novo. Não registre como "funcionou" o que você não viu funcionar.
2. Onde salvar:
   - Dentro de um repo git: `<raiz>/.claude/sessions/AAAA-MM-DD-<assunto-curto>.md`
     (`.claude/sessions/` está no gitignore global, nunca vai pro repo).
   - Fora de repo: `~/.claude/session-data/AAAA-MM-DD-<assunto-curto>.md`.
   - Mesmo dia e mesmo assunto: atualize o arquivo existente em vez de criar outro.
3. Escreva no modelo abaixo, sem pular seção (seção sem conteúdo leva "nada").
4. Nada de segredo ou dado pessoal (LGPD): sem token, senha, CPF, número de cartão, e-mail ou
   telefone de cliente. Aponte o arquivo ou a variável, nunca o valor.
5. Mostre o caminho e o conteúdo ao Daniel e pergunte se falta algo.

```markdown
# Sessão: <assunto> (AAAA-MM-DD)

**Repo / branch:** <repo> / <branch> · **Último commit:** <sha curto> <mensagem>

## Objetivo
<1–3 parágrafos: o que é, por que, onde se encaixa. Alguém sem memória desta sessão tem que entender.>

## O que funcionou (com evidência)
- **<item>** — evidência: <teste X passou / `fvm flutter analyze` limpo / testado no simulador / API respondeu 200>
<Sem evidência, vai para "Não testado".>

## O que não funcionou (e por quê)
- **<abordagem>** — falhou porque: <erro exato ou motivo concreto>

## Não testado / ainda não tentado
- <ideia ou verificação pendente, específica o bastante para executar>

## Estado dos arquivos
| Arquivo | Estado | Nota |
| --- | --- | --- |
| `caminho/arquivo` | pronto · em andamento · quebrado · não iniciado | <o que falta> |

## Decisões
- **<decisão>** — motivo: <por que esta e não a alternativa>

## Bloqueios e perguntas em aberto
- <o que depende de alguém ou de resposta>

## Próximo passo exato
<A primeira coisa a fazer ao retomar, sem precisar pensar onde começar.>
```

## Retomar

1. Sem caminho: use o arquivo mais recente de `.claude/sessions/` do repo atual; se não houver,
   o mais recente de `~/.claude/session-data/`. Com caminho: leia exatamente esse arquivo.
2. Antes de mexer em código, confira se o estado bate: branch, `git status`, `git log` desde o
   commit registrado, arquivos da tabela. Diga o que mudou desde o handoff.
3. Resuma em 3–5 linhas: objetivo, onde parou, próximo passo. Não tente de novo o que está em
   "O que não funcionou" sem um motivo novo.
4. Se o Daniel só pediu para retomar, espere o ok; se pediu para continuar, siga o próximo passo.
