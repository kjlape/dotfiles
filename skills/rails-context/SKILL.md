---
name: rails-context
description: Orient in a Ruby or Rails repo while spending the fewest tokens. Defaults to the cheap path — schema, routes and ripgrep, no installs — and escalates through a ladder only for cross-cutting changes. Rails-native artifacts first (schema, routes, zeitwerk, packwerk, tapioca RBIs), then Rubydex semantic queries (declarations, ancestor chains, constant references, descendants), then structural search, then runtime. Use when asked to orient in or map a Rails/Ruby codebase, find where something is defined or referenced, plan a refactor across files, work out what a change will break, find dead code, or stop burning context reading whole files.
version: "1.0"
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

Goal: answer "what is this app and where does X live" without reading files.

**Start at the lowest tier that can answer the question. Stop when answered.**

## Default: don't tool up

Most work — a bug fix, one feature, a question about a model — is answered by
**Tier 0 plus `rg`**, and nothing else. That is the day-to-day setting: no
installs, no MCP, no index.

```bash
cat db/schema.rb                               # data model
bin/rails routes --expanded | rg <resource>    # URL -> controller#action
rg -n '<symbol>' --type ruby                    # where else does this appear
```

Reach for the rest of the ladder only when one of these is true:

- **You are about to change code that many files depend on** — a model, a
  concern, a base class, a shared service, a column.
- **The repo is unfamiliar and you need its shape**, not one answer.
- **`rg` is returning too much or the wrong thing** — ambiguous names, dynamic
  calls, locals shadowing methods.
- **A rename or deletion needs a real reference set**, not a text match.

Big refactor? Run Tier 0 in full, then Tier 1 for every symbol you will touch,
and use the *"What breaks if I change this?"* recipe before editing. Everything
below that threshold is over-equipping: installing an MCP server to answer one
question costs more than reading the file.

The load-bearing fact: **no tool here understands the Rails DSL.** Rubydex is a
*Ruby* indexer — `has_many :posts` is a method call to it, not an association.
Rails-specific structure (associations, callbacks, route→controller, jobs,
mailers, conventions) comes from Tier 0, not from a code graph. That gap is why
this is a ladder and not one tool.

## Which tier answers what

| Question | Tier |
|---|---|
| What tables/columns exist? | 0 — `db/schema.rb` |
| What URLs map to what actions? | 0 — `bin/rails routes --expanded` |
| What are the real constants (autoloading)? | 0 — `zeitwerk:check` |
| What are the component boundaries? | 0 — packwerk | 
| What is this model's attribute/association surface? | 0 — tapioca RBIs, `annotate` |
| Where is `Foo::Bar` defined / what does it contain? | 1 — Rubydex |
| Who references `Foo::Bar`? | 1 — Rubydex |
| What inherits from / includes this? | 1 — Rubydex |
| Which class is the fat one / where is the complexity concentrated? | 1 — Rubydex aggregate query |
| Is this symbol used anywhere? | 1 — Rubydex, then Tier 2 grep to confirm |
| "Every `has_many` with `dependent: :destroy`" | 2 — ast-grep |
| Is this name a local variable, a method, or an ivar? | 2 — `referral` |
| Which scope does this occurrence live in? | 2 — `referral --scope` |
| Literal strings, comments, log messages, YAML/ERB | 2 — `rg` |
| Does it actually work at runtime? | 3 — `bin/rails runner` |

## Tier 0 — Rails-native, no install (~2–5k tokens total)

Read these before any code. They are generated from the truth, cheap, and no
third-party tool is guessing.

```bash
# Data model. The highest-signal single file in most Rails apps.
cat db/schema.rb          # or db/structure.sql: psql-style, use grep on CREATE TABLE

# Every route -> controller#action. Nothing else in the repo gives you this.
bin/rails routes --expanded

# Autoloading is convention-based, so directory listings lie. This is the real constant set.
bin/rails zeitwerk:check

# Versions, adapters, framework surface.
bin/rails about
head -40 Gemfile; bundler_deps=$(grep -c '^    [a-z]' Gemfile.lock)

# Component boundaries, if the app uses packwerk.
bin/packwerk validate && find . -name package.yml | head -50

# Generated symbol surface for models (Sorbet apps only) — free, machine-generated index.
ls sorbet/rbi/dsl/ 2>/dev/null | head -20
```

Optional artifacts when a picture beats a list: `bundle exec annotate --models`
(inline columns), `bundle exec rails-erd`, `bundle exec railroady`.

**Do not generate a whole-repo markdown "map" artifact.** It is stale the moment
you edit a file, and the agent re-reads the code anyway. Query, don't precompute.

## Tier 1 — Rubydex (Shopify), semantic Ruby queries

Rubydex is a Rust static-analysis engine for Ruby that ships an MCP server.

### Install

Ad-hoc is enough and needs no project mutation:

```bash
gem install rubydex          # precompiled binary per platform, no native build
rdx --version                # v0.4.1 verified
```

Only add it to the Gemfile when the bundle is isolated — see *Guard* below.
Soft-suggest, don't require:

```ruby
group :development do
  gem "rubydex", require: false
end
```

### Guard — check these before using it

- **A `Gemfile` must exist.** Not contain rubydex — just exist. Without one,
  `rdx` dies with an uncaught `Bundler::GemfileNotFound`
  (`lib/rubydex/graph.rb:54`). A Rails app always has one; a bare Ruby tree may not.
- **Run bare `rdx`, not `bundle exec rdx`** unless the gem is in the Gemfile.
- **Gem resolution is by name, not version.**
  `Gem::Specification.find_by_name(lazy_spec.name)` drops the locked version, so
  if two versions of a gem are installed it indexes the newest, not the pinned
  one. It also rescues `Gem::MissingSpecError` silently — gems invisible to
  `Gem.path` are skipped without a warning.
  *Consequence:* ad-hoc mode is correct when the bundle's gems are also installed
  system-wide (the usual rbenv/mise/system-gem case). If the app vendors its
  bundle or has duplicate gem versions, `bundle add rubydex` and use
  `bundle exec rdx` so bundler sets `GEM_PATH`.
- If any of that fails → **fall back to Tier 0 + Tier 2.** Do not debug rubydex
  in the middle of someone's refactor.

### MCP: 6 tools (not 7)

`rdx mcp [PATH]` starts a stdio server. Verified tool list:

| Tool | Args | Use |
|---|---|---|
| `search_declarations` | `query`, `kind?`, `match_mode?` (`fuzzy`\|`exact`), `limit`, `offset` | Find a definition by partial name. **Prefer over grep** for identifiers. |
| `get_declaration` | `name` | Exact FQN: `Foo::Bar`, `Foo::Bar#instance_method`, `Foo::Bar.method` |
| `get_descendants` | `name`, `limit`, `offset` | Everything that inherits/includes this |
| `find_constant_references` | `name`, `limit` (max 200), `offset` | Resolved constant usages, file+line+column |
| `get_file_declarations` | `file_path` | A file's structure **before** reading it |
| `codebase_stats` | — | Composition check; also proves indexing finished |

Operational gotchas (verified):

- **First calls after startup return
  `{"error":"indexing","suggestion":"retry in a few seconds"}`.** This is not a
  failure. Retry once or twice.
- Paginated tools return `total`; page with `offset` rather than re-querying.
- `codebase_stats` counts **gem and stdlib sources too** — a one-file app reported
  252 files / 10,820 declarations. Use it to confirm the index is warm, not to
  size the app.
- **`find_dead_code_candidates` is documented upstream but does not exist in
  0.4.1.** Do not call it. Do not promise dead-code analysis from this tool.

### CLI

```bash
rdx query --schema                              # free: labels, edges, properties, no indexing
rdx query 'MATCH ... RETURN ...'                # table output
rdx query 'MATCH ... RETURN ...' --format json
rdx console                                     # interactive graph REPL
rdx skill                                       # list the built-in skill library (1 skill today)
```

### Cypher cookbook (all run against 0.4.1)

Schema: nodes `Document, Definition, Declaration (Namespace|Class|Module|SingletonClass|Method|Constant|ConstantAlias|GlobalVariable|InstanceVariable|ClassVariable)`;
edges `DEFINES, DECLARES, CONTAINS, HAS_PARENT, INCLUDES, PREPENDS, EXTENDS, OWNS, HAS_ANCESTOR, HAS_DESCENDANT, REFERENCES`;
properties `name, unqualified_name, visibility, kind, file, line, path, uri`.

```bash
# Members with visibility. (attr_* readers are synthesised as methods.)
rdx query 'MATCH (c:Class {name: "User"})-[:OWNS]->(m) RETURN m.kind, m.name, m.visibility'

# Full ancestor chain. Use HAS_ANCESTOR for the linearized chain;
# HAS_PARENT is the *direct* superclass only and is empty for implicit-Object classes.
rdx query 'MATCH (c:Class {name: "User"})-[:HAS_ANCESTOR]->(a) RETURN a.name'

# Mixins it includes.
rdx query 'MATCH (d:Declaration)-[:INCLUDES]->(m) WHERE d.name = "User" RETURN m.name'

# Who references a constant.
rdx query 'MATCH (d:Document)-[:REFERENCES]->(t:Declaration) WHERE t.name = "User" RETURN d.path'

# Where the weight is. NOTE: stdlib dominates — filter to your namespace.
rdx query 'MATCH (d:Declaration)-[:OWNS]->(m:Method) WHERE d.name CONTAINS "MyApp" RETURN d.name, count(m) AS n ORDER BY n DESC LIMIT 10'
```

If a query errors, re-read `rdx query --schema` rather than guessing; the engine
supports a read-only subset of Cypher (`MATCH`/`WHERE`/`RETURN`, `ORDER BY`,
`LIMIT`, `count`). **Don't** include `rdx lint` or `rdx dead_code` in a workflow —
`lint` crashed on a minimal fixture in 0.4.1 and `dead_code` doesn't exist.

### "What breaks if I change this?"

Rubydex has **no blast-radius tool** and no cross-file call graph at method
level (no receiver type inference). Build the answer from four cheap steps
instead of reading files:

```bash
# 1. Direct references to the constant.
rdx query 'MATCH (d:Document)-[:REFERENCES]->(t:Declaration) WHERE t.name = "User" RETURN d.path'

# 2. Everything that inherits or includes it.
rdx query 'MATCH (c:Declaration)-[:HAS_DESCENDANT]->(d) WHERE c.name = "User" RETURN d.name'

# 3. Unresolved/dynamic uses a graph can't see — do this every time.
rg -n 'User\b' --type ruby | rg -v 'spec/|test/'
rg -n "send\(:?user|const_get\(['\"]User" --type ruby

# 4. Convention wiring no Ruby tool models — check the Rails side.
rg -n 'user' config/routes.rb; rg -n 'User\.' app/jobs app/mailers app/services
```

Report the list, not a guess. If the change touches a column, add
`db/schema.rb` dependents (`rg -n 'user_id' db/schema.rb app/`) — nothing in this
ladder resolves schema-to-code edges for you.

## Tier 2 — text and structural search

```bash
rg -n 'SomeLiteral|some_log_message'          # literals, comments, ERB, YAML
rg -n --type ruby 'class \w+Controller'       # cheap shape checks

# ast-grep has first-class Ruby support (tree-sitter-ruby). Use it for DSL
# patterns, which are method calls and therefore invisible to rubydex/graph tools.
# NOTE: the binary is `ast-grep`; `sg` is deprecated. `-l` means --lang, not
# files-with-matches.
ast-grep run -p 'has_many $ASSOC, dependent: :destroy' --lang rb app/models
ast-grep run -p 'before_action $FILTER' --lang rb app/controllers
ast-grep run -p 'attr_reader $ARGS' --lang rb --files-with-matches
```

Language inference usually works without `--lang`, but pass `--lang rb` whenever a
Ruby pattern fails to match — a mis-inferred grammar fails silently with 0 results.

### `referral` — scope/occurrence listing (the rung between `rg` and ast-grep)

`gem install referral` (testdouble, v0.0.6, MIT, no Gemfile needed, no index).
It walks `RubyVM::AbstractSyntaxTree` and prints one line per occurrence with
`location:type:scope:name`, which answers the question `rg` cannot: **is this
token a local variable, a method definition, or a call?**

```bash
referral .                                        # everything, sorted by file
referral --exact-name nickname --columns location,type,scope,name --print-headers --delimiter $'\t'
referral --scope 'User#full_name'                  # what does this method actually contain
referral --type call,local_var --name total        # name appears as a call and as a local
referral --name has_many --arity 2                 # DSL calls by argument count
```

What it gives you that nothing else in this ladder does:

- **Local-variable resolution.** `puts full_name` where `full_name` is a local is
  emitted as `local_var`; `user.nickname` is a `call`. Rubydex does not track
  locals at all, and `rg` cannot distinguish the two.
- **Every occurrence attributed to an enclosing `Class#method`**, sortable by
  `--sort scope`.
- **`--arity`** turns it into a cheap DSL query (`has_many` with exactly 2 args)
  without installing ast-grep.
- **Works with no Gemfile** — drop it in a lone script or a non-bundled Ruby tree
  where `rdx` refuses to start.

What it does **not** give you (verified, so don't ask it for these):

- **No receiver type inference**, so `--full-name 'User#full_name'` returns only
  the definition, never external call sites on a `user` object.
- **No namespaced-constant matching**: `--full-name 'Foo::Bar'` returns nothing
  even when `Foo::Bar.baz` is called. Use `--name`/`--exact-name` on the last
  segment instead, or use rubydex.
- No ancestors, descendants, or cross-file graph. That is Tier 1.
- `referral --help` is the only doc; it is 0.0.x and built on
  `RubyVM::AbstractSyntaxTree`, which Ruby core is migrating away from in favour
  of Prism. Works clean on Ruby 3.4.10; treat it as disposable if a future Ruby
  drops the API.

`universal-ctags` (`ctags -R --languages=Ruby`) is a decent zero-cost symbol index
when rubydex is unavailable: one `tags` file, `rg`-able, regenerated in ~1s.

## Tier 3 — runtime

Only when static resolution can't answer (callbacks firing, concerns composing,
service objects wiring at boot, `define_method`).

```bash
bin/rails runner 'puts ActiveRecord::Base.descendants.map(&:name).sort'
bin/rails runner 'puts Rails.application.routes.routes.map { |r| [r.path.spec.to_s, r.defaults[:controller], r.defaults[:action]] }'
bin/rails runner 'puts User.reflect_on_all_associations.map { |a| [a.macro, a.name, a.options] }'
```

A runtime MCP (e.g. Tidewave) supersedes Tier 0+1 whenever the app boots, at the
cost of needing a running server.

## Failure modes to avoid

- **Generating an index/map file** and then trusting it after edits. Query instead.
- **Reading a file to learn its shape.** `get_file_declarations` first; read only
  the ranges you need.
- **Unfiltered aggregate queries.** Stdlib and gems are indexed; scope to your
  namespace or you will conclude `String` is your fattest class.
- **Treating rubydex as Rails-aware.** It will not tell you about associations,
  callbacks, or route→action. That is Tier 0/3.
- **Answering "is this dead?" from one tool.** Resolve refs (Tier 1), then grep
  for the symbol name and `send(:sym)`/string forms (Tier 2) before deleting.
- **Installing an MCP server to answer one question.** `rg` is one call.

## Verified facts (do not assume otherwise)

As of rubydex **v0.4.1**, verified by running it on Linux x86_64:

- Ships precompiled (`rubydex-0.4.1-x86_64-linux`); `gem install` needs no compiler.
- CLI subcommands are exactly: `console`, `lint`, `mcp [PATH]`, `query`, `skill`, `help`.
- MCP exposes **6** tools. `find_dead_code_candidates` is in the upstream README,
  not in the shipped gem (grep of the installed `lib/`/`exe/` finds no reference).
- `rdx dead_code` is an upstream README command that **does not exist** in 0.4.1.
- `rdx lint` crashed on a minimal fixture; treat the linter as pre-release.
- **No consumer-facing first-party skill exists.** `Shopify/rubydex` has
  `.claude/skills/` with four *maintainer* skills (`benchmark-rbs`, `profiling`,
  `review_changes`, `rubydex-mcp-benchmark`) — `npx skills add Shopify/rubydex`
  installs the wrong audience. Its `skills/` dir plus `rdx skill <id>` is a
  *runtime* library of one skill (`send-private-method`), designed to surface
  guidance only on a verified lint violation — copy that pattern, not its content.
- The MCP `instructions` field is the closest thing to first-party guidance: use
  these tools for `.rb`/`.rbi`/`.rbs`, use text search for literals and comments,
  FQN format `Foo::Bar` / `Foo::Bar#method`, paginate with `offset`.

As of **referral v0.0.6** (published 2026-09-18), verified on Ruby 3.4.10:

- Token types emitted: `class`, `instance_method`, `call`, `function_call`,
  `constant`, `constant_declaration`, `local_var`, `local_var_assign`,
  `instance_var`, `instance_var_assign`.
- `--exact-name User` matches qualified names, so it does find `User.new` call
  sites — but `--full-name 'Foo::Bar'` does not match `Foo::Bar.baz` receivers.
- No deprecation warning from `RubyVM::AbstractSyntaxTree` on Ruby 3.4.10.
