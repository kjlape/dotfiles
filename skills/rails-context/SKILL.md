---
name: rails-context
description: Orient in a Ruby or Rails repo with the fewest tokens. Cheapest path first — schema, routes, ripgrep, no installs — escalating only for cross-cutting changes: Rails artifacts (schema, routes, zeitwerk, packwerk, tapioca RBIs), then Rubydex semantic queries (declarations, ancestors, references, descendants), then structural search, then runtime. Use to map a Rails/Ruby codebase, find definitions/references, plan a cross-file refactor, see what a change breaks, find dead code, or stop reading whole files.
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

Goal: answer "what is this app and where is X" without reading files. Start at the
lowest tier that answers the question; stop when answered.

## Default: don't tool up

A bug fix, one feature, a model question — most work needs only **Tier 0 + `rg`**:
no installs, no MCP, no index.

```bash
cat db/schema.rb                               # data model
bin/rails routes --expanded | rg <resource>    # URL -> controller#action
rg -n '<symbol>' --type ruby                    # where else this appears
```

Escalate only when:

- **You're changing code many files depend on** — a model, concern, base class,
  shared service, column.
- **The repo is unfamiliar and you need its shape**, not one answer.
- **`rg` returns too much or the wrong thing** — ambiguous names, dynamic calls,
  shadowed methods.
- **A rename or deletion needs a real reference set**, not a text match.

Big refactor: full Tier 0, Tier 1 for every symbol touched, then the *"What breaks
if I change this?"* recipe before editing. Below that is over-equipping — an MCP
server for one question costs more than reading the file.

Load-bearing fact: **no tool here understands the Rails DSL.** Rubydex is a *Ruby*
indexer — `has_many :posts` is a method call to it, not an association.
Associations, callbacks, route→action, jobs, mailers and other conventions come
from Tier 0. That gap is why this is a ladder and not one tool.

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

## Tier 0 — Rails-native, no install (~2–5k tokens)

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

**Never generate a whole-repo markdown "map"**: stale on the next edit, and the
agent re-reads code anyway. Query, don't precompute.

## Tier 1 — Rubydex (Shopify)

A Rust static-analysis engine for Ruby, shipping an MCP server.

### Install

Ad-hoc is enough, no project mutation:

```bash
gem install rubydex          # precompiled binary per platform, no native build
rdx --version                # v0.4.1 verified
```

Only add it to the Gemfile when the bundle is isolated — see *Guard*:

```ruby
group :development do
  gem "rubydex", require: false
end
```

### Guard

- **A `Gemfile` must exist** (not contain rubydex). Without one `rdx` dies with an
  uncaught `Bundler::GemfileNotFound` (`lib/rubydex/graph.rb:54`). Rails apps
  always have one; bare Ruby trees may not.
- **Run bare `rdx`, not `bundle exec rdx`**, unless the gem is in the Gemfile.
- **Gem resolution is by name, not version.** `Gem::Specification.find_by_name(lazy_spec.name)`
  drops the locked version, so with two versions installed it indexes the newest.
  It also silently rescues `Gem::MissingSpecError` — gems outside `Gem.path` are
  skipped without warning. *Consequence:* ad-hoc is correct when the bundle's gems
  are also installed system-wide (usual rbenv/mise/system case). If the app
  vendors its bundle or has duplicate gem versions, `bundle add rubydex` and use
  `bundle exec rdx` so bundler sets `GEM_PATH`.
- Any failure → **fall back to Tier 0 + Tier 2**. Don't debug rubydex mid-refactor.

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

Gotchas (verified):

- **First calls return `{"error":"indexing",...}`** — not a failure; retry once
  or twice.
- Paginated tools return `total`; page with `offset` rather than re-querying.
- `codebase_stats` counts **gems and stdlib too** — a one-file app reported 252
  files / 10,820 declarations. Warmth check, not app size.
- **`find_dead_code_candidates` is documented upstream but absent in 0.4.1.**
  Don't call it; don't promise dead-code analysis from this tool.

### CLI

```bash
rdx query --schema                              # free: labels, edges, properties, no indexing
rdx query 'MATCH ... RETURN ...'                # table output
rdx query 'MATCH ... RETURN ...' --format json
rdx console                                     # interactive graph REPL
rdx skill                                       # built-in skill library (1 skill today)
```

### Cypher cookbook (all run against 0.4.1)

Schema: nodes `Document, Definition, Declaration (Namespace|Class|Module|SingletonClass|Method|Constant|ConstantAlias|GlobalVariable|InstanceVariable|ClassVariable)`;
edges `DEFINES, DECLARES, CONTAINS, HAS_PARENT, INCLUDES, PREPENDS, EXTENDS, OWNS, HAS_ANCESTOR, HAS_DESCENDANT, REFERENCES`;
properties `name, unqualified_name, visibility, kind, file, line, path, uri`.

```bash
# Members with visibility. (attr_* readers are synthesised as methods.)
rdx query 'MATCH (c:Class {name: "User"})-[:OWNS]->(m) RETURN m.kind, m.name, m.visibility'

# Full ancestor chain. HAS_ANCESTOR gives the linearized chain;
# HAS_PARENT is the *direct* superclass only and is empty for implicit-Object classes.
rdx query 'MATCH (c:Class {name: "User"})-[:HAS_ANCESTOR]->(a) RETURN a.name'

# Mixins it includes.
rdx query 'MATCH (d:Declaration)-[:INCLUDES]->(m) WHERE d.name = "User" RETURN m.name'

# Who references a constant.
rdx query 'MATCH (d:Document)-[:REFERENCES]->(t:Declaration) WHERE t.name = "User" RETURN d.path'

# Where the weight is. NOTE: stdlib dominates — filter to your namespace.
rdx query 'MATCH (d:Declaration)-[:OWNS]->(m:Method) WHERE d.name CONTAINS "MyApp" RETURN d.name, count(m) AS n ORDER BY n DESC LIMIT 10'
```

On error, re-read `rdx query --schema` instead of guessing; it supports a
read-only Cypher subset (`MATCH`/`WHERE`/`RETURN`, `ORDER BY`, `LIMIT`, `count`).
**Don't** put `rdx lint` or `rdx dead_code` in a workflow — see *Verified facts*.

### "What breaks if I change this?"

No blast-radius tool, no method-level call graph (no receiver type inference).
Four cheap steps instead of reading files:

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

Report the list, not a guess. For a column change also check `db/schema.rb`
dependents (`rg -n 'user_id' db/schema.rb app/`) — nothing here resolves
schema-to-code edges.

## Tier 2 — text and structural search

```bash
rg -n 'SomeLiteral|some_log_message'          # literals, comments, ERB, YAML
rg -n --type ruby 'class \w+Controller'       # cheap shape checks

# ast-grep has first-class Ruby support (tree-sitter-ruby). Use it for DSL
# patterns: method calls, invisible to rubydex/graph tools.
# NOTE: the binary is `ast-grep` (`sg` is deprecated); `-l` means --lang.
ast-grep run -p 'has_many $ASSOC, dependent: :destroy' --lang rb app/models
ast-grep run -p 'before_action $FILTER' --lang rb app/controllers
ast-grep run -p 'attr_reader $ARGS' --lang rb --files-with-matches
```

Language inference usually works, but pass `--lang rb` whenever a Ruby pattern
fails — a mis-inferred grammar fails silently with 0 results.

### `referral` — occurrence/scope listing (between `rg` and ast-grep)

`gem install referral` (testdouble, v0.0.6, MIT, no Gemfile, no index). It walks
`RubyVM::AbstractSyntaxTree`, printing `location:type:scope:name` per occurrence —
answering what `rg` cannot: **is this token a local variable, a method definition,
or a call?**

```bash
referral .                                        # everything, sorted by file
referral --exact-name nickname --columns location,type,scope,name --print-headers --delimiter $'\t'
referral --scope 'User#full_name'                  # what does this method actually contain
referral --type call,local_var --name total        # name appears as a call and as a local
referral --name has_many --arity 2                 # DSL calls by argument count
```

What nothing else here gives you:

- **Local-variable resolution.** `puts full_name` on a local emits `local_var`;
  `user.nickname` is a `call`. Rubydex ignores locals; `rg` can't distinguish.
- **Every occurrence attributed to an enclosing `Class#method`**, sortable by
  `--sort scope`.
- **`--arity`** for cheap DSL queries (`has_many` with exactly 2 args) without
  ast-grep.
- **No Gemfile needed** — works in a lone script or non-bundled tree where `rdx`
  refuses to start.

What it does **not** do (verified — don't ask for these):

- **No receiver type inference**: `--full-name 'User#full_name'` returns only the
  definition, never call sites on a `user` object.
- **No namespaced-constant matching**: `--full-name 'Foo::Bar'` returns nothing
  even when `Foo::Bar.baz` is called — use `--name`/`--exact-name` on the last
  segment, or rubydex.
- No ancestors, descendants, or cross-file graph — Tier 1.
- Only doc is `referral --help`; 0.0.x on `RubyVM::AbstractSyntaxTree`, which Ruby
  core is replacing with Prism. Clean on Ruby 3.4.10; disposable if a future Ruby
  drops the API.

`universal-ctags` (`ctags -R --languages=Ruby`) is a decent zero-cost symbol index
when rubydex is unavailable: one `tags` file, `rg`-able, ~1s to regenerate.

## Tier 3 — runtime

Only when static resolution can't answer — callbacks firing, concerns composing,
boot-time wiring, `define_method`.

```bash
bin/rails runner 'puts ActiveRecord::Base.descendants.map(&:name).sort'
bin/rails runner 'puts Rails.application.routes.routes.map { |r| [r.path.spec.to_s, r.defaults[:controller], r.defaults[:action]] }'
bin/rails runner 'puts User.reflect_on_all_associations.map { |a| [a.macro, a.name, a.options] }'
```

A runtime MCP (e.g. Tidewave) supersedes Tier 0+1 when the app boots — at the
cost of a running server.

## Failure modes to avoid

- **Generating an index/map file** and trusting it after edits — query instead.
- **Reading a file to learn its shape** — `get_file_declarations` first, then read
  only the ranges you need.
- **Unfiltered aggregate queries** — stdlib and gems are indexed; scope to your
  namespace or `String` looks like your fattest class.
- **Treating rubydex as Rails-aware** — associations, callbacks and route→action
  are Tier 0/3.
- **Answering "is this dead?" from one tool** — resolve refs (Tier 1), then grep
  the symbol name plus `send(:sym)`/string forms (Tier 2) before deleting.
- **Installing an MCP server to answer one question** — `rg` is one call.

## Verified facts (do not assume otherwise)

Rubydex **v0.4.1**, verified on Linux x86_64:

- Ships precompiled (`rubydex-0.4.1-x86_64-linux`); `gem install` needs no compiler.
- CLI subcommands are exactly: `console`, `lint`, `mcp [PATH]`, `query`, `skill`, `help`.
- MCP exposes **6** tools, not 7: `find_dead_code_candidates` is upstream README
  only (no reference in installed `lib/`/`exe/`), as is `rdx dead_code`. Both are
  **absent in 0.4.1**.
- `rdx lint` crashed on a minimal fixture — pre-release.
- **No consumer-facing first-party skill exists.** `Shopify/rubydex` ships
  `.claude/skills/` with four *maintainer* skills (`benchmark-rbs`, `profiling`,
  `review_changes`, `rubydex-mcp-benchmark`) — `npx skills add Shopify/rubydex`
  installs the wrong audience. Its `skills/` dir plus `rdx skill <id>` is a
  *runtime* library of one skill (`send-private-method`), surfaced only on a
  verified lint violation — copy the pattern, not the content.
- The MCP `instructions` field is the closest first-party guidance: these tools
  for `.rb`/`.rbi`/`.rbs`, text search for literals and comments, FQN format
  `Foo::Bar` / `Foo::Bar#method`, paginate with `offset`.

**referral v0.0.6** (published 2026-09-18), verified on Ruby 3.4.10:

- Token types emitted: `class`, `instance_method`, `call`, `function_call`,
  `constant`, `constant_declaration`, `local_var`, `local_var_assign`,
  `instance_var`, `instance_var_assign`.
- `--exact-name User` matches qualified names, so it does find `User.new` call
  sites — but `--full-name 'Foo::Bar'` does not match `Foo::Bar.baz` receivers.
- No deprecation warning from `RubyVM::AbstractSyntaxTree` on Ruby 3.4.10.
