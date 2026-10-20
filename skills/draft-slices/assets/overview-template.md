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

## Prerequisites

What must be true before Wave 1 can be built. Every new library, tool, service, migration, or config value this cycle introduces belongs here, and every entry names the slice that delivers it.

| Prerequisite | Why it is needed | Delivered by | Status |
|---|---|---|---|
| <library / tool / migration / env var> | <which slice or interface needs it> | `01-<name>` | planned / already present at `<path:line>` |

No entry may be left without a delivering slice. Anything unverified is marked `assumption` and repeated under Risks.

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

## Slice Audit

| Slice | Minimal | Sufficient | Notes |
|---|---|---|---|
| `01-<name>` | <every deliverable and test traces to Done when + a pitch work stream> | <slice plus declared dependencies reaches Done when> | <merged, split, trimmed, or none> |

**Verdict:** <one sentence — the set is minimal and sufficient, or what changed and why.>

## Risks & Checkpoints

Cross-slice risks only; per-slice tests live in the slice files. Include integration seams, migration ordering, external dependencies, and any assumption that would invalidate a wave.

| Risk | Affects | Mitigation | Checkpoint |
|---|---|---|---|
| <risk> | `02`, `03` | <what to do> | <observable signal> |

### Wave checkpoints

- [ ] After Wave 1: `<command>` passes; <interface or data model exists as planned>
- [ ] After Wave N: `<command>` passes; <integration behavior observable>
- [ ] Final: <the pitch's outcome is observable — quote it>

## Architecture Conventions

Describe the functional core / imperative shell boundary as it applies specifically to this cycle's files. Name the directories and their roles. Call out any pattern that differs from or extends what's already in the codebase.
