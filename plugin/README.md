# Transcript Plugin

The distributable part of this repository — what Claude Code and Codex install. Everything needed to operate the app by conversation, none of the app's source.

```bash
skills/run/       launch, daemon signals, state tracking (+setup.md for new machines)
skills/backfill/  regenerate any pipeline stage: re-transcribe audio, re-summarize transcripts
agents/           meeting-note, lecture-note — transcript → structured note
templates/        the note formats those agents fill in
.claude-plugin/   Claude manifest
.codex-plugin/    Codex manifest
```

Both manifests must carry the same version — bump both on any change here, then refresh the installed plugin. Development rules for this repo live outside the plugin, under the repo-local Claude directory.
