# Tier 1 — Rubydex (Shopify)

Rust static-analysis engine for Ruby, ships an MCP server. Use for semantic
facts: definitions, references, ancestors, descendants, fat classes. Not
Rails-aware — see end.

## Install

Ad-hoc is enough, no project mutation:

```bash
gem install rubydex          # precompiled binary per platform, no native build
rdx --version                # v0.4.1 verified
```

Gemfile entry only when the bundle is isolated — see *Guard*:

```ruby
group :development do
  gem "rubydex", require: false
end
```

## Guard

- **`Gemfile` must exist** (not containing rubydex); otherwise `rdx` dies with an uncaught `Bundler::GemfileNotFound` (`lib/rubydex/graph.rb:54`). Rails apps always have one; bare Ruby trees may not.
- **Bare `rdx`, not `bundle exec rdx`**, unless the gem is in the Gemfile.
- **Gem resolution is by name, not version**: `Gem::Specification.find_by_name(lazy_spec.name)` drops the locked version — with two versions installed it indexes the newest. Silently rescues `Gem::MissingSpecError` — gems outside `Gem.path` skipped without warning. *Consequence:* ad-hoc is correct when the bundle's gems are also installed system-wide (usual rbenv/mise/system case); vendored bundle or duplicate gem versions → `bundle add rubydex` + `bundle exec rdx` so bundler sets `GEM_PATH`.
- Any failure → **fall back to Tier 0 (`daily-checks.md`) + Tier 2 (`search.md`)**. Don't debug rubydex mid-refactor.

## MCP: 6 tools (not 7)

`rdx mcp [PATH]` starts a stdio server. Verified tool list:

- `search_declarations` — `query`, `kind?`, `match_mode?` (`fuzzy`\|`exact`), `limit`, `offset`; partial-name lookup, **prefer over grep** for identifiers.
- `get_declaration` — `name`, exact FQN: `Foo::Bar`, `Foo::Bar#instance_method`, `Foo::Bar.method`
- `get_descendants` — `name`, `limit`, `offset`; everything that inherits/includes this
- `find_constant_references` — `name`, `limit` (max 200), `offset`; resolved constant usages, file+line+column
- `get_file_declarations` — `file_path`; a file's structure **before** reading it
- `codebase_stats` — no args; composition check, proves indexing finished

Gotchas (verified):

- **First calls return `{"error":"indexing",...}`** — not a failure; retry once or twice.
- Paginated tools return `total`; page with `offset`, don't re-query.
- `codebase_stats` counts **gems and stdlib too** — a one-file app reported 252 files / 10,820 declarations. Warmth check, not app size.
- **`find_dead_code_candidates` is documented upstream but absent in 0.4.1.** Don't call it; don't promise dead-code analysis from this tool.

## CLI

```bash
rdx query --schema                              # free: labels, edges, properties, no indexing
rdx query 'MATCH ... RETURN ...'                # table output
rdx query 'MATCH ... RETURN ...' --format json
rdx console                                     # interactive graph REPL
rdx skill                                       # built-in skill library (1 skill today)
```

## Cypher cookbook (all run against 0.4.1)

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

On error re-read `rdx query --schema` instead of guessing; read-only Cypher subset
(`MATCH`/`WHERE`/`RETURN`, `ORDER BY`, `LIMIT`, `count`). **Don't** put `rdx lint`
or `rdx dead_code` in a workflow — see *Verified facts*.

Recipes ("what breaks if I change this?", rename/dead-code checklists): `refactor.md`.

## Verified facts (do not assume otherwise)

Rubydex **v0.4.1**, verified on Linux x86_64:

- Ships precompiled (`rubydex-0.4.1-x86_64-linux`); `gem install` needs no compiler.
- CLI subcommands exactly: `console`, `lint`, `mcp [PATH]`, `query`, `skill`, `help`.
- MCP exposes **6** tools, not 7: `find_dead_code_candidates` is upstream README only (no reference in installed `lib/`/`exe/`), as is `rdx dead_code`. Both **absent in 0.4.1**.
- `rdx lint` crashed on a minimal fixture — pre-release.
- **No consumer-facing first-party skill exists.** `Shopify/rubydex` ships `.claude/skills/` with four *maintainer* skills (`benchmark-rbs`, `profiling`, `review_changes`, `rubydex-mcp-benchmark`) — `npx skills add Shopify/rubydex` installs the wrong audience. Its `skills/` dir plus `rdx skill <id>` is a *runtime* library of one skill (`send-private-method`), surfaced only on a verified lint violation — copy the pattern, not the content.
- MCP `instructions` field is the closest first-party guidance: these tools for `.rb`/`.rbi`/`.rbs`, text search for literals and comments, FQN format `Foo::Bar` / `Foo::Bar#method`, paginate with `offset`.

## Not Rails-aware

Rubydex indexes Ruby; `has_many :posts` is a method call to it, not an
association. Associations, callbacks, route→action, jobs, mailers:
`daily-checks.md` or `runtime.md`. Rails-DSL questions → wrong tier.
