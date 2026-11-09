#!/usr/bin/env bash
# Preferências do macOS para um setup minimalista de dev. Idempotente: pode rodar de novo a qualquer hora.
# Uso: bash ~/development/dotfiles/macos.sh   (algumas mudanças pedem logout para valer 100%)
set -euo pipefail

# --- Dock: escondido, rápido, sem distração ---
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.3
defaults write com.apple.dock tile-size -int 44
defaults write com.apple.dock magnification -bool false
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock mru-spaces -bool false          # não reordena os Spaces sozinho
defaults write com.apple.dock expose-group-apps -bool true    # Mission Control agrupado por app
# Dock só com apps abertos (o Raycast vira o launcher). Descomente se curtir:
# defaults write com.apple.dock static-only -bool true

# --- Desktop: limpo ---
defaults write com.apple.finder CreateDesktop -bool false     # sem ícones na mesa
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
defaults write com.apple.WindowManager GloballyEnabled -bool false   # Stage Manager desligado

# --- Barra de menu ---
# Esconder a barra de menu inteira até passar o mouse. Descomente se curtir:
# defaults write NSGlobalDomain _HIHideMenuBar -bool true

# --- Finder ---
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv     # lista
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowRecentTags -bool false
defaults write com.apple.finder FXDefaultSearchScope -string SCcf     # busca na pasta atual
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder NewWindowTarget -string PfLo
defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/development/"
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true   # sem .DS_Store em rede
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true       # nem em pendrive

# --- Sistema ---
defaults write NSGlobalDomain AppleInterfaceStyle -string Dark
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write NSGlobalDomain AppleShowScrollBars -string WhenScrolling
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# --- Teclado de programador (sem autocorreção, repetição rápida) ---
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain KeyRepeat -int 2
for k in NSAutomaticCapitalizationEnabled NSAutomaticDashSubstitutionEnabled NSAutomaticPeriodSubstitutionEnabled \
         NSAutomaticQuoteSubstitutionEnabled NSAutomaticSpellingCorrectionEnabled; do
  defaults write NSGlobalDomain "$k" -bool false
done

# --- Screenshots: pasta própria, png, sem sombra ---
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture type -string png
defaults write com.apple.screencapture disable-shadow -bool true

killall Dock Finder SystemUIServer 2>/dev/null || true
echo "Pronto. Algumas mudanças (teclado, barra de menu) só valem 100% depois de logout/login."
