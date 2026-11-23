---
name: aidemo-rails-after
description: "Record a short narrated before/after video (voice, captions, visible cursor and click rings) of what a change did to a Rails app, using aidemo against the local app. Input is a git target: feature branch, PR, merge commit, single commit, or commit range. It finds matching outputs of the aidemo-rails-before skill if they exist, replays the same steps on the new code, and reports each earlier claim as fixed, changed, unchanged or regressed, plus anything new in the diff. Triggers: \"after video\", \"show the fix\", \"before and after\", \"did this fix the bug\", \"verify the change against the before recording\", \"demo what this branch changed\"."
---

# Before/after demo of a change with aidemo

Produce a 20–90 second narrated MP4 of the **local** app on the changed code, organised as **before → after** for each thing the change touches, plus a write-up ready for a PR or ticket. When an `aidemo-rails-before` recording exists, this skill replays its steps and gives a verdict on every claim it made. Otherwise it builds the "before" from the base commit itself.

Tool: [aidemo](https://github.com/tandryukha/aidemo) (MIT, local Chrome + ffmpeg). For a plain feature demo with no comparison, use `aidemo-rails` instead.

This is **verification, not a victory lap**. If a reported bug still reproduces, or something got worse, that is the headline.

## Ground rules (read first)

1. **Leave the repo untouched.** Everything you create (the aidemo clone, storyboard, cookies, recordings, scripts, extra worktrees) lives in the session scratchpad. `git status` in the user's checkout must match the start. If a command regenerates `db/schema.rb` (or `db/structure.sql`), back it up first, restore it afterwards, and `cmp`.
2. **Record the right code.** The "after" take runs on the **head** of the target, the "before" take (if you make one) on the **base**. Check what the running server has checked out (`git rev-parse HEAD` in its directory, dirty files). If it isn't the commit you need, **ask** before switching branches. Prefer a separate worktree (the `kjlape-worktree` skill if present) over checking out in the user's tree. Write both SHAs into the deliverable.
3. **Local only.** Never record against shared environments (dev, staging, production). Confirm local mail goes to a catcher before triggering email.
4. **Stop and ask before anything destructive** (db drop/reset, deleting data, killing servers or containers you didn't start). Switching between base and head often means migrating forward and back: ask first, back up the schema file, and prefer a separate database for the second worktree over rolling migrations back on the user's.
5. **Read-only on GitHub and ticket systems.** Read PRs and tickets freely; never comment, edit descriptions, attach files or change status without an explicit yes.
6. **Follow the project's own agent rules** (`CLAUDE.md`, `AGENTS.md`, `.claude/`). They override this skill. Use Read/Write/Edit for files; Python for computation from a scratchpad script (`python3 -I script.py`).
7. **No secrets or customer data in outputs.** Seeded test passwords are fine; nothing else.

## Step 1: Resolve the target into base and head

| Input | Base | Head |
|---|---|---|
| Feature branch `B` | `git merge-base <default> B` | `B` |
| PR `#n` | `gh pr view n --json baseRefName,headRefOid,mergeCommit`, then the merge-base of the base branch and head | `headRefOid` (or the merge commit if merged) |
| Merge commit `M` | `M^1` | `M` |
| Single commit `C` | `C^` | `C` |
| Range `A..B` | `A` | `B` |
| Nothing given | merge-base of the default branch and `HEAD` | `HEAD` |

Find the default branch with `git symbolic-ref refs/remotes/origin/HEAD`. Show the user the resolved `base..head` (short SHAs and one-line subjects) and `git log --oneline base..head` before going further. Note any ticket ids in branch names, commit messages and the PR body; Step 2 uses them.

## Step 2: Find the "before" outputs

The `aidemo-rails-before` skill delivers to `~/Downloads/`:
- `<name>-before-vN.md`, whose YAML header has `aidemo: before`, `ticket`, `title`, `commit`, `branch`, `recorded`, `kit`, `claims`
- `<name>-before-vN.mp4` / `.srt`
- `<name>-before-vN/` (the replay kit): `storyboard.json`, `inventory.md`, seed scripts, `login.sh`

Look for them (`grep -l '^aidemo: before' ~/Downloads/*-before-v*.md`, plus any path the user gave) and match on, in order:
1. A path or name the user gave.
2. The same **ticket id** as the PR, branch or commits.
3. A `commit` that is an ancestor of head (`git merge-base --is-ancestor <commit> <head>`) and whose title or claims match the diff's area.

When several match, take the highest `vN` and say so. **Show the match to the user and confirm** unless it's unambiguous (the user named it, or exact ticket id plus ancestry).

Check that the recording is still valid as a baseline:
- `commit` equal to `base`: ideal.
- `commit` an ancestor of `base`: other changes landed in between (`git log --oneline <commit>..<base>`). Say so; a claim that changed may have changed before this branch did. If the gap touches the same files, offer to re-record the before take on `base`.
- Not an ancestor of head: wrong baseline. Don't use it without asking.

**No before outputs found:** say so, then offer:
- **(a) Record a fresh before take on `base`** in a scratch worktree, following the `aidemo-rails-before` skill's workflow, then continue here. Best when the change is a bug fix or the user wants real side-by-side evidence.
- **(b) Proceed with an after-only demo**, describing the before state from the diff in narration ("Previously, there was no search here."). Mark every such claim as **"before: from code, not recorded"**.

Default to (a) for bug fixes and (b) for pure new features, but ask.

## Step 3: Build the comparison inventory

Start from the before claims (if any), then mine `git diff base..head` the same way `aidemo-rails` does: routes, views/components/helpers, JavaScript, locale files (exact wording), controllers/policies, models/services/jobs, mailers, migrations, and spec/test names. Classify each change as UI/UX, behavior, or internal-only.

Then merge the two lists:

```
| # | Claim / change (plain English) | Source | Before (observed or from code) | After (observed) | Verdict |
```

`Source` is `before #k`, `diff`, or both. `Verdict` gets filled in during Step 5:
- **Fixed:** a reported bug no longer happens.
- **Changed as intended:** the before state now matches the requirement.
- **Partially:** some of it is done; say what's left.
- **Unchanged:** a before claim the diff didn't address (often fine if it was out of scope; say which).
- **Not fixed:** the change aimed at it, but it still reproduces. **Headline this.**
- **Regressed:** something that worked before is now worse. **Headline this.**
- **New:** in the diff, with no before claim (a new screen or option).
- **Can't test locally:** why.

Every claim in the before write-up gets a row. Never drop one because it's awkward.

## Step 4: Get the local app onto head with the same preconditions

1. **Learn how the project runs** (`bin/dev`, `Procfile.dev`, compose files, README, agent docs): start command, port, command wrapper. Ask before starting servers.
2. Make sure the server is running **head** (ground rule 2). Migrate if needed (ground rule 4). Check `curl -s -o /dev/null -w '%{http_code}\n' <base-url>/` returns 200.
3. **Recreate the before preconditions.** Run the kit's seed scripts (via the project's runner, e.g. `bin/rails runner <kit>/seed_x.rb`). If the change renamed fields or models, adapt a **scratchpad copy** of the seed, never the kit, and note what you adapted. Without a kit, seed from the before write-up's preconditions, or, for diff-only claims, from the app's own seeds and factories.
4. Use the **same roles and accounts** as the before take (the kit's `login.sh`), then build a fresh `state.json`.
5. **Try each claim by hand first** (curl, `aidemo inspect`). Confirm what you'll see before scripting the video. For "fixed" claims, repeat the original repro steps exactly. For a fix to an intermittent bug, run the repro several times and report the count ("0 of 10 attempts", against the before's rate).
6. Run the relevant tests the branch added or changed, if that's cheap (`bin/rails test <files>` / `bundle exec rspec <files>`), and report pass/fail. Don't fix failures.

## Step 5: Install and configure aidemo (scratchpad only)

```bash
git clone --depth 1 https://github.com/tandryukha/aidemo $SCRATCH/aidemo
cd $SCRATCH/aidemo && npm install --no-audit --no-fund
node bin/aidemo.mjs doctor      # needs Node 22+, ffmpeg, system Chrome
```

Run the CLI as `node bin/aidemo.mjs <cmd>` from the clone (`cd` inside each command). Demo dirs go under `$SCRATCH/demo/<name>/`; **storyboard paths are relative to the demo dir**.

**Voice (no paid API):** the lemonade server on the tailnet (Kokoro TTS). Check `curl -s -m 10 https://ai.hair-pentatonic.ts.net/v1/models` lists `kokoro-v1`, then run every `voice`/`record`/`captions` call as:

```bash
env -u OPENAI_API_KEY OPENAI_BASE_URL=https://ai.hair-pentatonic.ts.net/v1 \
  AIDEMO_TTS_MODEL=kokoro-v1 AIDEMO_STT_MODEL=Whisper-Small \
  node bin/aidemo.mjs <cmd> <demo-dir> --headless
```

Use the before storyboard's `voice` settings so both takes sound the same (default `"voiceId": "af_heart"`). If lemonade is unreachable, stop and ask. **Captions:** `captions --offline` (see the `aidemo-rails` skill for the measured-timing patch, if installed).

**Selectors: re-inspect, never assume.** The change may have moved or renamed the very controls the before storyboard clicks. Run `node bin/aidemo.mjs inspect <url> --dir <demo-dir> --storage-state state.json` on every page, grep real `href`s, and `assert` the URL after navigating clicks. Hide dev chrome (`"hide": [".profiler-results"]`), but never hide an error that shows up in the after take.

## Step 6: Storyboard: same steps, new outcome

Start from a **copy** of the kit's `storyboard.json` in `$SCRATCH/demo/<name>-after/generated/` (or from the `aidemo-rails` template if there's no kit). Change the title to `"<ticket or name>: before and after"`. Keep the action sequence for each before claim **as close to the original as the new UI allows**, so the comparison is fair. Where the UI changed the path (a renamed button, a new step), use the new path and say so in narration.

Scene structure:
- **Hook (≤5 s):** what changed, in one line ("Discounts now apply to the cart total").
- **One scene per inventory row worth showing,** in the order: Not fixed / Regressed first (if any), then Fixed / Changed as intended, then New.
  - **Before beat:** either a short clip from the before video (see "Side-by-side and inserts" below) or, with no recording, one narration sentence over the starting screen ("Before this change, the total ignored the discount.").
  - **After beat:** perform the same steps live and stop on the result. Pause 1.5–3 s and point at it with `highlight`/`spotlight`/`callout` (≤80 chars).
- **Recap:** the verdict counts ("Two issues fixed, one new option, nothing regressed. Recorded on commit abc1234.").
- Keep actions about as long as narration (~2.5 words/s); `aidemo lint <dir>` and fix `[scene-freeze]`/`[overrun-cut]`. Over ~90 s, split into one video per area.

Narration in plain, neutral English:
- "Before" / "Now" framing: "Before, the total stayed at fifty dollars. Now it shows forty-five."
- Say plainly when something isn't fixed: "The export still fails for admins."
- Don't call something fixed unless the after take shows it. "From code, not recorded" claims are worded as "previously…" and flagged in the write-up.
- No code names, ticket ids, jargon, or real customer data. Use the on-screen labels exactly.

### Side-by-side and inserts (optional, ffmpeg)

When a before MP4 exists, you can show the before beat as real footage. Find the claim's time span in the before `.srt` (its cue times), then in the scratchpad:

```bash
# cut the before beat
ffmpeg -ss <start> -to <end> -i <before>.mp4 -c:v libx264 -an $SCRATCH/clips/before-k.mp4
# side-by-side with the matching after beat (same height), labelled
ffmpeg -i $SCRATCH/clips/before-k.mp4 -i $SCRATCH/clips/after-k.mp4 -filter_complex \
  "[0]scale=-2:720,drawtext=text='Before':x=20:y=20:fontsize=36:fontcolor=white:box=1:boxcolor=black@0.6[a];\
   [1]scale=-2:720,drawtext=text='After':x=20:y=20:fontsize=36:fontcolor=white:box=1:boxcolor=black@0.6[b];\
   [a][b]hstack=inputs=2" -an $SCRATCH/clips/sbs-k.mp4
```

Pick one form per video: either the narrated aidemo after video on its own (simplest, default), or the after video plus a separate **side-by-side reel** of the key claims. Don't splice ffmpeg clips into the aidemo composition, because it throws off aidemo's caption and audio timing. Say which you delivered.

## Step 7: Probe, render, review

```bash
cd $SCRATCH/aidemo
node bin/aidemo.mjs validate <dir>
node bin/aidemo.mjs probe <dir> --headless      # dry run, screenshots in <dir>/logs/fail-*.png
# with the lemonade env vars:
node bin/aidemo.mjs voice <dir>
node bin/aidemo.mjs record <dir> --headless
node bin/aidemo.mjs captions <dir> --offline
node bin/aidemo.mjs compose <dir>
node bin/aidemo.mjs frames <dir> --every 3 --sheet --columns 3
```

Review `output/frames/final-sheet.png` (mandatory), and compare with the before video's frames when it exists (`frames` on a copy of it, or `ffmpeg -ss <t> -i <before>.mp4 -frames:v 1 …`):
- Each after result is visible and readable, and it's the same screen and data as the before beat (same record, same role), so the comparison is fair.
- Every verdict matches what's on screen, especially "Fixed".
- No login screen, stray flash, dev toolbar, or real customer data in frame.
- Narration fits the scenes (`audio/voice.json` `durationMs` against the compose log's stretch, `x0.50`–`x1.6`). You can't hear the audio; say so.

Cheap iteration: narration → `voice` → `captions --offline` → `compose`. Actions → re-`record`.

## Step 8: Deliver

1. Copy `output/final-demo.mp4` and `.srt` to `~/Downloads/<ticket-or-name>-after-vN.mp4` (never overwrite; bump N), plus `-sbs-vN.mp4` if you made a side-by-side reel.
2. Write `~/Downloads/<ticket-or-name>-after-vN.md`, ready to paste into a PR or ticket:

   ```yaml
   ---
   aidemo: after
   ticket: ABC-123
   title: <short name>
   base: <full SHA>
   head: <full SHA>
   target: <what the user gave: branch / PR #n / range>
   before: <name>-before-vN.md   # or null
   recorded: <YYYY-MM-DD>
   ---
   ```
   - **Summary:** one line with the verdict counts, with any Not fixed / Regressed first.
   - **Comparison table:** the Step 3 table, filled in.
   - **How it was checked:** roles, preconditions, seed adaptations, repeated-run counts for intermittent bugs, and the tests run with their results.
   - **Not shown:** internal-only changes (one line each), "can't test locally" items with reasons, and before claims that were out of scope.
   - **Baseline caveats:** commits between the before recording and base, and claims whose before came "from code, not recorded".
3. Save the after kit next to it (`<ticket-or-name>-after-vN/`: storyboard, adapted seed scripts, inventory), so it can be re-run after review fixes.
4. Final message: paths, duration, base..head, which before outputs were used (or that none were found and which option you took), the comparison table, side effects (worktrees created, DB migrated/seeded, servers started, accounts created), honest rough edges, and confirmation that `git status` and the schema file are unchanged in the user's checkout. Offer to post the write-up to the PR or ticket; don't post without a yes. Remove scratch worktrees only after asking.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Several before recordings match | Highest `vN` for the same ticket; otherwise ask. |
| Before `commit` isn't an ancestor of head | Wrong baseline (other branch, rebased away). Ask; offer a fresh before take on base. |
| Before storyboard's selectors fail on head | The change moved the UI. Re-`inspect`, use the new path, say so in narration. |
| Kit seed script fails on head | Schema changed. Adapt a scratch copy; note the changes in the write-up. |
| Server is on the wrong commit | Ground rule 2: ask; prefer a scratch worktree, ideally with its own database. |
| A "fixed" bug shows up again on a rerun | Mark it Intermittent / Not fixed with the counts. Don't pick the good take. |
| Side-by-side clips out of sync | Trim each beat to start on the same action; don't speed one side up. |
| `storageState … ENOENT` | Path is relative to the demo dir. |
| Empty captions on lemonade | `captions --offline`, then `compose`. |

## Don'ts

- Don't fix bugs, edit the branch, or commit, stage or add files to the repo.
- Don't change the before kit or recordings; work on copies.
- Don't call something fixed without showing it, or drop a before claim from the table.
- Don't record against shared environments or use real customer data.
- Don't touch PRs or tickets without approval.
