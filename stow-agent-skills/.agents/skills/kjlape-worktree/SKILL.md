---
name: kjlape-worktree
description: Kaleb's personal git worktree workflow, using the `git-new-worktree` and `git-teardown-worktree` scripts from his dotfiles plus per-project setup/teardown hooks. Use whenever Kaleb asks to create/set up a new git worktree, start a new branch in a worktree, spin up an isolated working copy for a branch, tear down/remove a worktree, or add project-specific worktree spin-up/cleanup — in any repo, not just dotfiles.
version: "2.0"
triggers:
  - "new worktree"
  - "git worktree"
  - "worktree for"
  - "set up a worktree"
  - "git-new-worktree"
  - "teardown worktree"
  - "remove worktree"
  - "worktree hook"
---

# kjlape: Worktree Management

## What this is

Kaleb manages git worktrees with two custom scripts from his dotfiles repo
(`stow-shell-config/.bin/`, stowed onto `PATH` so they're invocable as
`git new-worktree` / `git teardown-worktree` from inside any git repo):

- `git-new-worktree` — creates a worktree, then runs the project's **setup hook**.
- `git-teardown-worktree` — runs the project's **teardown hook**, then removes the worktree.

The scripts themselves are generic. Everything project-specific (env files,
ports, docker compose clusters, dependency installs) lives in per-project
hooks. This skill documents that behavior so it can be invoked correctly and
explained accurately — it is not a generic worktree tutorial.

## When to use

Use this skill whenever Kaleb wants to:
- Create a new worktree for a branch (new or existing) in the repo he's currently in
- Base a new worktree off something other than `master` (e.g. a repo that uses `main` or `develop`)
- Tear down a worktree (and optionally its branch)
- Add or change project-specific spin-up/cleanup for a repo's worktrees
- Understand why a worktree ended up where it did, or why its env files look the way they do

Do not use plain `git worktree add` / `git worktree remove` for this — always
defer to the scripts so hooks run and behavior stays consistent across repos.

## Creating a worktree

```
git-new-worktree [-b base-branch] <branch-name>
```

- `<branch-name>` (required) — branch to create/reset in the new worktree.
- `-b <base-branch>` (optional) — branch to fork from.

Base branch resolution (highest precedence first):
1. `-b` flag
2. `GIT_NEW_WORKTREE_BASE_BRANCH` environment variable
3. Default: `master`

Check the repo's default branch (`git symbolic-ref refs/remotes/origin/HEAD`)
and pass `-b` when it isn't `master`.

Worktree location — **no dependency on the target repo's internal structure**:
- `~/.local/git/<sanitized-remote-fqn>/worktrees/branch/<branch-name>`
- `<sanitized-remote-fqn>` is derived from `git config --get remote.origin.url`:
  strips `git@`/`.git`, lowercases, and replaces non `[a-z0-9-]` characters with `_`
  (e.g. `git@github.com:FaithBibleInstitute/FaithBI.git` → `github_com_faithbibleinstitute_faithbi`).

What the script does, in order:
1. Resolves `BASE_BRANCH` and parses `<branch-name>`.
2. Locates the real repo root (`ORIGINAL_CLONE_PATH`) via `git rev-parse --git-dir`,
   so it works even when run from inside an existing worktree.
3. Creates `WORKTREE_PATH` under `~/.local/git/...`.
4. `git fetch origin "$BASE_BRANCH"`, then
   `git worktree add -B "$BRANCH_NAME" "$WORKTREE_PATH" "origin/$BASE_BRANCH"`.
   Exits if either fails.
5. Runs the setup hook, if one exists (see below). A failing hook is reported
   and the script exits non-zero, but the worktree is left in place.

## Tearing down a worktree

```
git-teardown-worktree [-d] [-f] <branch-name>
```

- `-d` — also delete the local branch.
- `-f` — skip the teardown hook and force-remove the worktree even if dirty.

Runs the teardown hook first; a non-zero exit aborts removal so nothing is
removed out from under a live cluster/server. Then `git worktree remove`.

## Hooks

Both scripts look up an executable hook, first match wins:

| | setup | teardown |
|---|---|---|
| 1. committed to the branch | `$WORKTREE_PATH/.worktree-setup` | `$WORKTREE_PATH/.worktree-teardown` |
| 2. shared by all worktrees | `$ORIGINAL_CLONE_PATH/.worktree-setup` | `$ORIGINAL_CLONE_PATH/.worktree-teardown` |
| 3. personal, untracked | `~/.local/git/<sanitized-remote-fqn>/worktree-setup` | `~/.local/git/<sanitized-remote-fqn>/worktree-teardown` |

Option 3 sits next to the `worktrees/` dir and never touches the repo — prefer
it for client repos where Kaleb doesn't want to commit personal tooling.

Hook arguments (PWD is the worktree in both cases):
- setup: `$1` worktree path, `$2` branch name, `$3` original clone path
- teardown: `$1` worktree path, `$2` branch name (get the original clone via
  `git rev-parse --path-format=absolute --git-common-dir`)

When writing hooks: make them executable (`chmod +x`), and have teardown mirror
setup (undo whatever setup created, and stop anything it started).

### Common setup building blocks

These used to be hardcoded in `git-new-worktree` and now belong in hooks:
- **Symlink the root `.env`** from the original clone so all worktrees share it live:
  `ln -sf "$ORIGINAL_CLONE_PATH/.env" "$WORKTREE_PATH/"`
- **Per-worktree `.env.*` copies with unique ports**: pipe each `.env.<something>`
  (excluding `.env.example`, and skipping encrypted `*.gpg`) through
  `uniqify-env-ports` (in `~/.bin`) into the worktree. Plain mode only avoids
  ports currently bound, so stopped clusters' ports can be handed out again. Prefer
  `--slot N` (every port offset by `N * 100`, exit 2 if any is taken) with the hook
  choosing a slot no other checkout's `.env.local` records, plus `--reserve` for
  ports other checkouts already claim. Keep `uniqify-env-ports` generic; anything
  repo-specific (which keys, where slots are stored) goes in the hook.

### Example: FaithBI

`~/.local/git/github_com_faithbibleinstitute_faithbi/worktree-setup`:
- symlinks `.env`, writes `.env.*` copies with ports offset by the lowest free
  `WORKTREE_SLOT` (read from every `git worktree list` checkout's `.env.local`;
  the main clone is slot 0). Adds every `${X_PORT:-default}` that
  `docker-compose.yml` publishes to `.env.local` first so they all get offset, and
  reserves those defaults plus other checkouts' ports
- sets `WORKTREE_NAME` (branch lowercased, `/` → `--`, other invalid chars → `-`) and
  `COMPOSE_PROJECT_NAME=fbi-$WORKTREE_NAME` in the worktree's `.env.local`, giving
  each worktree its own docker compose cluster (the repo's `run` script sources `.env.local`)

`.../worktree-teardown`:
- `docker compose -p "$COMPOSE_PROJECT_NAME" down --remove-orphans`, skipped if the
  name matches the original clone's (so it never takes down `fbi-main`)
- removes the `.env` symlink and generated `.env.*` copies

## Explaining behavior to Kaleb

- Worktree path: always `~/.local/git/<sanitized-remote-fqn>/worktrees/branch/<branch-name>`.
- Env files, ports, compose names, etc.: whatever that repo's setup hook does —
  find the hook via the lookup order above and read it rather than assuming.
- No hook found → the worktree is a plain checkout; nothing project-specific happens.

## Constraints

- Never suggest storing worktrees inside the target repo (e.g. under a `tmp/` dir) —
  deliberately abandoned; Kaleb wants zero dependency on client repo structure.
- Never hardcode `main` or `master` in the scripts — the base branch must stay
  overridable via `-b` or `GIT_NEW_WORKTREE_BASE_BRANCH`.
- Keep the scripts generic. Project-specific logic goes in hooks, never back into
  `git-new-worktree` / `git-teardown-worktree`.
- The canonical source for the scripts is `stow-shell-config/.bin/` in Kaleb's
  dotfiles repo. Edit them there (they're stowed, so changes take effect immediately).
