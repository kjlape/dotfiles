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

`stow-agent-skills/` holds skills for AI coding agents. The generic `~/.agents/skills/` location is the source of truth:

```
stow-agent-skills/
  .agents/skills/<name>/SKILL.md                     # the skill itself
  .claude/skills/<name> -> ../../.agents/skills/<name>
```

**Claude Code doesn't read `~/.agents/skills/`**, so every skill also needs a relative symlink under `.claude/skills/`:

```
ln -s ../../.agents/skills/<name> stow-agent-skills/.claude/skills/<name>
stow -v --target=$HOME stow-agent-skills
```

## Guarantee

**Works On My Machine™** guaranteed! 👍

Supports macOS and Linux (Arch/Omarchy). On Linux, uses Linuxbrew as the primary package manager with Flatpak and `omarchy pkg` as fallbacks for GUI applications.
