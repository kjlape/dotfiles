# Daily checks — Tier 0 and plain `rg`

Use for: one question about the app, a bug fix, a single feature, a model
question, first contact with an unfamiliar repo. No installs, no MCP, no index.

## The whole default toolkit

```bash
cat db/schema.rb                               # data model
bin/rails routes --expanded | rg <resource>    # URL -> controller#action
rg -n '<symbol>' --type ruby                    # where else this appears
```

That answers most questions. Stop when answered.

## Tier 0 — Rails-native artifacts (~2–5k tokens)

Read these before any code: generated from truth, cheap, no third-party guesswork.

```bash
# Data model. Highest-signal single file in most Rails apps.
cat db/schema.rb          # or db/structure.sql: psql-style, grep CREATE TABLE

# Every route -> controller#action. Nothing else in the repo gives you this.
bin/rails routes --expanded

# Autoloading is convention-based, so directory listings lie. This is the real constant set.
bin/rails zeitwerk:check

# Versions, adapters, framework surface.
bin/rails about
head -40 Gemfile; bundler_deps=$(grep -c '^    [a-z]' Gemfile.lock)

# Component boundaries, if the app uses packwerk.
bin/packwerk validate && find . -name package.yml | head -50

# Generated symbol surface for models (Sorbet only) — free, machine-generated index.
ls sorbet/rbi/dsl/ 2>/dev/null | head -20
```

Optional artifacts when a picture beats a list: `bundle exec annotate --models`
(inline columns), `rails-erd`, `railroady`.

## What Tier 0 cannot tell you

- Where a symbol is defined when names are ambiguous → `rubydex.md`.
- Who references it → `rubydex.md`.
- Inheritance and mixin chains → `rubydex.md`.
- Literals, comments, ERB/YAML text → `search.md`.
- What happens at boot / when a callback fires → `runtime.md`.

## Anti-pattern

**Never generate a whole-repo markdown "map"**: stale on the next edit, and the
agent re-reads code anyway. Query, don't precompute.

Also don't read a file just to learn its shape — get its declarations first
(`rubydex.md`, `get_file_declarations`), then read only the ranges you need.
