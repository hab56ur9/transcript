---
name: meeting-note
description: Generates a structured meeting note from a VoiceScribe transcript. Invoke manually on "미팅 노트 만들어줘", "회의록 정리", or "전사 요약". Falls back to the latest transcript when no target is given.
---

# Meeting Note Generator

Turns a VoiceScribe transcript into a structured meeting note, written in the transcript's language.

## Selecting the Target

- Use the file the user names or the date they mention.
- Without a target, pick the most recent transcript, excluding generated notes and backfill copies (transcripts whose frontmatter contains a source_audio field).
- If no transcript exists, report that and stop.

Selection command:

```bash
ls -t ~/Documents/VoiceScribe/*.md | grep -v '\.meeting-note\.md' | xargs grep -L '^source_audio:' | head -1
```

## Note Structure

Start from the template file, keep its section order, and replace every braced placeholder. Omit a section only when the transcript has nothing for it — except My Notes, which always stays.

Section rules on top of the template:

- Header: infer the title from the discussion, take the date from the file name, list attendees as speaker labels. Map labels to real names only when the user provides the mapping.
- Discussion: three to five topic sections following the flow of the conversation.
- Decisions: agreed items only. When agreement is ambiguous in the transcript, the item belongs in Open Questions, not Decisions.
- Action items: spoken commitments only — someone said they will do it, or it was explicitly assigned. Ideas, possibilities, and attendance at already-scheduled meetings are not action items; when in doubt, keep it in Discussion.
- My notes: fill with any memo the user handed over; otherwise leave the section empty for later editing.

Template file:

```bash
${CLAUDE_PLUGIN_ROOT}/templates/meeting-note.md
```

## Grounding Rules

- Attribute statements only with speaker labels present in the transcript.
- Correct only transcription typos that are obvious from context; never reshape meaning by guessing. Mark unclear passages as (unclear).
- Never invent attendees, dates, owners, or deadlines that were not spoken.

## Saving and Reporting

- Save next to the original with the meeting-note suffix. Never modify the original file.
- Keep the template's provenance frontmatter filled in, so the note's lineage (which transcript, which template) stays machine-readable.
- Notes are regenerable: rerun on the same transcript any time. When the user experiments with template variants, add a variant tag to the file name instead of overwriting.
- Local markdown is the only output. Never publish to external services such as Notion, Confluence, or Slack.
- In chat, report only the TL;DR and the saved path.

Naming example:

```bash
~/Documents/VoiceScribe/2026-08-30-184038.md
~/Documents/VoiceScribe/2026-08-30-184038.meeting-note.md
```
