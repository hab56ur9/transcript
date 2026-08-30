# VoiceScribe Agent Guide

Local realtime meeting transcriber for macOS (menu bar app). This file routes coding agents to the operational documents; those documents are the single source of truth — follow them rather than duplicating their content here.

- Operating the app (launch, recording signals, state tracking, troubleshooting): plugin/skills/run/SKILL.md
- One-time machine setup: plugin/skills/run/setup.md. The marketplace checkout path there is Claude-specific — on other hosts, clone this repository anywhere and run the install script from the repo root instead.
- Codex: skills install via the plugin marketplace (this repository ships both Claude and Codex manifests); the app binary still needs the clone-and-install step above.
- Re-transcribing archived audio and comparing engines: plugin/skills/backfill/SKILL.md
- Generating meeting notes from transcripts: plugin/agents/meeting-note.md, with the format fixed by plugin/templates/meeting-note.md

Development: the coding rulebook and the diff-review agent are repo-local, and each major directory carries its own README (human) and AGENTS.md (agent) pair.

```bash
.agents/skills/dev/SKILL.md
.agents/agents/dev-review.md
Sources/VoiceScribe/AGENTS.md
plugin/AGENTS.md
```

Setup, build, and test commands:

```bash
bin/install
swift build -c release
swift test
```
