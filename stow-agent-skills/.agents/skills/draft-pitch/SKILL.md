---
name: draft-pitch
description: Draft a new Shape Up pitch at the right altitude — fat marker sketch of WHAT users can do and WHY it matters, without pre-deciding HOW. Use when a user supplies a problem and appetite and wants a pitch file written to pitches/<slug>.md.
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

Use this skill when the user wants to capture a new feature idea as a Shape Up pitch. The user must supply:
- A clear description of the problem
- A rough appetite (one cycle / two cycles / spike)

Check whether `pitches/<slug>.md` or `pitches/.archive/<slug>.md` already exists before writing anything. If either does, show its contents and stop — do not overwrite without explicit confirmation.

---

## Workflow / Steps

### Step 1 — Extract the JTBD framing

Before drafting any prose, extract three things from the user's input:

- **The job:** What is the user trying to get done? What outcome do they want?
- **The gap:** What friction or missing capability prevents them from doing it today?
- **The appetite:** How much time is this worth? (One cycle / two cycles / spike.)

These become the spine of the Problem and Appetite sections. If you cannot identify all three, ask the user to clarify before proceeding.

---

### Step 2 — Draft each section

#### Problem

Describe the friction, gap, or missing capability a user faces today. Frame it from the user's perspective — what they cannot do, what breaks, what slows them down. This section should make a reader nod and say "yes, that's the problem."

Do not include any reference to implementation: no file names, no class names, no proposed mechanisms.

#### Appetite

State the time budget and a one-sentence scope constraint. Example: "One cycle. Scope is limited to the `squad review` flow — no changes to the agent harness or container lifecycle."

#### Solution

Describe the solution at the altitude of product decisions and observable behavior. Implementers should finish this section knowing what the user can do, not how the system achieves it.

**Include:**
- User-facing config examples — TOML blocks showing developer-visible fields are product decisions about DX, not implementation
- CLI command names, flags, and terminal output examples
- High-level behavioral descriptions: "waits for services to be healthy before the agent launches," "tears down services before the container stops"
- Scope decisions at the right altitude: "a new method on the engine interface," "extends the existing readiness check"
- ASCII art, low fi, word based diagrams of UX flow (called "breadboards") where applicable, calling out affordances users interact with and the results of interactions
- ASCII art diagrams of rough UI design (AKA "fat marker sketch") only when necessary to communicate a specific UI affordance

**Do not include:**
- Ruby code blocks, method signatures, or class names
- Internal file or socket paths (`/var/run/...`, `/proc/<pid>/...`, `/var/log/...`)
- Exact timing constants (poll intervals, timeout values in seconds)
- DB column names
- System-level mechanisms by name: `kill -0`, POSIX `timeout`, `/proc/<pid>/fd/0`
- References to specific library or framework calls: `TomlRB`, `EngineFactory`, `ClaudeCode#launch_command`
- Exact prompt text to be injected into the agent (state what the agent is told to do, not the injection mechanism or verbatim string)

#### Rabbit Holes

List the tempting wrong turns — paths that look reasonable but would blow up scope, cross a boundary, or require solving a harder problem. Each entry should help an implementer recognize when they are about to veer off course.

**Include:**
- Warnings about scope-expanding alternatives: "don't try to X — the existing Y is sufficient"
- Behavioral edge cases that would require disproportionate effort: "handling Z is a separate problem"
- Integration boundaries that look adjacent but are out of scope

**Do not include:**
- Implementation reminders: "remember to define this path as a constant" — these are for slice docs
- Implementation assurances: "no new logic needed here" — these pre-decide the implementation
- Notes about library or OS availability: "coreutils ships `timeout` on all supported platforms"
- Prescriptive alternatives that specify the internal mechanism rather than warning against a wrong turn

#### No Gos

An explicit list of things this cycle will not do. State each as a user-observable omission, not an implementation constraint.

**Good:** "Does not push the branch to remote." "Does not run checks inside the container."

**Not this:** "Do not call `git push` from the daemon." "Do not use ActiveRecord."

---

### Step 3 — Write the file

Use the frontmatter template at `assets/pitch-frontmatter.yaml`.

Use the slug the user provides, or derive one from the feature name: lowercase, hyphen-separated, noun phrase. Example: `agent-log-observability`, `loop-control`, `sign-off`.

---

## Constraints / Do's and Don'ts

Apply before finishing. Fix any failures before handing off.

- No Ruby code blocks in the Solution section (TOML config and terminal output are the only acceptable code blocks)
- No internal file or socket paths appear outside Rabbit Holes
- No system call names (`kill -0`, `timeout`, `/proc/...`) appear outside Rabbit Holes
- No DB column names, method names, or class names appear in Solution
- Every Rabbit Hole entry warns about a tempting wrong turn — not an implementation note, reminder, or assurance
- A developer reading Solution understands what users can do and has freedom to choose internal mechanisms, file paths, method names, and timing constants
- No Gos are stated as user-observable omissions, not implementation constraints

---

## Output Format

Confirm to the user:

- File written: `pitches/<slug>.md`
- Appetite recorded
- Any judgment calls made (scope edges inferred, sections condensed) worth flagging
- Next step: run the `draft-slices` skill (`skills/draft-slices/SKILL.md`) when ready to begin the cycle
