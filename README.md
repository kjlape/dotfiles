# 🔵🗂

👋 Hi, I'm Kaleb, and this is my collection of `.files`. If you find something useful, take it, it's yours! If you have suggestions for improvement, feel free to leave an issue on the repo.  I'm always eager to learn!

## Setup

Run `./bootstrap.sh`

### YOLO

Do not run this unless you're me.

```
/bin/bash -c "$(curl https://raw.githubusercontent.com/kjlape/dotfiles/master/yolo.sh)"
```

## Agent skills

`skills/` holds the canonical skill sources, including each skill's `SKILL.md` and supporting assets. Install them with the Skills CLI:

```sh
npx skills add kjlape/dotfiles
# Or install a specific skill:
npx skills add kjlape/dotfiles --skill draft-pitch
```

To preview discovery from a local checkout without installing anything:

```sh
npx skills add . --list
```

### Stow installation

The links tracked under `stow-agent-skills/` select which skills each harness receives. `./install.sh` installs those selections with Stow; it does not automatically install everything in `skills/` into every harness.

Use `./link-skills <target-dir> <skill>...` (Python 3.9+) to add or relink selected skills:

```sh
# Select Claude defaults:
./link-skills stow-agent-skills/.claude/skills draft-pitch draft-slices

# Pi-only defaults (independent of Claude's selection):
./link-skills stow-agent-skills/.pi/agent/skills adverse-review-pi

# Shared defaults for agents that read ~/.agents/skills/:
./link-skills stow-agent-skills/.agents/skills kjlape-worktree
```

| Target in this repo | Installed location |
| --- | --- |
| `stow-agent-skills/.claude/skills` | `~/.claude/skills/` |
| `stow-agent-skills/.pi/agent/skills` | `~/.pi/agent/skills/` |
| `stow-agent-skills/.agents/skills` | `~/.agents/skills/` |

**Pi also loads `~/.agents/skills/`**, so keep Pi-only or Claude-only skills in the harness-specific directories. These commands add links; they do not remove existing shared defaults. Claude Code does not read `~/.agents/skills/`.

The target directory is relative to this repository's root, even when calling the script from elsewhere. Missing directories are created. Every generated link points directly to `skills/<name>/` using a relative path, with no copied content or dependency on another harness's selection. Rerunning the command is safe: existing symlinks are refreshed, regular files/directories are never replaced, and unmentioned skills are left alone. Relinking an older Claude link also removes its previous dependency on the shared `.agents` link.

Commit the skill sources and selected links to propagate your defaults. After pulling on another machine, run `./install.sh`, or install only the skills package:

```sh
stow -v --target="$HOME" stow-agent-skills
```

## Guarantee

**Works On My Machine™** guaranteed! 👍

Supports macOS and Linux (Arch/Omarchy). On Linux, uses Linuxbrew as the primary package manager with Flatpak and `omarchy pkg` as fallbacks for GUI applications.
