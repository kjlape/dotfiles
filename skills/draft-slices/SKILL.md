---
name: draft-slices
description: Draft a cycle's slice directory — 00-overview.md plus numbered slice files — from a validated pitch. Use when a pitch is `pitched` and needs breaking into vertical slices.
version: "1.9"
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

1. **Pitch exists.** `pitches/<slug>.md` must exist. If only `pitches/.archive/<slug>.md` exists, the cycle is complete — stop. Otherwise list `pitches/` and stop.

2. **Pitch status is `pitched`, or `in_progress` with an existing map.** From frontmatter:
   - `pitched` → proceed.
   - `in_progress` → if `slices/<slug>/` contains a map from this skill, follow **Re-slicing an existing map**; if not (or archived), ask whether to add to that cycle.
   - `complete` → nothing to draft. `abandoned` → confirm intent first.

3. **Five required sections.** `## Problem`, `## Appetite`, `## Solution`, `## Rabbit Holes`, `## No Gos`; list any missing and stop. (In a re-slice run, a pitch revised after review is expected — don't block.)

4. **Slice directory.** If `slices/<slug>/` or `slices/.archive/<slug>/` exists:
   - Existing map from this skill → do not stop or overwrite; draft a versioned map (v2, v3, …) per **Re-slicing an existing map**.
   - Other content or no prior map → list it and stop; never overwrite without explicit confirmation.

5. **Review and betting decision.** If `pitches/.reviews/<slug>.md` exists, require `verdict: ready_for_betting`, `betting_decision: approved`, and `pitch_sha256` matching current pitch bytes (`sha256sum pitches/<slug>.md`). A missing/malformed field, unready verdict, or pending/declined approval blocks slicing — return to `stress-test-pitch` (`../stress-test-pitch/SKILL.md`) and the human decision. Never infer approval from the request or rewrite the review. Check the digest before changing lifecycle frontmatter; those changes need no new product review.

   **In a re-slice run**, a digest mismatch from post-review pitch revisions is expected: record `review stale: pitch revised after review` in the overview and continue. A never-ready verdict or declined approval still blocks.

   If the approved outcome is a non-software intervention, stop and hand off its bounded action, owner, and evaluation checkpoint; do not invent software work.

   With no review record, recommend `stress-test-pitch` first. Proceed only if the user explicitly bypasses it and approves the bet; record the exception in `00-overview.md` and the handoff, and never fabricate a passing review. This does not override an existing stale or failing review.

---

## Re-slicing an existing map

When a cycle already has a slice map, treat the new run as a **second opinion**, not an error. Don't ask for confirmation; open with one line and proceed unless the user stops it:

> A slice map already exists (v1, drafted with `draft-slices` v1.4, N slices, M shipped). Drafting v2 as a second opinion.

Assume the developer wants this, especially when the skill version differs from the earlier map's.

**Version the map.** Read prior `vN/` directories for the highest version; write the new map to `slices/<cycle>/vN/` (`00-overview.md` plus slice files). Earlier maps stay untouched — never overwrite or delete one. Read the earlier overview for its drafting skill version and shipped slices.

**Treat shipped work as fixed.** Shipped or in-flight slices stay as they are, with actual LOC and PRs; the new map slices only remaining work and refers to shipped slices as context. Their `est_loc` vs actual LOC are calibration data for Step 4.

**Record the differences.** The new overview opens with a short comparison: skill versions, slice counts (shipped listed separately), merges/splits/reorders/drops of remaining slices and why, and any newer-skill rule that changed the outcome.

**Leave the choice to the developer.** Both maps stay on disk; the new one is marked `proposed`. The overview names the current map only if the developer says so. `slice-planner` builds only the map marked `current` — an unchosen v2 never gets built by accident.

**Fresh maps.** Write directly into `slices/<slug>/`; implicitly current once the pitch frontmatter points at it. Don't stamp `audited` on a fresh draft.

---

## Workflow / Steps

### Step 1 — Read and internalize the pitch

Read the full pitch before designing. Extract:

- **The job**: per work stream, who needs progress, in what circumstance, and how they'd observe it. Slices are steps of progress on that job, not layers of code.
- **Work streams** from Solution: each becomes one or more slices.
- **Rabbit Holes** as hard constraints: flag and redesign any slice crossing one.
- **No Gos** as absolute guards: stop and flag any slice implementing one.
- **Appetite** bounds total scope, not slice count; count falls out of the size budget (Step 5).

---

### Step 2 — Ground the pitch in the codebase

Before mapping work streams, read the code the cycle touches — structure and entry points, not the full tree.

- List likely directories and modules plus neighbours; read file heads and public interfaces for existing patterns, naming, and layering.
- **Search for call sites, not just definitions:** for any component a slice replaces or reshapes, find every constructor, caller, and importer (`rg "<ClassName>"`, `rg "\.<method>\("`) — don't hope file heads reveal them. Each replacing slice must name every call site it updates.
- Read the nearest tests; read manifests and lockfiles for libraries, versions, scripts.
- Check the functional core / imperative shell boundary so slices extend it rather than invent a parallel convention.
- **Note lifecycle:** if a slice creates resources (files, records, processes, config) and none removes them, order a teardown slice early (when teardown is cheap) or state in the creating slice how the resources are removed until it lands.

Cite findings as `path:line` in `00-overview.md` (Context, Architecture Conventions) to sanity-check the work streams. If the code contradicts the Solution — absent library, nonexistent module, a forbidden pattern already load-bearing — stop and report; that's a pitch-level finding.

---

### Step 3 — Confirm feasibility against the codebase

The review confirms the bet was examined, not that its assumptions hold against this checkout. Verify what would invalidate a slice:

- Every library, tool, service, or API the Solution depends on exists at an available version, or is declared a prerequisite.
- Assumed migrations, schema changes, and data shapes match what's on disk.
- Unresolved review questions are answered or carried forward explicitly.

Research by any means — lockfiles, installed versions, `--help`, upstream source and changelogs, docs, a scratch probe, web search/fetch, asking the user — recording each check with its source. Anything unverifiable is labeled an assumption in the overview, with what would settle it; never present recall as confirmation.

If the pitch isn't buildable as written, stop and route the finding back to the pitch or `stress-test-pitch` rather than re-slicing around a different solution.

---

### Step 4 — Calibrate against the team's own merged PRs

Before setting the size budget, measure how this team actually ships; write a **Calibration** table in the overview.

**Pull the evidence.** List the last 40–50 merged PRs to the default branch, e.g.:
`gh pr list --state merged --limit 50 --json number,title,additions,deletions,commits,mergedAt,createdAt,reviews,files`
Fall back to `git log --merges` if `gh` can't reach a remote. In a re-slice run, add the earlier map's shipped slices as data.

**Measure each PR the same way.** Insertions plus deletions of **non-test source only** (exclude lockfiles, `schema.rb`, generated files, fixtures, snapshots; whole-file delete counts as 1). Record first-commit and merged size.

**Screen for compliance** — a PR is an exemplar only if it passes all:

| Screen | Test |
|---|---|
| One job | Title and description name one behavior; title has no "and" |
| Observable behavior | Ships something observable, or is a declared migration or preparatory change |
| Size | ≤1.5× the skill's budget |
| No fix tail | No revert; no follow-up "fix" PR within ~7 days touching the same files |
| Healthy review | Two review rounds or fewer |
| Not mechanical | Not a dependency bump, bulk rename, wave bundle, or generated-code import |

Don't accept a PR as an exemplar just because it merged. Report how many of the 40–50 failed, one line of reason each. If most failed, the team's habit isn't a usable norm — say so.

**Derive from passing PRs:**
- **Typical size:** median and p75 of merged LOC.
- **Inflation factor:** median merged/first-commit ratio, computed for passing and failing PRs separately. Replaces any fixed 1.4×/1.5× assumption.
- **Fix-tail rate:** share of PRs (both groups) needing a follow-up fix.

**Use the numbers:**
- **≥8 passing:** target slice size = their p75, capped by the skill's budget — team signal can tighten, never loosen.
- **<5 passing:** ignore team signal, use the skill default, record `team norm: not established`.
- **Per slice:** cite the closest 1–2 passing PRs as analogues; `est_loc` = analogue first-commit size × inflation factor; cross-check against a bottom-up count of the named files — if they differ >2×, write down why.
- **Greenfield:** bottom-up × nearest sibling repo's factor, or 1.5× if none; write `analogue: none (greenfield)` once. After the first three slices ship, recompute from actuals and re-estimate the rest.
- **Hardening:** include the inflation factor; name the specific failure the slice closes.

**Close the loop.** When a slice ships, fill in `pr`, `commits`, actual LOC, and the estimate-to-actual ratio (Ship checkpoints → Size review). Calibrate again next cycle — the only signal that estimates are improving.

---

### Step 5 — Design the ship sequence

Order the work as production ships. Each slice is one PR that merges to main and deploys on its own, in order: one observable step of progress on a job, for a named actor, in a named circumstance. No foundation / parallel / wiring waves — an audit of ~90 slices found they shipped nothing observable until the last wave.

**Job step.** Every slice states its job step in one line:

> When **[circumstance]**, **[actor]** can **[progress]**, observed via **[named command / log line / UI / query]**.

Actors are end user, admin, system/operator, or dev, stated with nouns and verbs — "faster" or "more robust" is not progress. A dev actor needs a concrete before/after check (e.g. "when I add a third engine, I can do it without touching the dispatcher", shown by a test or diff). The job is larger than the slice; each slice moves one step along one axis.

**Naming:** verb phrases (`01-report-form-saves`, `02-report-reaches-linear`); the filename is the slice's identity. Never `wiring`, `foundation`, `integration`, or `polish` — those names mark bundles.

**Walking skeleton.** Slice 01 is the walking skeleton unless the repo already has an end-to-end path: "When I change code, I can see it build, deploy and pass one end-to-end check." Without deployment (e.g. a local CLI), the skeleton is the **thinnest runnable path**: "When I run the binary, one command executes end to end and prints observable output." Its actor is dev or system; it need not carry user value; keep it hello-world sized. Slice 02 is the first user-facing slice; later slices widen it — more cases, entry points, error handling, UI polish.

**Size budget.** The single statement of the size rule — audit, constraints, and templates defer to it:

- Target ≤100 changed LOC per slice, excluding tests, docs, lockfiles, generated files; a soft tripwire, not a hard limit.
- Up to 1.5× (≤150) is a **shippable exception**: record `size_exception:` with cause and ship. Don't stop in-flight work to re-slice around the number.
- Past 1.5× signals a genuinely oversized job step: re-cut along a split axis, never trim to fit.

Every `size_exception` names its cause: **new subsystem** (daemon, store, protocol, or engine whose thinnest end-to-end path already exceeds budget), **first-of-kind surface** (first slice through a new entry point or integration, where scaffolding dominates), or **measured analogue** (cited analogue PR of the same shape that also landed above budget). A new subsystem is almost always over budget: plan its thinnest end-to-end path, then widen. Never plan "build the subsystem" as one slice.

**Merge floor.** Merge a slice into its neighbour when **all** hold: ≤40 LOC combined, same component, one shared `Done when` check — unless the small slice ships independently valuable behavior (a named actor would notice it alone).

**Floor — keep a slice separate** only if **all three** hold:
1. **Circumstance and actor:** a named actor in a real situation would notice this slice was never built; otherwise fold it into the slice it serves.
2. **Real split axis:** it differs from its neighbour along one axis — workflow step, operation, business rule, data variant, entry method, simple vs complex, deferred performance.
3. **Concrete buy:** at least one of — merging would violate the merge-floor conditions; the work is droppable without losing the neighbour's value; or it can be reordered after the neighbour. "It feels cleaner separate" is not a buy.

**Ceiling — split a slice** when either fires:
- Its job statement needs "and" to connect two *independent* observations (two actors, circumstances, or Done-when checks no single test asserts). A compound verb phrase describing one observation is fine: "save and show the form" is one slice if the check is one test.
- It exceeds 1.5× the budget with no `size_exception` cause.

Check each slice is visibly different from its predecessor. A smaller overage is recorded as a `size_exception` and shipped. When in doubt whether an overage is "large", it's a reviewer call — default to recording and shipping.

**Size classes** (`size_class` in each slice):
- `normal`: ≤100 LOC, one observable job step.
- `sweep`: one mechanical transform over many files; the only class allowed past 100 LOC, and only with: the transform as a one-sentence rule plus the committed script, codemod, or command applying it; a reviewer check not requiring reading every hunk (deterministic script, 3–5 sample before/after hunks, a command showing zero remaining matches); batches split by directory or module, each ≤300 changed LOC where tooling allows, each mergeable alone; and no behavior change mixed in — renames and moves are their own slice.

**Any size exception** — over budget and not a `sweep` — is recorded under `size_exception:` with cause and listed in the overview's Slice Audit. These are tuning data for a later pass, not in-flight blockers. Expect few.

**Other value rules:**
- If the honest answer to "what would the actor observe after merge" is "nothing", there's no named actor or circumstance — merge or redesign.
- Hide unfinished work behind a flag or unlinked route; don't hold slices back until the whole feature is ready.
- No wiring slice: each slice wires its own piece. A seemingly necessary final integration slice means the earlier slices were layers — redesign.
- Spikes and research are not slices; record them as time-boxed pitch steps with a written finding, outside the sequence. QA harnesses, corpora, and manual checks that change nothing an actor can do are operational checkpoints in the overview's Ship checkpoints list.
- Hardening slices name the failure they close and the actor who'd hit it, and carry the inflation factor in `est_loc`.

**Dependencies:** strict order by default. Parallel only when slices touch disjoint files and neither needs the other's code to merge; shared files mean sequence them.

---

### Step 6 — Write `slices/<cycle>/00-overview.md`

Use `assets/overview-template.md`; fill every placeholder, no leftover `<angle brackets>`. Include the Calibration table and, in a re-slice run, the version comparison. Leave `audited: ~`; the audit skill stamps it.

---

### Step 7 — Write each `slices/<cycle>/NN-<name>.md`

Use `assets/slice-template.md`; every field is required.

**One deliverable per file.** A slice touching multiple files gets a `### Component — path` subsection per file. Keep entries to a responsibility and a path — signatures, ordering, and interface detail belong in the implementation plan (`slice-planner`).

**Audit each slice** before updating the pitch:

- **Minimal:** every Deliverable and test traces to `Done when` and a pitch work stream. No "while we're here" work, speculative abstractions, or unrelated refactors — record as follow-ups.
- **Sufficient:** slice file plus declared dependencies alone reach `Done when` — no missing interface, migration, wiring step, or un-listed call site.
- **No duplication:** nothing built twice; earlier-slice work not quietly folded into a later one.
- **Right-sized:** per the size budget — `est_loc` backed by a cited analogue and inflation factor, ≤100 preferred. Small is fine if the floor passes; don't merge just because a slice is short.
- **Ships progress:** Job section names actor, circumstance, and named observation, and passes the floor tests.

Record the verdict in the Slice Audit table in `00-overview.md`, with merges, splits, and trims and reasons. Never mark a slice sufficient just to avoid reopening the graph.

---

### Step 8 — Update pitch frontmatter

After all files are written, update `pitches/<slug>.md`:

```yaml
status: in_progress
started: <today YYYY-MM-DD>   # was ~ (unchanged if already in_progress)
slices: slices/<slug>/         # the current map; a proposed v2 doesn't change this until chosen
```

Leave `completed` and `audited` unchanged. In a re-slice run with no map chosen yet, leave `slices:` pointing at the existing map and note in both overviews that the choice is pending.

---

## Constraints / Do's and Don'ts

Apply to every slice before finishing; fix any failure before moving on.

- "Done when" is observable — a passing test, printed output, created file — not "code is implemented"
- No slice is purely a layer (schema, file, or config only); each is end-to-end functionality, or a dev-actor slice with a concrete before/after check
- Every slice has `est_loc` ≤100 with cited `analogue` and inflation factor, or `size_class: sweep` meeting the sweep rules, or a `size_exception` naming its cause, and names its split axis in `axis:`
- Every slice has a Job section naming circumstance, actor, progress, and named observation, and passes the floor
- No slice named or shaped as wiring, foundation, integration, or polish; slice 01 is a walking skeleton (or thinnest runnable path for a local CLI) unless the repo already has one
- No spike or research written as a slice
- Every Deliverable has an exact path
- No slice crosses a Rabbit Hole or implements a No Go
- Slice-header dependencies match the overview's ship sequence
- A slice that creates resources states how they're removed until its teardown slice lands; teardown slices ordered early when teardown is cheap
- Slices replacing or reshaping a component list every constructor and call site found by search; each updated by exactly one slice
- Tests name at least one test asserting `Done when`; acceptance tests only when `Done when` is user-visible. Test volume stays proportionate — outside the size budget
- Deployment is present: rollout, migration, flag, rollback plan, or "Not applicable — <reason>"
- Every Deliverable and test traces to "Done when" and a pitch work stream
- Each slice is sufficient with only its declared dependencies
- No deliverable duplicated or silently folded into a later slice
- Every new library, tool, service, migration, or config value appears in Prerequisites with a delivering slice
- Feasibility claims name their source or are labeled assumptions — never from memory
- Discovery findings cite `path:line`; no invented modules or files
- Cross-slice risks and ship checkpoints recorded in the overview
- Fresh drafts leave `audited: ~`; only the audit skill stamps it
- Existing slice maps are versioned, never overwritten or deleted; `slice-planner` builds only the map marked current

---

## Output Format

Confirm:

- Files written: each path (in a re-slice run, the versioned directory and what it was diffed against)
- Ship sequence: one line with est LOC, actor, and progress per ship (e.g. "01 skeleton builds+deploys (~15, dev) → 02 form saves (~60, end user) → 03 reaches Linear (~80, end user)")
- Calibration: PRs sampled, pass/fail counts with reasons, median / p75, inflation factor (passing vs failing), fix-tail rate — or "team norm: not established"
- Size: slice count, median `est_loc`, any `sweep` or `size_exception` slices with causes and reasons
- Pitch updated: `status`, `started`, `slices` (or held pending map choice in a re-slice run)
- Prerequisites: new dependencies/tools and delivering slices, or "none"
- Slice audit: verdict, plus merges, splits, re-cuts with reasons
- Feasibility: what was verified and with which sources, plus unconfirmed assumptions
- Risks and ship checkpoints: confirmed recorded in `00-overview.md`
- Deployment: slices with a real rollout/migration plan, and those not applicable with reasons
- Judgment calls: slices combined, rabbit holes avoided
- Next: slices ready for `slice-planner` (`../slice-planner/SKILL.md`) — in a re-slice run it builds the map marked current only
