# Shared by bin/flatpak, bin/release, and bin/flatpak-repo. Sourced, not run.
# The block below is the only part to change per app.

NAME=<name>                       # binary, Arch package, icon and .desktop basename
TITLE=<Name>                      # display name
SUMMARY="<one-line summary>"      # same as the metainfo <summary>
APP=io.github.<owner>.<Name>      # Flatpak app ID
GITHUB_REPO=<owner>/<name>
FLATPAK_RUNTIME=org.kde.Platform//6.11
FLATPAK_SDK=org.kde.Sdk//6.11

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
# Where GitHub Pages serves the Flatpak repository. You can override it, so
# bin/flatpak-repo can be rehearsed against a local web server.
PAGES_URL="${APP_PAGES_URL:-https://${GITHUB_REPO%%/*}.github.io/${GITHUB_REPO#*/}}"

die() {
  echo "error: $*" >&2
  exit 1
}

# Asks before anything other people will see. APP_YES=1 answers yes.
confirm() {
  [ "${APP_YES:-}" = 1 ] && return 0
  printf '%s [y/N] ' "$1"
  read -r answer
  case "$answer" in y | Y | yes) return 0 ;; *) die "stopped" ;; esac
}

need() {
  command -v "$1" >/dev/null || die "$1 is not installed. $2"
}

# Sets BUILDER and LINT. The runtime and SDK are installed by the host's
# flatpak, which can always see Flathub. The sandboxed builder sometimes can't.
setup_builder() {
  need flatpak "Install it from your distribution's packages."
  flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak install --user -y --noninteractive flathub "$FLATPAK_RUNTIME" "$FLATPAK_SDK" org.flatpak.Builder
  # Inside its sandbox, "user" means the builder's own data directory, so
  # point it at ours.
  user_dir="${XDG_DATA_HOME:-$HOME/.local/share}/flatpak"
  BUILDER="flatpak run --env=FLATPAK_USER_DIR=$user_dir --command=flatpak-builder org.flatpak.Builder"
  LINT="flatpak run --command=flatpak-builder-lint org.flatpak.Builder"
}

# The version from the `VERSION = x.y.z` line in the .pro file, which the
# binary reports.
current_version() {
  sed -n 's/^VERSION *= *\([0-9.]*\).*/\1/p' "$ROOT/$NAME.pro"
}
