---
name: draft-slices
description: Draft a cycle's slice directory — 00-overview.md plus numbered slice files — from a validated pitch. Use when a pitch is `pitched` and needs breaking into vertical slices.
version: "2.0"
triggers:
  - "draft slices"
  - "write slices"
  - "create slices"
  - "break pitch into slices"
  - "slice out"
  - "new cycle"
---

# Draft Slices

## Instruction precedence

Developer instructions take precedence over this procedure, including review and required-section checks. Follow compatible requirements; explicitly identify each departure and its reason in the overview and handoff. Do not claim a skipped or overridden check passed.

## Preconditions

Before writing, check all five; stop and report any failure:

1. **Pitch:** `pitches/<slug>.md` must exist. If only `pitches/.archive/<slug>.md` exists, the cycle is complete; otherwise list `pitches/`.
2. **Status:** `pitched` proceeds. `in_progress` with a map from this skill in `slices/<slug>/` follows Re-slicing; without one (or if archived), ask whether to add to that cycle. `complete`: nothing to draft. `abandoned`: confirm intent first.
3. **Sections:** require `## Problem`, `## Appetite`, `## Solution`, `## Rabbit Holes`, `## No Gos`; list missing sections and stop. In a re-slice, a pitch revised after review is expected; don't block.
4. **Directory:** if `slices/<slug>/` or `slices/.archive/<slug>/` exists, version a map from this skill per Re-slicing; otherwise list existing content and stop. Never overwrite scope without explicit confirmation; non-scope-changing notes are allowed as described under Re-slicing.
5. **Review and bet:** if `pitches/.reviews/<slug>.md` exists, require `verdict: ready_for_betting`, `betting_decision: approved`, and `pitch_sha256` matching current pitch bytes (`sha256sum pitches/<slug>.md`). Missing/malformed fields, unready verdict or pending/declined approval block: return to `stress-test-pitch` (`../stress-test-pitch/SKILL.md`) and the human decision. Never infer approval from the request or rewrite the review. Check the digest before lifecycle frontmatter changes; those need no new product review. In a re-slice, a digest mismatch from post-review pitch revisions is expected: record `review stale: pitch revised after review` in the overview and continue; a never-ready verdict or declined approval still blocks. If the approved outcome is non-software, stop and hand off its bounded action, owner and evaluation checkpoint; don't invent software work. With no review, recommend `stress-test-pitch` first; proceed only if the user explicitly bypasses it **and** approves the bet. Record the exception in `00-overview.md` and the handoff; never fabricate a passing review. This doesn't override an existing stale or failing review.

## Re-slicing an existing map

Treat this as a second opinion, not an error. Without asking confirmation, open with one line and proceed unless stopped:

> A slice map already exists (v1, drafted with `draft-slices` v1.4, N slices, M shipped). Drafting v2 as a second opinion.

Assume the developer wants this, especially when skill versions differ. Read prior `vN/` directories for the highest version and the earlier overview for its skill version and shipped slices. Write `slices/<cycle>/vN/` with `00-overview.md` and slice files; never overwrite or delete earlier maps or change their scope without explicit confirmation. Add non-scope-changing notes to existing slices or maps when useful (for example, a pending map choice); preserve their existing content and scope. Shipped or in-flight slices stay fixed with actual LOC and PRs; slice only remaining work, referencing shipped slices as context and using their estimated vs actual LOC for calibration.

Open the new overview with skill versions, slice counts (shipped separate), remaining-slice merges/splits/reorders/drops and why, and newer-skill rules changing the outcome. Mark the new map `proposed`; both remain on disk. Name the current map only if the developer says so. `slice-planner` builds only the map marked `current`; an unchosen v2 must not be built. Fresh maps go directly in `slices/<slug>/`, implicitly current once pitch frontmatter points there; don't stamp `audited`.

## Workflow

### 1. Read the pitch

Read it in full. Extract each work stream's job (who needs progress, when, and how they'd observe it); slices are steps in that job, not code layers. Each Solution work stream becomes one or more slices. Rabbit Holes are hard constraints: flag and redesign crossings. No Gos are absolute: stop and flag implementations. Appetite bounds total scope, not slice count; size budget determines count.

### 2. Ground in the codebase

Before mapping streams, read touched structure and entry points, not the full tree:

- List likely directories, modules and neighbours; read file heads and public interfaces for patterns, naming and layering. Read nearest tests, manifests and lockfiles for libraries, versions and scripts.
- Search **all** constructors, callers and importers of each replaced/reshaped component, not just definitions (`rg "<ClassName>"`, `rg "\.<method>\("`). Each replacing slice names every call site it updates.
- Check the functional core / imperative shell boundary; extend rather than duplicate the convention.
- If a slice creates resources (files, records, processes, config) with no removal, order teardown early when cheap, or say in the creating slice how they're removed until teardown lands.

Cite findings as `path:line` in overview Context and Architecture Conventions to sanity-check streams. If code contradicts the Solution (absent library, nonexistent module, forbidden pattern already load-bearing), stop and report a pitch-level finding.

### 3. Verify feasibility

Review examined the bet, not its assumptions against this checkout. Verify libraries, tools, services and APIs exist at available versions or are prerequisites; assumed migrations, schema and data shapes match disk; and unresolved review questions are answered or explicitly carried forward. Use lockfiles, installed versions, `--help`, upstream source/changelogs, docs, scratch probes, web search/fetch or user questions. Record each check and source; label anything unverifiable an assumption in the overview and say what would settle it. Never present recall as confirmation. If unbuildable as written, stop and route the finding to the pitch or `stress-test-pitch`, not a different solution via re-slicing.

### 4. Calibrate against merged PRs

Before estimating slices, measure team shipping and write an overview **Calibration** table. List the last 40–50 PRs merged to the default branch, e.g.:

`gh pr list --state merged --limit 50 --json number,title,additions,deletions,commits,mergedAt,createdAt,reviews,files`

If `gh` can't reach a remote, use `git log --merges`. For re-slices, add earlier shipped slices. Measure each PR's first-commit and merged size identically: insertions + deletions of non-test source only; exclude lockfiles, `schema.rb`, generated files, fixtures and snapshots; whole-file delete counts as 1.

An exemplar must pass **all** screens:

| Screen | Test |
|---|---|
| One job | Title and description name one behavior; no "and" in title |
| Observable | Observable ship, or declared migration/preparatory change |
| Size | ≤300 LOC (1.5× the 200 LOC breakpoint) |
| No fix tail | No revert or follow-up "fix" PR within ~7 days touching same files |
| Healthy review | ≤2 review rounds |
| Not mechanical | No dependency bump, bulk rename, wave bundle or generated-code import |

A merge alone isn't evidence. Report how many of the 40–50 fail and one line of reason each; if most fail, say team habit isn't a usable norm. Derive median and p75 merged LOC of passing PRs, median merged/first-commit inflation separately for passing and failing PRs (instead of fixed 1.4×/1.5×), and fix-tail rate across both groups.

- ≥5 passing: establish the team norm and use the passing PRs to inform estimates; the 200 LOC breakpoint still applies.
- <5 passing: use the default inflation factor of 1.5×, ignore team signal, record `team norm: not established`.
- Each slice with an established norm: cite closest 1–2 passing PR analogues; `est_loc` = analogue first-commit size × passing inflation factor. Without an established norm, estimate bottom-up × 1.5 and record `analogue: none (team norm not established)`. For analogue-based estimates, cross-check bottom-up against named files; explain discrepancies >2×.
- Greenfield: bottom-up × nearest sibling repo's factor, or 1.5× if none; write `analogue: none (greenfield)` once. After first three slices ship, recompute from actuals and re-estimate the rest.
- Hardening: include inflation factor and name the specific failure closed.

On ship, fill `pr`, `commits`, actual LOC and estimate-to-actual ratio (Ship checkpoints → Size review); recalibrate next cycle to measure improvement.

### 5. Design the ship sequence

Each slice is one PR, merged to main and deployed independently in order: one observable job step for a named actor and circumstance. No foundation/parallel/wiring waves; an audit of ~90 slices found they shipped nothing observable until the last wave.

State each job step in one line:

> When **[circumstance]**, **[actor]** can **[progress]**, observed via **[named command / log line / UI / query]**.

Actors: end user, admin, system/operator or dev; use nouns and verbs, not "faster" or "more robust". A dev actor needs a concrete before/after check, e.g. "when I add a third engine, I can do it without touching the dispatcher", shown by test or diff. The larger job advances one step on one axis per slice.

Name slices with verb phrases (`01-report-form-saves`, `02-report-reaches-linear`); filename is identity. Never name them `wiring`, `foundation`, `integration` or `polish` (bundles).

Slice 01 is a hello-world-sized walking skeleton unless an end-to-end path already exists: "When I change code, I can see it build, deploy and pass one end-to-end check." Without deployment (e.g. local CLI), use the thinnest runnable path: "When I run the binary, one command executes end to end and prints observable output." Actor is dev or system; user value isn't required. Slice 02 is first user-facing; later slices widen cases, entry points, error handling and UI polish.

**Size breakpoint** (audit, constraints and templates defer here): estimate changed LOC excluding tests, docs, lockfiles and generated files. Ship slices estimated at or below 200 LOC; split slices estimated above 200 along a real split axis, never trim scope merely to fit. The breakpoint applies to every slice, including mechanical changes.

**Merge floor:** merge neighbours when all hold: ≤40 LOC combined, same component, one shared `Done when` check; except when the small slice independently ships valuable behavior a named actor would notice.

**Separate floor:** keep separate only if all three hold:
1. A named actor in a real circumstance would notice its absence; otherwise fold it into the slice it serves.
2. It differs from its neighbour on a real split axis: workflow step, operation, business rule, data variant, entry method, simple vs complex, or deferred performance.
3. A concrete buy: merging violates merge-floor conditions, the work is droppable without losing the neighbour's value, or it can be reordered after the neighbour. "Feels cleaner separate" doesn't count.

**Ceiling:** split if the job statement joins two independent observations with "and" (two actors, circumstances or Done-when checks no single test asserts), or `est_loc` exceeds 200. A compound verb for one observation is fine: "save and show the form" is one slice if one test checks it. Each slice must visibly differ from its predecessor.

**Other value rules:**
- If the actor observes nothing after merge, or there's no named actor/circumstance, merge or redesign. Hide unfinished work behind a flag or unlinked route, rather than holding slices back.
- No wiring slice: each wires its own piece. A final integration slice means earlier slices were layers; redesign.
- Spikes/research aren't slices: record time-boxed pitch steps with written findings outside the sequence. QA harnesses, corpora and manual checks changing nothing an actor can do are operational checkpoints in overview Ship checkpoints.
- Hardening names the failure closed and actor who'd hit it, and includes inflation in `est_loc`.
- Dependencies are strictly ordered by default. Parallel only for disjoint files when neither needs the other's code to merge; shared files require sequence.

### 6. Write overview

Use `assets/overview-template.md` for `slices/<cycle>/00-overview.md`; fill every placeholder, leaving no `<angle brackets>`. Include Calibration and, for re-slices, the version comparison. Leave `audited: ~`; the audit skill stamps it.

### 7. Write and audit slices

Use `assets/slice-template.md` for each `slices/<cycle>/NN-<name>.md`; every field is required. One deliverable per file: for a multi-file slice use a `### Component — path` subsection per file. Entries give responsibility and path; signatures, ordering and interface details belong in the `slice-planner` implementation plan.

Before updating the pitch, audit each slice:
- **Minimal:** every Deliverable and test traces to `Done when` and a pitch work stream. Record "while we're here" work, speculative abstractions and unrelated refactors as follow-ups.
- **Sufficient:** slice plus declared dependencies alone reach `Done when`, with no missing interface, migration, wiring or unlisted call site.
- **No duplication:** nothing built twice or earlier work silently folded into a later slice.
- **Right-sized:** breakpoint applies; `est_loc` backed by an analogue and inflation or the documented fallback, ≤200. Small is fine if floor passes; don't merge merely for size.
- **Ships progress:** Job names actor, circumstance and observation and passes floor tests.

Record verdict, merges, splits and trims with reasons in overview Slice Audit. Never mark sufficient merely to avoid reopening the graph.

### 8. Update pitch frontmatter

After writing all files, update `pitches/<slug>.md`:

```yaml
status: in_progress
started: <today YYYY-MM-DD>   # was ~ (unchanged if already in_progress)
slices: slices/<slug>/         # the current map; a proposed v2 doesn't change this until chosen
```

Leave `completed` and `audited` unchanged. In a re-slice with no map chosen, leave `slices:` pointing at the existing map and note choice pending in both overviews.

## Final constraints

Apply to every slice; fix failures before moving on:

- `Done when` is observable (passing test, printed output, created file), not "code is implemented". Tests name at least one test asserting it; acceptance tests only when user-visible. Keep test volume proportionate; tests are outside the size budget.
- No purely layer slice (schema, file, config): end-to-end functionality or a dev-actor slice with concrete before/after check. No wiring, foundation, integration or polish shape/name; slice 01 is a walking skeleton (or local CLI's thinnest runnable path) unless one exists. No spike/research slice.
- Each slice has `est_loc` ≤200 with cited `analogue` and inflation factor or the documented fallback; name split axis in `axis:`. Job names circumstance, actor, progress and observation and passes floor.
- Every Deliverable has an exact path; every Deliverable and test traces to `Done when` and a pitch stream. No Rabbit Hole crossing or No Go implementation. Each slice is sufficient with declared dependencies; no duplicate deliverable or silent folding into a later slice.
- Header dependencies match overview ship sequence. Resource creators state removal until teardown; order teardown early when cheap. Slices replacing/reshaping components list every searched constructor and call site, each updated by exactly one slice.
- Deployment includes rollout, migration, flag, rollback plan, or "Not applicable — <reason>". Every new library, tool, service, migration or config value appears in Prerequisites with a delivering slice.
- Feasibility claims cite sources or are labeled assumptions, never memory; discovery cites `path:line`, with no invented modules/files. Record cross-slice risks and ship checkpoints in overview.
- Fresh drafts leave `audited: ~`; only audit skill stamps it. Version existing maps, never overwrite/delete their scope; non-scope-changing notes are allowed; `slice-planner` builds only the current map.

## Handoff

Confirm:
- Files written, each path; for re-slice, versioned directory and what it was diffed against.
- Ship sequence: one line with est LOC, actor and progress per ship (e.g. "01 skeleton builds+deploys (~15, dev) → 02 form saves (~60, end user) → 03 reaches Linear (~80, end user)").
- Calibration: PRs sampled, pass/fail counts and reasons, median/p75, passing vs failing inflation, fix-tail rate; or `team norm: not established`.
- Size: slice count, median `est_loc`, and splits made for the 200 LOC breakpoint.
- Pitch `status`, `started`, `slices`, or held pending map choice; prerequisites (new dependencies/tools and delivering slices, or "none").
- Slice audit verdict and merges/splits/re-cuts with reasons; feasibility checks and sources plus unconfirmed assumptions.
- Risks and ship checkpoints confirmed in `00-overview.md`; deployment slices with real rollout/migration plans and those not applicable with reasons.
- Judgment calls: slices combined, rabbit holes avoided, and any departures from this procedure required by developer instructions (including review or sections) and their reasons. Next: slices ready for `slice-planner` (`../slice-planner/SKILL.md`); in a re-slice it builds only the map marked current.
