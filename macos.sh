#!/usr/bin/env bash
[[ "$(uname)" == "Darwin" ]] || exit 0

# Inspired by https://mths.be/macos

# Developed on
# MacBook Pro (15-inch, 2018)
# 2.9 GHz Intel Core i9
# 32 GB 2400 MHz DDR4
# Intel UHD Graphics 630 1536 MB

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# Set DNS to 1.1.1.1 (https://1.1.1.1)
networksetup -setdnsservers Wi-Fi 1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Trackpad Settings
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

# Convenience
## Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false
