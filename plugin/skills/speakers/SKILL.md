---
name: speakers
description: Attributes each utterance of a Transcript transcript to a named speaker and fixes misheard terms from meeting context, live during a recording or as one pass over a saved file, writing a speakers sibling. Invoke on "화자 보정", "화자 분리", "누가 말했는지 정리해줘", or "speakers".
user-invocable: true
---

# Speaker Attribution

The engine's speaker numbers are unreliable: one voice splits across numbers, and one number covers several people. This skill rebuilds who said what, fixes misheard words, and writes a speakers sibling. The raw transcript stays immutable.

## Selecting the Target

- While recording, the target is the live path in the state file: run the live loop.
- Otherwise use the named file, or the latest transcript excluding notes, memos, and corrected, speakers, or backfill copies, and run one full pass.

Live target lookup:

```bash
cat "$HOME/Library/Application Support/Transcript/state.json"
```

## Knowing the Context

Collect the cast and a glossary first: attendees and roles from chat, the companion memo, names spoken in the transcript, and product, system, and team terms. Self-references, people addressed by name, and who explains or asks identify speakers. Until names surface, use role labels.

## Live Loop

- Arm a Monitor (or a background command) on the command below with the live path; each event is a batch of new raw lines. It exits when recording ends; re-arm it if it expires.
- Attribute and correct each batch, then append it to the speakers file. Rewrite only the trailing turn when a later line proves it wrong; earlier turns wait for the final pass.

Monitor command:

```bash
f=<live transcript path>; n=$(wc -l < "$f"); while true; do sleep 60; m=$(wc -l < "$f"); if [ "$m" -gt "$n" ]; then sed -n "$((n+1)),${m}p" "$f"; n=$m; fi; grep -q '^status: live' "$f" || { echo "[recording ended]"; exit 0; }; done
```

## Rules

- Ignore the engine's numbers; judge each utterance by content and flow.
- Label turns with the speaker's name in brackets; add a question mark when unsure, and a slash between two candidates.
- Merge fragments of one speaker's sentence; split a line holding two speakers.
- Replace a misheard word only when the glossary or context makes the intended term certain, such as names, products, and domain terms; otherwise keep it.
- Drop lone filler hallucinations and empty dash lines. Mask spoken passwords, credentials, and account numbers.

## Finalizing

When recording ends, or for a saved file, rewrite the whole speakers file in one pass so later evidence fixes earlier guesses. Copy the frontmatter, set status to speakers, add source_transcript, and note that names are inferred. Report turn counts per speaker, notable word fixes, uncertainties, and the path. Local markdown only.

Naming example:

```bash
~/Documents/Transcript/2026-11-03-131258.md
~/Documents/Transcript/2026-11-03-131258.speakers.md
```
