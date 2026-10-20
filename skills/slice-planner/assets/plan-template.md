---
slice: slices/<slug>/NN-<name>.md
planned: <YYYY-MM-DD>
---

# Plan — NN <Slice Title>

**Slice restated:** <one sentence in your own words; if you cannot restate it plainly, the slice is unclear — stop and report.>

**Scope guard:** In scope — <what this plan builds>. Out of scope — <what belongs to other slices or to the pitch's No Gos>.

**Deployment:** <the slice's rollout order, flags, migration, and rollback, or "not applicable">.

**Baseline:** `<command run before any change>` → <result: pass/fail counts, or "failed because ...">.

---

## Research notes

| Question | Source (command, doc, URL, date) | Finding |
|---|---|---|
| <e.g. is library X still the current approach?> | <how you checked> | <what you learned> |

**Unverified assumptions:** <each assumption + what would settle it, or "none">

---

## Stages

```
Stage 1 (sequential): 1.1 → 1.2
Stage 2 (parallel):   2.1 ∥ 2.2
Stage 3 (sequential): 3.1
```

Critical path: <step ids>

### Stage 1 — <Name>

#### Step 1.1 — <Outcome in plain English>

- **Files:** `path/to/file` (new | modify), `path/to/test` (new | modify)
- **Notes:** <approach, public signatures, data shapes, patterns to follow, `path:line` references>
- **Depends on:** <step id, or "none">
- **Parallel with:** <step ids, or "none">
- **Verify:** `copy-pasteable command` → expected: <output or exit status>
- **Done when:** <observable condition>
- **Rollback:** <revert command or manual undo>

#### Step 1.2 — <Outcome in plain English>

...

### Stage 2 — <Name> (parallel)

#### Step 2.1 — <Outcome in plain English>

...

#### Step 2.2 — <Outcome in plain English>

...

---

## Checkpoints

- [ ] After Stage 1: `<command>` passes
- [ ] After Stage 2: `<command>` passes
- [ ] Slice's `Done when` is observable: <quote it> → <how to observe it>

---

## Rabbit-hole / No-Go check

| Pitch constraint | Touched by any step? | Why not / mitigation |
|---|---|---|
| <Rabbit Hole> | no | <reason> |
| <No Go> | no | <reason> |

---

## Open questions (need a human)

- <question, the options, and a recommendation — or "none">

## Discovered follow-ups (out of scope — do not implement here)

- <thing found while planning that belongs in another slice or a new pitch — or "none">

## Slice defects (route to draft-slices, do not self-fix)

- <missing field, non-observable done-when, wrong dependency, missing deliverable — or "none">
