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

```ruby
# Key method signatures and logic — enough to implement without ambiguity.
# Show the public interface and any non-obvious internals.
```

### <Second component if needed> — `lib/squad/<path>.rb`

...

---

## Tests

- `<ClassName>#<method>` <what is asserted and under what conditions>
- `<ClassName>#<method>` raises `<ErrorClass>` when <condition>
- CLI: `squad <command>` exits 0 and prints <expected output>
- Integration (`SQUAD_INTEGRATION=1`): <what real runtime behavior is verified — only for slices touching Docker/Podman>
