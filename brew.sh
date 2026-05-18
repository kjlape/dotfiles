#!/usr/bin/env bash
set -e

OS="$(uname)"

# Install brew (works on both macOS and Linux as Linuxbrew)
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
fi

# Freshen brew
brew update
brew upgrade

# Set up flatpak on Linux for GUI app fallback
if [[ "$OS" != "Darwin" ]] && ! command -v flatpak &>/dev/null; then
  if command -v omarchy &>/dev/null; then
    omarchy pkg add flatpak 2>/dev/null || true
  fi
fi
if command -v flatpak &>/dev/null; then
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

install_gui() {
  local name="$1"
  local flatpak_id="$2"
  if [[ "$OS" == "Darwin" ]]; then
    brew install --cask "$name" || true
  elif command -v flatpak &>/dev/null && [[ -n "$flatpak_id" ]]; then
    flatpak install -y flathub "$flatpak_id" || true
  elif command -v omarchy &>/dev/null; then
    omarchy pkg add "$name" 2>/dev/null || omarchy pkg aur add "$name" 2>/dev/null || true
  fi
}

# Essentials
# brew install ctags
brew install bat
brew install bison
brew install fzf && \
  "$(brew --prefix)"/opt/fzf/install --xdg --all 2>/dev/null || true
brew install git
brew install git-lfs
brew install delta # fancy git diff
brew install gpg
if [[ "$OS" == "Darwin" ]]; then
  brew install pinentry-mac
fi
brew install htop
brew install shellcheck

# Manage dotfiles
brew install stow

# Manage my runtimes
# brew cask install vagrant
brew install rbenv ruby-build
brew install nodenv node-build

# Manage my apps (mas is macOS-only, skip on Linux)
if [[ "$OS" == "Darwin" ]]; then
  brew install mas
fi

# Productivity
brew install tmux
brew install tmate
# brew install hub
brew install gh
brew install tree
brew install ripgrep
brew install act

# Web
# brew install ievms

# GUI (use brew on macOS, fallback to flatpak then omarchy on Linux)
install_gui discord com.discordapp.Discord
install_gui docker
install_gui google-chrome com.google.Chrome
install_gui 1password
if [[ "$OS" == "Darwin" ]]; then
  brew install --cask macvim || true
  brew install --cask rectangle || true
fi
# brew cask install virtualbox || true # requires sudo
# brew cask install virtualbox-extension-pack || true
# brew cask install licecap || true

# Finally
brew cleanup
