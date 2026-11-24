# Shared by bin/flatpak and bin/release-flatpak. Sourced, not run, after
# bin/pages.sh. Change the first four lines per app.

APP=io.github.<owner>.<Name>      # Flatpak app ID
FLATPAK_RUNTIME=org.kde.Platform//6.11
FLATPAK_SDK=org.kde.Sdk//6.11
FLATPAK_EXTENSIONS=""             # e.g. org.freedesktop.Sdk.Extension.rust-stable//25.08

# Sets BUILDER and LINT. The runtime, SDK and builder come from the host's
# flatpak, which can always see Flathub; the sandboxed builder sometimes can't.
setup_builder() {
  need flatpak "Install it from your distribution's packages."
  flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  # shellcheck disable=SC2086 # FLATPAK_EXTENSIONS is a list.
  flatpak install --user -y --noninteractive flathub "$FLATPAK_RUNTIME" "$FLATPAK_SDK" $FLATPAK_EXTENSIONS org.flatpak.Builder
  # In its sandbox "user" means its own data directory; point it at ours.
  user_dir="${XDG_DATA_HOME:-$HOME/.local/share}/flatpak"
  BUILDER="flatpak run --env=FLATPAK_USER_DIR=$user_dir --command=flatpak-builder org.flatpak.Builder"
  LINT="flatpak run --command=flatpak-builder-lint org.flatpak.Builder"
}

# The builder runs in its own sandbox with a private /tmp, so a checkout
# there is invisible to it and the build fails with a confusing path.
refuse_tmp() { # path
  case "$1" in /tmp/* | /var/tmp/*) die "build from a checkout under your home directory, not $1." ;; esac
}
