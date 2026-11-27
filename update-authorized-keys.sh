#!/usr/bin/env bash
# Sync ~/.ssh/authorized_keys with a GitHub user's public keys.
#
# Usage: update-authorized-keys.sh [github-username]
#   GITHUB_USER env var or argument; defaults to kjlape.
#
# Behavior:
#   - Fetches keys from https://github.com/<user>.keys
#   - Backs up the existing authorized_keys
#   - Preserves any existing keys not in the GitHub list (local extras kept)
#   - Writes atomically with correct perms/ownership
set -euo pipefail

GITHUB_USER="${1:-${GITHUB_USER:-kjlape}}"
SSH_DIR="$HOME/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"
URL="https://github.com/${GITHUB_USER}.keys"

command -v curl >/dev/null || { echo "curl not found" >&2; exit 1; }

keys="$(curl -fsSL --max-time 15 "$URL")" || { echo "Failed to fetch keys from $URL" >&2; exit 1; }

if [[ -z "$keys" ]]; then
  echo "No public keys found for GitHub user '$GITHUB_USER' — aborting." >&2
  exit 1
fi

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Normalize + dedupe fetched keys
mapfile -t gh_keys < <(printf '%s\n' "$keys" | awk 'NF && $1 !~ /^#/ {print}' | awk '!seen[$0]++')

# Local extras: existing lines not present in the GitHub set
extras=""
if [[ -f "$AUTH_KEYS" ]]; then
  cp "$AUTH_KEYS" "$AUTH_KEYS.bak.$(date +%Y%m%d%H%M%S)"
  extras="$(awk 'NF && $1 !~ /^#/ {print}' "$AUTH_KEYS" \
    | grep -Fxvf <(printf '%s\n' "${gh_keys[@]}") || true)"
fi

tmp="$(mktemp "$SSH_DIR/.authorized_keys.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
{
  printf '%s\n' "${gh_keys[@]}"
  [[ -n "$extras" ]] && printf '%s\n' "$extras"
} > "$tmp"
chmod 600 "$tmp"

if cmp -s "$tmp" "$AUTH_KEYS" 2>/dev/null; then
  echo "authorized_keys already up to date ($(wc -l < "$AUTH_KEYS") keys)."
  exit 0
fi

mv "$tmp" "$AUTH_KEYS"
trap - EXIT
echo "Updated $AUTH_KEYS with $(wc -l < "$AUTH_KEYS") keys from github.com/$GITHUB_USER."
