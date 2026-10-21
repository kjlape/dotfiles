# Bundled adverse helpers

This skill vendors the deterministic helpers and review prompts from
[addyosmani/adverse](https://github.com/addyosmani/adverse), revision
`4b9eb7b764a9d55ea08dff4f1c960926e0691f2a`.

The upstream MIT license is included in `../LICENSE`. The upstream skill is
`skills/adverse-review/`; its helper scripts also import modules from the
repository's `src/` directory. Those runtime dependencies must be bundled too:
copying only the upstream skill's `scripts/` directory is not sufficient.

The Pi adaptation uses `@tintinweb/pi-subagents` for reviewer invocations
instead of Claude Code's Agent tool. The Node helpers only collect source,
combine review JSON, and generate deterministic Markdown, JSON, and HTML
reports; they do not launch models or require the adverse CLI to be installed.
Runtime modules from upstream `src/{collect,synthesis,html}.mjs` live in
`scripts/lib/`. The bridge scripts import them locally; all other code and
prompts are unchanged. The unused upstream `dump-prompts.mjs` maintainer tool
is not bundled. Collection instructions use `--diff=` (working tree vs. HEAD)
or `--diff=<base>` (branch changes from the merge base to HEAD) because Node's
argument parser does not accept a bare `--diff`. All helper imports resolve
within this skill directory or to Node built-ins.

## Updating

1. Compare the upstream helper scripts, persona/round prompts, and their
   transitive source dependencies with the bundled copies.
2. Copy changes and keep imports relative to files inside this skill. Do not
   introduce a dependency on an adjacent checkout or an absolute home path.
3. Preserve the upstream license and update the revision above.
4. From the dotfiles repository root, run:

   ```sh
   python3 -m unittest discover -s tests -v
   ```

   The smoke tests copy only this skill into a temporary directory with spaces
   in its path and run the helpers from a separate review target. They exercise
   collection, both review rounds' combination, report generation, and the
   expected exit status of a blocking verdict, without invoking any models.
