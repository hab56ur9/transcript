# Transcript Agent Guide

Local realtime meeting transcriber for macOS (menu bar app). This file routes coding agents to the operational documents; those documents are the single source of truth — follow them rather than duplicating their content here.

- Operating the app (launch, recording signals, state tracking, troubleshooting): plugin/skills/run/SKILL.md
- One-time machine setup: plugin/skills/run/setup.md — a single install.sh one-liner that works on any host.
- Codex: skills install via the plugin marketplace (this repository ships both Claude and Codex manifests); the app installs through the same install.sh.
- Re-transcribing archived audio and comparing engines: plugin/skills/backfill/SKILL.md
- Correcting misrecognized domain terms in a transcript: plugin/agents/correct.md
- Generating meeting notes from transcripts: plugin/agents/meeting-note.md, with the format fixed by plugin/templates/meeting-note.md
- Generating development documents from design-discussion transcripts: plugin/agents/dev-doc.md, with the format fixed by plugin/templates/dev-doc.md

Release convention: squash-merge PR titles follow Conventional Commits (feat:, fix:, chore:). release-please reads those titles, keeps a release PR open with the next version and changelog, and merging that release PR is the whole release procedure — the workflow then builds the app on a macOS runner and attaches Transcript.app.zip. Versions live in version.txt and both plugin manifests; the bot owns every version edit.

Development: the coding rulebook and the diff-review agent are repo-local, and each major directory carries its own README (human) and AGENTS.md (agent) pair.

```bash
.agents/skills/dev/SKILL.md
.agents/agents/dev-review.md
Sources/Transcript/AGENTS.md
plugin/AGENTS.md
```

Setup, build, and test commands:

```bash
direnv allow
swift build -c release
swift test
```
