# Cross-cutting changes, blast radius, renames, dead code

Use for: changing a model, concern, base class, shared service or column;
renaming or deleting a symbol; planning a multi-file refactor; answering
"what breaks if I change this?"; proving something is dead.

Order of operations: full Tier 0 (`daily-checks.md`), Tier 1 (`rubydex.md`) for
every symbol touched, then the recipes below *before editing*. Below that is
over-equipping.

## Step 1 — Rails side first (no installs)

```bash
cat db/schema.rb                               # column types, indexes, FKs
bin/rails routes --expanded                    # which actions touch this
bin/rails zeitwerk:check                       # real constant set
bin/packwerk validate                          # if packwerk is in use
```

## Step 2 — semantic facts for each symbol

```bash
rdx query 'MATCH (d:Document)-[:REFERENCES]->(t:Declaration) WHERE t.name = "User" RETURN d.path'
rdx query 'MATCH (c:Declaration)-[:HAS_DESCENDANT]->(d) WHERE c.name = "User" RETURN d.name'
rdx query 'MATCH (c:Class {name: "User"})-[:HAS_ANCESTOR]->(a) RETURN a.name'
```

See `rubydex.md` for schema, install/guard rules, FQN format, and pagination.

## Step 3 — "What breaks if I change this?"

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

Report the list, not a guess.

## Step 4 — column changes

Nothing here resolves schema-to-code edges. Grep both sides:

```bash
rg -n 'user_id' db/schema.rb app/ spec/
rg -n 'user_id' db/migrate/
```

## Step 5 — before deleting anything

```bash
rg -n 'Thing\b' --type ruby
rg -n "send\(:thing|const_get\(['\"]Thing|method\(:thing" --type ruby
rg -n 'thing' app/views config/ db/seeds.rb lib/tasks
rdx query 'MATCH (d:Document)-[:REFERENCES]->(t:Declaration) WHERE t.name = "Thing" RETURN d.path'
referral --exact-name thing --columns location,type,scope   # calls vs locals
```

Answering "is this dead?" from one tool is how dead-code analysis goes wrong:
resolve refs (Tier 1), then grep the symbol name plus `send(:sym)` and string
forms (Tier 2). `find_dead_code_candidates` does **not** exist in rubydex 0.4.1
(`rubydex.md`) — don't promise it.

## Renames

1. Collect the reference set (steps 2–3) and keep it as a checklist.
2. Rename the definition.
3. Walk the checklist; for each hit, confirm it is the same symbol, not a
   shadowed local or an unrelated constant.
4. Re-run `rg` for the old name over everything, including YAML, ERB, routes,
   i18n files and `db/seeds.rb`.
5. `bin/rails zeitwerk:check` and the relevant specs.

## What to hand back

- The list of dependent files, grouped by layer (models, controllers, jobs,
  mailers, views, specs).
- Anything the tools could not resolve (dynamic dispatch, `send`, string
  references) called out explicitly as unverified.
- The commands run, so the user can re-check after the edit.
