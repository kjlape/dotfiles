---
name: slice-planner
description: Turn one drafted slice into an executable plan — ordered steps, exact files, runnable verification, parallel tracks, and checkpoints. Use after draft-slices, when deciding how to build a slice without changing cycle scope or dependencies.
version: "1.1"
triggers:
  - "plan this slice"
  - "slice plan"
  - "plan the slice"
  - "implementation plan for slice"
  - "how do I build this slice"
  - "break down this slice"
---

# Slice Planner

## What this is

Companion to `draft-slices` (`../draft-slices/SKILL.md`).

- **draft-slices** works at cycle altitude: what work exists, cut into vertical slices, with a wave/dependency graph.
- **slice-planner** works at one-slice altitude: how that slice gets built, step by step, so an implementer can execute it without re-deriving the design.

It plans only: no new slices, waves, pitch edits, or lifecycle changes. If planning shows the slice is wrong, stop and hand the finding to `draft-slices` rather than widening scope.

## When to use

Use when the user points at `slices/<slug>/NN-<name>.md`. All conditions must hold before writing; if one fails, stop and say which.

1. **A slice exists.** If none is named, list `slices/` and ask. If no slice directory exists, hand off to `draft-slices` — do not invent slices.

2. **The slice is complete enough:** `Depends on:` and `Parallel with:` in the header, an observable `Done when:`, at least one `### <Component> — <path>` deliverable with an exact path, and a `## Tests` section. Missing fields are underspecified — report the gap to `draft-slices`; do not fill it by assumption.

3. **Constraints are in hand.** Read `pitches/<slug>.md` (Problem, Appetite, Solution, Rabbit Holes, No Gos) and `slices/<slug>/00-overview.md` (dependency graph, Architecture Conventions). If the pitch is missing, say so, plan from slice plus overview, and flag reduced confidence. Rabbit Holes and No Gos are hard constraints.

4. **The destination is free.** Default `slices/<slug>/plans/NN-<name>-plan.md`; if it exists, show it and ask before overwriting.

5. **Dependencies are accounted for.** Check every slice under `Depends on:`. If one is unbuilt, plan against its intended interface and state the assumption at the top of the plan. Do not plan the dependency's work.

### Stop and report instead of planning when

- there is no slice directory → hand off to `draft-slices`
- required fields are missing → not ready
- a step would implement a No Go or cross a Rabbit Hole
- the plan needs a deliverable the slice does not list → a slice change; report it for `draft-slices`
- the slice needs splitting, resequencing, or a new dependency → report it; do not edit the graph
- the baseline is red unrelated to the slice → a precondition, not part of this plan

## Workflow

### Step 1 — Read the ground truth

Read the slice in full, then the code it names: every `Deliverables` file, its neighbours, relevant tests, and the manifests/lockfiles governing libraries and versions. List directories rather than guessing structure. Follow the functional core / imperative shell boundary in `00-overview.md`.

Treat `## Deployment` as a constraint. If it is not "Not applicable", its rollout order, migration, and rollback requirements shape the step sequence — plan the migration or flag before dependent code.

The goal is to replace recollection with what is on disk. Cite existing code as `path:line` wherever a step depends on it.

### Step 2 — Research anything that may be stale

Assume your knowledge of versions, APIs, and current practice is out of date, and verify it **by whatever means the environment offers**: package-manager and registry queries, lockfiles, vendored source, changelogs, docs, `--help`/`--version`, a scratch probe, upstream source, web search/fetch if available, or asking the user.

Record each finding with source and date. If a claim cannot be verified, label it an **unverified assumption** and state what would settle it. Never present recall as verified fact or claim research you did not do.

### Step 3 — Establish the baseline

Run the slice's verification commands — or the repo's standard tests — before proposing changes. Record the command and result. A plan against an unknown baseline is a guess; if the baseline is red, add the fix as a precondition step or call it out.

### Step 4 — Decompose into independently verifiable steps

Break the slice into the smallest steps that leave the repo green and can be reviewed alone. Not keystroke-level: split anything over roughly half a day or a dozen files.

Every step records:

- **Outcome** — plain English, what is true afterward
- **Files** — exact paths, `new` or `modify`
- **Notes** — signatures, data shapes, patterns, `path:line` references
- **Verify** — a copy-pasteable command from the repo root, with expected result
- **Depends on** / **Parallel with** — step ids
- **Rollback** — how to undo it

Order vertically: deliver behavior first and add only the scaffolding needed to test it. Do not split into schema, logic, and wiring steps unless the slice's template requires it. Every behavior change carries its test in the same step — never a separate "add tests" step.

No `TODO: figure this out` steps: resolve them or list them as open questions.

### Step 5 — Mark sequence and parallelism

Identify the critical path, then group steps into stages. Two steps may run in parallel only if they touch disjoint files and share no migration, schema, or generated artifact. Mark parallel tracks and note that parallel agents need isolated worktrees.

### Step 6 — Risks, constraints, and checkpoints

Map every step against the pitch's Rabbit Holes and No Gos and record the check. Add a checkpoint after each stage: rerun the verification commands and confirm `Done when` still points the right way. For risky steps, state the rollback before the step, not after it fails.

### Step 7 — Write the plan

Use `assets/plan-template.md`, writing to `slices/<slug>/plans/NN-<name>-plan.md` (create `plans/` if needed).

If the user asks for it inline, replace or create only an `## Implementation Plan` section in the slice. Leave the frontmatter — `status`, `wave`, `completed`, `audited` — and all required fields untouched.

Do not edit the pitch, review record, or `00-overview.md`.

### Step 8 — Report

Tell the user:

- the plan path
- the stage/critical-path summary in one line (e.g. "Stage 1: 1.1 → Stage 2: 2.1 ∥ 2.2 → Stage 3: 3.1")
- research performed and every unverified assumption
- slice defects, scope issues, and follow-ups found (routed to `draft-slices`, not fixed here)

## Constraints / Do's and Don'ts

- Plan only; do not write implementation code.
- Do not change the slice's frontmatter, wave, or dependencies.
- Do not invent deliverables or paths. Propose one only as a flagged slice change for a human to approve.
- Do not weaken `Done when`; if it is not observable, flag it as a slice defect.
- Do not skip the baseline — "tests presumably pass" is not a baseline.
- Do not present remembered APIs or versions as current; research them or label the assumption.
- Do not write a plan another agent cannot execute without this conversation — no missing paths, implicit ordering, or undefined names.
- Never mark a slice complete, advance its status, or create review records.
- Honor `## Deployment`. If it says "Not applicable" but the plan introduces a migration, flag, or sequenced rollout, record the contradiction as a slice defect rather than deciding unilaterally.
- A plan is done when an implementer can follow it end to end and needs a human only for its open questions.
