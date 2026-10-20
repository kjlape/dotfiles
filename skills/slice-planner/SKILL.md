---
name: slice-planner
description: Turn one already-drafted slice into an executable implementation plan — ordered steps, exact files, runnable verification commands, parallel tracks, and checkpoints. Use after draft-slices, when you need to decide how to build a specific slice without changing the cycle's scope or dependency graph.
version: "1.0"
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

The companion to `draft-slices` (`../draft-slices/SKILL.md`).

- **draft-slices** works at cycle altitude: it decides *what* work exists, cuts a pitch into vertical slices, and sets the wave/dependency graph.
- **slice-planner** works at one-slice altitude: it decides *how* a single drafted slice gets built, step by step, so an implementer (human or agent) can execute it without re-deriving the design.

It plans only. It does not add slices, change waves, edit the pitch, or advance lifecycle state. If planning reveals that the slice itself is wrong, stop and hand the finding back to `draft-slices` rather than silently widening scope.

## When to use

Use this skill when the user points at a slice file — `slices/<slug>/NN-<name>.md`. Before writing anything, all of these must hold. If one fails, stop and say which.

1. **A slice exists.** If the user has not named one, list `slices/` and ask which slice to plan. If no slice directory exists, hand off to `draft-slices` — do not invent slices here.

2. **The slice is complete enough to plan.** It must have:
   - `Depends on:` and `Parallel with:` in the header
   - an observable `Done when:`
   - at least one `### <Component> — \`<path>\`` deliverable with an exact path
   - a `## Tests` section

   Missing fields mean the slice is underspecified. Report the gap and route it to `draft-slices`; do not fill it in by assumption.

3. **Constraints are in hand.** Read `pitches/<slug>.md` (Problem, Appetite, Solution, Rabbit Holes, No Gos) and `slices/<slug>/00-overview.md` (dependency graph, Architecture Conventions). If the pitch is missing, say so, plan from the slice plus overview alone, and flag the reduced confidence in the plan. The slice's Rabbit Holes and No Gos are hard constraints, not suggestions.

4. **The destination is free.** The default plan path is `slices/<slug>/plans/NN-<name>-plan.md`. If it already exists, show it and ask before overwriting.

5. **Dependencies are accounted for.** Check the state of every slice listed under `Depends on:`. If a dependency is not built yet, plan against its intended interface and open the plan with that assumption stated explicitly. Do not plan work that belongs to the dependency.

### Stop and report instead of planning when

- there is no slice directory → hand off to `draft-slices`
- the slice is missing required fields → it is not ready
- a step would require implementing a No Go or crossing a Rabbit Hole
- the plan needs a new deliverable or file that the slice does not list → that is a slice change; report it and let the human route it through `draft-slices`
- the slice needs splitting, resequencing, or a new dependency → report it; do not edit the graph
- the baseline is red in a way that is unrelated to the slice → that is a precondition, not part of this plan

## Workflow

### Step 1 — Read the ground truth

Read the slice file in full, then read the actual code it names: every file in `Deliverables`, their neighbours, the relevant tests, and the manifests/lockfiles that govern available libraries and versions. List directories rather than guessing structure. Follow the functional core / imperative shell boundary described in `00-overview.md`'s Architecture Conventions.

Treat the slice's `## Deployment` section as a constraint. If it is not "Not applicable", its rollout order, migration, and rollback requirements shape the step sequence — plan the migration or flag before the code that depends on it.

The goal is to replace recollection with what is on disk. Cite existing code as `path:line` in the plan wherever a step depends on it.

### Step 2 — Research anything that may be stale

Assume your knowledge of library versions, APIs, and current best practice is out of date, and verify it **by whatever means the environment offers**: package-manager and registry queries, lockfiles and vendored source, changelogs and release notes, local docs, `--help` and `--version`, a throwaway REPL or scratch probe, reading upstream source, web search/fetch if available, or asking the user.

Record each finding with its source and date. If a claim cannot be verified with the tools available, label it an **unverified assumption** in the plan and state what would settle it. Never present recall as verified fact, and never claim research you did not do.

### Step 3 — Establish the baseline

Run the slice's verification commands — or the repo's standard test command — before proposing changes. Record the exact command and its result. A plan written against an unknown baseline is a guess; if the baseline is red, include the required fix as a precondition step or call it out.

### Step 4 — Decompose into independently verifiable steps

Break the slice into the smallest steps that each leave the repo green and can be reviewed on their own. Granular, but not keystroke-level: if a step takes more than roughly half a day or sprawls across a dozen files, split it.

Every step records:

- **Outcome** — plain English, what is true after this step that was not before
- **Files** — exact paths, marked `new` or `modify`
- **Notes** — signatures, data shapes, patterns to follow, `path:line` references
- **Verify** — a copy-pasteable command runnable from the repo root, plus the expected result
- **Depends on** / **Parallel with** — step ids
- **Rollback** — how to undo it if it goes wrong

Order vertically: deliver behavior first and add only the scaffolding needed to make that behavior testable. Do not produce a "schema step" followed by a "logic step" followed by a "wiring step" unless the slice's own template requires that split. Every behavior change carries its test in the same step — never a separate "add tests" step at the end.

There are no `TODO: figure this out` steps. Resolve it, or list it under open questions.

### Step 5 — Mark sequence and parallelism

Identify the critical path, then group steps into stages. Two steps may run in parallel only if they touch disjoint files and share no migration, schema, or generated artifact. Mark parallel tracks explicitly and note that parallel agents need isolated worktrees.

### Step 6 — Risks, constraints, and checkpoints

Map every planned step against the pitch's Rabbit Holes and No Gos and record the check in the plan. Add a checkpoint after each stage: rerun the verification commands, and confirm the slice's observable `Done when` still points the right way. For risky steps, state the rollback before the step, not after it fails.

### Step 7 — Write the plan

Use `assets/plan-template.md` and write to `slices/<slug>/plans/NN-<name>-plan.md` (create the `plans/` directory if needed).

If the user explicitly asks for the plan inline, replace or create only an `## Implementation Plan` section inside the slice file. Leave the slice's frontmatter — `status`, `wave`, `completed`, `audited` — and all required template fields untouched.

Do not edit the pitch, the review record, or `00-overview.md`.

### Step 8 — Report

Tell the user:

- the plan path written
- the stage/critical-path summary in one line (e.g. "Stage 1: 1.1 → Stage 2: 2.1 ∥ 2.2 → Stage 3: 3.1")
- research performed, and every assumption left unverified
- any slice defects, scope issues, or follow-ups discovered (routed to `draft-slices`, not fixed here)

## Constraints / Do's and Don'ts

- Plan only. Do not write implementation code.
- Do not change the slice's frontmatter, wave, or dependencies.
- Do not invent deliverables or file paths. Proposing one is allowed only if it is flagged as a slice change for the human to approve.
- Do not weaken `Done when`. If it is not observable, flag it as a slice defect.
- Do not skip the baseline. "Tests presumably pass" is not a baseline.
- Do not present remembered APIs or versions as current. Research, or label the assumption.
- Do not write a plan another agent cannot execute without this conversation — no missing paths, no implicit ordering, no undefined names.
- Never mark a slice complete, advance its status, or create review records.
- Honor the slice's Deployment section. If it says "Not applicable" but the plan introduces a migration, flag, or sequenced rollout, record that contradiction as a slice defect rather than deciding unilaterally.
- A plan is done when an implementer can follow it start to finish and only needs a human for the open questions it lists.
