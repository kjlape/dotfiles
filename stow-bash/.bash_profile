# Login shells (macOS terminals) read this file, not .bashrc.

# Apple's /bin/bash is 3.2; silence its zsh nag.
export BASH_SILENCE_DEPRECATION_WARNING=1

# If still on bash 3.2 (login shell not yet switched), hop to Homebrew bash 5
# so fzf, function names, and process substitution in eval work.
if ((BASH_VERSINFO[0] < 4)) && [[ $- == *i* && -z "${BASH_EXECUTION_STRING:-}" ]]; then
  for brew_bash in /opt/homebrew/bin/bash /usr/local/bin/bash; do
    [[ -x "$brew_bash" ]] && exec "$brew_bash" -l
  done
fi

[[ -f "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
