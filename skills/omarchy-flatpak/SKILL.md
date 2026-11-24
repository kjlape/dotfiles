---
name: omarchy-flatpak
description: Package a native Omarchy app (C++/Qt Quick, qmake, Arch PKGBUILD, as made by the omarchy-app skill) as a Flatpak, and publish it from a public GitHub repository as GitHub release bundles and a self-hosted, GPG-signed Flatpak repository on GitHub Pages that users install with one command and update with `flatpak update`. Use when asked to flatpak an app, ship it to non-Omarchy or non-Arch Linux, make it installable anywhere, set up a Flatpak repo, flatpakref, or flatpakrepo, sign a Flatpak repo, or script releases. Not for Flathub submissions, which Flathub's policy forbids AI from doing.
---

# From Omarchy app to self-hosted Flatpak

This skill takes an app built the omarchy-app way and adds three things
without changing how it installs on Omarchy (`bin/install` and the PKGBUILD
stay):

1. A Flatpak manifest, and `bin/flatpak` to build and install it locally.
2. `bin/release <version> [--publish]`: it bumps the version everywhere,
   writes AppStream release notes, tags the release, and makes a GitHub
   release with a `.flatpak` bundle.
3. `bin/flatpak-repo [--publish]`: a signed OSTree repository on the
   `gh-pages` branch, served by GitHub Pages. People install it with
   `flatpak install --user https://<owner>.github.io/<name>/<app-id>.flatpakref`.

`templates/` holds working copies of all of it. Copy them into the project,
then fill in the block at the top of `bin/lib.sh` and the `<placeholders>` in
`flatpak/`. The scripts read everything else from `lib.sh`. They come from
Flip, where the whole flow was rehearsed end to end: install, update, a
fresh-machine publish, and refusing a wrong key.

## Rules first

- **Nothing outward-facing without the user saying so.** Don't push, run
  `gh repo create` or `gh release create`, or enable Pages. Don't run either
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
- **Version in one place.** Put `VERSION = 0.1.0` in the `.pro` file and
  `DEFINES += APP_VERSION=\\\"$$VERSION\\\"`. `bin/release` rewrites that
  line, the PKGBUILD's `pkgver`/`pkgrel`, and the metainfo.
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
  to `bin/`.
- Runtime: `org.kde.Platform` with a Qt 6 version matching what the app
  needs (6.11 had Qt 6.11). Before choosing, check what's current with
  `flatpak remote-info flathub org.kde.Platform//<v>`.
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
    `raw.githubusercontent.com/<owner>/<name>/v<version>/docs/screenshot.png`.
  - Validate with `appstreamcli validate --no-net`.
- `.gitignore` gains `.flatpak-builder`, `flatpak/build-dir`, `flatpak/repo`,
  and `*.flatpak`.
- Run `bin/flatpak`. The first run downloads a couple of gigabytes (the SDK
  and `org.flatpak.Builder`), so run it in the background and keep working.
  Then run `flatpak run <app-id>` and look at it: icon in the dock, theme
  accent, open and save through the portal, exports.
- `$LINT manifest flatpak/<app-id>.yml` and `$LINT appstream …` (from
  `setup_builder`) catch most metadata mistakes. Some of their checks are
  Flathub-only, like the screenshot mirror, and can be ignored for a
  self-hosted repo.

## 3. Releases and the Pages repository

Read `templates/bin/flatpak-repo` before changing it. Each of these choices
fixed a real failure:

- **Signed commits.** The script runs
  `flatpak build-commit-from --src-repo=flatpak/repo --gpg-sign=$KEY`, then
  `flatpak build-update-repo --gpg-sign --generate-static-deltas --prune
  --prune-depth=3`. Deltas keep updates small, and pruning keeps the branch
  around 15 MB per release.
- **Starting from what's published.** `build/pages` is a git worktree of
  `gh-pages`, reset to `origin/gh-pages` on every run. Every earlier release
  stays in the OSTree history, even when publishing from a fresh clone.
- **Recreating OSTree's empty directories.** Git drops empty directories,
  so the script makes `refs/heads`, `refs/remotes`, `refs/mirrors`, `tmp`,
  `state`, and `extensions` again after a restore. It also gitignores
  `/repo/.lock`, `/repo/tmp/`, and `/repo/state/`.
- **One parentless commit, force-pushed.** History lives in OSTree, so the
  branch doesn't grow without end. The commit is made with plumbing
  (`add -A`, `write-tree`, `commit-tree`, `update-ref`), which runs no hooks.
  A broken global hook (for example Git LFS hooks with no `git-lfs`
  installed) then can't stop a publish halfway. A normal `git push` still
  runs hooks; document the fix for the user rather than bypassing it.
- **`.nojekyll`.** Without it, Pages runs Jekyll over the repository's files.
- **`.flatpakrepo` and `.flatpakref`.** `GPGKey=` holds the *binary* public
  key, base64-encoded (`gpg --export KEY | base64 -w0`), not the armored
  one. `Url=` ends with `/`. `Branch=` comes from the built ref (`master` by
  default). `RuntimeRepo=` points at Flathub, so the runtime installs too.
- **`index.html`.** A small page with the install command. It's plain HTML
  with no scripts.
- **Turning Pages on.** If Pages isn't on yet, `--publish` runs
  `gh api -X POST repos/<owner>/<name>/pages -f source[branch]=gh-pages
  -f source[path]=/`.
- **x86_64 only**, unless the user sets up an ARM build.

`bin/release` refuses a dirty tree or a tag on another commit. It puts every
file back if the tests or AppStream validation fail. It re-dates a release
entry that was written by hand instead of replacing it. Run again on a tag
that's already made, `--publish` publishes only, which makes it safe to
retry after a network failure.

## 4. Rehearse locally before anyone publishes

Run the whole flow against stand-ins. Use a scratch directory, never the
user's real remotes, keys, or Flatpak installation:

1. Clone under the user's home directory, e.g. `<project>/build/rehearsal`
   (already gitignored), not `/tmp`. The builder's sandbox has a private
   `/tmp` and can't see a checkout there. Run
   `git -c core.hooksPath=/dev/null clone --bare <project> build/rehearsal/origin.git`,
   then clone that to `build/rehearsal/work`.
2. Make a throwaway key:
   `gpg --homedir <scratch>/gnupg --batch --passphrase '' --quick-gen-key "Test" rsa2048 sign never`.
   Export `GNUPGHOME` and `APP_GPG_KEY` from that keyring.
3. Set `APP_PAGES_URL=http://127.0.0.1:8765`, and `APP_STATE_DIR=<project>/.flatpak-builder`
   so the rehearsal reuses the real build cache.
4. Run `bin/release 0.1.0`, then `bin/flatpak-repo`. Serve `build/pages`
   with `python3 -m http.server 8765 --bind 127.0.0.1`, and record its PID
   in a file. Stop it with `kill $(cat pidfile)`, never `pkill -f`, which
   matches and kills the agent's own shell.
5. Install as a client. Set `FLATPAK_USER_DIR=<scratch>/client` **only on
   the client commands**. Set for the whole session, the builder installs the
   multi-gigabyte SDK there too. Run `remote-add` with the `.flatpakrepo`,
   then `install --no-deps`.
6. Commit a change, release 0.1.1, publish into the stand-in repo, and run
   `update`. Then delete `build/pages` and the local `gh-pages` branch, and
   publish 0.1.2. The OSTree log must still show every release.
7. Add the repo with a different key's `--gpg-import`. `remote-ls` must
   refuse it.
8. `bin/flatpak` installs the rehearsal build into the user's real Flatpak
   installation under the same app ID. Afterwards, run `bin/flatpak` from
   the real checkout to put theirs back.

The rehearsal doesn't cover `gh release create`, the Pages API, or a
`.flatpakref` install over HTTPS. Say so when reporting results.

## 5. Write `docs/PUBLISHING.md` for the user

Assume they'll do the outward-facing steps themselves, in a public repo
under their GitHub account. Cover:

- **Channels.** A table of GitHub release bundles (single file, no
  updates), the Pages repo (recommended: one command, then updates), and
  Flathub (manual, by policy).
- **What each script does,** and whether it leaves the machine.
- **One-time setup:**
  - Tools: `github-cli flatpak ostree gnupg python appstream`.
  - Check that `git push` works. Look for broken global hooks in
    `~/.config/git/hooks` and in `core.hooksPath`.
  - `gh auth login` and `gh auth setup-git`.
  - Review what becomes public: commit emails, the screenshot, and a
    suggested AI disclosure line in the README.
  - `gh repo create <owner>/<name> --public --source=. --remote=origin --push`.
  - Make the signing key. Use a dedicated key, not their personal one:
    ```sh
    gpg --quick-gen-key "<Name> Flatpak repository" rsa4096 sign never
    gpg --list-secret-keys --with-colons "<Name> Flatpak repository" | awk -F: '/^fpr/{print $10; exit}'
    ```
    Put `export APP_GPG_KEY=<fingerprint>` in their profile. Back the key up
    offline with `gpg --export-secret-keys --armor`, and never commit it.
- **Cutting a release:** run `bin/release X`, then `bin/release X --publish`,
  then `bin/flatpak-repo --publish`. Cover how to undo an unpublished release
  (`git tag -d`, `git reset --hard HEAD~1`) and how to write release notes
  by hand.
- **Install commands to give people:** the `.flatpakref` one-liner, and the
  `remote-add` plus `install` pair.
- **Changing the signing key.** Existing installs stop updating until people
  run `flatpak remote-modify --user --gpg-import=<new key> <remote>`. Say so
  in the release notes.
- **Flathub.** Explain the policy, what must be disclosed, and the history
  requirement, and link Flathub's requirements and submission docs. Make
  clear it's the user's job, by hand.
- **Troubleshooting:**
  - `this commit isn't a release`
  - `gpg has no secret key`
  - Pages showing 404 for the first few minutes
  - "public key not found", which means the remote has a different key
  - The builder not finding the SDK, which happens when `FLATPAK_USER_DIR`
    is set globally
- **Settings:** `APP_GPG_KEY`, `APP_YES`, `APP_PAGES_URL`, `APP_STATE_DIR`,
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
- A screenshot URL pinned to a tag returns 404 until that tag is pushed.
  The local validation uses `--no-net`, so it doesn't notice.
