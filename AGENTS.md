# Agent notes

Setup: `./bootstrap.sh`; `yolo.sh` is Kaleb-only.

`skills/` holds canonical sources; install with `npx skills add kjlape/dotfiles`. Add a skill: create `skills/<name>/SKILL.md` (frontmatter: `name` = directory, `description` = what and when) plus optional `assets/`/`scripts/`; link it into the target harness dirs; run `./install.sh`; verify via `npx skills add . --list`.

`stow-agent-skills/` selects each harness's skills; `./install.sh` links only those, not all of `skills/`. `./link-skills <target-dir> <skill>...` (Python 3.9+) adds/relinks: repo-relative targets, missing dirs created, relative links to `skills/<name>/` (no copies), reruns refresh symlinks but never replace regular files or touch unmentioned skills.

| Target in this repo | Installed location |
| --- | --- |
| `stow-agent-skills/.claude/skills` | `~/.claude/skills/` |
| `stow-agent-skills/.pi/agent/skills` | `~/.pi/agent/skills/` |
| `stow-agent-skills/.agents/skills` | `~/.agents/skills/` |

Skills can't share a file by symlink. `npx skills add` (Skills CLI 1.9.0, checked 2026-11-24) silently drops symlinked files inside a skill, so the installed skill is missing them, with no error. Stow installs (`./install.sh`) keep them, which hides the problem locally. Until that changes, keep identical copies in each skill and list them in `tests/test_shared_skill_files.py`, which fails if they differ or are symlinks.

To recheck on a newer CLI (`npx skills --version`), link a file into a skill and install it into a scratch git repo: `npx skills add <dotfiles> --skill <name> -a claude-code -y --copy`. If the linked file arrives as a regular file, switch the shared files to one real copy plus links, and drop the test's symlink check.

Pi also loads `~/.agents/skills/` (Claude doesn't), so keep harness-only skills harness-specific.

Commit sources and links; after pulling, run `./install.sh` or `stow -v --target="$HOME" stow-agent-skills`.

Supports macOS and Linux (Arch/Omarchy); Linux uses Linuxbrew, with Flatpak and `omarchy pkg` fallbacks for GUI apps.
