---
name: draft-slices
description: Draft a cycle's slice directory — 00-overview.md plus numbered slice files — from a validated pitch. Use when a pitch is `pitched` and needs breaking into vertical slices.
version: "1.8"
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

All five conditions must hold before writing any file; if one fails, stop and report:

1. **Pitch exists.** `pitches/<slug>.md` must exist. If only `pitches/.archive/<slug>.md` exists, the cycle is complete — say so and stop. Otherwise list `pitches/` and stop.

2. **Pitch status is `pitched`.** Read the frontmatter. Any other status stops with an explanation:
   - `in_progress` → slices exist or are being built; ask whether to add to that cycle.
   - `complete` → nothing to draft.
   - `abandoned` → confirm intent before proceeding.

3. **Five required sections.** Scan for `## Problem`, `## Appetite`, `## Solution`, `## Rabbit Holes`, `## No Gos`; list any missing and stop.

4. **No slice directory.** If `slices/<slug>/` or `slices/.archive/<slug>/` exists, list it and stop; do not overwrite without explicit confirmation.

5. **Review and betting decision.** If `pitches/.reviews/<slug>.md` exists, require `verdict: ready_for_betting`, `betting_decision: approved`, and a `pitch_sha256` matching the current pitch bytes (`sha256sum pitches/<slug>.md`). A missing/malformed field, stale digest, unready verdict, or pending/declined approval blocks slicing — return to `stress-test-pitch` (`../stress-test-pitch/SKILL.md`) and the human decision. Never infer approval from the slicing request or rewrite the review. Check the digest before changing lifecycle frontmatter; those changes need no new product review.

   If the approved outcome is a non-software intervention, stop and hand off its bounded action, owner, and evaluation checkpoint; do not invent software work.

   With no review record, recommend `stress-test-pitch` first. Proceed only if the user explicitly bypasses it and approves the bet; record the exception in `00-overview.md` and the handoff, and never create a passing review record. This does not override an existing stale or failing review.

---

## Workflow / Steps

### Step 1 — Read and internalize the pitch

Read the full pitch before designing. Extract:

- **The job**: per work stream, who needs progress, in what circumstance, and how they would observe it. Slices are steps of progress on that job, not layers of code.
- **Work streams** from Solution: distinct pieces to build; each becomes one or more slices.
- **Rabbit Holes** as hard constraints: flag and redesign any slice that would cross one.
- **No Gos** as absolute guards: stop and flag any slice that would implement one.
- **Appetite** bounds total scope, not slice count; slice count falls out of the size budget in Step 4. Many small slices are correct provided each passes the floor.

---

### Step 2 — Ground the pitch in the codebase

Before mapping work streams, read the code the cycle touches — structure and entry points, not the full tree.

- List likely directories and modules plus immediate neighbours.
- Read file heads and public interfaces for existing patterns, naming, and layering.
- Read the nearest tests to learn how behavior is verified.
- Read manifests and lockfiles for available libraries, versions, and scripts.
- Check the existing functional core / imperative shell boundary so slices extend it rather than invent a parallel convention.

Cite findings as `path:line` in `00-overview.md` (Context, Architecture Conventions) and use them to sanity-check the work streams. If the code contradicts the Solution — an absent library, a nonexistent module, a forbidden pattern already load-bearing — stop and report; that is a pitch-level finding for the pitch or `stress-test-pitch`.

---

### Step 3 — Confirm feasibility against the codebase

The review confirms the bet was examined, not that its technical assumptions hold against this checkout. Verify what would invalidate a slice:

- Every library, tool, service, or API the Solution depends on exists at an available version, or is declared a prerequisite.
- Assumed migrations, schema changes, and data shapes match what is on disk.
- Unresolved technical questions from the review are answered or carried forward explicitly.

Research by any available means — lockfiles, installed versions, `--help`, upstream source and changelogs, docs, a scratch probe, web search/fetch, or asking the user — and record each check with its source. Anything unverifiable is labeled an assumption in the overview, with what would settle it; never present recall as confirmation.

If the pitch is not buildable as written, stop and route the finding back to the pitch or `stress-test-pitch` rather than re-slicing around a different solution.

---

### Step 4 — Design the ship sequence

Order the work as production ships. Each slice is one PR that merges to main and deploys on its own, in order: one observable step of progress on a job, for a named actor, in a named circumstance. Do not use foundation / parallel / wiring waves — an audit of ~90 slices found they shipped nothing observable until the last wave.

**Job step.** Every slice states its job step in one line:

> When **[circumstance]**, **[actor]** can **[progress]**, observed via **[named command / log line / UI / query]**.

Actors are end user, admin, system/operator, or dev, stated with nouns and verbs — "faster" or "more robust" is not progress. A dev actor needs a concrete before/after check (e.g. "when I add a third engine, I can do it without touching the dispatcher", shown by a test or a diff). The job is larger than the slice; each slice moves one step along one axis.

**Naming:** verb phrases (`01-report-form-saves`, `02-report-reaches-linear`); the filename is the slice's identity. Never name a slice `wiring`, `foundation`, `integration`, or `polish` — those names mark bundles.

**Walking skeleton.** Slice 01 is the walking skeleton unless the repo already has an end-to-end path: "When I change code, I can see it build, deploy and pass one end-to-end check." Its actor is dev or system; it need not carry user value; keep it hello-world sized. Slice 02 is the first user-facing slice; later slices widen it — more cases, more entry points, error handling, UI polish.

**Size budget.** Target ≤100 changed LOC per slice, excluding tests, docs, lockfiles, and generated files; LOC is a soft tripwire for review size, not a hard limit. A slice over budget is still shippable: an overage up to 1.5× the budget (≤150 LOC) is recorded (`size_exception:` and the Slice Audit) and shipped — do not stop in-flight work to re-slice around the number. Only an overage past 1.5× signals a genuinely oversized job step: re-cut along a split axis. An under-budget slice still must pass the floor below.

- Give every slice `est_loc` and an `analogue`: a past change of similar shape in this repo, with measured size (`git log --shortstat`, cite the commit). No analogue → say so and widen the estimate. Recorded overages are tuning data for `est_loc` and the budget in a later pass (see the overview's Size review checkpoint), not a reason to redo the current one.
- Estimate the merged result, including expected review fixes and hardening; hardening is either in the estimate or its own small slice — never unplanned.
- A new subsystem (daemon, store, protocol, engine) is almost always over budget. Plan the thinnest end-to-end path through it, then widen. Never plan "build the subsystem" as one slice.

**Value rules:**
- Every slice states its Job section in the job-step form (body, not frontmatter). If the honest answer to "what would the actor observe after merge" is "nothing", it has no named actor or circumstance — merge or redesign.
- Hide unfinished work behind a flag or an unlinked route; don't hold slices back until the whole feature is ready.
- No wiring slice: each slice wires its own piece. A seemingly necessary final integration slice means the earlier slices were layers — redesign.
- Spikes and research are not slices; record them as time-boxed pitch steps with a written finding, outside the sequence. QA harnesses, corpora, and manual checks that change nothing an actor can do are likewise not slices — record them as operational checkpoints in the overview's Ship checkpoints list.
- Hardening slices name the failure they close and the actor who would hit it.

**Floor — merge a slice into its neighbour** unless all three hold:
1. **Circumstance and actor.** A named actor in a real situation would notice this slice was never built; otherwise it's a non-story — fold it into the slice it serves.
2. **Real split axis.** It differs from its neighbour along one axis: workflow step, operation, business rule, data variant, entry method, simple vs complex, or deferred performance.
3. **The split buys something.** Less risk, droppable work, or a different order becomes possible.

**Ceiling — split a slice** whose job statement needs "and" or spans two circumstances, and check each slice is visibly different from its predecessor. An overage past 1.5× the budget is re-cut along an axis, never trimmed; a smaller overage is recorded as a `size_exception` and shipped. When in doubt whether an overage is "large", it is a reviewer call — default to recording and shipping.

**Size classes** (`size_class` in each slice):
- `normal`: ≤100 LOC, one observable job step.
- `sweep`: one mechanical transform over many files; may exceed budget. See below.

**Sweep slices** cover repetitive mechanical change (rename, API migration, adding an argument everywhere, pattern replacement). They are the only slices allowed past 100 LOC, and only with:
- the transform stated as a one-sentence rule, plus the committed script, codemod, or command that applies it;
- a reviewer check that doesn't require reading every hunk: a deterministic script, 3–5 sample before/after hunks, and a command showing zero remaining matches;
- batches split by directory or module, each ≤300 changed LOC where tooling allows, each mergeable alone;
- no behavior change mixed in — renames and moves are their own slice.

**Any size exception** — anything over budget that is not a `sweep` — is recorded under `size_exception:` with the reason and listed in the overview's Slice Audit. Overages ≤1.5× the budget ship as-is; those past 1.5× are re-cut along an axis. These records are tuning data for a later pass, not in-flight blockers. Expect few.

**Dependencies:** strict order by default. Mark slices parallel only when they touch disjoint files and neither needs the other's code to merge; shared files (e.g. one view or controller) mean sequence them.

---

### Step 5 — Write `slices/<slug>/00-overview.md`

Use `assets/overview-template.md`; fill every placeholder, leaving no `<angle bracket>` tokens.

---

### Step 6 — Write each `slices/<slug>/NN-<name>.md`

Use `assets/slice-template.md`; every field is required.

**One deliverable per file.** A slice touching multiple files gets a `### Component — path` subsection per file. Keep entries to a responsibility and a path — signatures, ordering, and interface detail belong in the implementation plan (`slice-planner`).

**Audit each slice for minimality and sufficiency** before updating the pitch:

- **Minimal:** every Deliverable and test traces to `Done when` and a pitch work stream. No "while we're here" work, speculative abstractions, or unrelated refactors — record them as follow-ups.
- **Sufficient:** the slice file plus declared dependencies alone reach `Done when` — no missing interface, migration, or wiring step.
- **No duplication:** nothing is built twice, and earlier-slice work is not quietly folded into a later one.
- **Right-sized:** `est_loc` backed by a cited analogue; ≤100 preferred, or labelled `sweep`. Small is fine as long as the floor passes — don't merge just because a slice is short. An overage past 1.5× the budget → re-cut along an axis, not trim; smaller → record as `size_exception` and move on.
- **Ships progress:** the Job section names actor, circumstance, and named observation, and passes the floor tests; otherwise merge into the neighbour.

Record the verdict in the Slice Audit table in `00-overview.md`, including merges, splits, and trims with reasons. Never mark a slice sufficient just to avoid reopening the graph.

---

### Step 7 — Update pitch frontmatter

After all files are written, update `pitches/<slug>.md`:

```yaml
status: in_progress
started: <today YYYY-MM-DD>   # was ~
slices: slices/<slug>/         # was ~
```

Leave `completed` and `audited` unchanged — `audited` is set by the audit skill.

---

## Constraints / Do's and Don'ts

Apply to every slice before finishing; fix any failure before moving on.

- "Done when" is observable — a passing test, printed output, created file — not "code is implemented"
- No slice is purely a layer (schema, file, or config only); each is end-to-end functionality, or a dev-actor slice with a concrete before/after check
- Every slice has `est_loc` ≤100 with a cited `analogue`, or `size_class: sweep` meeting the sweep rules, or a recorded `size_exception`, and names its split axis in `axis:`
- Every slice has a Job section naming circumstance, actor, progress, and a named observation, and passes all three floor tests
- No slice is named or shaped as wiring, foundation, integration, or polish; slice 01 is a hello-world-sized walking skeleton (unless the repo already has an end-to-end path)
- No spike or research written as a slice
- Every Deliverable has an exact path
- No slice crosses a Rabbit Hole or implements a No Go
- Slice-header dependencies match the `00-overview.md` ship sequence
- Frontmatter `wave` is the ship order (1-based); equal numbers only for genuinely parallel slices
- Tests name at least one test asserting `Done when`; add an acceptance test only when `Done when` is user-visible. Test volume stays proportionate — it's outside the size budget
- Deployment is present: rollout, migration, flag, and rollback plan, or "Not applicable — <reason>"
- Every Deliverable and test traces to "Done when" and a pitch work stream; no opportunistic work
- Each slice is sufficient with only its declared dependencies
- No deliverable is duplicated or silently folded into a later slice
- Every new library, tool, service, migration, or config value appears in Prerequisites with a delivering slice
- Feasibility claims name their source or are labeled assumptions — never asserted from memory
- Discovery findings cite `path:line`; no invented modules or files
- Cross-slice risks and ship checkpoints are recorded in the overview

---

## Output Format

Confirm:

- Files written: each path
- Ship sequence: one line with est LOC and each ship's actor and progress (e.g. "01 skeleton builds+deploys (~15, dev) → 02 form saves (~60, end user) → 03 reaches Linear (~80, end user)")
- Size: slice count, median `est_loc`, and any `sweep` or `size_exception` slices with reasons
- Pitch updated: `status`, `started`, `slices` fields
- Prerequisites: new dependencies/tools and their delivering slices, or "none"
- Slice audit: verdict, plus merges, splits, and re-cuts with reasons
- Feasibility: what was verified and with which sources, plus unconfirmed assumptions
- Risks and ship checkpoints: confirmed recorded in `00-overview.md`
- Deployment: slices with a real rollout/migration plan, and those marked not applicable with reasons
- Judgment calls: slices combined, rabbit holes avoided
- Next: slices are ready for `slice-planner` (`../slice-planner/SKILL.md`)
