# Cross-cutting changes: blast radius, renames, dead code

Use for: model/concern/base class/shared service/column change; rename or
delete a symbol; multi-file refactor; "what breaks if I change this?"; proving
death. Order: full Tier 0 (`daily-checks.md`), Tier 1 (`rubydex.md`) per symbol
touched, then these recipes *before editing*. Below that: over-equipping.

## Step 1 — Rails side first (no installs)

```bash
cat db/schema.rb                               # column types, indexes, FKs
bin/rails routes --expanded                    # which actions touch this
bin/rails zeitwerk:check                       # real constant set
bin/packwerk validate                          # if packwerk is in use
```

## Step 2 — semantic facts per symbol

```bash
rdx query 'MATCH (d:Document)-[:REFERENCES]->(t:Declaration) WHERE t.name = "User" RETURN d.path'
rdx query 'MATCH (c:Declaration)-[:HAS_DESCENDANT]->(d) WHERE c.name = "User" RETURN d.name'
rdx query 'MATCH (c:Class {name: "User"})-[:HAS_ANCESTOR]->(a) RETURN a.name'
```

Schema, install/guard rules, FQN format, pagination: `rubydex.md`.

## Step 3 — "What breaks if I change this?"

No blast-radius tool, no method-level call graph (no receiver type inference) —
four cheap steps, not file reading:

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

Nothing resolves schema-to-code edges. Grep both sides:

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

"Is this dead?" from one tool is how dead-code analysis goes wrong: resolve
refs (Tier 1), then grep the name plus `send(:sym)` and string forms (Tier 2).
`find_dead_code_candidates` does **not** exist in rubydex 0.4.1
(`rubydex.md`) — don't promise it.

## Renames

1. Collect the reference set (steps 2–3) as a checklist.
2. Rename the definition.
3. Walk the checklist; per hit confirm same symbol — not a shadowed local or
   unrelated constant.
4. `rg` old name over everything: YAML, ERB, routes, i18n, `db/seeds.rb`.
5. `bin/rails zeitwerk:check` + relevant specs.

## What to hand back

- Dependent files grouped by layer (models, controllers, jobs, mailers, views,
  specs).
- Unresolved uses (dynamic dispatch, `send`, string refs) flagged unverified.
- Commands run, so the user can re-check after the edit.
