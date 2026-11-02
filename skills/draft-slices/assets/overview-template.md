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

What must be true before slice 01 can be built. Every new library, tool, service, migration, or config value this cycle introduces belongs here, and every entry names the slice that delivers it.

| Prerequisite | Why it is needed | Delivered by | Status |
|---|---|---|---|
| <library / tool / migration / env var> | <which slice or interface needs it> | `01-<name>` | planned / already present at `<path:line>` |

No entry may be left without a delivering slice. Anything unverified is marked `assumption` and repeated under Risks.

## Ship Sequence

Each row is one PR that merges and deploys on its own, in this order. Slice 01 is the thinnest end-to-end tracer. No wiring or integration slice.

| # | Slice | Class | Est LOC | Analogue | Ships (observable in production) |
|---|---|---|---|---|---|
| 1 | `01-<name>` | normal | <N> | <sha, size> | <what a user or operator can now do> |
| 2 | `02-<name>` | normal | <N> | <sha, size> | <what is newly observable> |

Parallel slices, if any, touch disjoint files and are listed with the same number. Shared files mean sequence them.

## Slice Audit

| Slice | Minimal | Sufficient | Right-sized | Notes |
|---|---|---|---|---|
| `01-<name>` | <every deliverable and test traces to Done when + a pitch work stream> | <slice plus declared dependencies reaches Done when> | <est_loc <=100 with analogue, or preparatory <=30, or sweep rules met> | <split, trimmed, size_exception reason, or none> |

**Verdict:** <one sentence — the set is minimal and sufficient, or what changed and why.>

## Risks & Checkpoints

Cross-slice risks only; per-slice tests live in the slice files. Include integration seams, migration ordering, external dependencies, and any assumption that would invalidate a slice.

| Risk | Affects | Mitigation | Checkpoint |
|---|---|---|---|
| <risk> | `02`, `03` | <what to do> | <observable signal> |

### Ship checkpoints

- [ ] After slice 01: `<command>` passes; <the tracer path is observable in production>
- [ ] After slice N: `<command>` passes; <newly observable behavior>
- [ ] Final: <the pitch's outcome is observable — quote it>
- [ ] Size review: compare each shipped slice's actual LOC to `est_loc`; record the drift in the slice's `commits`/`pr` fields

## Architecture Conventions

Describe the functional core / imperative shell boundary as it applies specifically to this cycle's files. Name the directories and their roles. Call out any pattern that differs from or extends what's already in the codebase.
