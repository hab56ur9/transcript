# Setup

One-time bootstrap for a new machine. The run skill assumes the launcher is already on PATH — come here only when the launcher command is missing.

## Install

- One command installs everything: it downloads the newest GitHub release of Transcript.app into the user Applications folder and puts the transcript CLI on PATH. It needs neither sudo, nor a clone, nor a build.
- Development setup is separate: clone the repository and allow its .envrc (direnv) so the repo's own bin/transcript shadows the installed CLI inside the checkout; that copy builds and runs the dev bundle.

Commands:

```bash
curl -fsSL https://raw.githubusercontent.com/hab56ur9/transcript/main/install.sh | bash
```

## First Run

- The app ships prebuilt, so the first launch needs no toolchain.
- Every permission attaches to Transcript.app itself — the launch host is irrelevant.
- The transcription model (about 1.6GB) downloads once on first use; queued chunks catch up afterward.
- The speaker-diarization model downloads once on first use as well.
- The microphone permission prompt appears on first recording.
- The notification permission prompt appears on the first signal-driven recording request; approving it enables the ask-before-recording flow.
- System audio (remote voices) needs the screen recording permission for Transcript.app; the app runs mic-only until granted.
- Writing into the Documents folder may prompt a files-and-folders permission once.
- The bundle is ad-hoc signed, so each release update changes the signature and macOS asks for the permissions again on the next recording.
