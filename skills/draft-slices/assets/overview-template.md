---
status: planned
pitch: pitches/<slug>.md
cycle_started: ~
cycle_completed: ~
audited: <today YYYY-MM-DD>
---

# <Pitch Title> Slice Overview

**Context:** One paragraph explaining what this cycle adds relative to the existing codebase. Name the specific files or subsystems it extends or introduces.

**Scope:** One sentence on what this cycle touches and one sentence on what it explicitly does not touch.

## Dependency Graph

```
01-<name>
├── 02-<name>          (can start after 01)
└── 03-<name>          (can start after 01, parallel with 02)
         └── 04-<name>  (requires 01 + 02 + 03)
```

## Parallelism Opportunities

### Wave 1 — <Name> (sequential)
- **01** brief description of what this slice establishes

### Wave 2 — <Name> (N devs in parallel after Wave 1)
- **02** brief description
- **03** brief description

### Wave 3 — <Name> (sequential, assembles Wave 2)
- **04** brief description

## Architecture Conventions

Describe the functional core / imperative shell boundary as it applies specifically to this cycle's files. Name the directories and their roles. Call out any pattern that differs from or extends what's already in the codebase.
