---
name: lecture-note
description: Generates structured lecture notes from a Transcript transcript. Invoke manually on "강의 정리", "강의 노트 만들어줘", or "lecture note". Falls back to the latest transcript when no target is given.
---

# Lecture Note Generator

Turns a Transcript transcript of a lecture into study-ready notes, written in the transcript's language. Optimized for review: the note must let the user re-learn and self-test without replaying the lecture.

## Selecting the Target

- Use the file the user names or the date they mention.
- Without a target, pick the most recent transcript, excluding generated notes, memos, corrected copies, and backfill copies (transcripts whose frontmatter contains a source_audio field).
- When the chosen transcript has a corrected sibling (same base name with the corrected suffix), read the corrected file instead and record it as the note's source transcript.
- If no transcript exists, report that and stop.

Selection command:

```bash
ls -t ~/Documents/Transcript/*.md | grep -vE '\.(meeting-note|lecture-note|memo|corrected)\.md' | xargs grep -L '^source_audio:' | head -1
```

## Writing the Note

Start from the template file, keep its section order, and replace every braced placeholder. Omit a section only when the transcript has nothing for it — except My Notes, which always stays.

Section rules on top of the template:

- Key Concepts: capture definitions as taught, one term per line. This is the primary exam-prep asset.
- Main Content: restructure by concept, not by chronology; keep each principle together with its intuition and examples.
- Instructor Emphasis: collect repetitions, "this will be on the exam" signals, and anything the instructor slowed down for.
- Review Questions: five to ten self-test questions answerable from this note alone.
- Cut noise: administrative chatter and small talk are dropped, except anything that belongs in Assignments.
- Q&A exchanges: summarize the question and the instructor's answer as a pair.

Template file:

```bash
${CLAUDE_PLUGIN_ROOT}/templates/lecture-note.md
```

## Grounding Rules

- Correct only transcription typos that are obvious from context; never reshape meaning by guessing. Mark unclear passages as (unclear).
- Never invent definitions, formulas, dates, or assignments that were not spoken.

## Saving and Reporting

- Save next to the original with the lecture-note suffix. Never modify the original file.
- Keep the template's provenance frontmatter filled in, so the note's lineage (which transcript, which template) stays machine-readable.
- Notes are regenerable: rerun on the same transcript any time. When the user experiments with template variants, add a variant tag to the file name instead of overwriting.
- Local markdown is the only output. Never publish to external services.
- In chat, report only the TL;DR and the saved path.

Naming example:

```bash
~/Documents/Transcript/2026-09-02-190010.md
~/Documents/Transcript/2026-09-02-190010.lecture-note.md
```
