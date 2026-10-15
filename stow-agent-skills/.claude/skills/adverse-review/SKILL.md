---
name: adverse-review
description: >
  Multi-agent adversarial code review. Spawns three reviewer subagents
  (Auditor, Adversary, Pragmatist) on a single model, runs a cross-examination
  round, then deterministically synthesizes a single ranked report. Use this
  for non-trivial PRs, security-sensitive changes, refactors that touch many
  files, or any change where one perspective has obvious blind spots. Trigger
  phrases include "adverse review", "adversarial review", "multi-perspective
  review", "review my changes from multiple angles", "panel review". NOT
  suitable for trivial diffs (typos, dependency bumps, formatting).
---

# Adverse — Multi-Agent Adversarial Code Review

This skill is the Claude Code-native side of the
[adverse](https://github.com/addyosmani/adverse) project. The same logic is
also available as a standalone CLI (`adverse review …`). When you run inside
Claude Code, prefer this skill — it uses Claude Code's native Agent tool to
spawn reviewers (no subprocess auth issues, faster) and calls Node helpers
only for the deterministic source-collection and synthesis steps.

## When to use this skill

The user explicitly asked for an adversarial / multi-perspective / panel
review of their code, OR they're about to merge / land / ship a non-trivial
change and asked for one more pass. If the diff is trivially mechanical
(formatting, dependency bumps, typos), do NOT invoke this — say so and stop.

## Prerequisites

`node` (>= 20) on PATH. Verify with `node --version`. The skill scripts live
under `${SKILL_DIR}/scripts/` and are stdlib-only (no `npm install` needed).

If `node` is missing, tell the user: install Node 20+ from nodejs.org (or
their package manager) and re-invoke. Do not fall back to a different
implementation; the deterministic synthesizer is the contract.

## Phase 0 — decide what to review

Pick scope before spending tokens:

1. If the user named a path, that's the scope.
2. Else if `git status --porcelain` reports uncommitted changes, review those
   (diff mode against `HEAD`).
3. Else if the current branch is ahead of `main` (or `master` / the configured
   upstream), review the diff since the merge base.
4. Else review the whole working directory.

State the scope you picked in one sentence so the user can redirect.

## Phase 1 — collect source

Run the Node helper that walks the target and produces a single prompt-ready
text block:

```bash
node ${SKILL_DIR}/scripts/collect.mjs --target <path> [--diff [base]] --out /tmp/adverse-source.txt --files-out /tmp/adverse-files.json
```

`/tmp/adverse-source.txt` is what you'll embed in the reviewer prompts.
`/tmp/adverse-files.json` is the file list (use it to confirm scope to the
user). The helper enforces the same source-size caps as the CLI.

If collect fails, surface the error to the user — it's almost always
"target not found" or "diff is empty".

## Phase 2 — round 1: independent reviews

Spawn **three reviewers in parallel** using Claude Code's Agent tool, one per
persona. Each one gets:

- **System prompt**: read from `${SKILL_DIR}/scripts/prompts/<persona>.txt`
  (auditor / adversary / pragmatist).
- **User message**: the contents of `/tmp/adverse-source.txt` prefixed by
  `${SKILL_DIR}/scripts/prompts/round1.txt`.
- **Model**: `opus` unless the user asked for a different one. If the user
  picks a smaller model, pass it to all three personas — different models
  across personas defeats the single-model design.

Each subagent must respond with a single JSON object matching this schema:

```json
{
  "persona": "<auditor|adversary|pragmatist>",
  "verdict": "approve|conditional|reject",
  "summary": "<one sentence>",
  "findings": [
    {
      "severity": "critical|warning|info",
      "file": "<path or null>",
      "line": <int or null>,
      "title": "<short noun phrase>",
      "detail": "<2-6 sentences>",
      "fix": "<concrete remediation or null>"
    }
  ]
}
```

Save each parsed JSON object to disk:

- `/tmp/adverse-round1-auditor.json`
- `/tmp/adverse-round1-adversary.json`
- `/tmp/adverse-round1-pragmatist.json`

If a subagent returns malformed JSON, **retry that one persona once** with
the parser/validator error appended to the original prompt. If the retry also
fails, drop that persona. If fewer than 2 personas survive, abort the run and
report the failure — synthesis requires at least 2 voices.

When all three are done, combine them into one file for the next phase:

```bash
node ${SKILL_DIR}/scripts/combine.mjs \
    --round1 /tmp/adverse-round1-auditor.json /tmp/adverse-round1-adversary.json /tmp/adverse-round1-pragmatist.json \
    --out /tmp/adverse-round1.json
```

## Phase 3 — round 2: cross-review

For each persona that produced a valid round-1 review, spawn a subagent that:

- Sees ALL round-1 reviews (the combined `/tmp/adverse-round1.json`).
- Validates findings it agrees with (cross-lane validation is the signal).
- Challenges findings it thinks are wrong / overstated (with a concrete
  reason).
- Optionally adds new findings the other angles surfaced.

System prompt: same persona file as round 1. User prompt: the contents of
`${SKILL_DIR}/scripts/prompts/round2.txt`, then the round-1 combined JSON,
then the source block.

Output schema:

```json
{
  "persona": "<auditor|adversary|pragmatist>",
  "validate":  [{ "from": "<reporter>", "title": "<title>", "reason": "<…>" }],
  "challenge": [{ "from": "<reporter>", "title": "<title>", "reason": "<…>" }],
  "added":     [<finding object>]
}
```

Save each to `/tmp/adverse-round2-<persona>.json` and combine:

```bash
node ${SKILL_DIR}/scripts/combine.mjs \
    --round2 /tmp/adverse-round2-*.json \
    --out /tmp/adverse-round2.json
```

If the user asked for a faster review or `--single-round`, skip phase 3
entirely. The synthesizer treats missing round 2 as an empty cross-review.

## Phase 4 — synthesize

Run the deterministic synthesizer. This produces the canonical report — never
LLM-render the findings yourself, the synthesizer's groupings (cross-validated
/ consensus / disputed / solo) carry the signal.

```bash
node ${SKILL_DIR}/scripts/synthesize.mjs \
    --round1 /tmp/adverse-round1.json \
    --round2 /tmp/adverse-round2.json \
    --out /tmp/adverse-report.md \
    --json-out /tmp/adverse-report.json \
    --html-out /tmp/adverse-report.html
```

Read `/tmp/adverse-report.md` and present a **summary** to the user, not the
full report:

1. The verdict line (e.g., `SHIP-WITH-CAVEATS (2/3 ship, 1/3 block)`).
2. Counts by severity and confidence.
3. The top 3 findings (cross-validated first, then consensus, then disputed)
   with one-line previews.
4. A pointer to the full report on disk and the HTML dashboard.

Then ask the user how they want to proceed:

- Apply fixes for cross-validated findings only? (highest confidence)
- Apply fixes for everything except disputed? (most common)
- Show me a specific finding's full reasoning?
- Just save the report; I'll review it myself.

Do not start editing files until the user picks one.

## Phase 5 — clean up

After the user is done with the report, delete `/tmp/adverse-*` and tell the
user the run is complete. Do not commit those files.

## Failure handling

| Failure | What to do |
|---|---|
| `collect.mjs` exits non-zero | Surface the error. Common causes: target doesn't exist, `--diff` on non-git dir, empty diff. |
| One reviewer returns garbage twice | Continue with 2 reviewers, mark the run "degraded" in your summary. |
| ≥2 reviewers fail | Abort. Tell the user the model is misbehaving and suggest re-running with a different model or with `--single-round`. |
| `node` not on PATH | Tell the user to install Node 20+. Do not improvise a fallback. |
| User interrupts | Stop spawning new subagents. Tell the user where the partial artifacts are. |

## Notes for the orchestrator

- This skill spends ~6 model calls (3 × round-1 + 3 × round-2). Skip round 2
  on user request to halve it.
- Persona prompts are deliberately written to "stay in your lane" — do NOT
  override them with general-purpose review instructions, doing so collapses
  the orthogonality the design relies on.
- The synthesizer is deterministic Python-free Node code (`synthesize.mjs`).
  Counting validate/challenge edges is the consensus signal; do not run a
  fourth LLM "judge" pass.
- The standalone CLI (`adverse review`) is an alternative path that
  subprocesses any coding agent (`claude -p`, `codex exec`, …). Mention it
  to the user only if they ask how to run this without Claude Code.
