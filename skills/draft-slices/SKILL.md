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

1. **Pitch exists.** `pitches/<slug>.md` must exist. If only `pitches/.archive/<slug>.md` exists, the cycle is complete — say so and stop. Otherwise list `pitches/` and stop.

2. **Pitch status is `pitched`, or `in_progress` with an existing map.** Read the frontmatter:
   - `pitched` → proceed normally.
   - `in_progress` → if `slices/<slug>/` already contains a slice map drafted by this skill, follow **Re-slicing an existing map** below: draft a versioned second opinion instead of stopping. If there is no map (or it is archived), ask whether to add to that cycle.
   - `complete` → nothing to draft.
   - `abandoned` → confirm intent before proceeding.

3. **Five required sections.** Scan for `## Problem`, `## Appetite`, `## Solution`, `## Rabbit Holes`, `## No Gos`; list any missing and stop. (In a re-slice run, a pitch revised after review is expected — see the re-slicing section; do not block on it.)

4. **Slice directory.** If `slices/<slug>/` or `slices/.archive/<slug>/` exists:
   - With an existing map from this skill → do **not** stop and do **not** overwrite. Draft a versioned map (v2, v3, …) as a second opinion, per **Re-slicing an existing map**.
   - With other content or no prior map → list it and stop; do not overwrite without explicit confirmation.

5. **Review and betting decision.** If `pitches/.reviews/<slug>.md` exists, require `verdict: ready_for_betting`, `betting_decision: approved`, and a `pitch_sha256` matching the current pitch bytes (`sha256sum pitches/<slug>.md`). A missing/malformed field, unready verdict, or pending/declined approval blocks slicing — return to `stress-test-pitch` (`../stress-test-pitch/SKILL.md`) and the human decision. Never infer approval from the slicing request or rewrite the review. Check the digest before changing lifecycle frontmatter; those changes need no new product review.

   **In a re-slice run** (existing map, pitch already `in_progress`), a digest mismatch caused by post-review pitch revisions is expected, not a blocker: record `review stale: pitch revised after review` in the overview and continue. A verdict that was never ready, or an approval that was declined, still blocks.

   If the approved outcome is a non-software intervention, stop and hand off its bounded action, owner, and evaluation checkpoint; do not invent software work.

   With no review record, recommend `stress-test-pitch` first. Proceed only if the user explicitly bypasses it and approves the bet; record the exception in `00-overview.md` and the handoff, and never create a passing review record. This does not override an existing stale or failing review.

---

## Re-slicing an existing map

When a cycle already has a slice map, treat the new run as a **second opinion**, not an error. Do not ask for confirmation; open with one line and proceed unless the user stops it:

> A slice map already exists (v1, drafted with `draft-slices` v1.4, N slices, M shipped). Drafting v2 as a second opinion.

Assume the developer wants this, especially when the skill version differs from the one that drafted the earlier map.

**Version the map.**
- The existing map is v1; the new one is v2; a later one is v3, and so on (read any prior `vN/` directories to find the highest version).
- Write the new map to `slices/<cycle>/v2/` (`00-overview.md` plus slice files inside). Earlier maps stay untouched — never overwrite or delete one.
- Read the earlier map's overview to learn which skill version drafted it and which slices shipped.

**Treat shipped work as fixed.**
- Slices already shipped or in flight stay as they are, with their actual LOC and PRs. v2 slices only the remaining work and refers to shipped slices as context.
- Use shipped slices as calibration data for the method in Step 4 (Calibrate): their `est_loc` vs actual LOC are real estimate-to-actual ratios.

**Record the differences.** The v2 overview opens with a short comparison against the previous map:
- Skill versions used for each map.
- Slice counts, with shipped slices listed separately.
- Which remaining slices were merged, split, reordered, or dropped, and why.
- Any rule in the newer skill that changed the outcome.

**Leave the choice to the developer.**
- Both maps stay on disk; v2 is marked `proposed` in its overview.
- The overview says which map is current only if the developer says so; otherwise neither is marked current.
- `slice-planner` reads the map marked `current` and ignores `proposed` ones — so an unchosen v2 never gets built by accident.

**Fresh maps (no existing map).** Write directly into `slices/<slug>/` as before. A fresh draft's overview is implicitly the current map once the pitch frontmatter points at it; do not stamp `audited` on it.

---

## Workflow / Steps

### Step 1 — Read and internalize the pitch

Read the full pitch before designing. Extract:

- **The job**: per work stream, who needs progress, in what circumstance, and how they would observe it. Slices are steps of progress on that job, not layers of code.
- **Work streams** from Solution: distinct pieces to build; each becomes one or more slices.
- **Rabbit Holes** as hard constraints: flag and redesign any slice that would cross one.
- **No Gos** as absolute guards: stop and flag any slice that would implement one.
- **Appetite** bounds total scope, not slice count; slice count falls out of the size budget in Step 5. Many small slices are correct provided each passes the floor.

---

### Step 2 — Ground the pitch in the codebase

Before mapping work streams, read the code the cycle touches — structure and entry points, not the full tree.

- List likely directories and modules plus immediate neighbours.
- Read file heads and public interfaces for existing patterns, naming, and layering.
- **Search for call sites, not just definitions:** for any component a slice replaces or reshapes, find every constructor, caller, and importer with a search (`rg "<ClassName>"`, `rg "\.<method>\("`) — not by reading file heads and hoping. Each slice that replaces a component must be able to name every call site it updates.
- Read the nearest tests to learn how behavior is verified.
- Read manifests and lockfiles for available libraries, versions, and scripts.
- Check the existing functional core / imperative shell boundary so slices extend it rather than invent a parallel convention.
- **Note lifecycle:** if a slice creates resources (files, records, processes, config entries) and no slice in the sequence removes them, either order a teardown slice early (when teardown is cheap) or state in the creating slice how the resources are removed until the teardown slice lands.

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

### Step 4 — Calibrate against the team's own merged PRs

Before setting the size budget in Step 5, measure how this team actually ships. Write the result as a short **Calibration** table in the overview.

**Pull the evidence.**
- List the last 40–50 merged PRs to the default branch, for example:
  `gh pr list --state merged --limit 50 --json number,title,additions,deletions,commits,mergedAt,createdAt,reviews,files`
- If `gh` can't reach a remote, fall back to `git log --merges` or the commit history.
- In a re-slice run, also treat the earlier map's shipped slices as calibration data.

**Measure each PR the same way.**
- Count insertions plus deletions of **non-test source only**.
- Exclude lockfiles, `schema.rb`, generated files, fixtures, and snapshots.
- A whole-file delete counts as 1.
- Record two sizes per PR: the **first commit's size** and the **merged size** (after review fixes).

**Screen for compliance.** A PR is an exemplar only if it passes all of these:

| Screen | Test |
|---|---|
| One job | Title and description name one behavior; title has no "and" |
| Observable behavior | Ships something observable, or is a declared migration or preparatory change |
| Size | ≤1.5× the skill's budget |
| No fix tail | No revert; no follow-up "fix" PR within ~7 days touching the same files |
| Healthy review | Two review rounds or fewer |
| Not mechanical | Not a dependency bump, bulk rename, wave bundle, or generated-code import |

Do not accept a PR as an exemplar just because it merged. Report how many of the 40–50 failed the screen, with one line of reason each. If most failed, the team's habit is not a usable norm — say so in the overview.

**Derive three numbers from the PRs that passed:**
- **Typical size:** the median and 75th percentile of merged LOC.
- **Inflation factor:** the median ratio of merged size to first-commit size. Compute it across passing PRs and across failing ones separately. This replaces any fixed 1.4×/1.5× assumption.
- **Fix-tail rate:** the share of PRs (passing and failing) that needed a follow-up fix.

**Use the numbers:**
- **Enough exemplars (≥8 passing):** use their 75th percentile as the target slice size — but if it exceeds the skill's budget, keep the skill's budget. Team signal can tighten the budget, never loosen it.
- **Too few exemplars (<5 passing):** ignore the team signal, fall back to the skill default, and record `team norm: not established` in the overview.
- **Per slice:** cite the closest 1–2 passing PRs as analogues by PR number and name what makes them similar; set `est_loc` to the analogue's first-commit size × the inflation factor; cross-check against a bottom-up count of the named files — if the two differ by more than 2×, write down why.
- **Greenfield (no analogue in this repo):** use bottom-up × the factor from the nearest sibling repo, or 1.5× if there is none. Write `analogue: none (greenfield)` once in the overview. After the first three slices ship, recompute the factor from actuals and re-estimate the rest.
- **Hardening:** include the inflation factor in the estimate, and name the specific failure the slice closes.

**Close the loop.** When a slice ships, fill in `pr`, `commits`, and actual LOC, and record the estimate-to-actual ratio in the overview (Ship checkpoints → Size review). Calibrate again at the next cycle. This is the only signal that tells you whether estimates are improving.

---

### Step 5 — Design the ship sequence

Order the work as production ships. Each slice is one PR that merges to main and deploys on its own, in order: one observable step of progress on a job, for a named actor, in a named circumstance. Do not use foundation / parallel / wiring waves — an audit of ~90 slices found they shipped nothing observable until the last wave.

**Job step.** Every slice states its job step in one line:

> When **[circumstance]**, **[actor]** can **[progress]**, observed via **[named command / log line / UI / query]**.

Actors are end user, admin, system/operator, or dev, stated with nouns and verbs — "faster" or "more robust" is not progress. A dev actor needs a concrete before/after check (e.g. "when I add a third engine, I can do it without touching the dispatcher", shown by a test or a diff). The job is larger than the slice; each slice moves one step along one axis.

**Naming:** verb phrases (`01-report-form-saves`, `02-report-reaches-linear`); the filename is the slice's identity. Never name a slice `wiring`, `foundation`, `integration`, or `polish` — those names mark bundles.

**Walking skeleton.** Slice 01 is the walking skeleton unless the repo already has an end-to-end path: "When I change code, I can see it build, deploy and pass one end-to-end check." For a repo without deployment (e.g. a local CLI), the skeleton is the **thinnest runnable path**: "When I run the binary, one command executes end to end and prints observable output." Its actor is dev or system; it need not carry user value; keep it hello-world sized. Slice 02 is the first user-facing slice; later slices widen it — more cases, more entry points, error handling, UI polish.

**Size budget.** This is the single statement of the size rule — the Slice Audit, constraints, and templates defer to it:

- Target ≤100 changed LOC per slice, excluding tests, docs, lockfiles, and generated files; LOC is a soft tripwire for review size, not a hard limit.
- An overage up to 1.5× the budget (≤150 LOC) is a **shippable exception**: record `size_exception:` (with its cause — see below) and ship. Do not stop in-flight work to re-slice around the number.
- An overage past 1.5× signals a genuinely oversized job step: re-cut along a split axis, never trim to fit.

Every `size_exception` names its cause:
- **new subsystem** — a daemon, store, protocol, or engine whose thinnest end-to-end path already exceeds the budget;
- **first-of-kind surface** — the first slice through a new entry point or integration, where scaffolding dominates;
- **measured analogue** — a cited analogue PR of the same shape that also landed above budget.

A new subsystem is almost always over budget. Plan the thinnest end-to-end path through it, then widen. Never plan "build the subsystem" as one slice.

**Merge floor.** Merge a slice into its neighbour when **all** of these hold:
- the two slices together total ≤40 LOC, and
- they touch the same component, and
- they share one `Done when` check —

unless the small slice ships independently valuable behavior (a named actor would notice it on its own). This is the concrete test behind floor condition 3.

**Value rules:**
- Every slice states its Job section in the job-step form (body, not frontmatter). If the honest answer to "what would the actor observe after merge" is "nothing", it has no named actor or circumstance — merge or redesign.
- Hide unfinished work behind a flag or an unlinked route; don't hold slices back until the whole feature is ready.
- No wiring slice: each slice wires its own piece. A seemingly necessary final integration slice means the earlier slices were layers — redesign.
- Spikes and research are not slices; record them as time-boxed pitch steps with a written finding, outside the sequence. QA harnesses, corpora, and manual checks that change nothing an actor can do are likewise not slices — record them as operational checkpoints in the overview's Ship checkpoints list.
- Hardening slices name the failure they close and the actor who would hit it, and carry the inflation factor in `est_loc`.

**Floor — keep a slice separate** only if **all three** hold:
1. **Circumstance and actor.** A named actor in a real situation would notice this slice was never built; otherwise it's a non-story — fold it into the slice it serves.
2. **Real split axis.** It differs from its neighbour along one axis: workflow step, operation, business rule, data variant, entry method, simple vs complex, or deferred performance.
3. **The split buys something concrete** — at least one of: the merge-floor condition above would be violated by merging (combined >40 LOC, different components, or separate Done-when checks); the work is droppable without losing the neighbour's value; or reordering it after the neighbour becomes possible. "It feels cleaner separate" is not a concrete buy.

**Ceiling — split a slice** when either concrete check fires:
- Its job statement needs "and" to connect two *independent* observations (two actors, two circumstances, or two Done-when checks that no single test asserts). A compound verb phrase describing one observation is fine: "save and show the form" is one slice if the check is one test.
- It exceeds 1.5× the budget and no `size_exception` cause applies.

Check each slice is visibly different from its predecessor. A smaller overage is recorded as a `size_exception` and shipped. When in doubt whether an overage is "large", it is a reviewer call — default to recording and shipping.

**Size classes** (`size_class` in each slice):
- `normal`: ≤100 LOC, one observable job step.
- `sweep`: one mechanical transform over many files; may exceed budget. See below.

**Sweep slices** cover repetitive mechanical change (rename, API migration, adding an argument everywhere, pattern replacement). They are the only slices allowed past 100 LOC, and only with:
- the transform stated as a one-sentence rule, plus the committed script, codemod, or command that applies it;
- a reviewer check that doesn't require reading every hunk: a deterministic script, 3–5 sample before/after hunks, and a command showing zero remaining matches;
- batches split by directory or module, each ≤300 changed LOC where tooling allows, each mergeable alone;
- no behavior change mixed in — renames and moves are their own slice.

**Any size exception** — anything over budget that is not a `sweep` — is recorded under `size_exception:` with its cause and reason (see Size budget above) and listed in the overview's Slice Audit. These records are tuning data for a later pass, not in-flight blockers. Expect few.

**Dependencies:** strict order by default. Mark slices parallel only when they touch disjoint files and neither needs the other's code to merge; shared files (e.g. one view or controller) mean sequence them.

---

### Step 6 — Write `slices/<cycle>/00-overview.md`

Use `assets/overview-template.md`; fill every placeholder, leaving no `<angle bracket>` tokens. The overview includes the Calibration table from Step 4 and — in a re-slice run — the version comparison. Leave `audited: ~` on a fresh draft; the audit skill stamps it.

---

### Step 7 — Write each `slices/<cycle>/NN-<name>.md`

Use `assets/slice-template.md`; every field is required.

**One deliverable per file.** A slice touching multiple files gets a `### Component — path` subsection per file. Keep entries to a responsibility and a path — signatures, ordering, and interface detail belong in the implementation plan (`slice-planner`).

**Audit each slice for minimality and sufficiency** before updating the pitch:

- **Minimal:** every Deliverable and test traces to `Done when` and a pitch work stream. No "while we're here" work, speculative abstractions, or unrelated refactors — record them as follow-ups.
- **Sufficient:** the slice file plus declared dependencies alone reach `Done when` — no missing interface, migration, wiring step, or un-listed call site of a replaced component.
- **No duplication:** nothing is built twice, and earlier-slice work is not quietly folded into a later one.
- **Right-sized:** `est_loc` backed by a cited analogue and the inflation factor; ≤100 preferred, or labelled `sweep`, or a `size_exception` with a named cause. Small is fine as long as the floor passes — don't merge just because a slice is short; check the merge floor's concrete conditions instead.
- **Ships progress:** the Job section names actor, circumstance, and named observation, and passes the floor tests; otherwise merge into the neighbour.

Record the verdict in the Slice Audit table in `00-overview.md`, including merges, splits, and trims with reasons. Never mark a slice sufficient just to avoid reopening the graph.

---

### Step 8 — Update pitch frontmatter

After all files are written, update `pitches/<slug>.md`:

```yaml
status: in_progress
started: <today YYYY-MM-DD>   # was ~ (unchanged if already in_progress)
slices: slices/<slug>/         # the map the developer should treat as current; a proposed v2 does not change this until the developer chooses
```

Leave `completed` and `audited` unchanged — `audited` is set by the audit skill.

In a re-slice run where the developer has not yet chosen a map, leave `slices:` pointing at the existing (v1) map and note in both overviews that the choice is pending.

---

## Constraints / Do's and Don'ts

Apply to every slice before finishing; fix any failure before moving on.

- "Done when" is observable — a passing test, printed output, created file — not "code is implemented"
- No slice is purely a layer (schema, file, or config only); each is end-to-end functionality, or a dev-actor slice with a concrete before/after check
- Every slice has `est_loc` ≤100 with a cited `analogue` and the calibration inflation factor, or `size_class: sweep` meeting the sweep rules, or a recorded `size_exception` naming its cause, and names its split axis in `axis:`
- Every slice has a Job section naming circumstance, actor, progress, and a named observation, and passes the floor (actor / axis / concrete buy) — the merge-floor conditions are the concrete test for "buys something"
- No slice is named or shaped as wiring, foundation, integration, or polish; slice 01 is a walking skeleton (build/deploy/e2e path, or thinnest runnable path for a local CLI) unless the repo already has one
- No spike or research written as a slice
- Every Deliverable has an exact path
- No slice crosses a Rabbit Hole or implements a No Go
- Slice-header dependencies match the overview's ship sequence
- A slice that creates resources states how they are removed until its teardown slice lands; teardown slices are ordered early when teardown is cheap
- Slices replacing or reshaping a component list every constructor and call site found by search, and each is updated by exactly one slice
- Tests name at least one test asserting `Done when`; add an acceptance test only when `Done when` is user-visible. Test volume stays proportionate — it's outside the size budget
- Deployment is present: rollout, migration, flag, and rollback plan, or "Not applicable — <reason>"
- Every Deliverable and test traces to "Done when" and a pitch work stream; no opportunistic work
- Each slice is sufficient with only its declared dependencies
- No deliverable is duplicated or silently folded into a later slice
- Every new library, tool, service, migration, or config value appears in Prerequisites with a delivering slice
- Feasibility claims name their source or are labeled assumptions — never asserted from memory
- Discovery findings cite `path:line`; no invented modules or files
- Cross-slice risks and ship checkpoints are recorded in the overview
- Fresh drafts leave `audited: ~`; only the audit skill stamps `audited`
- Existing slice maps are versioned, never overwritten or deleted; `slice-planner` builds only the map marked current

---

## Output Format

Confirm:

- Files written: each path (in a re-slice run, the versioned directory and what it was diffed against)
- Ship sequence: one line with est LOC and each ship's actor and progress (e.g. "01 skeleton builds+deploys (~15, dev) → 02 form saves (~60, end user) → 03 reaches Linear (~80, end user)")
- Calibration: PRs sampled, pass/fail counts with failure reasons, median / p75, inflation factor (passing vs failing), fix-tail rate — or "team norm: not established"
- Size: slice count, median `est_loc`, and any `sweep` or `size_exception` slices with causes and reasons
- Pitch updated: `status`, `started`, `slices` fields (or held pending map choice in a re-slice run)
- Prerequisites: new dependencies/tools and their delivering slices, or "none"
- Slice audit: verdict, plus merges, splits, and re-cuts with reasons
- Feasibility: what was verified and with which sources, plus unconfirmed assumptions
- Risks and ship checkpoints: confirmed recorded in `00-overview.md`
- Deployment: slices with a real rollout/migration plan, and those marked not applicable with reasons
- Judgment calls: slices combined, rabbit holes avoided
- Next: slices are ready for `slice-planner` (`../slice-planner/SKILL.md`) — noting that in a re-slice run it builds the map marked current only
