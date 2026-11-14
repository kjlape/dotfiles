# mise shims — before the interactive guard so non-interactive shells (agents, scripts) get them too
export PATH="$HOME/.local/share/mise/shims:$PATH"

# Agents (no TTY for pinentry) can't GPG-sign; let their commits go unsigned.
if [ -z "${GIT_NOSIGN_SET:-}" ] && { [ -n "${AI_AGENT:-}${CLAUDECODE:-}" ] || ! [ -t 0 ]; }; then
  export GIT_NOSIGN_SET=1
  export GIT_CONFIG_COUNT=$(( ${GIT_CONFIG_COUNT:-0} + 1 ))
  export "GIT_CONFIG_KEY_$(( GIT_CONFIG_COUNT - 1 ))=commit.gpgsign"
  export "GIT_CONFIG_VALUE_$(( GIT_CONFIG_COUNT - 1 ))=false"
fi

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
source "$OMARCHY_PATH/default/bash/rc"

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

[ -f "${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf.bash ] && source "${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf.bash

source $HOME/.env
source $HOME/.me

export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
export HISTTIMEOUT=1
