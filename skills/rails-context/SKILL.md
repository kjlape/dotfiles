---
name: rails-context
description: Orient in a Ruby or Rails repo with the fewest tokens. Cheapest path first — schema, routes, ripgrep, no installs — escalating only for cross-cutting changes: Rails artifacts (schema, routes, zeitwerk, packwerk, tapioca RBIs), then Rubydex semantic queries (declarations, ancestors, references, descendants), then structural search, then runtime. Use to map a Rails/Ruby codebase, find definitions/references, plan a cross-file refactor, see what a change breaks, find dead code, or stop reading whole files.
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

This file is an index. Read the one doc that matches the job; skip the rest.

Goal: answer "what is this app and where is X" without reading files. Start at the
lowest tier that answers the question; stop when answered.

## Pick the doc

| Situation | Read |
|---|---|
| One question — schema, a route, where a file/constant lives; small bug fix or feature | [daily-checks.md](references/daily-checks.md) |
| Change that other files depend on: model, concern, base class, shared service, column; rename; delete; "what breaks?" | [refactor.md](references/refactor.md) |
| Need semantic facts: definitions, references, ancestors, descendants, fat classes | [rubydex.md](references/rubydex.md) |
| Need literals, comments, ERB/YAML, DSL call shapes; local vs method confusion | [search.md](references/search.md) |
| Static answers are insufficient: callbacks firing, concerns composing, boot wiring, `define_method` | [runtime.md](references/runtime.md) |

## Which doc answers what

| Question | Where |
|---|---|
| What tables/columns exist? | `daily-checks.md` — `db/schema.rb` |
| What URLs map to what actions? | `daily-checks.md` — `bin/rails routes --expanded` |
| What are the real constants (autoloading)? | `daily-checks.md` — `zeitwerk:check` |
| What are the component boundaries? | `daily-checks.md` — packwerk |
| What is this model's attribute/association surface? | `daily-checks.md` — tapioca RBIs, `annotate` |
| Where is `Foo::Bar` defined / what does it contain? | `rubydex.md` |
| Who references `Foo::Bar`? | `rubydex.md` |
| What inherits from / includes this? | `rubydex.md` |
| Which class is the fat one / where is complexity concentrated? | `rubydex.md` aggregate query |
| Is this symbol used anywhere? | `rubydex.md`, then `search.md` to confirm |
| "Every `has_many` with `dependent: :destroy`" | `search.md` — ast-grep |
| Is this name a local variable, a method, or an ivar? | `search.md` — `referral` |
| Which scope does this occurrence live in? | `search.md` — `referral --scope` |
| Literal strings, comments, log messages, YAML/ERB | `search.md` — `rg` |
| Does it actually work at runtime? | `runtime.md` — `bin/rails runner` |

## Default: don't tool up

Most work — a bug fix, one feature, a model question — needs only schema,
routes, and `rg`. No installs, no MCP, no index. See `daily-checks.md`.

Escalate only when:

- **You're changing code many files depend on** — a model, concern, base class,
  shared service, column → `refactor.md`.
- **The repo is unfamiliar and you need its shape**, not one answer.
- **`rg` returns too much or the wrong thing** — ambiguous names, dynamic calls,
  shadowed methods → `rubydex.md` / `search.md`.
- **A rename or deletion needs a real reference set**, not a text match
  → `refactor.md`.

An MCP server for one question costs more than reading the file.

## Load-bearing fact

**No tool here understands the Rails DSL.** Rubydex is a *Ruby* indexer —
`has_many :posts` is a method call to it, not an association. Associations,
callbacks, route→action, jobs, mailers and other conventions come from Tier 0
(`daily-checks.md`) or Tier 3 (`runtime.md`). That gap is why this is a ladder
and not one tool.

## Failure modes to avoid

- **Generating an index/map file** and trusting it after edits — query instead.
- **Reading a file to learn its shape** — get its declarations first
  (`rubydex.md`), then read only the ranges you need.
- **Unfiltered aggregate queries** — stdlib and gems are indexed; scope to your
  namespace or `String` looks like your fattest class.
- **Treating rubydex as Rails-aware** — associations, callbacks and
  route→action are Tier 0/3.
- **Answering "is this dead?" from one tool** — resolve refs (Tier 1), then grep
  the symbol name plus `send(:sym)`/string forms (Tier 2) before deleting.
  Full checklist: `refactor.md`.
- **Installing an MCP server to answer one question** — `rg` is one call.
- **Trusting a tool's advertised features** — `rubydex.md` and `search.md` list
  what was verified in the installed versions; don't promise the rest.

## Layout

```
SKILL.md                      this index
references/daily-checks.md    Tier 0: Rails-native artifacts + rg, no installs
references/refactor.md        cross-cutting changes, blast radius, renames, dead code
references/rubydex.md         Tier 1: install, guard, MCP tools, CLI, Cypher cookbook
references/search.md          Tier 2: rg, ast-grep, referral, universal-ctags
references/runtime.md         Tier 3: bin/rails runner, runtime MCPs
```

All paths are relative to this file. Each doc is self-contained; don't load more
than the job needs.
