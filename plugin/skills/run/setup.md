# Setup

One-time bootstrap for a new machine. The run skill assumes the launcher is already on PATH — come here only when the launcher command is missing.

## Install

- Adding this marketplace already fetches the full repository — app sources included — into the Claude plugins marketplace directory. No separate clone is needed.
- Run the install script from that checkout once; it links the launcher into a writable PATH directory (no sudo).
- The first launch builds the binary (requires Xcode Command Line Tools) and downloads models automatically.

Commands:

```bash
command -v voicescribe
~/.claude/plugins/marketplaces/voicescribe/bin/install
voicescribe
```

## First Run

- The transcription model (about 1.6GB) downloads once on first use; queued chunks catch up afterward.
- The speaker-diarization model downloads once on first use as well.
- The microphone permission prompt appears on first recording.
- System audio (remote voices) needs the screen recording permission for the hosting terminal; the app runs mic-only until granted.
- Writing into the Documents folder may prompt a files-and-folders permission once.
- Run once from the user's terminal to seed all permissions.
