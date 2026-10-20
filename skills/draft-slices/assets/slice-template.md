---
status: planned
completed: ~
audited: <today YYYY-MM-DD>
wave: <N>
---

# Slice NN — <Verb Phrase Title>

**Depends on:** <slug of prior slice, e.g. "01-engine-protocol", or "none">
**Parallel with:** <slug of sibling slice(s), or "none">

**Done when:** <Observable, testable criteria. Write it as something a test can assert or a human can see: "bundle exec rake test passes with N new tests", "`squad up --engine podman` starts a container visible in `podman ps`", etc. Never write "the code is written" or "the class is implemented".>

---

## Deliverables

### <Component name> — `lib/squad/<path>.rb`

<One sentence: single responsibility + which layer (functional core / imperative shell / orchestrator / CLI).>

### <Second component if needed> — `lib/squad/<path>.rb`

...

---

## Tests

- <Behavior>: <what is asserted and under what conditions>
- <Error path>: <what fails and how the failure is surfaced>
- CLI/acceptance: `<command>` <expected observable result>
- Integration (only when the slice touches a real runtime): <what runtime behavior is verified>

---

## Deployment

Rollout plan when this slice ships something operators or users must sequence: schema or data migration, config or env var, feature flag, service restart, dependency install, or user-visible behavior that cannot be switched on atomically. Otherwise replace the bullets below with "Not applicable — <reason>."

- **Order / rollout:** <what ships before or after what; flags and their default state>
- **Data:** <migration or backfill, idempotency, how to verify it applied>
- **Rollback:** <revert steps, and what makes rollback unsafe>
- **Post-deploy verification:** `<command or signal>` → expected <result>
