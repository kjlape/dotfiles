Steps:
- This first https://github.com/kjlape/dotfiles
- Ran the yolo script
- Running git commands forces macOS to install dev tools, so waiting for that now… leaving for dinner
- Bootstrap script needs to run brew commands or set up an alias for brew; couldn’t find the binary
- Accept Xcode license
  - sudo xcodebuild -license accept
- Copy private configs from places like `.ssh`, `.gnupg`, `.aws` to icloud directory for transfer to new mac
  - There was a bit of trial and error to allow things to settle, but this mostly worked. I think I committed the requisite tweaks. I'm sure the future holds more unpredictable quirky behavior. Such is life.
- Overall it seems to have gone pretty smoothly. The manual things I had to do were clearly spelled out as instructions from commands/apps, so I don't feel the need to copy them here.
