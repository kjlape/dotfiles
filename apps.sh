#!/usr/bin/env bash
set -e
[[ "$(uname)" == "Darwin" ]] || exit 0

mas install 497799835  # Xcode
mas install 1569813296 # 1Password for Safari
