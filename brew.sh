#!/usr/bin/env bash
set -e

# Install brew
command -v brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Freshen brew
brew update
brew upgrade

# Essentials
# brew install ctags
brew install bat
brew install bison
brew install fzf && \
  "$(brew --prefix)"/opt/fzf/install --xdg --all
brew install git
brew install gpg
brew install pinentry-mac
brew install htop
brew install shellcheck

# Manage dotfiles
brew install stow

# Manage my runtimes
# brew cask install vagrant
brew install rbenv ruby-build
brew install nodenv node-build

# Manage my apps
brew install mas

# Productivity
brew install tmux
brew install tmate
# brew install hub
brew install gh
brew install tree
brew install ripgrep

# Web
# brew install ievms

# GUI
brew install --cask discord || true
brew install --cask docker || true
brew install --cask macvim || true # "... || true" -> continue on error
brew install --cask rectangle || true
brew install --cask google-chrome || true
brew install --cask 1password || true
# brew cask install virtualbox || true # requires sudo
# brew cask install virtualbox-extension-pack || true
# brew cask install licecap || true

# Finally
brew cleanup
