#!/usr/bin/env bash
set -e

if [[ "$(uname)" == "Darwin" ]]; then
  brew install --cask slack
elif command -v flatpak &>/dev/null; then
  flatpak install -y flathub com.slack.Slack
fi
