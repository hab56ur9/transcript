# Transcript

Local realtime meeting transcriber for macOS. It lives in the menu bar, captures the microphone and system audio, transcribes on-device with Whisper (Korean/English), separates speakers, and streams text into markdown as people speak. Nothing leaves your machine.

Ships with a Claude Code / Codex plugin so an AI agent can run the whole flow hands-free: start and stop recording by voice command, generate meeting or lecture notes, and re-run any stage later.

## Pipeline

Three immutable stages, each regenerable from the previous one:

```bash
audio (.m4a)  →  transcript (.md)  →  note (.meeting-note.md / .lecture-note.md)
```

## Install

```bash
claude plugin marketplace add <this-repo>
claude plugin install transcript@transcript
~/.claude/plugins/marketplaces/transcript/bin/install
```

## Use

Say "전사 모드 시작" to your agent, or use the menu bar icon. Outputs land in Documents/Transcript. Details: plugin/skills/run/SKILL.md.

Requires macOS 14+ and Xcode Command Line Tools.
