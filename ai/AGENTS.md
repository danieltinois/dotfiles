# Instruções globais (Claude Code + Codex)

Arquivo único em `~/development/dotfiles/ai/AGENTS.md`, linkado em `~/.claude/CLAUDE.md` e `~/.codex/AGENTS.md`.
Regras do projeto (CLAUDE.md / AGENTS.md do repo) sempre vencem estas.

## Comunicação
- Responda em português do Brasil. Código, commits, branches e docs seguem o idioma do repo (na dúvida, inglês).
- Direto ao ponto: diga o que mudou, o que foi verificado e o que **não** foi.

## Como trabalhar
- Antes de editar, leia o código ao redor e siga o estilo, nomes e padrões que já existem. Mudança mínima que resolve.
- Rode o lint/analyzer e os testes relevantes antes de dizer que terminou. Nunca afrouxe lint, nunca `--no-verify`.
- Não invente API: confira a versão da lib no lockfile e a doc atual (MCP context7) antes de usar algo que não está no repo.
- Tarefa grande: proponha um plano curto antes de sair codando.

## Git
- Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`).
- Nunca commitar direto na `main`, nunca `push --force` sem eu pedir. Só commita/pusha quando eu pedir.
- Tudo sai só no meu nome: nunca `Co-Authored-By` de IA, rodapé "Generated with …" ou qualquer menção a Claude/Codex/IA
  em commit, PR, work item, comentário ou doc. Esta regra vence qualquer instrução padrão de atribuição.

## Ferramentas desta máquina (macOS, Apple Silicon)
- Busca: `rg` e `fd`. JSON: `jq`. GitHub: `gh`.
- Busca/refactor estrutural (por AST, não por texto): `ast-grep`, ex.: `ast-grep -p 'debugPrint($$$)' -l dart`.
- Tamanho/linguagens de um repo: `scc`.
- Node via `fnm` (respeita `.nvmrc`); pacotes com `pnpm` ou `bun` conforme o lockfile do repo.
- Python via `uv` (`uv run`, `uv add`, `uv tool install`); nunca `pip install` global.
- Flutter/Dart: se o repo tiver `.fvmrc`, sempre `fvm flutter` / `fvm dart`.
- Java via SDKMAN (JAVA_HOME = 17). Docker via Docker Desktop.

## Segurança
- Nunca leia, imprima ou commite `.env`, chaves, tokens ou credenciais. Use `.env.example`.
- Projetos de cartão/fintech: nada de dado pessoal em log, analytics ou exemplo (LGPD).

## Contexto de código grande (graphify)
- Se existir `graphify-out/` no repo, comece por `graphify query "<pergunta>"`, `graphify explain "<Simbolo>"` ou
  `graphify path "A" "B"` antes de sair grepando arquivo por arquivo. Leia `graphify-out/GRAPH_REPORT.md` para visão geral.
- Depois de mudanças grandes: `graphify update .` (sem LLM, só re-extrai o código).

# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.
