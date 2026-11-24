---
name: omarchy-flatpak
description: Package a native Omarchy app (C++/Qt Quick, qmake, Arch PKGBUILD, as made by the omarchy-app skill) as a Flatpak, and publish it from a public GitHub repository as a self-hosted, GPG-signed Flatpak repository on GitHub Pages that users install with one command and update with `flatpak update`. Companion to omarchy-arch-repo; both share one gh-pages branch, signing key and bin/pages.sh. Use when asked to flatpak an app, ship it to non-Omarchy or non-Arch Linux, make it installable anywhere, set up a Flatpak repo, flatpakref, or flatpakrepo, sign a Flatpak repo, or script releases. Not for Flathub submissions, which Flathub's policy forbids AI from doing.
---

# From Omarchy app to self-hosted Flatpak

This skill takes an app built the omarchy-app way and adds two scripts,
without changing how it installs on Omarchy (`bin/install` and the PKGBUILD
stay):

1. `bin/flatpak` builds this checkout, installs it for the user, and writes
   `build/<name>.flatpak`, a single file that installs anywhere but never
   updates.
2. `bin/release-flatpak [--publish]` builds the tagged release and adds it,
   signed, to an OSTree repository at `flatpak/repo/` on the `gh-pages`
   branch, served by GitHub Pages. People install it with
   `flatpak install --user https://<owner>.github.io/<name>/flatpak/<app-id>.flatpakref`
   and update with `flatpak update`.

It's the Flatpak half of [[omarchy-arch-repo]], which adds
`bin/release-arch` for a signed pacman repository at `arch/` on the same
branch. Both scripts work the same way: they take the version from the
`.pro` file, tag it, build the tag's commit, sign it with `APP_GPG_KEY`,
and write their own folder and their own section of the page through the
shared `bin/pages.sh`. Release both from the same tag, in either order. Each
starts from what's published, so it keeps the other's files.

`templates/` holds working copies:

- `bin/pages.sh`: the per-app settings, plus the shared gh-pages code (checkout,
  page assembly, parentless commit, publish). omarchy-arch-repo ships the
  same file. If the project already has one from there, keep it.
- `bin/flatpak-lib.sh`: the app ID, runtime, and `setup_builder`.
- `bin/flatpak`, `bin/release-flatpak`.
- `flatpak/APP.yml` and `flatpak/APP.metainfo.xml`.

Copy them into the project, then fill in the top blocks of `bin/pages.sh`
and `bin/flatpak-lib.sh` and the `<placeholders>` in `flatpak/`. They come
from Needful (`~/dev/kjlape/needful`: `bin/release-flatpak`, `bin/pages.sh`,
`bin/flatpak-lib.sh`), which publishes both channels from one page with
them. They first came from Flip, where the Flatpak flow was rehearsed end to
end: install, update, a fresh-machine publish, and refusing a wrong key.

## Rules first

- **Nothing outward-facing without the user saying so.** Don't push, run
  `gh repo create` or `gh release create`, or enable Pages. Don't run
  `--publish` unless asked. The scripts ask before each of those steps; don't
  answer for the user with `APP_YES=1`.
- **Never touch the user's own GPG keys.** Test only with a throwaway keyring.
  Set `GNUPGHOME=<scratch>` and pass `--homedir` on *every* gpg command. A
  failed command earlier in a chain can otherwise leave a later lookup
  reading the real keyring. The user makes the real signing key themselves.
  It's one command, documented for them.
- **Flathub is off-limits.** Flathub's Generative AI policy, and the
  `AGENTS.md` in `github.com/flathub/flathub`, forbid AI tools from
  generating or editing Flathub manifests. They also forbid opening or
  automating submission PRs, and writing their descriptions, comments, or
  replies to reviewers. Don't script it, don't draft it, don't offer to.
  Tell the user it's theirs to do by hand, that AI-generated parts must be
  disclosed, and that Flathub wants real development history first. The
  self-hosted repo is how that history gets built.
- **Keep personal data out of public files.** Before the first push, check
  commit emails with `git log --format='%an <%ae>' | sort -u`, and check the
  screenshot, LICENSE, and metainfo. Never put the user's email in docs.

## 1. Make the app sandbox-ready

Check these in the app before writing the manifest:

- **App ID.** Use `io.github.<owner>.<Name>`, the form GitHub-hosted apps
  use without owning a domain. The desktop file, icon, and metainfo are all
  installed under that ID. The native build keeps its short name.
- **Wayland app ID.** The window must report the ID its desktop file is
  installed under, or the dock and launcher show a generic icon. Flatpak sets
  `FLATPAK_ID` inside the sandbox, so:
  ```cpp
  const QString desktopFile = qEnvironmentVariable("FLATPAK_ID", "<name>");
  app.setDesktopFileName(desktopFile);
  app.setWindowIcon(QIcon::fromTheme(desktopFile));
  ```
- **The version.** Put `VERSION = 0.1.0` in the `.pro` file and
  `DEFINES += APP_VERSION=\\\"$$VERSION\\\"`. The release scripts read it
  from there. A release is one commit that bumps it, together with the
  PKGBUILD's `pkgver` (and `pkgrel=1`), which `bin/release-arch` checks
  match. The metainfo carries no version; see section 3.
- **Files through the portal.** The omarchy-app skill already requires
  xdg-desktop-portal's FileChooser, which is what makes open and save work in
  the sandbox with no `--filesystem=home`. If the app uses `QFileDialog` or
  hard-coded paths, fix that first.
- **Work well off Omarchy.** Flatpak users mostly aren't on Omarchy. Test
  with the Omarchy files absent (the `Theme` and `Translator` take their paths
  as arguments, so this is a unit test):
  - Accent: fall back to `#FFD60A` when `colors.toml` is missing.
  - Language: when `~/.config/omarchy/language` is missing, follow
    `QLocale::system()`. Map it to Omarchy's codes: `C` becomes `en`; keep
    `pt-BR`, `zh-CN`, `zh-TW`, and `es-MX` regional; reduce everything else
    to the base language.
  - Quitting: bind `Ctrl+Q` next to `Q`, because that's what other desktops
    expect. Keep `?` as `["?", "Shift+?"]`, because some layouts send
    Shift+? for it.
  - Corners: `hyprctl` isn't in the sandbox, so `theme.radius` stays 0.
    That's the right look anyway, so accept it.
- **Tools the app runs.** The KDE runtime has no `ffmpeg` or `ffprobe`
  command and no H.264 encoder. If the app runs them, the manifest builds x264
  and ffmpeg as modules (see the template). Anything else the app runs via
  `QProcess` must be in the runtime or built in, too. Check with
  `flatpak run --command=sh <app-id> -c 'command -v <tool>'`.

## 2. Manifest, metainfo, local build

- Copy `templates/flatpak/APP.yml` to `flatpak/<app-id>.yml` and
  `APP.metainfo.xml` to `flatpak/<app-id>.metainfo.xml`. Copy `templates/bin/*`
  to `bin/`, keeping a `bin/pages.sh` the project already has.
- Runtime: `org.kde.Platform` with a Qt 6 version matching what the app
  needs (6.11 had Qt 6.11). Before choosing, check what's current with
  `flatpak remote-info flathub org.kde.Platform//<v>`. An SDK extension the
  manifest uses (Needful's `rust-stable` for cargo) goes in
  `FLATPAK_EXTENSIONS` too, so `setup_builder` installs it.
- Keep `finish-args` minimal: ipc, wayland, fallback-x11, dri, and read-only
  access to the two Omarchy directories. Add devices and sockets only for a
  feature that needs them, with a comment saying which.
- The app module builds the checkout itself (`type: dir`, `path: ..`), skips
  build output, and reuses `pkgbuild/<name>.desktop` and `<name>.svg`. It
  renames them to the app ID with `sed` on `Icon=` and `StartupWMClass=`.
- Metainfo:
  - Use `<developer id="io.github.<owner>">`.
  - Add homepage, bugtracker, and vcs URLs; the bugtracker is the GitHub issues
    page, so keep Issues on.
  - Add an OARS rating and branding colors.
  - Point the screenshot at
    `raw.githubusercontent.com/<owner>/<name>/<anything>/docs/screenshot.png`;
    the release rewrites `<anything>` to its tag.
  - Leave `<releases>` empty; the release adds each entry.
  - Validate with `appstreamcli validate --no-net`.
- `.gitignore` gains `/build/`, `/.flatpak-builder/`, `/flatpak/build-dir/`,
  `/flatpak/repo/`, and `*.flatpak`.
- Run `bin/flatpak`. The first run downloads a couple of gigabytes (the SDK
  and `org.flatpak.Builder`), so run it in the background and keep working.
  Then run `flatpak run <app-id>` and look at it: icon in the dock, theme
  accent, open and save through the portal, exports.
- `$LINT manifest flatpak/<app-id>.yml` and `$LINT appstream …` (from
  `setup_builder`) catch most metadata mistakes. Some of their checks are
  Flathub-only, like the screenshot mirror, and can be ignored for a
  self-hosted repo.

## 3. Releases and the Pages repository

A release is a commit that bumps `VERSION` (and the PKGBUILD's `pkgver`),
then `bin/release-flatpak`, then `bin/release-flatpak --publish`. Read
`templates/bin/release-flatpak` and `bin/pages.sh` before changing them.
Each of these choices fixed a real failure:

- **What gets built.** The release is `v<VERSION>`. If the tag doesn't
  exist, the script tags this commit. If it exists on another commit, the
  script builds the tag's commit and says so: a fix to the scripts after the
  tag changes how it publishes, never what ships. The build runs in a
  detached worktree of that commit, `build/release-tree-flatpak`, never
  in the working tree.
- **Release notes at release time.** In that worktree, the script adds a
  `<release>` entry made from the commit subjects since the last tag, and
  points the screenshot at the tag. Then it runs `appstreamcli validate
  --no-net`. The checked-in metainfo stays without releases, so nothing has
  to be committed after tagging.
- **Version checks.** `flatpak/version` on `gh-pages` records what's
  published. An older or equal version is refused. If origin already has
  this version, `--publish` finishes a publish that stopped partway (by
  pushing the tag and turning Pages on). A version built locally but never
  pushed is simply built again.
- **Signed commits.** `flatpak build-commit-from --gpg-sign=$KEY` from a
  fresh build repo (`build/flatpak-repo`), then `flatpak build-update-repo
  --gpg-sign --generate-static-deltas --prune --prune-depth=3`. Deltas keep
  updates small, and pruning keeps the branch around 15 MB per release.
- **Starting from what's published.** `pages_checkout` makes `build/pages` a
  git worktree of `gh-pages`, reset to `origin/gh-pages` on every run. Every
  earlier release stays in the OSTree history, even when publishing from a
  fresh clone, and the other channels' folders stay.
- **Leftovers don't count.** Ignored files survive that reset, so a run
  without `--publish` can leave an OSTree `tmp/` behind. The repository
  counts as existing only if `config` is there (tracked). Otherwise it's
  cleared and initialised again.
- **Recreating OSTree's empty directories.** Git drops empty directories,
  so the script makes `refs/heads`, `refs/remotes`, `refs/mirrors`, `tmp`,
  `state`, and `extensions` again after a restore. It also gitignores
  the repo's `.lock`, `tmp/`, and `state/`.
- **One parentless commit, force-pushed.** History lives in OSTree, so the
  branch doesn't grow without end. `pages_commit` makes the commit with
  plumbing (`add -A`, `write-tree`, `commit-tree`, `update-ref`), which runs
  no hooks. A broken global hook (for example Git LFS hooks with no
  `git-lfs` installed) then can't stop a publish halfway. A normal `git push`
  still runs hooks; document the fix for the user rather than bypassing it.
- **The page.** `flatpak/install.html` is this channel's section: an `<h2>`,
  the install command, and the update line, with no `<html>` wrapper.
  `pages_commit` writes `index.html` from the header and every
  `*/install.html` in alphabetical order (`arch/`, then `flatpak/`), and adds
  `.nojekyll` and the icon. Never write `index.html` from a channel script;
  that wipes the other channel's section.
- **`.flatpakrepo` and `.flatpakref`** go in `flatpak/`. `GPGKey=` holds the
  *binary* public key, base64-encoded (`gpg --export KEY | base64 -w0`), not
  the armored one. `Url=` ends with `/`. `Branch=` comes from the built ref
  (`master` by default). `RuntimeRepo=` points at Flathub, so the runtime
  installs too. The armored key is published as `flatpak/<name>.gpg`.
- **Turning Pages on.** `pages_publish` checks with `gh api
  repos/<owner>/<name>/pages` and, if it's off, POSTs `source[branch]=gh-pages`.
  A public repository turns Pages on by itself when `gh-pages` is first
  pushed, sometimes between the check and the POST, so a 409 counts as on.
- **Don't move the repository once people use it.** Every install's remote
  points at `$PAGES_URL/flatpak/repo/`. A project that already published
  with this skill's older layout (repository at `repo/`, the `.flatpakref` at
  the root) sets `REPO_DIR=repo` in `bin/release-flatpak`, and adds lines
  copying the `.flatpakrepo` and `.flatpakref` to their old paths too, so
  links people already have keep working.
- **x86_64 only**, unless the user sets up an ARM build.

The `build/<name>.flatpak` bundle from `bin/flatpak` can be attached to a
GitHub release by hand (`gh release create v<version> build/<name>.flatpak`)
for people without the repo. That's the user's step, and it never updates.

## 4. Rehearse locally before anyone publishes

Run the whole flow against stand-ins. Use a scratch directory, never the
user's real remotes, keys, or Flatpak installation:

1. Clone under the user's home directory, e.g. `<project>/build/rehearsal`
   (already gitignored), not `/tmp`. The builder's sandbox has a private
   `/tmp` and can't see a checkout there. Run
   `git -c core.hooksPath=/dev/null clone --bare <project> build/rehearsal/origin.git`,
   then clone that to `build/rehearsal/work`. Give origin as an absolute
   path: `build/pages` is a worktree, and a relative origin doesn't resolve
   from there.
2. Make a throwaway key:
   `gpg --homedir <scratch>/gnupg --batch --passphrase '' --quick-gen-key "Test" ed25519 sign never`.
   Export `GNUPGHOME` and `APP_GPG_KEY` from that keyring *before any git
   command*. Make every rehearsal commit with
   `git -c commit.gpgsign=false -c tag.gpgSign=false`. The user may sign
   commits globally, and their gpg-agent will otherwise sign scratch commits
   with their real key.
3. Set `APP_PAGES_URL=http://127.0.0.1:8765`, and `APP_FLATPAK_STATE=<project>/.flatpak-builder`
   so the rehearsal reuses the real build cache.
4. Run `bin/release-flatpak`. Serve `build/pages` with
   `python3 -m http.server 8765 --bind 127.0.0.1`, and record its PID in a
   file. Stop it with `kill $(cat pidfile)`, never `pkill -f`, which matches
   and kills the agent's own shell.
5. Install as a client. Set `FLATPAK_USER_DIR=<scratch>/client` **only on
   the client commands**. Set for the whole session, the builder installs the
   multi-gigabyte SDK there too. Run `remote-add` with
   `flatpak/<name>.flatpakrepo`, then `install --no-deps`.
6. Push to the stand-in origin by hand (`git push origin v0.1.0` and
   `git -C build/pages push --force origin gh-pages`). `--publish` would call
   the GitHub API for the real repository. Then commit a version bump, run
   `bin/release-flatpak` again, push the same way, and run `update`. Delete
   `build/pages` and the local `gh-pages` branch, and release once more. The
   OSTree log must still show every release. Re-running a pushed version
   must be refused.
7. Add the repo with a different key's `--gpg-import`. `remote-ls` must
   refuse it.
8. If the project also has `bin/release-arch`, run it with `APP_NO_CHROOT=1`
   on the same tag, after pushing the Flatpak run to the stand-in origin.
   `index.html` must keep both sections, and `flatpak/` must be unchanged.
9. Installing with `remote-add` puts the rehearsal build in a scratch
   location, but `bin/flatpak` installs into the user's real Flatpak
   installation under the same app ID. If you ran it, run `bin/flatpak`
   afterwards from the real checkout to put theirs back.

The rehearsal doesn't cover the Pages API or a `.flatpakref` install over
HTTPS. Say so when reporting results.

## 5. Write `docs/PUBLISHING.md` for the user

Assume they'll do the outward-facing steps themselves, in a public repo
under their GitHub account. Cover:

- **Channels.** A table of the Pages repo (recommended: one command, then
  updates), the Arch repo if the project has omarchy-arch-repo's, the
  single-file bundle (no updates), and Flathub (manual, by policy). Needful's
  `docs/releasing-for-linux.md` is a worked example of one doc covering both
  repos.
- **What each script does,** and whether it leaves the machine.
- **One-time setup:**
  - Tools: `github-cli flatpak ostree gnupg python appstream`.
  - Check that `git push` works. Look for broken global hooks in
    `~/.config/git/hooks` and in `core.hooksPath`.
  - `gh auth login` and `gh auth setup-git`.
  - Review what becomes public: commit emails, the screenshot, and a
    suggested AI disclosure line in the README.
  - `gh repo create <owner>/<name> --public --source=. --remote=origin --push`.
  - Make the signing key, one for every channel of this app. Use a dedicated
    key, not their personal one:
    ```sh
    gpg --quick-gen-key "<Name> releases" ed25519 sign never
    gpg --list-secret-keys --with-colons "<Name> releases" | awk -F: '/^fpr/{print $10; exit}'
    ```
    Put `export APP_GPG_KEY=<fingerprint>` in their profile. Back the key up
    offline with `gpg --export-secret-keys --armor`, and never commit it.
- **Cutting a release:** commit the version bump, then run
  `bin/release-flatpak`, then `bin/release-flatpak --publish`. With both
  channels, run `bin/release-arch --publish` and `bin/release-flatpak --publish`
  from the same commit. Cover how to undo an unpublished release
  (`git tag -d v<version>`, `rm -rf build/pages`) and that the release notes
  are the commit subjects since the last tag, so write those well.
- **Install commands to give people:** the `.flatpakref` one-liner, and the
  `remote-add` plus `install` pair.
- **Changing the signing key.** Existing installs stop updating until people
  run `flatpak remote-modify --user --gpg-import=<new key> <remote>`. Say so
  in the release notes.
- **Flathub.** Explain the policy, what must be disclosed, and the history
  requirement, and link Flathub's requirements and submission docs. Make
  clear it's the user's job, by hand.
- **Troubleshooting:**
  - "isn't newer than the published": bump `VERSION`
  - `gpg has no secret key`
  - Pages showing 404 for the first few minutes
  - "public key not found", which means the remote has a different key
  - The builder not finding the SDK, which happens when `FLATPAK_USER_DIR`
    is set globally
- **Settings:** `APP_GPG_KEY`, `APP_YES`, `APP_PAGES_URL`, `APP_FLATPAK_STATE`,
  and `GNUPGHOME`.

Then add a short Flatpak section to the README linking the `.flatpakref`
and `docs/PUBLISHING.md`.

## Traps

- If `flatpak-builder` can't find the Flathub remote or SDK, it's looking at
  its own sandboxed data directory. `setup_builder` installs dependencies on
  the host and passes `--env=FLATPAK_USER_DIR=<host user dir>`.
- `org.flatpak.Builder` can't see `/tmp`; it fails with "Can't load
  '<app-id>.yml'" and a path in your home directory. `bin/flatpak` refuses
  to run from `/tmp` for that reason.
- `flatpak build-bundle` needs `--runtime-repo=…flathub.flatpakrepo`, or a
  bundle installed on a fresh machine can't find its runtime.
- Don't test Hyprland shortcuts with `hyprctl dispatch sendshortcut`; it
  doesn't reliably deliver modifier chords. Drive the QML offscreen with
  QTest instead, as in the omarchy-app skill.
- **Two channels released locally, nothing pushed in between.** Each run
  resets `build/pages` to origin's `gh-pages`, so the second run drops the
  first's unpushed output. Run `--publish` on each in turn, or push to the
  stand-in origin between them when rehearsing.
- **`--` in an XML comment** is invalid XML, and `appstreamcli` then rejects
  the whole metainfo. That includes a command line like `--no-net`.
- A screenshot URL pinned to a tag returns 404 until that tag is pushed.
  The local validation uses `--no-net`, so it doesn't notice.
