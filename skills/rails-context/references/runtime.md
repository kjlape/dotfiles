# Tier 3 — runtime

Only when static resolution can't answer — callbacks firing, concerns composing,
boot-time wiring, `define_method`.

```bash
bin/rails runner 'puts ActiveRecord::Base.descendants.map(&:name).sort'
bin/rails runner 'puts Rails.application.routes.routes.map { |r| [r.path.spec.to_s, r.defaults[:controller], r.defaults[:action]] }'
bin/rails runner 'puts User.reflect_on_all_associations.map { |a| [a.macro, a.name, a.options] }'
```

Runtime MCP (e.g. Tidewave) supersedes Tier 0+1 when the app boots — at the cost
of a running server.

What the Ruby DSL hides from static tools:

- Which callbacks run, and in what order.
- What a concern contributes once composed.
- Association options (`reflect_on_all_associations`).
- Route→action wiring as the app sees it, vs `config/routes.rb` as written.
- Anything built by `define_method`, `class_eval`, or metaprogramming loops.
