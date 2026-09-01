---
name: backfill
description: Regenerates any stage of the Transcript pipeline from its immutable input — audio to transcript (re-transcription), or transcript to note (re-summarization). Invoke on "백필", "재전사", "전사 엔진 비교", "요약 재생성", "템플릿 바꿔서 다시".
user-invocable: true
---

# Transcript Backfill

The pipeline has three stages — audio → transcript → note — plus an optional correction pass between the last two, and each stage can be regenerated from the previous one at any time. Originals are never modified; every run only adds a file, and every derived file records its lineage in frontmatter.

## When to Use

- After swapping or upgrading the transcription engine, to measure quality on real past meetings.
- To re-derive a transcript when the original run was interrupted or degraded.
- Safe to run while the menu bar app is resident — backfill is a separate headless process.

## Running

- If the launcher command is missing, complete the run skill's setup document first.
- Target any archived audio file (mic or aux channel) stored next to the transcripts.
- The run is headless: it transcribes faster than realtime, prints the resulting lines to stdout, saves the new transcript, and exits by itself.
- The new transcript is named by the run's own timestamp; what it came from lives in its frontmatter, not in the file name.

Command:

```bash
transcript --backfill <audio.m4a>
```

## Provenance

Every transcript records the engine that produced it. Backfill transcripts additionally record their source audio — a transcript with a source_audio field is a backfill copy, and the note agents (meeting-note, lecture-note) must skip these when picking the latest transcript.

Frontmatter example:

```bash
engine: openai_whisper-large-v3-v20240930
source_audio: 2026-08-30-192011.mic.m4a
```

## Correction (transcript → corrected transcript)

The correct agent restores domain terms the engine misheard, using the companion memo's background links as a glossary source. The corrected copy lives next to the raw transcript with the corrected suffix, records its input in a source_transcript field, and is what the note agents read when present. Rerun it freely as the glossary improves — a rerun replaces the previous copy. Engine comparisons always use raw transcripts, never corrected ones.

## Note Regeneration (transcript → note)

Notes are cheap derived views over immutable transcripts — regenerate them freely.

- Single note: point the matching note agent (meeting-note or lecture-note) at the transcript. A plain rerun replaces the previous note of the same kind.
- Template experiment: ask the agent to save with a variant tag in the file name instead of overwriting, then compare variants side by side and fold the winner back into the template file.
- After a template change: list transcripts that already have notes of that kind, and rerun the agent over each. Lineage stays correct because every note records its template and source_transcript.
- After a transcript-level backfill: if the new transcript wins, regenerate its notes from the winner.
- After a correction pass: regenerate the transcript's notes so they pick up the corrected sibling.

## Comparing Versions

- Collect the versions: transcripts sharing the same source_audio, plus the original paired by closest timestamp to the audio file.
- Extract only the segments where versions differ, and judge each difference from context.
- For segments that cannot be judged from text alone, give the user the audio position so they can verify by ear.
- Report a per-difference verdict and an overall recommendation on which engine output is better.

## Testing Without Real Audio

To verify the pipeline without an archived recording, synthesize a clip with the macOS built-in TTS, convert it to the archive format, and backfill it. Since the spoken sentence is known, transcription accuracy can be checked against it directly.

```bash
say -v Yuna -o /tmp/test.aiff "검증용 문장"
afconvert /tmp/test.aiff -o /tmp/test.m4a -f m4af -d aac@16000 -c 1
transcript --backfill /tmp/test.m4a
```

## Caveats

- Archived audio is 16kHz mono. Foreign audio at other sample rates is not resampled yet — results will be wrong.
- Backfill leaves the state file untouched and does not re-archive audio.
- Speaker labels are re-derived on every run, so speaker numbering may differ across versions of the same meeting.
