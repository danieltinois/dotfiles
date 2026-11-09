# Instale/atualize tudo com: brew bundle --file ~/development/dotfiles/Brewfile

# --- Linguagens / runtimes ---
brew "fnm"          # versões do Node (lê .nvmrc / .node-version)
brew "pnpm"
brew "bun"
brew "uv"           # Python: versões, venvs e pacotes

# --- CLIs modernas ---
brew "eza"          # ls melhor
brew "bat"          # cat com cores
brew "fzf"          # busca fuzzy (Ctrl+R, Ctrl+T)
brew "zoxide"       # cd inteligente (z nome)
brew "lazygit"
brew "gh"           # GitHub CLI
brew "git-delta"    # diffs bonitos
brew "jq"
brew "tlrc"         # tldr: exemplos rápidos de comandos
brew "btop"         # monitor de sistema
brew "fd"
brew "wget"
brew "bash"         # Bash moderno (exigido pelo SDKMAN)
brew "lefthook"     # git hooks por projeto (lint/format antes do commit)

# --- Apps ---
# cask "docker-desktop"  # já instalado fora do brew (adotar falha por permissão do macOS); descomente numa máquina nova
cask "raycast"
cask "ghostty"
cask "google-chrome"
cask "bruno"        # cliente de API (coleções versionáveis no git)
cask "jetbrains-toolbox"  # instala/atualiza IntelliJ e outras IDEs
cask "font-jetbrains-mono-nerd-font"
cask "proxyman"     # inspeciona HTTP do simulador/celular
cask "xcodes-app"   # instala e alterna versões do Xcode

# --- IA / agentes ---
brew "ast-grep"     # busca e refactor estrutural
brew "scc"          # contagem de código por linguagem
brew "typescript-language-server"  # LSP usado pelo plugin typescript-lsp do Claude Code
brew "pyright"      # LSP usado pelo plugin pyright-lsp
# cask "wispr-flow"  # ditado por voz pra prompts (pago; descomente se quiser)
# Fora do brew:
# uv tool install "graphifyy[mcp]" && graphify install --platform claude && graphify install --platform codex
# Instruções globais dos agentes: ~/development/dotfiles/ai/AGENTS.md (symlink em ~/.claude/CLAUDE.md e ~/.codex/AGENTS.md)
