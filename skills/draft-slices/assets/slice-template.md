---
status: planned
completed: ~
audited: ~              # set by the audit skill, never on a fresh draft
size_class: <normal | sweep>
est_loc: <N>              # changed LOC excluding tests, docs, lockfiles, generated; = analogue first-commit size × calibration inflation factor; <=100 unless sweep or size_exception
axis: <split axis vs the prior slice: workflow step, operation, business rule, data variant, entry method, simple vs complex, or deferred performance — "none" only for slice 01>
analogue: <PR number or commit sha/path:line of a similar past change and its measured size, or "none (greenfield)">
size_exception: ~         # cause (new subsystem / first-of-kind surface / measured analogue) + reason, only if over budget and not a sweep
pr: ~                     # PR URL, filled when shipped
commits: ~                # implementing commit SHAs, filled when shipped
---

# Slice NN — <Verb Phrase Title>

**Depends on:** <slug of prior slice, e.g. "01-report-form-saves", or "none">
**Parallel with:** <slug of sibling slice(s), or "none">

**Job:** <One line: When [circumstance], [actor] can [progress], observed via [named command / log line / UI / query]. Actor is an end user, admin, system/operator, or dev; a dev actor requires a concrete before/after check.>

**Done when:** <Observable, testable criteria. Write it as something a test can assert or a human can see: "bundle exec rake test passes with N new tests", "`squad up --engine podman` starts a container visible in `podman ps`", etc. Never write "the code is written" or "the class is implemented".>

---

## Deliverables

### <Component name> — `lib/squad/<path>.rb`

<One sentence: single responsibility + which layer (functional core / imperative shell / orchestrator / CLI).>

### <Second component if needed> — `lib/squad/<path>.rb`

...

---

## Tests

- <Behavior>: <what is asserted and under what conditions; at least one test asserts Done when>
- <Error path, if the slice adds one>: <what fails and how the failure is surfaced>
- Acceptance (only when Done when is user-visible): `<command>` <expected observable result>
- Integration (only when the slice touches a real runtime): <what runtime behavior is verified>

For a `sweep` slice, replace this section with: the transform rule, the committed script or command, 3–5 sample before/after hunks, and the command that shows zero remaining matches.

---

## Deployment

Rollout plan when this slice ships something operators or users must sequence: schema or data migration, config or env var, feature flag, service restart, dependency install, or user-visible behavior that cannot be switched on atomically. Otherwise replace the bullets below with "Not applicable — <reason>."

- **Order / rollout:** <what ships before or after what; flags and their default state>
- **Data:** <migration or backfill, idempotency, how to verify it applied>
- **Rollback:** <revert steps, and what makes rollback unsafe>
- **Post-deploy verification:** `<command or signal>` → expected <result>
