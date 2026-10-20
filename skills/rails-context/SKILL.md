---
name: rails-context
description: Orient in a Ruby/Rails repo with fewest tokens: schema, routes, ripgrep first, no installs. Escalate for cross-cutting changes only — Rails artifacts (schema, routes, zeitwerk, packwerk, tapioca RBIs), then Rubydex semantics (declarations, ancestors, references, descendants), structural search, runtime. Use to map a codebase, find definitions/references, plan a cross-file refactor, see what a change breaks, find dead code, or stop reading whole files.
version: "2.0"
triggers:
  - "orient in this rails repo"
  - "map this codebase"
  - "codebase context"
  - "rubydex"
  - "rdx"
  - "find references in ruby"
  - "where is this defined"
  - "what breaks if I change this"
  - "dead code ruby"
---

# Rails context ladder

An index: read only the doc matching the job. Answer "what is this app, where is X" without reading files — lowest answering tier, then stop.

## Pick the doc

| Situation | Read |
|---|---|
| One question — schema, a route, where a file/constant lives; small bug fix or feature | [daily-checks.md](references/daily-checks.md) |
| Change other files depend on — model, concern, base class, shared service, column; rename; delete; "what breaks?" | [refactor.md](references/refactor.md) |
| Semantic facts: definitions, references, ancestors, descendants, fat classes | [rubydex.md](references/rubydex.md) |
| Literals, comments, ERB/YAML, DSL call shapes; local vs method confusion | [search.md](references/search.md) |
| Static answers insufficient — callbacks firing, concerns composing, boot wiring, `define_method` | [runtime.md](references/runtime.md) |

## Which doc answers what

| Question | Where |
|---|---|
| Tables/columns? | `daily-checks.md` — `db/schema.rb` |
| URLs → actions? | `daily-checks.md` — `bin/rails routes --expanded` |
| Real constants (autoloading)? | `daily-checks.md` — `zeitwerk:check` |
| Component boundaries? | `daily-checks.md` — packwerk |
| A model's attribute/association surface? | `daily-checks.md` — tapioca RBIs, `annotate` |
| Where `Foo::Bar` is defined / what it contains? | `rubydex.md` |
| Who references `Foo::Bar`? | `rubydex.md` |
| What inherits from / includes this? | `rubydex.md` |
| The fat class / where complexity concentrates? | `rubydex.md` aggregate query |
| Is this symbol used anywhere? | `rubydex.md`, then `search.md` to confirm |
| "Every `has_many` with `dependent: :destroy`" | `search.md` — ast-grep |
| Local variable, method or ivar? | `search.md` — `referral` |
| Which scope does this occurrence live in? | `search.md` — `referral --scope` |
| Literal strings, comments, logs, YAML/ERB | `search.md` — `rg` |
| Does it work at runtime? | `runtime.md` — `bin/rails runner` |

## Default: don't tool up

A bug fix, feature or model question needs only schema, routes and `rg` — no installs, MCP or index (`daily-checks.md`). Escalate when:

- **Changing what many files depend on** — model, concern, base class, shared service, column → `refactor.md`.
- **An unfamiliar repo needs its shape, not one answer.**
- **`rg` returns too much or the wrong thing** — ambiguous names, dynamic calls, shadowed methods → `rubydex.md` / `search.md`.
- **A rename or deletion needs a real reference set**, not a text match → `refactor.md`.

An MCP server for one question costs more than reading the file.

## Load-bearing fact

**No tool here understands the Rails DSL.** Rubydex indexes *Ruby*: `has_many :posts` is a method call, not an association. Associations, callbacks, route→action, jobs and mailers come from Tier 0/3 — hence a ladder, not one tool.

## Failure modes to avoid

- **Trusting a generated index/map after edits** — query instead.
- **Reading a file to learn its shape** — get declarations first (`rubydex.md`), then only the ranges you need.
- **Unfiltered aggregates** — gems and stdlib are indexed; scope to your namespace or `String` looks like your fattest class.
- **Treating rubydex as Rails-aware** — associations, callbacks and route→action are Tier 0/3.
- **Answering "is this dead?" from one tool** — resolve refs (Tier 1), then grep the symbol plus `send(:sym)`/string forms (Tier 2); full checklist in `refactor.md`.
- **Installing an MCP server for one question** — `rg` is one call.
- **Trusting advertised features** — `rubydex.md` and `search.md` list what was verified in the installed versions; don't promise the rest.

## Layout

```
SKILL.md                      this index
references/daily-checks.md    Tier 0: Rails-native artifacts + rg, no installs
references/refactor.md        cross-cutting changes, blast radius, renames, dead code
references/rubydex.md         Tier 1: install, guard, MCP tools, CLI, Cypher cookbook
references/search.md          Tier 2: rg, ast-grep, referral, universal-ctags
references/runtime.md         Tier 3: bin/rails runner, runtime MCPs
```

Paths are relative to this file; each doc is self-contained, so load only what the job needs.
