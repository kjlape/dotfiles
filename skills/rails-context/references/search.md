# Tier 2 — text and structural search

Use when the semantic tools can't answer: literals, comments, log messages,
ERB/YAML, DSL call shapes, or telling a local variable from a method. No index,
no MCP; works in any tree, Gemfile or not.

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

## `referral` — occurrence/scope listing (between `rg` and ast-grep)

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
- No ancestors, descendants, or cross-file graph — Tier 1 (`rubydex.md`).
- Only doc is `referral --help`; 0.0.x on `RubyVM::AbstractSyntaxTree`, which Ruby
  core is replacing with Prism. Clean on Ruby 3.4.10; disposable if a future Ruby
  drops the API.

`universal-ctags` (`ctags -R --languages=Ruby`) is a decent zero-cost symbol index
when rubydex is unavailable: one `tags` file, `rg`-able, ~1s to regenerate.

## Verified facts (referral v0.0.6, published 2026-09-18, Ruby 3.4.10)

- Token types emitted: `class`, `instance_method`, `call`, `function_call`,
  `constant`, `constant_declaration`, `local_var`, `local_var_assign`,
  `instance_var`, `instance_var_assign`.
- `--exact-name User` matches qualified names, so it does find `User.new` call
  sites — but `--full-name 'Foo::Bar'` does not match `Foo::Bar.baz` receivers.
- No deprecation warning from `RubyVM::AbstractSyntaxTree` on Ruby 3.4.10.
