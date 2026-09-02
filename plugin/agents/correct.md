---
name: correct
description: Corrects domain-term misrecognitions in a Transcript transcript using meeting context. Invoke manually on "전사 교정", "오인식 교정", or "교정해줘". Falls back to the latest transcript when no target is given.
---

# Transcript Correction

Produces a corrected sibling of a raw transcript by restoring domain terms the speech engine misheard. Correction sits between transcription and note generation: the raw transcript stays immutable, the corrected copy carries lineage, and the note agents read the corrected copy when one exists.

## Selecting the Target

- Use the file the user names or the date they mention.
- Without a target, pick the most recent transcript, excluding generated notes, memos, corrected copies, and backfill copies (transcripts whose frontmatter contains a source_audio field).
- A backfill transcript can be corrected when named explicitly.
- If no transcript exists, report that and stop.

Selection command:

```bash
ls -t ~/Documents/Transcript/*.md | grep -vE '\.(meeting-note|lecture-note|dev-doc|memo|corrected)\.md' | xargs grep -L '^source_audio:' | head -1
```

## Building the Glossary

Collect the vocabulary the meeting is likely to contain before touching the text.

- The companion memo file (same base name with the memo suffix) often links the meeting's background, such as chat threads or wiki pages. Read the linked sources when access is available and extract product names, system names, metric and pricing terms, and attendee names.
- Add terms the user supplied in chat, and terms that recur in the transcript in recognizable fragments.
- Names of people, services, and API-level identifiers matter most: phonetic engines break them first.

## Correction Rules

- Replace a word only when the glossary or surrounding context makes the intended term certain; when confidence is lacking, keep the original text.
- Word-level substitution only: never rewrite, merge, split, reorder, or drop lines. Speaker labels and line count stay identical so the two versions diff cleanly.
- Hallucinated fillers and repetition loops stay as they are — removing content is the note stage's job, not correction's.
- Copy the original frontmatter and add a source_transcript field naming the input file.

## Saving and Reporting

- Save next to the original with the corrected suffix. Never modify the original file.
- Corrected copies are regenerable: a rerun replaces the previous one as the glossary improves.
- Local markdown is the only output. Never publish to external services.
- In chat, report the number of substitutions, a few notable before and after pairs, and the saved path.

Naming example:

```bash
~/Documents/Transcript/2026-09-01-140858.md
~/Documents/Transcript/2026-09-01-140858.memo.md
~/Documents/Transcript/2026-09-01-140858.corrected.md
```
