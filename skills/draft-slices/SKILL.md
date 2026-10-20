---
name: draft-slices
description: Draft a cycle's slice directory — 00-overview.md plus numbered slice files — from a validated pitch. Use when a pitch is `pitched` and needs breaking into vertical slices.
version: "1.3"
triggers:
  - "draft slices"
  - "write slices"
  - "create slices"
  - "break pitch into slices"
  - "slice out"
  - "new cycle"
---

# Draft Slices

## When to use

Use this skill when a pitch is ready to slice. All five conditions must hold before writing any file; if one fails, stop and report:

1. **Pitch exists.** `pitches/<slug>.md` must exist. If only `pitches/.archive/<slug>.md` exists, the cycle is complete — stop with that explanation. Otherwise list `pitches/` and stop.

2. **Pitch status is `pitched`.** Read the frontmatter. Any other status stops with an explanation:
   - `in_progress` → slices already exist or are being built; ask whether to add to that cycle.
   - `complete` → nothing to draft.
   - `abandoned` → confirm intent before proceeding.

3. **Five required sections.** Scan for `## Problem`, `## Appetite`, `## Solution`, `## Rabbit Holes`, `## No Gos`; list any missing and stop.

4. **No slice directory.** If `slices/<slug>/` or `slices/.archive/<slug>/` exists, list it and stop; do not overwrite without explicit confirmation.

5. **Review and betting decision.** If `pitches/.reviews/<slug>.md` exists, require `verdict: ready_for_betting`, `betting_decision: approved`, and `pitch_sha256` matching the current pitch bytes (`sha256sum pitches/<slug>.md`). A missing or malformed field, stale digest, unready verdict, or pending/declined approval blocks slicing — return to `stress-test-pitch` (`../stress-test-pitch/SKILL.md`) and the human decision. Do not infer approval from the slicing request or rewrite the review. Check the digest before this skill changes lifecycle frontmatter; those changes need no new product review.

   If the approved outcome is a non-software intervention, stop and hand off its bounded action, owner, and evaluation checkpoint; do not invent software work.

   With no review record, recommend `stress-test-pitch` first. Proceed only if the user explicitly bypasses it and approves the bet. Record the exception in `00-overview.md` and the handoff; never create a passing review record. This does not override an existing stale or failing review.

---

## Workflow / Steps

### Step 1 — Read and internalize the pitch

Read the full pitch before designing. Extract:

- **Work streams** from Solution: distinct pieces to build; each becomes one or more slices.
- **Rabbit Holes** as hard constraints: if a slice would cross one, flag it and redesign.
- **No Gos** as absolute guards: if a slice would implement one, stop and flag it.
- **Appetite** to calibrate depth: one cycle means ≤7 slices, each finishable in a few hours. Do not over-slice.

---

### Step 2 — Ground the pitch in the codebase

The pitch describes intent; the repo describes reality. Before mapping work streams, read the code the cycle touches — structure and entry points, not the full tree.

- List the likely directories and modules plus immediate neighbours.
- Read file heads and public interfaces to learn existing patterns, naming, and layering.
- Read the nearest tests to learn how behavior is verified.
- Read manifests and lockfiles for available libraries, versions, and scripts.
- Check the existing functional core / imperative shell boundary so new slices extend it rather than invent a parallel convention.

Cite findings as `path:line` in `00-overview.md` (Context, Architecture Conventions) and use them to sanity-check the pitch's work streams. If the code contradicts the Solution — an absent library, a module that does not exist, a forbidden pattern already load-bearing — stop and report. That is a pitch-level finding; route it back to the pitch or `stress-test-pitch`.

---

### Step 3 — Confirm feasibility against the codebase

The review is evidence, not proof: it confirms the bet was examined, not that its technical assumptions hold against this checkout. Trust it, then verify what would invalidate a slice:

- Every library, tool, service, or API the Solution depends on exists at the version available here, or is declared as a prerequisite.
- Migrations, schema changes, and data shapes the slices assume match what is on disk.
- Unresolved technical questions from the review are answered or carried forward explicitly.

Research by whatever means are available: lockfiles, installed versions, `--help`, upstream source and changelogs, docs, a scratch probe, web search/fetch if present, or asking the user. Record each check and its source. If something cannot be verified, label it an assumption in the overview and say what would settle it — never present recall as confirmation.

If the pitch is not buildable as written, stop and route the finding back to the pitch or `stress-test-pitch` rather than re-slicing around a different solution.

---

### Step 4 — Design the dependency graph

Map work streams to slices and assign waves.

**Naming:** use verb phrases (`01-engine-protocol`, `02-podman-engine`, `03-config-engine-select`, `04-wiring`). The filename is the slice's identity — make it descriptive.

**Wave rules:**
- **Wave 1, foundation:** establishes the interface contract or data model everything builds on; usually one sequential slice.
- **Middle waves:** parallel streams buildable once Wave 1 is done.
- **Final wave, wiring:** assembles the streams, runs integration tests, handles error propagation.

**Scope rules:**
- Aim for ≤7 slices; combine trivially sequential ones.
- Each slice is vertical end-to-end, not a layer: "add DB schema" is a layer; "`squad up` persists an instance row and a test proves it" is a slice.
- Slices that cannot be built independently belong in one slice or in strict sequence (declare the dependency in the header).

---

### Step 5 — Write `slices/<slug>/00-overview.md`

Use `assets/overview-template.md`; fill every placeholder, leaving no `<angle bracket>` tokens.

---

### Step 6 — Write each `slices/<slug>/NN-<name>.md`

Use `assets/slice-template.md` for every slice; every field is required.

**One deliverable per file.** A slice touching multiple files gets a `### Component — path` subsection for each. Keep entries to a responsibility and a path — signatures, ordering, and interface detail belong in the implementation plan (`slice-planner`).

**Audit each slice for minimality and sufficiency** before updating the pitch:

- **Minimal:** every Deliverable and test traces to `Done when` and a pitch work stream. Drop "while we're here" work, speculative abstractions, and unrelated refactors; record them as follow-ups.
- **Sufficient:** the slice file plus declared dependencies alone reach `Done when` — no missing interface, migration, or wiring step.
- **No duplication:** no deliverable is built twice, and earlier-slice work is not quietly folded into a later one.
- **Right-sized:** minutes of work is a step, not a slice — merge it; work that cannot plausibly fit a few hours is too fat — split it or cut scope.

Record the verdict in the Slice Audit table in `00-overview.md`, including merges, splits, and trims with reasons. Do not mark a slice sufficient to avoid reopening the graph.

---

### Step 7 — Update pitch frontmatter

After all files are written, update `pitches/<slug>.md`:

```yaml
status: in_progress
started: <today YYYY-MM-DD>   # was ~
slices: slices/<slug>/         # was ~
```

Leave `completed` and `audited` unchanged — `audited` is set by the audit skill, not here.

---

## Constraints / Do's and Don'ts

Apply to every slice before finishing. Fix any failure before moving on.

- "Done when" is observable — a passing test, printed output, created file — not "code is implemented"
- No slice is purely a layer (schema, file, or config only); each is end-to-end functionality
- Every Deliverable has an exact path
- No slice crosses a Rabbit Hole or implements a No Go from the pitch
- Slice-header dependencies match the `00-overview.md` graph
- Tests name at least one behavior/unit test and one CLI or acceptance test per slice
- Deployment is present: a rollout, migration, flag, and rollback plan, or "Not applicable — <reason>"
- Every Deliverable and test traces to "Done when" and a pitch work stream; no opportunistic work
- Each slice is sufficient with only its declared dependencies — no missing interface, migration, or wiring step
- No deliverable is duplicated, and earlier-wave work is not silently folded into a later slice
- Every new library, tool, service, migration, or config value appears in Prerequisites with a delivering slice
- Feasibility claims name their source or are labeled assumptions — never asserted from memory
- Discovery findings cite `path:line`; no invented modules or files
- Cross-slice risks and per-wave checkpoints are recorded in the overview

---

## Output Format

Confirm:

- Files written: each path
- Wave structure: one line (e.g. "Wave 1: 01 → Wave 2: 02 + 03 in parallel → Wave 3: 04")
- Pitch updated: `status`, `started`, `slices` fields
- Prerequisites: new dependencies/tools and their delivering slices, or "none"
- Slice audit: verdict, plus merges, splits, and trims with reasons
- Feasibility: what you verified and with which sources, and any unconfirmed assumptions
- Risks and wave checkpoints: confirmed recorded in `00-overview.md`
- Deployment: slices with a real rollout/migration plan, and those marked not applicable with reasons
- Judgment calls: slices combined, rabbit holes avoided
- Next: slices are ready for `slice-planner` (`../slice-planner/SKILL.md`), which turns one slice into ordered steps, exact files, and runnable verification without changing scope or dependencies
