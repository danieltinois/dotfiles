#!/usr/bin/env bash
# macOS preferences for a minimal dev setup. Idempotent: safe to run again at any time.
# Usage: bash ~/development/dotfiles/macos.sh   (some changes need a logout to fully apply)
set -euo pipefail

# --- Dock: hidden, fast, no distractions ---
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.3
defaults write com.apple.dock tile-size -int 44
defaults write com.apple.dock magnification -bool false
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock mru-spaces -bool false          # don't reorder Spaces automatically
defaults write com.apple.dock expose-group-apps -bool true    # Mission Control grouped by app
defaults write com.apple.dock launchanim -bool true           # bounce/zoom when an app opens
# Dock with open apps only (Raycast becomes the launcher). Uncomment if you like it:
# defaults write com.apple.dock static-only -bool true

# --- Desktop: files and widgets visible, Stage Manager off, native window tiling on ---
defaults write com.apple.finder CreateDesktop -bool true          # files and folders on the desktop
defaults write com.apple.WindowManager HideDesktop -bool false    # "Show items: on Desktop"
defaults write com.apple.WindowManager StandardHideWidgets -bool false   # widgets on the desktop
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
defaults write com.apple.WindowManager GloballyEnabled -bool false       # Stage Manager off
# Drag a window to a screen edge to tile it (or fn+ctrl+arrows / Window > Move & Resize)
defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool true
defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool true      # drag to the top = fill the screen

# --- Menu bar ---
# Hide the whole menu bar until you hover over it. Uncomment if you like it:
# defaults write NSGlobalDomain _HIHideMenuBar -bool true

# --- Finder ---
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv     # list view
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowRecentTags -bool false
defaults write com.apple.finder FXDefaultSearchScope -string SCcf     # search the current folder
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder NewWindowTarget -string PfLo
defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/development/"
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true   # no .DS_Store on network drives
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true       # nor on USB drives

# --- System ---
defaults write NSGlobalDomain AppleInterfaceStyle -string Dark
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write NSGlobalDomain AppleShowScrollBars -string WhenScrolling
# Window animations on (open/close and resize). An older version of this script turned them off.
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool true
defaults delete NSGlobalDomain NSWindowResizeTime 2>/dev/null || true

# --- Programmer keyboard (no autocorrect, fast key repeat) ---
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain KeyRepeat -int 2
for k in NSAutomaticCapitalizationEnabled NSAutomaticDashSubstitutionEnabled NSAutomaticPeriodSubstitutionEnabled \
         NSAutomaticQuoteSubstitutionEnabled NSAutomaticSpellingCorrectionEnabled; do
  defaults write NSGlobalDomain "$k" -bool false
done

# --- Screenshots: own folder, png, no shadow ---
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture type -string png
defaults write com.apple.screencapture disable-shadow -bool true

killall Dock Finder SystemUIServer WindowManager 2>/dev/null || true
echo "Done. Some changes (keyboard, menu bar) only fully apply after logging out and back in."
