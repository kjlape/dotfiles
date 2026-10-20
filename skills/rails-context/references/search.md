# Tier 2 — text and structural search

For what semantic tools can't answer: literals, comments, log messages, ERB/YAML,
DSL call shapes, local vs method. No index/MCP; any tree, Gemfile or not.

```bash
rg -n 'SomeLiteral|some_log_message'          # literals, comments, ERB, YAML
rg -n --type ruby 'class \w+Controller'       # cheap shape checks

# ast-grep: tree-sitter-ruby; DSL patterns (method calls) invisible to rubydex/graph tools.
# binary is `ast-grep` (`sg` deprecated); `-l` means --lang.
ast-grep run -p 'has_many $ASSOC, dependent: :destroy' --lang rb app/models
ast-grep run -p 'before_action $FILTER' --lang rb app/controllers
ast-grep run -p 'attr_reader $ARGS' --lang rb --files-with-matches
```

Inference usually works; pass `--lang rb` if a Ruby pattern fails — a mis-inferred
grammar silently returns 0 results.

## `referral` — occurrence/scope listing (between `rg` and ast-grep)

`gem install referral` (testdouble v0.0.6, MIT, no Gemfile/index). Walks
`RubyVM::AbstractSyntaxTree`, prints `location:type:scope:name` per occurrence —
answers what `rg` can't: **local variable, method definition, or call?**

```bash
referral .                                        # everything, sorted by file
referral --exact-name nickname --columns location,type,scope,name --print-headers --delimiter $'\t'
referral --scope 'User#full_name'                  # what does this method actually contain
referral --type call,local_var --name total        # name appears as a call and as a local
referral --name has_many --arity 2                 # DSL calls by argument count
```

Unique to it:

- **Local-variable resolution** — `puts full_name` on a local emits `local_var`;
  `user.nickname` is a `call`. Rubydex ignores locals; `rg` cannot tell.
- **Every occurrence attributed to enclosing `Class#method`** — `--sort scope`.
- **`--arity`** — cheap DSL queries (`has_many` with exactly 2 args), no ast-grep.
- **No Gemfile needed** — lone script or non-bundled tree where `rdx` refuses to start.

Does **not** do (verified — don't ask):

- **No receiver type inference** — `--full-name 'User#full_name'` returns only the
  definition, never call sites on a `user` object.
- **No namespaced-constant matching** — `--full-name 'Foo::Bar'` returns nothing
  even when `Foo::Bar.baz` is called; use `--name`/`--exact-name` on the last
  segment, or rubydex.
- No ancestors, descendants, or cross-file graph — Tier 1 (`rubydex.md`).
- Only doc: `referral --help`. 0.0.x on `RubyVM::AbstractSyntaxTree`, which Ruby
  core replaces with Prism. Clean on Ruby 3.4.10; disposable if a future Ruby drops
  the API.

`universal-ctags` (`ctags -R --languages=Ruby`) — zero-cost symbol index if rubydex
is unavailable: one `tags` file, `rg`-able, ~1s to regenerate.

## Verified facts (referral v0.0.6, published 2026-09-18, Ruby 3.4.10)

- Token types: `class`, `instance_method`, `call`, `function_call`, `constant`,
  `constant_declaration`, `local_var`, `local_var_assign`, `instance_var`,
  `instance_var_assign`.
- `--exact-name User` matches qualified names, so it finds `User.new` call sites —
  but `--full-name 'Foo::Bar'` does not match `Foo::Bar.baz` receivers.
- No deprecation warning from `RubyVM::AbstractSyntaxTree` on Ruby 3.4.10.
