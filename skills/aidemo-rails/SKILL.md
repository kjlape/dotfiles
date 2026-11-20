---
name: aidemo-rails
description: Make a short narrated demo video (voice, captions, visible cursor and click rings) of a feature or change in a Rails app, using aidemo against the local app. First discovers every UI/UX change and significant behavior change in the work, then shows each one in plain English. Triggers — "demo this feature", "make a demo video of <change/PR/branch>", "record a walkthrough", "narrated demo", "show what changed".
---

# Demo a Rails feature with aidemo

Produce a 20–60 second narrated MP4 of the **local** app showing what changed, written so a non-technical reader (an end user, a manager, a customer) understands it. Tool: [aidemo](https://github.com/tandryukha/aidemo) (MIT, local Chrome + ffmpeg).

## Ground rules (read first)

1. **Leave the repo untouched.** Everything you create (the aidemo clone, storyboard, cookies, recordings, scripts) lives in the session scratchpad, never in the repo. `git status` at the end must match `git status` at the start. If a command regenerates `db/schema.rb` (or `db/structure.sql`), restore it from a backup you took first (`cp -p db/schema.rb $SCRATCH/schema.rb.bak`, then `cp -p` back and `cmp`).
2. **Local only.** Never record against shared environments (dev, staging, production): mail and side effects are real there. Locally, confirm mail goes to a catcher (letter_opener, Mailpit, MailCatcher, `:test` delivery) before triggering anything that sends email. Check `config/environments/development.rb`.
3. **Stop and ask before anything destructive** (db drop/reset, deleting data, killing containers or servers you didn't start). If the local app raises `ActiveRecord::PendingMigrationError`, back up the schema file and run the project's migrate command (`bin/rails db:migrate`, or its wrapper, see Step 2). If a migration fails on existing data, stop and ask the user which way to go (fix rows, reseed, or a scratch DB copy). Do not decide for them.
4. **Follow the project's own agent rules** (`CLAUDE.md`, `AGENTS.md`, `.claude/`): command wrappers, forbidden commands, shell restrictions. They override the defaults here. Use Read/Write/Edit for files; Python for computation is fine, from a script in the scratchpad (`python3 -I script.py`).
5. **No secrets in outputs.** Seeded test passwords are fine; never print API keys or credentials. Default to the local voice server below, not a paid API.

## Step 1: Discover what changed (do this before touching aidemo)

The video is only as good as this list. Build a **change inventory** and show it to the user (short table) before recording if anything is ambiguous.

Find the scope, in order:
- The user's pointer (PR number, branch, commit range, issue/ticket id, or a feature name). If none, diff the current branch against the default branch (find it with `git symbolic-ref refs/remotes/origin/HEAD`): `git diff <default>...HEAD --stat`, `git log <default>..HEAD --oneline`. For a PR: `gh pr view <n>` and `gh pr diff <n> --name-only`.
- Read the PR/issue description and any linked docs in the repo (`docs/`, `doc/`, ADRs).

Then mine the diff for everything a user could notice. Check each category; most features touch several:

| Look at | What it reveals |
|---|---|
| `config/routes.rb` diff | New or moved pages, new URLs |
| `app/views/**`, `app/components/**`, `app/helpers/**` | New/changed screens, buttons, labels, banners, empty states, flash messages |
| `app/javascript/**` (Stimulus controllers, etc.) | New interactions (toggles, live validation, modals, auto-save) |
| `config/locales/*.yml` | Every new or changed user-facing string. The best source of exact wording |
| `app/controllers/**`, `app/policies/**` (Pundit/CanCan etc.) | Who can now do what; redirects; new permission checks |
| `app/services/**`, `app/jobs/**`, `app/models/**` | Behavior changes with no UI of their own: pricing, calculations, eligibility, notifications, state transitions, validations |
| `app/mailers/**`, `app/views/*mailer*` | New or changed emails (check the local mail catcher) |
| `db/migrate/**` | New fields or data meaning; hints at user-visible behavior |
| `spec/**` / `test/**` diff (system, request, model tests) | The author's own statement of intended behavior. Read the `it`/`describe`/`test` names |
| I18n / RTL | If the app is multilingual, note which locales the changed pages must work in |

Classify each finding:
- **UI/UX change**: something a person sees or clicks differently. **Must be shown.**
- **Behavior change**: same screen, different outcome (a price, a total, who gets an email, an action that is now allowed/denied). **Must be shown or called out**: demonstrate the before/after outcome on screen; if it truly cannot be seen (background job, internal rule), say it in narration over the nearest visible screen and in the summary.
- **Internal only** (refactor, rename, perf, tests): leave out of the video; list under "not shown".

Output of this step, kept in the scratchpad (`inventory.md`) and summarized to the user:

```
| # | Audience | Change (plain English) | Type | Where (URL / role) | Source (file or PR) | Demoable? |
```

Write each "Change" as one sentence a non-developer could read aloud: "Customers now see a banner when their trial is about to end", not "Added `trial_ends_at` partial".

## Step 2: Make sure the local app can show it

1. **Learn how this project runs.** Look at `bin/dev`, `Procfile.dev`, `docker-compose.yml`/`compose.yml`, `README`, and project agent docs for the start command, the port, and any command wrapper (e.g. `bin/rails` vs. `docker compose exec web bin/rails` vs. a `./run` script). Use the wrapper consistently below.
2. App up? Check the server process or `docker compose ps`, then `curl -s -o /dev/null -w '%{http_code}\n' <base>/` (and the sign-in page, e.g. `/users/sign_in` for Devise, `/session/new` for Rails' auth generator) returns 200. If it isn't running, ask before starting it.
3. 500s: read `log/development.log` (or `docker logs --tail 40 <web container>`). Pending migrations: see ground rule 3.
4. **Seed the state each change needs.** Prefer what the project already has: `db/seeds.rb`, `db/seeds/**`, custom rake tasks (`bin/rails -T` and grep for `seed`/`scenario`/`demo`), factories via `bin/rails runner`. For one-offs, a scratchpad Ruby script run with `bin/rails runner $SCRATCH/seed_x.rb`. Seed only locally, and record every account/record you create.
5. Pick the **right account for each change's audience** (end user vs admin vs other roles). Look for documented dev credentials in the README or seeds; otherwise create a dedicated demo user.
6. If a change needs a state that doesn't exist and can't be seeded, mark it **NOT DEMOABLE** in the inventory and tell the user, rather than faking it.

## Step 3: Install and configure aidemo (scratchpad only)

```bash
git clone --depth 1 https://github.com/tandryukha/aidemo $SCRATCH/aidemo
cd $SCRATCH/aidemo && npm install --no-audit --no-fund
node bin/aidemo.mjs doctor      # needs Node 22+, ffmpeg, system Chrome
```

The first record downloads Playwright's tiny ffmpeg helper automatically. The CLI is `node bin/aidemo.mjs <cmd>` run from the clone (the shell cwd may reset between calls, so `cd` inside each command). Demo dirs go under `$SCRATCH/demo/<name>/` and **all storyboard paths are relative to the demo dir**.

### Voice and caption timing (no paid API)

Default to the lemonade server on the tailnet: Kokoro TTS. Verify first:

```bash
curl -s -m 10 https://ai.hair-pentatonic.ts.net/v1/models        # look for "kokoro-v1"
```

Use these env vars on every `voice`/`render` call (and unset any OpenAI key so it can't be used by accident):

```bash
env -u OPENAI_API_KEY \
  OPENAI_BASE_URL=https://ai.hair-pentatonic.ts.net/v1 \
  AIDEMO_TTS_MODEL=kokoro-v1 \
  AIDEMO_STT_MODEL=Whisper-Small \
  node bin/aidemo.mjs <cmd> <demo-dir> --headless
```

Storyboard voice: `"voice": {"voiceId": "af_heart"}`. If lemonade is unreachable, stop and ask (options: local `kokoro-js`, or the user's OpenAI key with permission).

**Caption timing.** Lemonade's Whisper *does* return word timestamps (`Whisper-Small`, `Whisper-Large-v3-Turbo`, `Whisper-Large-v3`, `Whisper-Tiny`, via `verbose_json`; checked against Kokoro audio). But it nests them in `segments[].words`, while aidemo reads only top-level `words`, so a stock `captions` run says "no word timestamps returned" and captions are empty. Two ways to get captions:

1. **Default: offline.** `aidemo captions <dir> --offline`, then `aidemo compose <dir>`. Words are spread across each scene by length. This is solid because each scene's audio length is already known exactly; only the position of words inside a scene is estimated. Good enough for scenes of one or two short sentences.
2. **Measured timing (better for long scenes, long sentences, or pauses inside narration).** In the scratchpad clone only (never the repo), make `src/captions.ts` fall back to the nested words, then run `captions --align-script` (without `--offline`). **`--align-script` is required**: without it the cues carry Whisper's raw tokens ("Dash board", a zero-length "." cue). **Delete `generated/captions.manifest.json` first** if an earlier `captions` run (stock or offline) happened, because aidemo caches the transcription result and will reuse the empty one (it prints "captions unchanged, reusing"). Tested with Whisper-Small: cues start at the real speech onset and follow pauses between sentences, and the text stays your script.

   ```ts
   // was: const words: Word[] = (res as unknown as { words?: Word[] }).words ?? [];
   const r = res as unknown as { words?: Word[]; segments?: { words?: Word[] }[] };
   const words: Word[] = r.words ?? (r.segments ?? []).flatMap((s) => s.words ?? []);
   ```

   Caveats: Whisper splits some words and emits "." as its own token; very short words can have near-zero length. Treat word times as approximate (segment times are reliable). The gain over offline is modest: caption start/stop match the speech instead of the scene slot. If it logs `caption drift`, or the result looks worse than offline, fall back to option 1. If `captions` still logs "no word timestamps", fall back to option 1.

Raw API check (use `verbose_json`; plain `json` has no timestamps; `srt`/`vtt` untested):

```bash
curl -s https://ai.hair-pentatonic.ts.net/v1/audio/transcriptions -F file=@audio.wav -F model=Whisper-Small \
  -F response_format=verbose_json -F 'timestamp_granularities[]=word' -F 'timestamp_granularities[]=segment'
```

### Logged-in session without showing a login screen

Open the demo on the value, not on a login page. Log in once with curl, convert the cookie jar to a Playwright `storageState`, and reference it from the storyboard (`"setup": {"storageState": "state.json"}`, file sits in the demo dir).

First read the app's sign-in form (`curl -s $BASE/<sign-in path>`) for its action URL and field names. Devise example:

```bash
# login.sh (scratchpad)
J=cookies.txt; rm -f $J
T=$(curl -s -c $J $BASE/users/sign_in | grep -o 'name="authenticity_token" value="[^"]*"' | head -1 | sed 's/.*value="//;s/"$//')
curl -s -b $J -c $J -o /dev/null $BASE/users/sign_in \
  --data-urlencode "authenticity_token=$T" \
  --data-urlencode "user[email]=$EMAIL" --data-urlencode "user[password]=$PASSWORD"
curl -s -b $J -c $J -o /dev/null $BASE/        # consume the "Signed in successfully" flash so it isn't in frame
```

Rails' built-in auth generator posts to `/session` with `email_address` and `password`; adjust to match. Then a small Python script reads `cookies.txt` into `{"cookies":[{name,value,domain,path,httpOnly,secure:false,sameSite:"Lax",expires:-1}],"origins":[]}`. To demo a second role, make a second storageState and a second demo dir (aidemo records one identity per take); cut the videos together or deliver them as separate clips.

If login uses SSO/OAuth/magic links and can't be scripted, sign in once in a headed aidemo/Playwright session and save its storageState, or ask the user.

## Step 4: Discover real selectors and real links. Never guess

- `node bin/aidemo.mjs inspect <url> --dir <demo-dir> --storage-state state.json` lists every visible control with unique selectors. Run it on each page you will visit.
- **Verify what a link actually points at before building a flow on it.** Fetch the page with the session cookie and grep the `href` (`curl -s -b cookies.txt <url> -o page.html`, then grep). A nav label often goes somewhere other than its name suggests (e.g. a "Projects" link that lands on the dashboard), so "click Projects" silently goes nowhere new. If a click doesn't change the URL, that's usually why.
- Add a `{"op":"assert","url":"/path$"}` after each navigating click so a no-op click fails the probe instead of shipping.
- A guessed URL can land on Rails' routing-error page. Fetch it or `inspect` it first.
- Hide dev-only chrome with `"hide": [...]`: rack-mini-profiler (`.profiler-results`), web-console, debug bars, environment banners. Check a screenshot for anything else.
- Pages can render in another locale if the seeded user has one set. Check the screenshot; avoid or fix that page.

## Step 5: Write the storyboard

Create `$SCRATCH/demo/<name>/generated/storyboard.json`. Authoring reference: `node bin/aidemo.mjs guide` (or `$SCRATCH/aidemo/docs/AUTHORING.md`).

Starting template:

```json
{
  "title": "<Feature name> demo",
  "video": { "width": 1280, "height": 720 },
  "voice": { "voiceId": "af_heart" },
  "setup": { "storageState": "state.json" },
  "hide": [".profiler-results"],
  "zoom": {},
  "captions": { "style": "bar" },
  "cursor": { "style": "dot", "scale": 1.5, "color": "#ffffff", "halo": true },
  "attention": { "clicks": true },
  "keystrokes": true,
  "scenes": [
    { "id": "intro", "title": "Where to start", "narration": "…",
      "actions": [ { "op": "goto", "url": "http://localhost:3000/…" }, { "op": "pause", "ms": 1500 } ] }
  ]
}
```

Making inputs visible:
- `cursor` block (present **when recording**) → a visible dot cursor drawn at compose time; restyle later without re-recording.
- `attention.clicks: true` → a ring at every click.
- `keystrokes: true` → a chip for each `press` (Enter, Esc…). Typed text needs no chip.
- Beats to point at the thing that changed: `highlight`, `spotlight`, `callout` (≤80 chars of text). Use one per sentence at most, right before or as the narration names it.

### Scene design rules

- **One scene per inventory item** (group tiny related ones). Order: the most important change first, "hook" in the first 3 seconds, end on a one-line recap.
- **Show, don't just tell.** For a behavior change, perform the action that triggers it and let the result appear (the new total, the banner, the disabled button, the email in the mail catcher). For before/after, show the old state if it still exists (another user, a feature flag, a different record) and say what is different.
- **Pre-navigate:** end a scene with the click that opens the next scene's page, so each scene opens on the screen its narration describes. Clicking real UI beats `goto` (it shows the user how to get there). Use `goto` only when no link exists, and say so in the summary as a possible UX finding.
- Use `{"op":"click","target":{"selector":…}}`, then `assert`. Add a `pause` (600–1500 ms) after a result appears so viewers can read it.
- Keep each scene's actions roughly as long as its narration (about 2.5 words/second). A one-line narration over long actions gets slowed to the 0.5× floor and looks sluggish; a long narration over a static page freezes. Run `aidemo lint <dir>` and fix `[scene-freeze]`/`[overrun-cut]`.
- Total 20–60 s. If the inventory is bigger, make several short videos (one per area), not one long one.

### Narration: clear simple English

- Speak to the person who uses the feature, in everyday words. Say what they can now do or what is different, and why it helps. ("You can now see your remaining balance without contacting support.")
- Short sentences, about 8–16 words, no jargon: no model/controller/job/migration/flag/endpoint talk, no ticket ids, no code names. Use the UI's own labels exactly as written on screen, in quotes only if it helps.
- Name the **who** ("Customers…", "Admins…", "Team members…"). Say **where** to find it only when it's not obvious.
- Behavior changes with nothing to see: one plain sentence over the nearest screen ("Late fees are now added on the first day after the deadline.").
- Write numbers and acronyms as spoken (`voice.pronounce` maps words: `{"CSV":"C S V"}`).
- Never invent behavior. Every claim must trace to a row in the inventory.

## Step 6: Probe, render, review

```bash
cd $SCRATCH/aidemo
node bin/aidemo.mjs validate <dir>
node bin/aidemo.mjs probe <dir> --headless        # dry run: no voice, catches bad selectors/URLs (screenshot in <dir>/logs/fail-*.png)
# then, with the lemonade env vars from Step 3:
node bin/aidemo.mjs voice  <dir>
node bin/aidemo.mjs record <dir> --headless
node bin/aidemo.mjs captions <dir> --offline
node bin/aidemo.mjs compose <dir>
node bin/aidemo.mjs frames <dir> --every 3 --sheet --columns 3
```

(`render` runs voice → record → captions → compose, but on an unpatched aidemo its caption step is empty on lemonade; use the staged commands above, or `render` then `captions --offline` + `compose`.)

Review is mandatory. Read `output/frames/final-sheet.png` and check:
- Every scene opens on the page its narration describes; no wrong page, routing-error page, login screen, flash message, or dev toolbar.
- Dot cursor and click rings visible; each inventory item actually appears on screen.
- Captions read cleanly (no awkward mid-phrase splits; shorten the line if so, then `voice` re-voices only changed scenes).
- Audio fits: compare each scene's narration duration (`audio/voice.json` `durationMs`) with its slot in `generated/` timing / compose log (`x0.50`–`x1.6` stretch limits; at the extremes the scene looks slowed or cut). Note you cannot hear the audio; say so.

Cheap iteration: edit narration → `voice` → `captions --offline` → `compose` (no re-record). Edit actions/cursor/attention → re-`record`. `record` keeps the previous take as `raw.prev.webm`.

## Step 7: Deliver

1. Copy `output/final-demo.mp4` and `output/final-demo.srt` to `~/Downloads/<feature>-demo-vN.mp4` / `.srt` (never overwrite an earlier version; bump N).
2. Final message to the user:
   - Path(s) and duration.
   - The **change inventory**: what was shown (one line each), what was called out in narration only, and what was **not shown / not demoable** and why.
   - Side effects on their environment: DB migrated/reset/seeded, servers or containers started/restarted, accounts created (list emails). Nothing else should have changed.
   - Honest rough edges (static stretches, slowed scenes, links that didn't exist, wording you couldn't verify by ear).
   - Confirm `git status` matches the start and the schema file is unchanged.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Every page 500, log says `PendingMigrationError` | Local DB behind the checkout. Back up the schema file, migrate, restore it. Failure on existing data → stop and ask. |
| `storageState … ENOENT …/demo/demo/…` | Path is relative to the demo dir. Use `state.json`, not `demo/<name>/state.json`. |
| Click ran, page didn't change | The link points somewhere else (grep its `href`). Add `assert url`. |
| `waitFor … not visible` | Selector wrong or page never navigated; open `logs/fail-*.png` and `logs/drift-*.json` for suggested selectors. |
| `no word timestamps returned; captions may be empty` | Lemonade nests words under `segments[]`; aidemo reads top-level only. Apply the Step 3 patch (`captions --align-script`, delete `captions.manifest.json` first), or use `captions --offline` then `compose`. |
| Login 422 / `InvalidAuthenticityToken` | Token and cookie jar out of sync, or wrong field names. Re-read the form; fetch token and post with the same jar. |
| "Signed in successfully" toast in frame | Consume the flash (extra GET after login) before building `state.json`. |
| Scene looks slow-motion / frozen | Narration/actions length mismatch. Lint, then adjust one side. |
| Page in the wrong language | Seeded user's locale; pick another user/page or note it. |
| Need a second role | Second `state.json` + second demo dir. |
| Docker/registry/proxy trouble | Don't improvise; check the project's docs and ask. |

## Don'ts

- Don't commit, stage or add files to the repo; don't leave `chrome-profile`, recordings or cookies in it.
- Don't run against shared environments, and don't trigger real mail.
- Don't script before inspecting: no guessed selectors, URLs or link targets.
- Don't claim a behavior you didn't see in the code/specs or on screen.
- Don't skip the frame review or the "not shown" list.
