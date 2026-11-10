# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
# /etc/omarchy.conf is written by omarchy-dev-link. When absent, force the
# package default instead of preserving a stale inherited dev-link value before
# we decide which rc file to source.
if [[ -f /etc/omarchy.conf ]]; then
  source /etc/omarchy.conf
  export OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
else
  export OMARCHY_PATH=/usr/share/omarchy
fi
if [[ -f "$OMARCHY_PATH/default/bash/rc" ]]; then
  source "$OMARCHY_PATH/default/bash/rc"
else
  # Not Omarchy (macOS): minimal interactive setup.
  unset OMARCHY_PATH
  for completion in /opt/homebrew/etc/profile.d/bash_completion.sh /usr/local/etc/profile.d/bash_completion.sh; do
    [[ -r "$completion" ]] && source "$completion" && break
  done
  shopt -s histappend
  HISTSIZE=100000
  HISTFILESIZE=100000
  HISTCONTROL=ignoreboth
fi

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

[ -f "${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf.bash ] && source "${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf.bash

source $HOME/.env
source $HOME/.me

export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
export HISTTIMEOUT=1


# mise
export PATH="$HOME/.local/share/mise/shims:$PATH"
