---
name: basecamp-coordinator
description: Use Basecamp as the coordination hub for agent work. One project per workstream (client, brand, service), with todos, cards, and messages tracking what agents are doing. Use when starting, handing off, or reporting on agent work that should be tracked in Basecamp, or when asked which Basecamp project work belongs in. Defers to the `basecamp` skill for CLI mechanics.
---

# Basecamp as agent coordinator

Basecamp is the shared record of what agents are doing, what is blocked, and what needs Kaleb. Load the `basecamp` skill for CLI usage; this skill only defines how to organize work.

## One project per workstream

A workstream is a body of related work, however many repos, people, or deliverables it spans.

- Client: one workstream regardless of repo count (Faith Bible Institute).
- Brand: one workstream with all its channels (the YouTube channel belongs to Rails Quest).
- Service: one workstream even if its customers differ (Rails Quest Council; each trainee is a todo list or card inside it, not a project).
- Standalone product or initiative: its own workstream.

Not workstreams: a single repo, branch, ticket, trainee, or video.

## Resolve the project first

1. Name the workstream from the user's words, the repo, or `.basecamp/config.json`. Ask once if truly unclear.
2. List projects and match case-insensitively, including obvious variants ("FBI" for Faith Bible Institute).
3. If one matches, use it with `--in <project>`. Never create a duplicate.
4. If none matches, create one named only for the workstream (no repo or task names). State the name before creating if it is a guess. Report the new ID/URL.
5. Offer to save the project in the repo's `.basecamp/config.json`. Many repos may share one project.

Confirm command names and flags with leaf `--agent --help` before running them.

## Where things go

- Todo list per initiative or trainee; one todo per unit of agent work. Assign it, and complete it only when done and verified.
- Card on a board when work moves through stages.
- Message for decisions, summaries, and anything Kaleb should read.
- Comment on the relevant todo for progress notes. Comments are flat.

## Coordination protocol

- Before starting: look for an existing todo or card for the work; claim it (comment or assign) instead of duplicating. Check for another agent already on it.
- While working: post a short comment at meaningful milestones, with branch, PR, or file links.
- Blocked or needs a decision: comment with the specific question, mention Kaleb, and leave the todo open.
- Finished: comment with what changed and how it was verified, link the PR, then complete the todo.
- Handoff: state the current status, remaining steps, and where the state lives (branch, worktree, files).

Keep entries terse and factual. Never put secrets or credentials in Basecamp.
