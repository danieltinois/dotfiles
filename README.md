# dotfiles

Setup de dev do Daniel (macOS, Apple Silicon).

| Arquivo | O que é | Onde é linkado |
| --- | --- | --- |
| `Brewfile` | CLIs e apps | `brew bundle --file ~/development/dotfiles/Brewfile` |
| `macos.sh` | Preferências do macOS (Dock, Finder, teclado) | rodar com `bash macos.sh` |
| `ghostty.config` | Terminal | `~/.config/ghostty/config` |
| `ai/AGENTS.md` | Regras globais dos agentes | `~/.claude/CLAUDE.md` e `~/.codex/AGENTS.md` |
| `ai/claude/scripts/` | Hooks e statusline do Claude Code | `~/.claude/scripts` |
| `ai/skills/codex-review` | Claude pede review ao Codex | `~/.claude/skills/codex-review` |
| `ai/skills/claude-review` | Codex pede review ao Claude | `~/.codex/skills/claude-review` |
| `ai/skills/save-session` | Handoff de sessão (salvar e retomar) | `~/.claude/skills/save-session` e `~/.codex/skills/save-session` |

## Hooks do Claude Code (`~/.claude/settings.json`)

- `guard.sh` (PreToolUse, Bash/Read/Grep/Glob/Edit/Write/MultiEdit/NotebookEdit): bloqueia ler ou buscar em `.env`/chaves,
  `push --force`, `--no-verify`, atribuição de IA em commit/PR, `rm -rf` na raiz/home e alterar
  config de lint/format/git hooks que já existe (`analysis_options.yaml`, eslint, prettier, biome,
  lefthook, husky, ruff…). Criar uma config nova pode; mudar regra de lint, só o Daniel na mão.
  No Grep/Glob, expande as chaves (com teto) e testa se cada parte do glob casaria com uma família de segredo
  (`.env`/`.env.<algo>`, `*.pem`/`.key`/…, `id_rsa`, `~/.ssh`, `~/.codex`…). Falha fechado: `?` ou `[` no
  nome bloqueiam, e com `*` só passam os trechos que não podem formar um segredo (`*.dart` passa; `.*`, `.e*`,
  `*nv.local` e `*.k*` não). Limite aceito: `*.test.*` casaria um `.env.test.local`; a barreira forte é o `/sandbox`.
- `format-on-edit.sh` (PostToolUse): formata o arquivo editado com o formatter do projeto. Só procura
  até a raiz do repo, e o `uvx ruff` roda com `--no-config` (o repo não escolhe de onde o ruff vem).
  Ferramenta escolhida pelo repo (prettier do `node_modules`, SDK do `.fvmrc`) só roda em repo dentro de uma
  pasta confiável, listada em `~/.config/claude-hooks/trusted-roots` (uma por linha; sem o arquivo, vale
  `~/development`). Repo clonado só para olhar fica de fora e não executa nada dele.
- `statusline.sh`: o `git` roda com `core.fsmonitor=false` e `--no-optional-locks` (um `.git/config` de
  terceiros não executa nada) e remove caracteres de controle de pasta/branch. Se o próprio repo define
  filtros clean/smudge (`filter.*` fora do global/system), não roda `git status` e mostra `?` em vez de `*`.

## Sandbox do Claude Code (`ai/claude/sandbox.json`)

A barreira forte. Os hooks acima filtram texto (dá para driblar); o sandbox roda cada comando Bash dentro do
Seatbelt do macOS e o próprio sistema nega o acesso. Copie o bloco `sandbox` para o `~/.claude/settings.json`.

- **Escrita:** só na pasta do projeto, no temp e em caches de pacote **sem executáveis** (`~/.pub-cache/hosted`,
  `~/.npm/_cacache`, `~/Library/pnpm/store`, `~/.bun/install/cache`, `~/.gradle/caches`, DerivedData do Xcode…).
  De propósito ficam de fora: `~/.cache` (o p10k do zsh carrega um script dali em todo terminal),
  `~/.pub-cache/bin` e `~/Library/pnpm` (estão no `PATH`), `~/fvm` (o SDK do Flutter), `~/.gradle/init.d` e
  `~/.npm/_npx` (usado por servidores MCP via `npx`). Liberar escrita nelas deixaria um comando sandboxed plantar
  algo que depois roda **fora** do sandbox.
- **Flutter:** precisa escrever no próprio SDK (`~/fvm/versions/*/bin/cache`), então falha no sandbox e o Claude
  pede para rodar fora, comando a comando. Para não ser perguntado, dá para pôr `"fvm *", "flutter *", "dart *"`
  em `excludedCommands` — aí eles rodam com acesso total, como antes do sandbox.
- **Leitura:** tudo, menos `~/.ssh`, `~/.aws`, `~/.gnupg`, `~/.codex/auth.json`, `~/.config/gh/hosts.yml`. Os `deny`
  de `Read(...)` do `permissions` também entram aqui (`.env`, `*.pem`, `*.key`…), então nem um script lê esses arquivos.
- **Rede:** passa por um proxy com lista de domínios (GitHub, npm, PyPI, pub.dev, Flutter, Azure DevOps). Fora do
  modo manual, host fora da lista pode ser aprovado pelo classificador do modo auto; para recusar sempre, use
  `"network": {"strictAllowlist": true}`.
- **Fora do sandbox:** `docker`, `gh` (TLS no macOS) e `open`, conforme a doc oficial. Hooks, MCP e statusline
  também rodam fora (a doc diz que o sandbox cobre só comandos de shell).
- `autoAllowBashIfSandboxed: false`: o sandbox não muda os prompts de permissão, só limita o que o comando alcança.

## Máquina nova

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
ln -sfn $D/ghostty.config ~/.config/ghostty/config
```

O `~/.claude/settings.json` não é linkado porque o próprio Claude Code reescreve esse arquivo.
