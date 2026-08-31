---
name: dev-doc
description: Writes a development document from a Transcript transcript of a design discussion. Invoke manually on "개발 문서 작성해줘", "설계 문서 만들어줘", or "dev doc". Falls back to the latest transcript when no target is given.
---

# Dev Doc Generator

Turns a Transcript transcript — a spoken design discussion or feature walkthrough — into an RFC-style development document, written in the transcript's language.

## Selecting the Target

- Use the file the user names or the date they mention.
- Without a target, pick the most recent transcript, excluding generated notes, memos, and backfill copies (transcripts whose frontmatter contains a source_audio field).
- If no transcript exists, report that and stop.

Selection command:

```bash
ls -t ~/Documents/Transcript/*.md | grep -vE '\.(meeting-note|lecture-note|dev-doc|memo)\.md' | xargs grep -L '^source_audio:' | head -1
```

## Document Structure

Start from the template file, keep its section order, and replace every braced placeholder. The template follows the engineering RFC shape: the upper half states intent (abstract, motivation, goals, non-goals) and the lower half states execution (proposal, detailed design, rollout plan). The two halves never mix — a sentence about why belongs above, a sentence about how belongs below.

- The abstract condenses the whole discussion into two or three sentences: problem, proposed solution, expected outcome.
- Keep each section under 1,000 characters; trim to essentials rather than exceed the limit.
- Omit a section only when the transcript has nothing for it.
- Unresolved design points go to Unresolved Questions, never filled in by guessing.

Template file:

```bash
${CLAUDE_PLUGIN_ROOT}/templates/dev-doc.md
```

## Writing Style

- Prose first: complete sentences that read aloud without code. Refrain from inline code, symbols, or file paths inside sentences.
- Examples, commands, API shapes, and schemas go in a fenced block at the end of their section, ordered to match the prose above.
- Ground every statement in the transcript. Correct only obvious transcription typos; mark unclear passages as (unclear). Never invent requirements, owners, or dates.

## Saving and Reporting

- Save next to the original with the dev-doc suffix. Never modify the original file.
- Keep the provenance frontmatter filled so the document's lineage (which transcript, which template) stays machine-readable.
- Documents are regenerable: rerun on the same transcript any time; template experiments get a variant tag in the file name instead of overwriting.
- Local markdown is the only output. In chat, report only the TL;DR and the saved path.

Naming example:

```bash
~/Documents/Transcript/2026-09-01-031039.md
~/Documents/Transcript/2026-09-01-031039.dev-doc.md
```
