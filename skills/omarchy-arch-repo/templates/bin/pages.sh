# Shared by every script that publishes to the gh-pages branch
# (bin/release-arch, bin/release-flatpak), each into its own folder with an
# install.html section for the page. Sourced, not run; set ROOT first.
#
# This file is the same in the omarchy-flatpak and omarchy-arch-repo skills;
# tests/test_shared_skill_files.py fails if the two copies differ.
# The block below is the only part to change per app.

NAME=<name>                       # binary, Arch package and repo, icon and .desktop basename
TITLE=<Name>                      # display name
SUMMARY="<one-line summary>"      # same as the metainfo <summary> and the PKGBUILD's pkgdesc
GITHUB_REPO=<owner>/<name>

# Where GitHub Pages serves the site. You can override it to rehearse
# against a local web server.
PAGES_URL="${APP_PAGES_URL:-https://${GITHUB_REPO%%/*}.github.io/${GITHUB_REPO#*/}}"
PAGES="$ROOT/build/pages"

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

need() { # command, how to get it
  command -v "$1" >/dev/null || die "$1 is not installed. $2"
}

# Sets PUBLISH from the script's one optional argument, or prints the
# script's header comment and exits.
parse_publish() {
  PUBLISH=0
  case "${1:-}" in
    "") ;;
    --publish) PUBLISH=1 ;;
    *) sed -n '2,/^[^#]/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 1 ;;
  esac
}

# Sets VERSION and TAG from the .pro file, on a clean checkout, and SOURCE to
# the commit that is the release: TAG's, once it's made, so commits after it
# (a fix to these scripts, say) change how it's published but not what ships.
release_version() {
  [ -z "$(git -C "$ROOT" status --porcelain)" ] || die "commit or stash your changes first."
  VERSION="$(sed -n 's/^VERSION *= *\([0-9.]*\).*/\1/p' "$ROOT/$NAME.pro")"
  [ -n "$VERSION" ] || die "couldn't read VERSION from $NAME.pro."
  TAG="v$VERSION"
  SOURCE="$(git -C "$ROOT" rev-parse HEAD)"
  if git -C "$ROOT" rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
    tagged="$(git -C "$ROOT" rev-parse "$TAG^{commit}")"
    if [ "$tagged" != "$SOURCE" ]; then
      SOURCE="$tagged"
      echo "Releasing $TAG as tagged, from $(git -C "$ROOT" rev-parse --short "$SOURCE"), not this commit."
      echo "To ship this commit, bump the version."
    fi
  fi
}

# The release notes as <li> lines: commit subjects since the last release,
# oldest first.
release_notes() {
  last="$(git -C "$ROOT" describe --tags --abbrev=0 --match 'v*' "$SOURCE^" 2>/dev/null || true)"
  notes=""
  [ -z "$last" ] || notes="$(git -C "$ROOT" log --reverse --format=%s "$last..$SOURCE" |
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' | sed 's|.*|<li>&</li>|')"
  printf '%s\n' "${notes:-<li>First release.</li>}"
}

# Makes build/pages a checkout of the gh-pages branch as published, so each
# release adds to what's there. Sets REMOTE_PAGES to 1 when origin has one.
# Bookkeeping on this branch uses commands that run no git hooks, so a
# broken global hook can't stop a release halfway.
pages_checkout() {
  REMOTE_PAGES=0
  git -C "$ROOT" ls-remote --exit-code origin refs/heads/gh-pages >/dev/null 2>&1 && REMOTE_PAGES=1
  if [ ! -e "$PAGES/.git" ]; then
    git -C "$ROOT" worktree prune
    if [ "$REMOTE_PAGES" = 1 ]; then
      git -C "$ROOT" fetch -q origin "+gh-pages:refs/remotes/origin/gh-pages"
      git -C "$ROOT" worktree add -q --no-checkout -B gh-pages "$PAGES" origin/gh-pages
      git -C "$PAGES" reset -q --hard
    else
      git -C "$ROOT" worktree add -q --orphan -b gh-pages "$PAGES"
    fi
  fi
  git -C "$PAGES" symbolic-ref HEAD refs/heads/gh-pages
  if [ "$REMOTE_PAGES" = 1 ]; then
    git -C "$PAGES" fetch -q origin gh-pages
    git -C "$PAGES" reset -q --hard FETCH_HEAD
  fi
}

# Writes index.html from each channel's install.html (arch/, flatpak/, …), so
# a release for one channel keeps the others' instructions, then commits the
# whole branch as one parentless commit, so dropped packages don't stay in
# its history. Tags SOURCE as TAG if it isn't yet.
pages_commit() { # message
  cp "$ROOT/pkgbuild/$NAME.svg" "$PAGES/$NAME.svg"
  # GitHub Pages would otherwise run Jekyll over the files.
  touch "$PAGES/.nojekyll"
  {
    cat <<EOF
<!doctype html>
<html lang="en">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$TITLE</title>
<style>
  body { font: 16px/1.5 system-ui, sans-serif; max-width: 42rem; margin: 3rem auto; padding: 0 1rem; color: #1a1a1a; background: #fff; }
  pre { background: #f2f2f2; padding: .75rem 1rem; overflow-x: auto; }
  img { width: 64px; height: 64px; }
  @media (prefers-color-scheme: dark) { body { color: #e6e6e6; background: #0e0e10; } pre { background: #1c1c20; } a { color: #ffd60a; } }
</style>
<img src="$NAME.svg" alt="">
<h1>$TITLE</h1>
<p>$SUMMARY. Source on <a href="https://github.com/$GITHUB_REPO">GitHub</a>.</p>
EOF
    for part in "$PAGES"/*/install.html; do
      [ -f "$part" ] && cat "$part"
    done
    echo "</html>"
  } >"$PAGES/index.html"
  git -C "$PAGES" add -A
  tree="$(git -C "$PAGES" write-tree)"
  commit="$(git -C "$PAGES" commit-tree "$tree" -m "$1")"
  git -C "$PAGES" update-ref refs/heads/gh-pages "$commit"
  # Annotated, with a message, so tag.gpgSign can't stop to open an editor.
  git -C "$ROOT" rev-parse -q --verify "refs/tags/$TAG" >/dev/null ||
    git -C "$ROOT" tag -a -m "$TITLE $VERSION" "$TAG" "$SOURCE"
}

# For a version gh-pages on origin already has: with --publish, finishes a
# publish that stopped after pushing gh-pages; without it, says so. Exits.
pages_finish() { # what
  [ "$PUBLISH" = 1 ] || die "$1 is already published. Bump the version to release another."
  echo "$1 is already on gh-pages; finishing its publish."
  pages_publish "$1"
  echo "Published."
  exit 0
}

# Pushes the tag and gh-pages, and turns on GitHub Pages the first time.
pages_publish() { # what, for the question
  need gh "Install github-cli and run: gh auth login"
  git -C "$ROOT" remote get-url origin >/dev/null 2>&1 || die "there's no origin remote. See docs/PUBLISHING.md."
  confirm "Push $TAG, replace gh-pages on origin with $1, and serve it on GitHub Pages?"
  git -C "$ROOT" push -q origin "$TAG" ||
    die "git push failed. If a git hook stopped it, see docs/PUBLISHING.md, \"Check that git can push\"."
  git -C "$PAGES" push -q --force origin gh-pages
  # A public repository turns Pages on by itself when gh-pages is first
  # pushed, sometimes between a check and this request, so "already
  # enabled" (409) counts as on.
  if ! gh api "repos/$GITHUB_REPO/pages" >/dev/null 2>&1; then
    if output="$(gh api -X POST "repos/$GITHUB_REPO/pages" -f "source[branch]=gh-pages" -f "source[path]=/" 2>&1)"; then
      echo "Turned on GitHub Pages; the first deploy takes a minute or two."
    else
      case "$output" in *409*) ;; *) die "couldn't turn on GitHub Pages: $output" ;; esac
    fi
  fi
}
