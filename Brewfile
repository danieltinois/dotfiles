# Install/update everything with: brew bundle --file ~/development/dotfiles/Brewfile

# --- Languages / runtimes ---
brew "fnm"          # Node versions (reads .nvmrc / .node-version)
brew "pnpm"
brew "bun"
brew "uv"           # Python: versions, venvs and packages

# --- Modern CLIs ---
brew "eza"          # a better ls
brew "bat"          # cat with colors
brew "fzf"          # fuzzy search (Ctrl+R, Ctrl+T)
brew "zoxide"       # smart cd (z name)
brew "lazygit"
brew "gh"           # GitHub CLI
brew "git-delta"    # nicer diffs
brew "jq"
brew "tlrc"         # tldr: quick command examples
brew "btop"         # system monitor
brew "fd"
brew "wget"
brew "bash"         # modern Bash (required by SDKMAN)
brew "lefthook"     # per-project git hooks (lint/format before commit)
brew "fastfetch"    # system summary in the terminal

# --- Apps ---
# cask "docker-desktop"  # already installed outside brew (adopting fails on a macOS permission); uncomment on a new machine
cask "raycast"
cask "ghostty"
cask "google-chrome"
cask "bruno"        # API client (collections versioned in git)
cask "jetbrains-toolbox"  # installs/updates IntelliJ and other IDEs
cask "font-jetbrains-mono-nerd-font"
cask "proxyman"     # inspects HTTP from the simulator/phone
cask "xcodes-app"   # installs and switches Xcode versions

# --- AI / agents ---
brew "ast-grep"     # structural search and refactor
brew "scc"          # code count by language
brew "typescript-language-server"  # LSP used by Claude Code's typescript-lsp plugin
brew "pyright"      # LSP used by the pyright-lsp plugin
# cask "wispr-flow"  # voice dictation for prompts (paid; uncomment if you want it)
# Outside brew:
# uv tool install "graphifyy[mcp]" && graphify install --platform claude && graphify install --platform codex
# Global agent instructions: ~/development/dotfiles/ai/AGENTS.md (symlinked as ~/.claude/CLAUDE.md and ~/.codex/AGENTS.md)
