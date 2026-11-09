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
  (`.env`/`.env.<algo>`, `*.pem`/`.key`/…, `id_rsa`, `~/.ssh`…), pegando `.en?`, `.e[n]v`, `{a/.env,b}`, `*nv.q?`.
- `format-on-edit.sh` (PostToolUse): formata o arquivo editado com o formatter do projeto. Só procura
  até a raiz do repo, e o `uvx ruff` roda com `--no-config` (o repo não escolhe de onde o ruff vem).
  Ferramenta escolhida pelo repo (prettier do `node_modules`, SDK do `.fvmrc`) só roda em repo dentro de uma
  pasta confiável, listada em `~/.config/claude-hooks/trusted-roots` (uma por linha; sem o arquivo, vale
  `~/development`). Repo clonado só para olhar fica de fora e não executa nada dele.
- `statusline.sh`: o `git` roda com `core.fsmonitor=false` e `--no-optional-locks` (um `.git/config` de
  terceiros não executa nada) e remove caracteres de controle de pasta/branch. Se o próprio repo define
  filtros clean/smudge (`filter.*` fora do global/system), não roda `git status` e mostra `?` em vez de `*`.

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
