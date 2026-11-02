---
name: draft-pitch
description: Draft a Shape Up pitch — a fat marker sketch of WHAT users can do and WHY it matters, without prescribing HOW. Use when a user supplies a problem and appetite and wants pitches/<slug>.md written.
version: "1.0"
triggers:
  - "draft pitch"
  - "write pitch"
  - "new pitch"
  - "create pitch"
  - "pitch for"
---

# Draft Pitch

## When to use

Capture a new feature idea as a Shape Up pitch. Require:
- A clear problem
- A rough appetite (one cycle / two cycles / spike)

Before writing, check `pitches/<slug>.md` and `pitches/.archive/<slug>.md`. If either exists, show its contents and stop; require explicit confirmation to overwrite.

---

## Workflow

### Step 1 — Extract the JTBD framing

Before drafting, extract from the user's input:

- **Job:** What outcome is the user trying to achieve?
- **Gap:** What friction or missing capability prevents it today?
- **Appetite:** How much time is this worth? (One cycle / two cycles / spike.)

Use these to frame Problem and Appetite. If any are unclear, ask before proceeding.

---

### Step 2 — Draft each section

#### Problem

Describe today's friction, gap, or missing capability from the user's perspective: what they cannot do, what breaks, or what slows them down. Make the problem recognizable, without implementation references (file names, class names, proposed mechanisms).

#### Appetite

State the time budget and constrain scope in one sentence. Example: "One cycle. Scope is limited to the `squad review` flow — no changes to the agent harness or container lifecycle."

#### Solution

Describe product decisions and observable behavior: what users can do, not how the system achieves it.

**Include:**
- User-facing TOML config examples: developer-visible fields are DX decisions, not implementation
- CLI command names, flags, and terminal output examples
- High-level behavior: "waits for services to be healthy before the agent launches," "tears down services before the container stops"
- Scope decisions at the right altitude: "a new method on the engine interface," "extends the existing readiness check"
- ASCII/word-based UX flows ("breadboards") showing interactive affordances and their results, where applicable
- Rough ASCII UI designs ("fat marker sketches") only when needed to communicate a specific affordance

**Do not include:**
- Ruby code blocks, method signatures, or class names
- Internal file or socket paths (`/var/run/...`, `/proc/<pid>/...`, `/var/log/...`)
- Exact timing constants (poll intervals, timeouts in seconds)
- DB column names
- System-level mechanisms by name: `kill -0`, POSIX `timeout`, `/proc/<pid>/fd/0`
- Specific library/framework calls: `TomlRB`, `EngineFactory`, `ClaudeCode#launch_command`
- Exact agent prompt text or injection mechanisms; state what the agent is told to do instead

#### Rabbit Holes (optional)

Include only tempting wrong turns that need explanation: why they fail, what to do instead, or when to stop and reshape. Do not repeat No Gos or Solution; put exclusions in No Gos and required behavior in Solution. Omit this section if nothing remains.

**Include:**
- Scope-expanding alternatives: "don't try to X — the existing Y is sufficient"
- Disproportionately costly behavioral edge cases: "handling Z is a separate problem"
- Adjacent but out-of-scope integration boundaries

**Do not include:**
- Implementation reminders: "remember to define this path as a constant" — save these for slice docs
- Implementation assurances: "no new logic needed here" — these pre-decide implementation
- Library/OS availability notes: "coreutils ships `timeout` on all supported platforms"
- Prescribed internal mechanisms instead of warnings against wrong turns

#### No Gos

List what this cycle will not do as user-observable omissions, not implementation constraints.

**Good:** "Does not push the branch to remote." "Does not run checks inside the container."

**Not this:** "Do not call `git push` from the daemon." "Do not use ActiveRecord."

---

### Step 3 — Write the file

Use the frontmatter template at `assets/pitch-frontmatter.yaml`.

Use the user's slug or derive a lowercase, hyphen-separated noun phrase from the feature name: `agent-log-observability`, `loop-control`, `sign-off`.

---

## Final checks

Fix all violations before handing off.

- Solution code blocks contain only TOML config or terminal output, never Ruby
- Internal file/socket paths and system call names (`kill -0`, `timeout`, `/proc/...`) appear only in Rabbit Holes
- Solution contains no DB column, method, or class names
- Every Rabbit Hole warns of a tempting wrong turn, not implementation notes, reminders, or assurances
- Solution explains user capabilities while leaving internal mechanisms, file paths, method names, and timing constants to developers
- No Gos describe user-observable omissions, not implementation constraints

---

## Output Format

Confirm:

- File written: `pitches/<slug>.md`
- Appetite recorded
- Notable judgment calls (inferred scope edges, condensed sections)
- Next: run `stress-test-pitch` (`../stress-test-pitch/SKILL.md`) to challenge business value, causal assumptions, and scope before human betting. `status: pitched` means drafted, not validated or approved. After review and explicit bet approval, run `draft-slices` (`../draft-slices/SKILL.md`).
