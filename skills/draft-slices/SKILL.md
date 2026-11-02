---
name: draft-slices
description: Draft a cycle's slice directory — 00-overview.md plus numbered slice files — from a validated pitch. Use when a pitch is `pitched` and needs breaking into vertical slices.
version: "1.4"
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
- **Appetite** bounds total scope, not slice count. Slice count falls out of the size budget in Step 4; there is no maximum. A cycle with many small slices is correct.

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

### Step 4 — Design the ship sequence

Order the work as a sequence of production ships. Each slice is one PR that merges to main and deploys on its own, in order. An audit of ~90 built slices found that foundation / parallel / wiring waves produced slices that shipped nothing observable, with the value landing in the last wave. Do not use that structure.

**Naming:** use verb phrases (`01-report-form-saves`, `02-report-reaches-linear`). The filename is the slice's identity — make it descriptive. Never name a slice `wiring`, `foundation`, `integration`, or `polish`; those names mark bundles.

**Size budget.** Target ≤100 changed LOC per slice, excluding tests, docs, lockfiles, and generated files. This is a design constraint, not a time estimate.
- Give every slice `est_loc` and an `analogue`: a past change in this repo of similar shape, with its measured size (`git log --shortstat`, cite the commit). If no analogue exists, say so and widen the estimate.
- Estimate the merged result, including expected review fixes and hardening. If hardening is expected, include it in the estimate or plan it as its own small slice; never leave it unplanned.
- Over budget: split along one more behavior, not one more layer. Cut a narrower case, a single entry point, or a single record type first, then widen in later slices.
- A slice that introduces a new subsystem (daemon, store, protocol, engine) is almost always over budget. Plan the thinnest path that exercises it end to end, then widen. Never plan "build the subsystem" as one slice.

**Value rules:**
- **Tracer bullet first.** Slice 01 is the thinnest complete path through the system: one input, one observable result, in production (dark or flagged if needed). Later slices widen it: more cases, more entry points, error handling, UI polish.
- Every slice states `ships:`, what a user or operator can observe in production after merge, in one sentence. If the honest answer is "nothing yet", the slice is `preparatory`.
- **Preparatory slices** (expand/contract steps, tidy-first refactors, a seam the next slice needs) are allowed only at ≤30 LOC, tagged `size_class: preparatory`, and immediately followed by the slice that uses them. One that cannot meet that bound is folded into its consumer, or the consumer is narrowed.
- Hide unfinished work behind a flag or an unlinked route. Do not hold a slice back until the whole feature is ready to expose.
- No wiring slice. Each slice wires its own piece. If a final integration slice seems necessary, the earlier slices were layers; redesign them.
- Spikes and research are not slices. Record them as a time-boxed pitch step with a written finding as the output, outside the slice sequence.

**Size classes** (`size_class` in each slice):
- `normal`: ≤100 LOC, ships observable value.
- `preparatory`: ≤30 LOC, no observable value, immediately precedes its consumer.
- `sweep`: one mechanical transform over many files; may exceed budget. See below.

**Sweep slices** cover repetitive, mechanical change (rename, API migration, adding an argument everywhere, pattern replacement). They are the only slices allowed to exceed 100 LOC, and only with:
- the transform stated as a one-sentence rule in the slice, plus the script, codemod, or command that applies it, committed with the slice;
- a reviewer check that does not require reading every hunk: a deterministic script, 3–5 sample before/after hunks in the slice, and a command that shows zero remaining matches;
- batches split by directory or module, each ≤300 changed LOC where the tooling allows, each mergeable alone;
- no behavior change mixed in. Renames and moves are their own slice.

**Any other size exception** is a failure to slice: split it. Record a genuine exception under `size_exception:` with the reason and list it in the overview's Slice Audit. Expect few.

**Dependencies:** slices are in strict order by default. Mark slices parallel only when they touch disjoint files and neither needs the other's code to merge. Shared files (for example one view or controller) mean sequence them.

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
- **Right-sized:** `est_loc` is ≤100 (or the slice is a labelled `preparatory` ≤30 or `sweep`), backed by a cited analogue. Small is good: do not merge a slice because it is only a few lines, as long as it ships observable value. Over budget means split it or cut scope.
- **Ships value:** the `ships:` line names something observable in production. If not, it is preparatory or it is merged into its consumer.

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
- No slice is purely a layer (schema, file, or config only); each is end-to-end functionality, or a labelled `preparatory` ≤30 LOC
- Every slice has `est_loc` ≤100 with a cited `analogue`, or `size_class: sweep` meeting the sweep rules, or a recorded `size_exception`
- Every slice has a `ships:` line naming what is observable in production after merge
- No slice is named or shaped as wiring, foundation, integration, or polish; slice 01 is a thin end-to-end tracer
- No spike or research is written as a slice
- Every Deliverable has an exact path
- No slice crosses a Rabbit Hole or implements a No Go from the pitch
- Slice-header dependencies match the `00-overview.md` ship sequence
- Frontmatter `wave` is the ship order (1-based); equal numbers only for genuinely parallel slices
- Tests name at least one test asserting `Done when`; add an acceptance test only when `Done when` is user-visible. Test volume is not part of the size budget but should stay proportionate to the change
- Deployment is present: a rollout, migration, flag, and rollback plan, or "Not applicable — <reason>"
- Every Deliverable and test traces to "Done when" and a pitch work stream; no opportunistic work
- Each slice is sufficient with only its declared dependencies — no missing interface, migration, or wiring step
- No deliverable is duplicated, and earlier-slice work is not silently folded into a later slice
- Every new library, tool, service, migration, or config value appears in Prerequisites with a delivering slice
- Feasibility claims name their source or are labeled assumptions — never asserted from memory
- Discovery findings cite `path:line`; no invented modules or files
- Cross-slice risks and ship checkpoints are recorded in the overview

---

## Output Format

Confirm:

- Files written: each path
- Ship sequence: one line with est LOC and what each ship delivers (e.g. "01 form saves (~60) → 02 reaches Linear (~80) → 03 nav entry (~70)")
- Size: slice count, median `est_loc`, and any `preparatory`, `sweep`, or `size_exception` slices with reasons
- Pitch updated: `status`, `started`, `slices` fields
- Prerequisites: new dependencies/tools and their delivering slices, or "none"
- Slice audit: verdict, plus merges, splits, and trims with reasons
- Feasibility: what you verified and with which sources, and any unconfirmed assumptions
- Risks and ship checkpoints: confirmed recorded in `00-overview.md`
- Deployment: slices with a real rollout/migration plan, and those marked not applicable with reasons
- Judgment calls: slices combined, rabbit holes avoided
- Next: slices are ready for `slice-planner` (`../slice-planner/SKILL.md`), which turns one slice into ordered steps, exact files, and runnable verification without changing scope or dependencies
