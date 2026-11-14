# mise shims for login shells that read ~/.profile (sh, display managers, agents)
export PATH="$HOME/.local/share/mise/shims:$PATH"

# Agents (no TTY for pinentry) can't GPG-sign; let their commits go unsigned.
if [ -z "${GIT_NOSIGN_SET:-}" ] && { [ -n "${AI_AGENT:-}${CLAUDECODE:-}" ] || ! [ -t 0 ]; }; then
  export GIT_NOSIGN_SET=1
  export GIT_CONFIG_COUNT=$(( ${GIT_CONFIG_COUNT:-0} + 1 ))
  export "GIT_CONFIG_KEY_$(( GIT_CONFIG_COUNT - 1 ))=commit.gpgsign"
  export "GIT_CONFIG_VALUE_$(( GIT_CONFIG_COUNT - 1 ))=false"
fi
