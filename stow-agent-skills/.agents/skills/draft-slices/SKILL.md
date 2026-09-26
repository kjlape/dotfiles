---
name: draft-slices
description: Draft a new cycle's slice directory — 00-overview.md + numbered slice files — from a validated pitch. Use when a pitch exists with status "pitched" and you need to break it into implementable vertical slices.
version: "1.0"
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

Use this skill when a pitch is ready to be broken into implementation work. All four conditions must hold before writing a single file — if any fail, stop and report:

1. **Pitch exists.** `pitches/<slug>.md` must be present. If no matching file exists, check `pitches/.archive/<slug>.md` — if found there, the cycle is already complete; stop with that explanation. Otherwise list what is in `pitches/` and stop.

2. **Pitch status is `pitched`.** Read the frontmatter. If `status` is anything other than `pitched`, stop with a clear explanation:
   - `in_progress` → slices are already being drafted or implemented; ask if they want to add slices to the existing cycle instead.
   - `complete` → cycle is done; nothing to draft.
   - `abandoned` → pitch was abandoned; confirm intent before proceeding.

3. **Pitch has all five required sections.** Scan the prose for: `## Problem`, `## Appetite`, `## Solution`, `## Rabbit Holes`, `## No Gos`. List any missing sections and stop.

4. **No existing slice directory.** Check whether `slices/<slug>/` or `slices/.archive/<slug>/` already exists. If either does, list its contents and stop — do not overwrite without explicit confirmation.

---

## Workflow / Steps

### Step 1 — Read and internalize the pitch

Read the full pitch before designing anything. Extract:

- **Work streams** from the Solution section: the distinct pieces of the system that need to be built. Each work stream becomes one or more slices.
- **Rabbit Holes** as hard scope constraints: anything the solution explicitly warns against touching. If a proposed slice would require crossing a rabbit hole, flag it and redesign.
- **No Gos** as absolute guards: if drafting a slice would require implementing a No Go, stop and flag it to the user.
- **Appetite** to calibrate depth: "one cycle" means ≤7 slices, each completable in a few hours. Do not over-slice.

---

### Step 2 — Design the dependency graph

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

### Step 3 — Write `slices/<slug>/00-overview.md`

Use the template at `assets/overview-template.md`. Fill in all placeholder fields; do not leave any `<angle bracket>` tokens in the output.

---

### Step 4 — Write each `slices/<slug>/NN-<name>.md`

Use the template at `assets/slice-template.md` for every slice file. Every field in the template is required — do not omit sections.

**One deliverable per file.** If a slice touches multiple files, list each with its own `### Component — path` subsection.

---

### Step 5 — Update pitch frontmatter

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
- Key public methods and their signatures appear in pseudocode — the implementer should not have to guess the interface
- No slice requires crossing a Rabbit Hole or implementing a No Go from the pitch
- Dependencies in each slice header match the dependency graph in `00-overview.md`
- Tests section includes at least one unit test and one CLI-level or acceptance test per slice

---

## Output Format

Confirm to the user:
- Files written: list each path
- Wave structure: one-line summary (e.g., "Wave 1: 01 → Wave 2: 02 + 03 in parallel → Wave 3: 04")
- Pitch updated: confirm `status`, `started`, `slices` fields
- Any judgment calls made (slices combined, rabbit holes avoided) worth flagging
