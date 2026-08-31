---
name: dev
description: Development guide for the Transcript codebase — architecture rules, code conventions, contracts, and release steps. Activate when editing Swift sources, plugin docs, or scripts in this repository.
user-invocable: true
---

# Transcript Development

Rules for changing this repository. The dev-review agent audits diffs against this document — keep the two in sync.

## Architecture

Hexagonal, composed in one place.

- Models holds the observable RecordingSession, domain rules (ChunkSplitter, Utterance), and the ports (ServiceProtocols). It imports Foundation and Observation only — AppKit, AVFoundation, WhisperKit, and FluidAudio never appear here.
- Services implements the ports and owns every framework and C-API boundary. Unsafe pointer expressions live only here.
- Views is SwiftUI reading the session through AppComposition. App is the composition root: wiring, signals, lifecycle.
- The session depends on ports only. A new requirement should land as a new file plus a wiring change in AppComposition — if it forces edits inside the session, question the design first.
- Wrap, don't touch: extend audio behavior with AudioSource decorators (see ArchivingAudioSource). Promote a domain collaborator to an injected factory only when a second implementation actually exists.

## Code Conventions

- Zero comments. The swift-tools-version directive is the only exception.
- No else blocks — use early returns. guard-else and do-catch are fine.
- One condition per if or guard; name compound conditions as a computed property or a let.
- Loops are for-in over ranges or collections.
- Object-oriented but minimal: no single-use wrapper methods; extract only when the name adds information beyond the statements. Give concepts value types.
- Concurrency: actors for shared engines, @MainActor for the session and views, dedicated serial queues at capture boundaries. @unchecked Sendable only in Services, with single-queue or write-once access.

## Behavior Contracts

- state.json and settings.json are public contracts consumed by the skills — change fields only together with the matching skill-doc update.
- Pipeline files are immutable inputs: never overwrite audio or transcripts. Derived files record lineage in frontmatter (engine, source_audio, template, source_transcript).
- Lifecycle guarantee: stop and quit always finish pending transcription and save before exiting.

## Tests

- Session rules are unit-tested with fake ports using Swift Testing (XCTest is unavailable — CLT-only machines). A new session rule ships with a test.
- Run the tests and a release build before finishing any change.

Commands:

```bash
swift test
swift build -c release
```

## Docs and Release

- Skill and agent documents: English body, each section under 1,000 characters, prose that reads aloud without code — copy-runnable content goes in a block at the end of the section.
- Any change under the plugin directory: bump the version in both manifests, then refresh the installed plugin.
- App release: bump the version in both manifests, merge to main, then run the release script — it tests, builds, assembles Transcript.app with the icon, zips, and publishes a GitHub release (marked prerelease when the version carries a suffix). install.sh and `transcript --install` pull the newest release.
- The stable app is ad-hoc signed, so each release update invalidates prior TCC grants; users re-approve once per update. Dev builds use the separate com.nathan.transcript.dev identity and leave the stable grants alone.

Files and commands:

```bash
plugin/.claude-plugin/plugin.json
plugin/.codex-plugin/plugin.json
claude plugin update --scope local transcript@transcript
bin/release
```
