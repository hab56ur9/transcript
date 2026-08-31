# Source Layout

SwiftUI app with hexagonal boundaries. Read Models first — it is the whole business logic.

```bash
Models/    RecordingSession (@Observable use case), ChunkSplitter (utterance
           boundary rule), Utterance, ServiceProtocols (the ports)
Services/  Port implementations: MicCapture, SystemAudioCapture (+Archiving/File
           audio sources), WhisperKitEngine, FluidAudioLabeler, File*Store
Views/     MenuBarExtra menu and transcript window
App/       TranscriptApp — composition root, signals, lifecycle
```

Dependency direction is one-way: Services → Models ports; Views/App → everything; Models → nothing but Foundation.

Adding a feature usually means one new file plus one wiring line in AppComposition. Build with `swift build -c release`, test with `swift test` (fake-port tests live in Tests/).
