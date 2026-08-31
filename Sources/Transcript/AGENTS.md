# Agent Guide — Sources

The rulebook for changing this code is the dev skill; read it before editing, and run the dev-review agent after.

Rulebook and review (repo-local, not part of the distributed plugin):

```bash
.agents/skills/dev/SKILL.md
.agents/agents/dev-review.md
```

Hard rules that fail review:

- Models imports Foundation and Observation only. Frameworks (AppKit, AVFoundation, WhisperKit, FluidAudio) and unsafe pointer expressions belong to Services.
- RecordingSession talks to ports only; all wiring lives in AppComposition. Prefer a new file plus a wiring line over editing the session.
- Extend audio behavior by wrapping AudioSource (decorator), not by modifying capture classes.
- Zero comments. No else blocks — early returns. One condition per if or guard; name compound conditions. No single-use wrapper methods.
- Never weaken the lifecycle guarantee: stop and quit finish pending transcription and save before exiting.
- state.json and settings.json fields are public contracts — change them only with the matching skill-doc update.

Verification before finishing any change:

```bash
swift test
swift build -c release
```

Session rules require a fake-port test (Swift Testing; XCTest unavailable on CLT-only machines).
