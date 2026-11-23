---
name: aidemo-rails-before
description: "Record a short narrated video (voice, captions, visible cursor and click rings) of how a Rails app behaves today, using aidemo against the local app, either to reproduce a bug report or to capture the \"before\" state ahead of planned changes. Input is requirements in any form, such as a ticket in Linear/GitHub/Basecamp/Fizzy/Jira or free text. It turns them into checkable claims, reproduces each one on the current code, and reports what was and wasn't reproduced. Triggers: \"reproduce this bug\", \"record a repro\", \"capture the before state\", \"film how it works now\", \"before video for <ticket>\", \"show the current behavior before we change it\"."
---

# Reproduce a bug / capture the "before" state with aidemo

Produce a 20–90 second narrated MP4 of the **local** app showing **how it behaves today** for the things a ticket or requirement talks about, plus written repro steps. Two modes, same workflow:

- **Bug repro:** show the reported wrong behavior happening, step by step, so anyone can reproduce it.
- **Before state:** show the current screens and outcomes that planned changes will touch, so the later "after" demo (the `aidemo-rails` skill) has something to compare against.

Tool: [aidemo](https://github.com/tandryukha/aidemo) (MIT, local Chrome + ffmpeg).

The job is **evidence, not advocacy**. Record what the app actually does. A bug that doesn't reproduce is a valid, useful result. Never stage, fake or exaggerate it.

## Ground rules (read first)

1. **Leave the repo untouched.** Everything you create (the aidemo clone, storyboard, cookies, recordings, scripts) lives in the session scratchpad. `git status` at the end must match the start. If a command regenerates `db/schema.rb` (or `db/structure.sql`), back it up first (`cp -p db/schema.rb $SCRATCH/schema.rb.bak`), restore it afterwards, and `cmp`.
2. **Record the right code.** "Before" means before the fix or change. Confirm which commit is running (`git rev-parse --short HEAD`, branch, dirty files). If the current checkout already contains work toward the change, **stop and ask**: switch to the base branch, use a separate worktree (the `kjlape-worktree` skill if present), or record as-is and label it. Put the commit SHA in the deliverable.
3. **Local only.** Never record against shared environments (dev, staging, production), even when the bug was reported there. If it only happens with production data or config, say so and ask; don't go there yourself. Locally, confirm mail goes to a catcher (letter_opener, Mailpit, MailCatcher, `:test` delivery) before triggering anything that sends email.
4. **Stop and ask before anything destructive** (db drop/reset, deleting data, killing servers or containers you didn't start). On `ActiveRecord::PendingMigrationError`, back up the schema file and run the project's migrate command. If a migration fails on existing data, ask.
5. **Read-only on the ticket system.** Read the ticket freely; never comment, change status, attach files or reassign without the user's explicit OK. Draft the comment and let them post it, or post only after they approve.
6. **Follow the project's own agent rules** (`CLAUDE.md`, `AGENTS.md`, `.claude/`). They override this skill. Use Read/Write/Edit for files; Python for computation from a scratchpad script (`python3 -I script.py`).
7. **No secrets or customer data in outputs.** Tickets often contain real names, emails and screenshots of production. Seed lookalike data locally; never copy real customer data into seeds, narration or the video.

## Step 1: Turn the requirements into checkable claims

Get the input:
- **Ticket reference** (URL, id like `ABC-123`, `#456`): fetch it with the matching tool or skill: `gh issue view <n> --comments`, the `linear-issues`, `basecamp` or `fizzy` skills, or an MCP connector. Read the description, **all comments** (later comments often correct the steps), linked issues/PRs, and attachments (screenshots show exact screens and wording).
- **Free text:** use it as given. Ask only for what blocks you (which role? which page?), not for things you can find in the code.

Then write a **claims inventory**: each requirement or symptom as one testable statement about today's app.

| Mode | Turn this… | …into this claim |
|---|---|---|
| Bug | "Export is broken for admins" | "An admin clicking 'Export CSV' on /reports gets an error page instead of a download" |
| Bug | "Totals are wrong after a discount" | "With a 10% discount on a $50 order, the cart shows $50 instead of $45" |
| Before | "Add a search box to the members list" | "The members list has no search; finding someone means scrolling N pages" |
| Before | "Only owners should be able to delete projects" | "Today a regular member can see and use 'Delete project'" |

For each claim, locate it in the code so the repro is targeted, not wandered into:
- `config/routes.rb` → the URL; `app/views/**`, `app/components/**`, `config/locales/*.yml` → the exact on-screen labels (search the ticket's quoted words in the locale files and views); `app/controllers/**`, `app/policies/**` → who can reach it; `app/models/**`, `app/services/**`, `app/jobs/**` → the logic behind an outcome; `spec/**`/`test/**` → whether a test already covers (or contradicts) it.
- For bugs, read the code path and form a **hypothesis of the trigger** (which data, role, or order of steps). It tells you what to seed. Don't fix anything.

Kept in the scratchpad (`inventory.md`) and shown to the user before recording if anything is ambiguous:

```
| # | Claim (plain English) | Mode | Role | Where (URL) | Preconditions / data | Code pointer | Result |
```

`Result` is filled in during Step 4: **Reproduced**, **Partially reproduced** (say what differs), **Not reproduced**, or **Can't test locally** (why).

## Step 2: Get the local app into the reported state

1. **Learn how the project runs:** `bin/dev`, `Procfile.dev`, `docker-compose.yml`/`compose.yml`, README, agent docs. Find the start command, the port, and any command wrapper; use it consistently. Ask before starting servers.
2. App up? `curl -s -o /dev/null -w '%{http_code}\n' <base>/` and the sign-in page return 200. Read `log/development.log` (or container logs) on 500s, except when the 500 *is* the bug. Then keep the log excerpt as evidence.
3. **Seed the preconditions** each claim needs: the role, the record in the right state, the edge-case data (empty list, long name, zero balance, other locale/time zone). Use the project's seeds and rake tasks (`bin/rails -T`), factories, or a scratchpad script via `bin/rails runner $SCRATCH/seed_x.rb`. Record every account and record you create.
4. **Try it by hand first** with curl or `aidemo inspect` before scripting a video. For a bug, confirm the symptom actually appears and note the exact steps. If it doesn't appear, vary one precondition at a time along your hypothesis (data shape, role, order), and note each attempt. Stop after a reasonable search and record "Not reproduced" with what you tried. Don't keep bending the setup until the symptom happens to show up.
5. Capture supporting evidence as you go: the log lines/stack trace for the request (`grep` the request id in `log/development.log`), the HTTP status, the relevant record's attributes. These go in the write-up, not the video.

## Step 3: Install and configure aidemo (scratchpad only)

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

Storyboard: `"voice": {"voiceId": "af_heart"}`. If lemonade is unreachable, stop and ask. **Captions:** use `captions --offline`. Lemonade's Whisper nests word timestamps under `segments[].words`, which stock aidemo ignores. For measured timing, see the `aidemo-rails` skill's caption patch, if it's installed.

**Logged-in session:** log in once with curl and convert the cookie jar to a Playwright `storageState` (`"setup": {"storageState": "state.json"}`). Read the sign-in form for its action and field names first. Devise: GET `/users/sign_in`, extract `authenticity_token`, POST `user[email]`/`user[password]` with the same jar, then GET `/` to consume the flash. Rails' auth generator: POST `/session` with `email_address`/`password`. Then a scratchpad Python script turns `cookies.txt` into `{"cookies":[{name,value,domain,path,httpOnly,secure:false,sameSite:"Lax",expires:-1}],"origins":[]}`. One role per demo dir.

**Selectors and links: never guess.** Run `node bin/aidemo.mjs inspect <url> --dir <demo-dir> --storage-state state.json` on every page you'll visit; grep the real `href` of links before clicking them; add `{"op":"assert","url":"/path$"}` after navigating clicks. Hide dev chrome (`"hide": [".profiler-results"]`), but **don't hide the error page or anything that is part of the bug**.

## Step 4: Storyboard for evidence

Create `$SCRATCH/demo/<name>/generated/storyboard.json` (reference: `node bin/aidemo.mjs guide`). Start from:

```json
{
  "title": "<Ticket id or short name>: current behavior",
  "video": { "width": 1280, "height": 720 },
  "voice": { "voiceId": "af_heart" },
  "setup": { "storageState": "state.json" },
  "hide": [".profiler-results"],
  "captions": { "style": "bar" },
  "cursor": { "style": "dot", "scale": 1.5, "color": "#ffffff", "halo": true },
  "attention": { "clicks": true },
  "keystrokes": true,
  "scenes": [
    { "id": "context", "title": "Starting point", "narration": "…",
      "actions": [ { "op": "goto", "url": "http://localhost:3000/…" }, { "op": "pause", "ms": 1500 } ] }
  ]
}
```

Scene rules (different from a feature demo):

- **Structure:** one short *context* scene (who, where, starting state), then **one scene per claim**, ending on the symptom or current state, and a closing *recap* line ("Reproduced on commit abc1234: two of three issues").
- **Show every step, in order.** The video is the repro steps. Prefer real clicks over `goto` so the path is visible; type real values (`keystrokes: true`); don't skip the step that triggers it.
- **Linger on the evidence.** Pause 1.5–3 s on the wrong value, error page, missing control or unexpected redirect, and point at it with `highlight`/`spotlight`/`callout` (≤80 chars). For a wrong number, show the inputs first so the viewer can check the math.
- **Expected vs actual** for bugs: the narration states what should happen (from the ticket) and the screen shows what does. For invisible symptoms (wrong email sent, background job), show the nearest visible proof: the mail catcher, a page that reflects the job's result.
- **Not reproduced claims** get a scene too when it's informative: do the steps and show the correct result. A video of a bug *not* happening tells the reporter something too.
- Keep actions about as long as narration (~2.5 words/s); run `aidemo lint <dir>` and fix `[scene-freeze]`/`[overrun-cut]`. Over ~90 s, split into one video per claim group.

Narration: neutral and factual, in plain English.
- Describe, don't judge or blame: "The total still shows fifty dollars after the ten percent discount," not "the broken discount code."
- For bugs: "The ticket says X should happen. Here, Y happens instead." For before state: "Today, members have to scroll to find someone. There is no search."
- No speculation about cause in the narration; put hypotheses and code pointers in the write-up.
- No real customer names, ticket-author names, or internal jargon. Use on-screen labels exactly.
- Only claim what is on screen. Every sentence traces to an inventory row.

## Step 5: Probe, render, review

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

Review `output/frames/final-sheet.png` (mandatory):
- The symptom/current state for each claim is actually **visible and readable** in a frame, not flashed past.
- Recording matches your hand repro. If the symptom is flaky (shows in one take, not another), say so in the write-up and mark it **Intermittent**. Don't keep re-recording until you get the take you wanted.
- No login screen, stray flash, dev toolbar, or real customer data in frame.
- Narration fits the scenes (compare `audio/voice.json` `durationMs` to the compose log's stretch, `x0.50`–`x1.6`). You can't hear the audio; say so.

Cheap iteration: narration → `voice` → `captions --offline` → `compose`. Actions → re-`record`.

## Step 6: Deliver

1. Copy `output/final-demo.mp4` and `.srt` to `~/Downloads/<ticket-or-name>-before-vN.mp4` (never overwrite; bump N).
2. Write `~/Downloads/<ticket-or-name>-before-vN.md`, ready to paste into the ticket:
   - **Environment:** local, commit SHA, branch, date, role(s) used.
   - **Steps to reproduce:** numbered, with the exact URL, clicks and values, plus preconditions (the seeded data, described generically).
   - **Expected** (from the ticket) / **Actual** (observed), per claim.
   - **Result per claim:** Reproduced / Partially / Not reproduced / Intermittent / Can't test locally, and for "not reproduced" what you varied.
   - **Evidence:** log excerpt or stack trace (trimmed, no secrets), HTTP status.
   - **Notes for whoever fixes it:** code pointers and your hypothesis, clearly labelled as hypothesis.

   Start the file with a YAML header so the `aidemo-rails-after` skill can find and match it:

   ```yaml
   ---
   aidemo: before
   ticket: ABC-123            # or null for free-text input
   title: <short name>
   commit: <full SHA recorded against>
   branch: <branch>
   recorded: <YYYY-MM-DD>
   kit: <ticket-or-name>-before-vN/
   claims: [{id: 1, claim: "…", result: reproduced}, …]
   ---
   ```
3. Save the **replay kit** in `~/Downloads/<ticket-or-name>-before-vN/` so the same steps can be re-run after the change: `storyboard.json`, `inventory.md`, the seed script(s), and `login.sh` (with the account emails, no cookies, no `state.json`, no secrets beyond seeded test passwords).
4. Final message: paths, duration, the claims table with results, side effects (DB migrated/seeded, servers started, accounts created), honest rough edges, and confirmation that `git status` and the schema file are unchanged. Offer to post the write-up to the ticket; don't post without a yes.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Bug won't reproduce locally | Usually data shape, role, locale/time zone, feature flag, or a later commit already fixed it (`git log -S'<term>'`). Vary one thing at a time; report what you tried. |
| Only reproduces with production data | Don't fetch it. Describe the needed data shape and ask; seed a lookalike. |
| Checkout already has the fix | Ground rule 2: base branch or separate worktree, after asking. |
| The error page is the bug but aidemo's step fails | Assert on the error page's text instead of waiting for the success element; don't `hide` it. |
| `storageState … ENOENT` | Path is relative to the demo dir. |
| Click ran, page didn't change | The link points elsewhere (grep its `href`). Add `assert url`. |
| Login 422 / `InvalidAuthenticityToken` | Token and cookie jar out of sync, or wrong field names. |
| Empty captions on lemonade | Use `captions --offline` then `compose`. |
| Scene looks slow-motion / frozen | Narration/actions length mismatch. Lint and adjust. |

## Don'ts

- Don't fix the bug, or commit, stage or add files to the repo.
- Don't record against shared environments or copy real customer data.
- Don't stage the symptom (editing records mid-take to force the result, hiding the correct state, cherry-picking a flaky take) without saying exactly what you did.
- Don't touch the ticket without approval.
- Don't drop "not reproduced" claims from the write-up.
