#!/usr/bin/env bash
set -ex

OS="$(uname)"

if [[ "$OS" == "Darwin" ]]; then
  ./macos.sh
  ./apps.sh
  ./configure_terminal_dot_app.sh
fi

./brew.sh
./install.sh
./bundle.sh
