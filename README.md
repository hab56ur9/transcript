# Transcript

Local realtime meeting transcriber for macOS. It lives in the menu bar, captures the microphone and system audio, transcribes on-device with Whisper (Korean/English), separates speakers, and streams text into markdown as people speak. Nothing leaves your machine.

Ships with a Claude Code / Codex plugin so an AI agent can run the whole flow hands-free: start and stop recording by voice command, generate meeting or lecture notes, and re-run any stage later.

## Pipeline

Three immutable stages, each regenerable from the previous one:

```bash
audio (.m4a)  →  transcript (.md)  →  note (.meeting-note.md / .lecture-note.md)
```

## Install

App and CLI, from the latest GitHub release:

```bash
curl -fsSL https://raw.githubusercontent.com/hab56ur9/transcript/main/install.sh | bash
```

Agent skills, as a Claude Code / Codex plugin from the agents-plugins marketplace:

```bash
claude plugin marketplace add hab56ur9/agents-plugins
claude plugin install transcript@agents-plugins
```

## Develop

Clone this repository and allow its `.envrc` (direnv): inside the checkout, `transcript` then resolves to `bin/transcript`, which builds the local sources and launches a dev bundle (TranscriptDev.app) whose permissions stay separate from the installed app.

Releases are automated with release-please: PR titles follow Conventional Commits (`feat:`, `fix:`, `chore:`), the bot keeps a release PR open with the next version and changelog, and merging that PR publishes the GitHub release with the built app attached.

## Use

Say "전사 모드 시작" to your agent, or use the menu bar icon. Outputs land in Documents/Transcript. Details: plugin/skills/run/SKILL.md.

Requires macOS 14+. Development additionally needs Xcode Command Line Tools.
