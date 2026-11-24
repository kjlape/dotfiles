---
name: omarchy-arch-repo
description: Publish a native Omarchy app (C++/Qt Quick, qmake, Arch PKGBUILD, as made by the omarchy-app skill) as a self-hosted, GPG-signed pacman repository on GitHub Pages, built in a clean chroot, so Arch machines add it once and get every release with `pacman -Syu`. Companion to omarchy-flatpak; both share one gh-pages branch, signing key and bin/pages.sh. Use when asked to make a pacman repo, an Arch repository, a custom repo for pacman.conf, ship an app to Arch users with updates, sign Arch packages, or publish Arch packages on GitHub Pages. Not for the AUR.
---

# From Omarchy app to self-hosted pacman repository

This skill gives an omarchy-app project `bin/release-arch [--publish]`. It
builds the tagged commit in a clean chroot, signs the package and the
database, and publishes them to `arch/x86_64/` on the `gh-pages` branch.
GitHub Pages serves that folder. People trust the key once, add three lines
to `pacman.conf`, and get updates with `pacman -Syu`. `bin/install` and
local `makepkg` keep working as before.

It's the Arch half of [[omarchy-flatpak]], whose `bin/release-flatpak`
publishes a Flatpak repository at `flatpak/` on the same branch. Both
scripts work the same way: they take the version from the `.pro` file, tag
it, build the tag's commit, sign it with `APP_GPG_KEY`, and write their own
folder and their own section of the page through the shared `bin/pages.sh`.

`templates/` holds working copies:

- `bin/pages.sh`: the per-app settings, plus the shared gh-pages code
  (checkout, page assembly, parentless commit, publish). omarchy-flatpak
  ships the same file. If the project already has one from there, keep it.
- `bin/release-arch`.
- A PKGBUILD that builds either the checkout or a release tarball.

They come from Needful (`~/dev/kjlape/needful`: `bin/release-arch`,
`bin/pages.sh`). They were used for real releases and checked from a client
(see section 4). Read them before changing them, because each choice in them
fixed a real failure.

## Rules first

The rules from omarchy-flatpak apply unchanged:

- **Nothing outward-facing without the user saying so.** Don't push, don't
  run `--publish`, and don't answer `confirm` with `APP_YES=1`.
- **Never touch the user's GPG keys.** Test only with a throwaway keyring.
  The user makes the real key themselves.
- **Keep personal data out of public files.** That includes commit emails
  and the key's user ID, since the page publishes the key.

For pacman:

- **Never edit `/etc/pacman.conf` or the system keyring** (`pacman-key`
  without `--gpgdir`) to test. Use a scratch client (section 4). Adding the
  repo to the user's own machine is the user's call.
- **The AUR is a different thing.** An AUR package is a PKGBUILD that users
  build themselves, and it doesn't use this repo. Don't submit to the AUR
  unasked.

## 1. Fit the project

- Copy `templates/bin/release-arch` into `bin/` and run
  `chmod +x bin/release-arch`. Copy `templates/bin/pages.sh` too, unless the
  project already has it from omarchy-flatpak, and fill in its top block
  (`NAME`, `TITLE`, `SUMMARY`, `GITHUB_REPO`).
- **An older omarchy-flatpak setup** (`bin/lib.sh`, `bin/release`,
  `bin/flatpak-repo`, which writes the whole `index.html`) would wipe the
  Arch section on its next publish. Move it to omarchy-flatpak's current
  templates first, keeping its repository where it is (see that skill's
  section 3, "Don't move the repository").
- **The PKGBUILD has to build without the checkout.** omarchy-app's
  PKGBUILD runs `cd "$startdir/.."` and installs `"$startdir/<name>.svg"`.
  The chroot gets only the staging folder, so both of those fail there.
  Merge in the template's changes:
  - `_tarball=` and `_sha256=`, left empty in git. The `source`/`sha256sums`
    lines expand to nothing when they're empty.
  - `_tree()`, and `cd "$(_tree)"` in `build()` and `package()`.
  - Every installed file addressed inside the tree (`pkgbuild/<name>.svg`),
    never through `$startdir`.

  Then run `makepkg -f` in `pkgbuild/`, which builds the checkout and must
  still work. `bin/install` is unchanged.
- **Complete `depends` and `makedepends`.** The chroot starts from
  `base-devel` only. That's the point of it: a dependency the PKGBUILD
  forgot fails the build instead of shipping. Add `cargo` and similar
  entries if `bin/build` needs them. The chroot has network access during
  the build.
- **Version in two places.** `VERSION` in the `.pro` file and `pkgver` in
  the PKGBUILD must match, or `release-arch` refuses to run. A release is
  one commit that bumps both. Reset `pkgrel=1` when `pkgver` changes, and
  bump only `pkgrel` to re-release the same source. Note the rule in the
  project's AGENTS.md.
- `.gitignore` already covers `build/`, where the staging folder (`build/arch`)
  and `build/pages` live. If it doesn't, add it.

## 2. Beside omarchy-flatpak

Nothing to change: `bin/release-flatpak` writes only `flatpak/`, including
its `flatpak/install.html`, and `pages_commit` assembles `index.html` from
every `*/install.html` in alphabetical order. Release both channels from the
same tag. Each run starts from what's published, so each keeps the other's
files:

```sh
bin/release-arch --publish
bin/release-flatpak --publish
```

A third channel (Needful also has `bin/release-macos`) follows the same
pattern: its own folder, its own `install.html`, and `pages_commit` and
`pages_publish` from `pages.sh`.

## 3. How `release-arch` works

- **What gets built.** The release is `v<VERSION>`. If the tag doesn't
  exist, the script tags this commit. If it exists on another commit, the
  script builds the tag's commit and says so: a fix to the scripts after the
  tag changes how it publishes, never what ships. The PKGBUILD is read with
  `git show $SOURCE:pkgbuild/PKGBUILD`, not from the working tree.
- **Clean chroot.** `git archive` exports `$SOURCE` as
  `build/arch/<name>-<ver>.tar.gz`. A copy of the PKGBUILD gets `_tarball`
  and its sha256 filled in, then `extra-x86_64-build` builds it. The chroot
  is created the first time and needs sudo. `APP_NO_CHROOT=1` uses plain
  `makepkg` to rehearse, and `--publish` refuses such a build.
- **Only the newest package.** pacman installs only the newest, so the old
  package and its `.sig` are deleted. The `-debug-` package isn't published.
- **Signatures.** There's a detached `.sig` for the package, and
  `repo-add --verify --sign --key` for the database. `--verify` checks the
  published database's signature before adding to it, so a tampered
  `gh-pages` stops the release.
- **No symlinks.** `repo-add` makes `<name>.db` and `<name>.files` symlinks.
  GitHub Pages doesn't serve symlinks, so each one becomes a copy. The
  `*.old` backups are deleted.
- **Version checks.** The script uses `vercmp` against what's on origin. If
  origin already has this version, `--publish` finishes a publish that
  stopped partway (by pushing the tag and turning Pages on). Without
  `--publish` it refuses. A version built locally but never pushed is
  simply built again.
- **The page section.** `arch/install.html` holds the key's full
  fingerprint, the `curl`/`pacman-key` commands, and the `pacman.conf`
  lines. The public key is published as `arch/<name>.gpg`.
- **Turning Pages on.** A public repository turns Pages on by itself when
  `gh-pages` is first pushed. That can happen between the GET check and the
  POST, so a 409 from the POST counts as on. This happened on Needful's
  first publish.
- **x86_64 only.** The PKGBUILD allows aarch64, but nothing here builds it.

## 4. Rehearse, then check the live repo as a client

**Rehearsal**, before anything is published:

1. Set `GNUPGHOME=<scratch>/gnupg`, make a throwaway key
   (`gpg --batch --passphrase '' --quick-gen-key Test ed25519 sign never`),
   and export `APP_GPG_KEY`, before any git command. Make every rehearsal
   commit with `git -c commit.gpgsign=false -c tag.gpgSign=false`, or a
   global `commit.gpgsign` signs it with the user's real key.
2. If `gh-pages` already exists on origin, rehearse in a clone whose origin
   is a scratch bare repo, given as an absolute path, as in omarchy-flatpak.
   Otherwise each run starts over from the real branch. Push to it by hand
   (`git push origin v<version>`, `git -C build/pages push --force origin
   gh-pages`), never with `--publish`, which calls the GitHub API.
3. Run `APP_NO_CHROOT=1 bin/release-arch` twice: once on a version, then after
   bumping it. The second run must swap the package. Re-running a published
   version must be refused, or finished with `--publish`.
4. Check that `build/pages/arch/x86_64` has no symlinks
   (`find -type l` prints nothing) and that `gpg --verify` passes on the
   database and the package.
5. If the project has `bin/release-flatpak`, push, then run it on the same
   tag. `index.html` must keep both sections, and `arch/` must be unchanged.
6. Run the real chroot build once without `--publish`, if devtools is
   installed. It's the only check on `depends`.

**Client check**, after the user publishes (this is how Needful's live
repo was checked). Everything goes in a scratch directory, under `fakeroot`,
so nothing touches the system:

```sh
S=<scratch>/pacclient; mkdir -p $S/db $S/cache $S/root $S/gnupg
ln -sfn $S/gnupg <short path>/pg; G=<short path>/pg   # see the trap below
cat >$S/pacman.conf <<'EOF'
[options]
Architecture = x86_64
SigLevel = Required
[<name>]
SigLevel = Required
Server = https://<owner>.github.io/<name>/arch/$arch
EOF
curl -fsSLo $S/<name>.gpg https://<owner>.github.io/<name>/arch/<name>.gpg
P="fakeroot pacman --config $S/pacman.conf --root $S/root --dbpath $S/db --cachedir $S/cache --gpgdir $G --noconfirm"
$P -Sy                                          # must fail: key not trusted yet
fakeroot sh -c "pacman-key --gpgdir $G --init && pacman-key --gpgdir $G --add $S/<name>.gpg && pacman-key --gpgdir $G --lsign-key <fingerprint>"
$P -Sy && $P -Swdd <name>                       # database and package verify
printf x | dd of=$S/cache/<pkg file> bs=1 seek=5000 conv=notrunc
$P -Swdd <name>                                 # must fail: corrupted package
gpgconf --homedir $G --kill gpg-agent; rm <short path>/pg
```

`-Swdd` downloads and verifies the package without installing it or
resolving its dependencies. The local-only rehearsal doesn't cover the
Pages API, the HTTPS download or the chroot (unless you ran step 6). Say so
when reporting.

## 5. Document it for the user

Add an Arch section to `docs/PUBLISHING.md` (omarchy-flatpak's), or write
one if the project doesn't have it:

- **Set up once:**
  - `sudo pacman -S devtools`.
  - The signing key. Use the same `APP_GPG_KEY` as the Flatpak. One key is
    one trust step for users, and one key per app limits what a leak can
    compromise. If it's a new key: `gpg --quick-gen-key "<Name> releases"
    ed25519 sign never`, then back it up offline with
    `gpg --export-secret-keys --armor`. Never commit it.
  - GitHub Pages: free for a public repo.
- **Each release:** commit the version bump, then run `bin/release-arch`
  and `bin/release-arch --publish`.
- **What users run:** the three `pacman-key` commands, the `pacman.conf`
  block, and `sudo pacman -Syu <name>`. A copy installed with `bin/install`
  has the same package name, so the repo's next release replaces it.
- **Changing the key:** every machine has to `pacman-key --add` and
  `--lsign-key` the new key before it can update again. Announce it from the
  old key's last release.
- **Troubleshooting:**
  - "signature … is unknown trust": the key was added but not lsigned.
  - "invalid or corrupted database (PGP signature)": the key is missing, or
    the database was rebuilt with another key.
  - 404 for the first minutes after the first publish.
  - "isn't newer than the published": bump `VERSION` and `pkgver`, or only `pkgrel` for the
    same source.
- **Settings:** `APP_GPG_KEY`, `APP_YES`, `APP_PAGES_URL`, `APP_NO_CHROOT`.

Add the Arch install steps to the README, next to the Flatpak ones.

## Traps

- **`$startdir` in `package()`.** It works with `makepkg` in the checkout
  and fails in the chroot with a missing icon or desktop file. Address
  everything through `_tree`.
- **Symlinks on Pages.** A database that `repo-add` left as a symlink comes
  back 404, and `pacman -Sy` reports the repo as missing.
- **Two channels released locally, nothing pushed in between.** Each run
  resets `build/pages` to origin's `gh-pages`, so the second run drops the
  first's unpushed output. Publish each in turn, or push to the stand-in
  between them.
- **The build reading the working tree.** Always use the `$SOURCE` export.
  Otherwise a release built after a later commit ships code its tag doesn't
  have.
- **Leftovers in `build/pages`.** It's reset to `origin/gh-pages` on every
  run, but ignored files survive the reset. Decide what counts as published
  from tracked files only (the package file name), never from a folder
  that merely exists. The Flatpak side hit this with an OSTree `tmp/`.
- **A scratch keyring for `pacman-key`.** It needs its own gpg-agent, and
  the agent's socket path has a length limit. A `--gpgdir` deep in a scratch
  directory fails with "GnuPG agent unusable", so link it to a short path.
  pacman and pacman-key also insist on root, which `fakeroot` covers for a
  scratch `--root`/`--dbpath`.
- **The repo name is the `[section]` in `pacman.conf`** and the database's
  basename (`<name>.db`). Here both are `NAME`. Renaming it later breaks
  every configured machine.
