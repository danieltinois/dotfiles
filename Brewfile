# Install/update everything with: brew bundle --file ~/development/dotfiles/Brewfile

tap "dart-lang/dart"
tap "anomalyco/tap"

# --- Languages / runtimes ---
brew "fnm"          # Node versions (reads .nvmrc / .node-version)
brew "pnpm"
brew "bun"
brew "uv"           # Python: versions, venvs and packages
brew "python@3.14"
brew "dart-lang/dart/dart"
brew "fvm"          # Flutter versions per project (reads .fvmrc)
brew "cocoapods"    # iOS dependencies for Flutter
cask "flutter"
cask "zulu@17"      # JDK 17 for Android/Gradle (SDKMAN manages the shell's java)

# --- Native build toolchain ---
brew "cmake"
brew "ninja"
brew "pkgconf"
brew "nasm"
brew "boost"
brew "glslang"

# --- Shell ---
brew "powerlevel10k"            # prompt theme (sourced in ~/.zshrc)
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"

# --- Modern CLIs ---
brew "git"          # newer than the one that ships with macOS
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
brew "fzf-tab"      # Tab completion as a searchable fzf list with preview
brew "atuin"        # shell history search (local only, see atuin.toml)
brew "yazi"         # terminal file manager with previews (y)
brew "lazydocker"   # terminal UI for Docker (lzd)
brew "tmux"         # sessions, windows and panes for parallel agents (see tmux.conf)
brew "typst"        # typesetting (PDFs from markup)

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
cask "visual-studio-code"
cask "obsidian"     # notes vault (Cérebro)
cask "spotify"

# --- AI / agents ---
cask "claude-code"
cask "codex"
brew "anomalyco/tap/opencode-v2"
brew "ast-grep"     # structural search and refactor
brew "scc"          # code count by language
brew "typescript-language-server"  # LSP used by Claude Code's typescript-lsp plugin
brew "pyright"      # LSP used by the pyright-lsp plugin
# cask "wispr-flow"  # voice dictation for prompts (paid; uncomment if you want it)
# Outside brew:
# uv tool install "graphifyy[mcp]" && graphify install --platform claude && graphify install --platform codex
# Global agent instructions: ~/development/dotfiles/ai/AGENTS.md (symlinked as ~/.claude/CLAUDE.md and ~/.codex/AGENTS.md)
