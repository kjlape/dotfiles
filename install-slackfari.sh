#!/usr/bin/env bash
[[ "$(uname)" == "Darwin" ]] || exit 0

clone-safari SlackfariTest
set-finder-icon \
  /Applications/Slack.app/Contents/Resources/slack.icns \
  /Applications/SlackfariTest.app
