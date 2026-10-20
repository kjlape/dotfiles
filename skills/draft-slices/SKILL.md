---
name: draft-slices
description: Draft a new cycle's slice directory — 00-overview.md + numbered slice files — from a validated pitch. Use when a pitch exists with status "pitched" and you need to break it into implementable vertical slices.
version: "1.2"
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

Use this skill when a pitch is ready to be broken into implementation work. All five conditions must hold before writing a single file — if any fail, stop and report:

1. **Pitch exists.** `pitches/<slug>.md` must be present. If no matching file exists, check `pitches/.archive/<slug>.md` — if found there, the cycle is already complete; stop with that explanation. Otherwise list what is in `pitches/` and stop.

2. **Pitch status is `pitched`.** Read the frontmatter. If `status` is anything other than `pitched`, stop with a clear explanation:
   - `in_progress` → slices are already being drafted or implemented; ask if they want to add slices to the existing cycle instead.
   - `complete` → cycle is done; nothing to draft.
   - `abandoned` → pitch was abandoned; confirm intent before proceeding.

3. **Pitch has all five required sections.** Scan the prose for: `## Problem`, `## Appetite`, `## Solution`, `## Rabbit Holes`, `## No Gos`. List any missing sections and stop.

4. **No existing slice directory.** Check whether `slices/<slug>/` or `slices/.archive/<slug>/` already exists. If either does, list its contents and stop — do not overwrite without explicit confirmation.

5. **Current review and human betting decision.** Check `pitches/.reviews/<slug>.md`. If present, read it in full and require `verdict: ready_for_betting`, `betting_decision: approved`, and a `pitch_sha256` matching the SHA-256 of the exact current pitch file bytes (for example, compute with `sha256sum pitches/<slug>.md`). Missing or malformed fields, a stale digest, an unready verdict, or pending/declined approval block slicing: return to `stress-test-pitch` (`../stress-test-pitch/SKILL.md`) and the human betting decision. Do not infer approval from the slicing request or rewrite the review to make it pass. Check the digest before this skill changes lifecycle frontmatter; those later lifecycle changes do not require a new product review.

   If the approved outcome is a non-software intervention, stop: hand off its bounded action, agreed owner, and evaluation checkpoint rather than inventing software implementation work to satisfy this skill.

   For an older or otherwise unreviewed pitch with no review record, recommend `stress-test-pitch` first. Proceed without review only if the user explicitly chooses to bypass it for this pitch and approves the bet. Record this exception in `00-overview.md` and flag it in the handoff; never create a passing review record on their behalf. This exception does not override an existing stale or non-passing review.

---

## Workflow / Steps

### Step 1 — Read and internalize the pitch

Read the full pitch before designing anything. Extract:

- **Work streams** from the Solution section: the distinct pieces of the system that need to be built. Each work stream becomes one or more slices.
- **Rabbit Holes** as hard scope constraints: anything the solution explicitly warns against touching. If a proposed slice would require crossing a rabbit hole, flag it and redesign.
- **No Gos** as absolute guards: if drafting a slice would require implementing a No Go, stop and flag it to the user.
- **Appetite** to calibrate depth: "one cycle" means ≤7 slices, each completable in a few hours. Do not over-slice.

---

### Step 2 — Ground the pitch in the codebase

The pitch describes intent; the repository describes reality. Before mapping work streams, read the code the cycle will touch. Budget this as structure-and-entry-points reading, not a full-tree read.

- List the directories and modules likely involved, plus their immediate neighbours.
- Read the head of the relevant files and their public interfaces — enough to learn existing patterns, naming, and layering.
- Read the tests nearest the proposed work to learn how behavior is verified here.
- Read manifests and lockfiles to know which libraries, versions, and scripts are actually available.
- Check the functional core / imperative shell boundary as it already exists, so new slices extend it rather than inventing a parallel convention.

Cite what you learned as `path:line` in `00-overview.md` (Context, Architecture Conventions) and use it to sanity-check the pitch's work streams. If the codebase contradicts the pitch's Solution — a named library is absent, a module it assumes does not exist, a pattern it forbids is load-bearing — stop and report. That is a pitch-level finding, not a slicing decision; route it back to the pitch or `stress-test-pitch`.

---

### Step 3 — Confirm feasibility against the codebase

The review at `pitches/.reviews/<slug>.md` is evidence, not proof: it confirms the bet was examined, not that its technical assumptions still hold against this checkout. Trust it, then verify the parts that would invalidate a slice if wrong:

- Every library, tool, service, or API the Solution depends on exists at the version available here, or is declared as a prerequisite.
- Any migration, schema change, or data shape the slices assume is compatible with what is on disk.
- Unresolved technical questions from the review are answered or carried forward explicitly — never assumed away.

Research with whatever means are available: lockfiles and manifests, installed tool versions, `--help`, upstream source and changelogs, documentation, a scratch probe, web search/fetch if present, or asking the user. Record what you checked and the source. If something cannot be verified, label it an assumption in the overview and say what would settle it — never present recall as confirmation.

If verification shows the pitch is not buildable as written, stop and route the finding back to the pitch or `stress-test-pitch` rather than re-slicing around a different solution.

---

### Step 4 — Design the dependency graph

Map the work streams to slices and assign wave numbers.

**Naming:** Use verb phrases matching the work being done: `01-engine-protocol`, `02-podman-engine`, `03-config-engine-select`, `04-wiring`. The filename is the slice's identity — make it descriptive.

**Wave rules:**
- **Wave 1:** Foundation — establishes the interface contract or data model everything else builds on. Usually sequential (one slice).
- **Middle waves:** Parallel implementation streams that can be built simultaneously once Wave 1 is done.
- **Final wave:** Wiring — assembles the parallel streams, runs integration tests, handles error propagation.

**Scope rules:**
- Aim for ≤7 slices. If you have more than 7, look for trivially sequential slices to combine.
- Each slice must be vertical end-to-end, not a layer. "Add DB schema" is a layer. "The `squad up` command persists an instance row and the test proves it" is a slice.
- Two slices that cannot be built independently must be in the same slice or in strict sequence (dependency declared in header).

---

### Step 5 — Write `slices/<slug>/00-overview.md`

Use the template at `assets/overview-template.md`. Fill in all placeholder fields; do not leave any `<angle bracket>` tokens in the output.

---

### Step 6 — Write each `slices/<slug>/NN-<name>.md`

Use the template at `assets/slice-template.md` for every slice file. Every field in the template is required — do not omit sections.

**One deliverable per file.** If a slice touches multiple files, list each with its own `### Component — path` subsection. Keep each entry to a responsibility and a path — signatures, ordering, and interface detail belong in the implementation plan (`slice-planner`), not here.

**Audit every slice for minimality and sufficiency** before updating the pitch. For each slice:

- **Minimal:** every Deliverable and test traces to the slice's `Done when` and to a work stream in the pitch. Drop "while we're here" work, speculative abstractions, and refactors that do not serve the observable outcome — record them as follow-ups instead.
- **Sufficient:** an implementer can reach `Done when` from the slice file plus its declared dependencies alone — no missing interface, migration, or wiring step. If they cannot, scope is missing.
- **No duplication:** no deliverable is built in two slices, and work assigned to an earlier slice is not quietly folded into a later one.
- **Right-sized:** a slice finishable in minutes is a step, not a slice — merge it. A slice that cannot plausibly finish in a few hours is too fat — split it or cut scope.

Record the verdict in the Slice Audit table in `00-overview.md`, including any slice you merged, split, or trimmed and why. Do not mark a slice sufficient just to avoid reopening the graph.

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

Apply to every slice before finishing. Fix any failures before moving on.

- "Done when" is observable: a test passes, a command prints something, a file is created — not "code is implemented"
- No slice is purely a layer (schema only, file only, config only) — each is end-to-end functionality
- Every Deliverable has an exact file path
- No slice requires crossing a Rabbit Hole or implementing a No Go from the pitch
- Dependencies in each slice header match the dependency graph in `00-overview.md`
- Tests section names at least one behavior/unit test and one CLI-level or acceptance test per slice
- Deployment section is present: either a rollout, migration, flag, and rollback plan, or an explicit "Not applicable — <reason>"
- Every Deliverable and test traces to the slice's "Done when" and to a pitch work stream; no opportunistic work
- Each slice is sufficient with only its declared dependencies — no missing interface, migration, or wiring step
- No deliverable is duplicated across slices, and earlier-wave work is not silently folded into a later slice
- Every new library, tool, service, migration, or config value appears in Prerequisites with a delivering slice
- Feasibility claims name their source or are labeled assumptions — never asserted from memory
- Discovery findings in `00-overview.md` cite `path:line`; no invented modules or files
- Cross-slice risks and per-wave checkpoints are recorded in the overview

---

## Output Format

Confirm to the user:
- Files written: list each path
- Wave structure: one-line summary (e.g., "Wave 1: 01 → Wave 2: 02 + 03 in parallel → Wave 3: 04")
- Pitch updated: confirm `status`, `started`, `slices` fields
- Prerequisites: new dependencies/tools and which slice delivers each, or "none"
- Slice audit: verdict, plus any slice merged, split, or trimmed and why
- Feasibility: what you verified and with which sources, and every assumption you could not confirm
- Risks and wave checkpoints: confirm they are recorded in `00-overview.md`
- Deployment: list slices with a real rollout/migration plan and slices marked not applicable, with the reason
- Any judgment calls made (slices combined, rabbit holes avoided) worth flagging
- Next step: each slice is now ready for implementation planning with `slice-planner` (`../slice-planner/SKILL.md`), which turns one slice file into ordered steps, exact files, and runnable verification commands without changing this cycle's scope or dependency graph
