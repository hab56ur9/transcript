# Agent Guide — Plugin

Rules for editing anything under this directory. These files ship to end users of the plugin — consumer-facing operation docs only; development guidance belongs in the repo-local Claude directory instead.

Document style (enforced by dev-review):

- English body; each section under 1,000 characters; whole skill or agent under 3,000.
- Prose reads aloud without code — commands, paths, and examples go in a fenced block at the end of the section, ordered to match the prose.
- Frontmatter: skills use name, description, user-invocable; agents use name and description. Korean trigger phrases stay in quotes inside the description.
- Skills route; sub-documents (like setup.md) carry one-time detail. Note agents pair with a template file in templates/ — keep agent rules and template placeholders consistent.

Contracts to preserve when editing:

- The pipeline wording: audio → transcript → note, with an optional correction pass producing a corrected sibling between transcript and note; immutable inputs, lineage in frontmatter (engine, source_audio, template, source_transcript).
- Note agents must exclude generated notes, memos, corrected copies, and backfill transcripts when picking a default target, and must read the corrected sibling when one exists.
- Signal semantics: USR1 record, USR2 stop and save, TERM quit-after-save.

Release procedure for any change here:

```bash
plugin/.claude-plugin/plugin.json
plugin/.codex-plugin/plugin.json
claude plugin update --scope local transcript@transcript
```

Bump the version in both manifests to the same value, then run the update command.
