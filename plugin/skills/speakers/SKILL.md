---
name: speakers
description: Attributes each utterance of a Transcript transcript to a named speaker from meeting context, live during a recording or as one pass over a saved file, and writes the result to a speakers sibling. Invoke on "화자 보정", "화자 분리", "누가 말했는지 정리해줘", or "speakers".
user-invocable: true
---

# Speaker Attribution

The engine's speaker numbers are unreliable: one voice splits across numbers, and one number covers several people. This skill rebuilds who said what from the conversation and writes it to a speakers sibling. The raw transcript stays immutable; the speakers file is a derived copy with lineage.

## Selecting the Target

- While recording, the target is the live path in the state file: run the live loop.
- Otherwise use the named file, or the latest transcript excluding notes, memos, and corrected, speakers, or backfill copies, and run one full pass.

Live target lookup:

```bash
cat "$HOME/Library/Application Support/Transcript/state.json"
```

## Knowing the Participants

Collect the cast first: attendees and roles from chat, the companion memo, and names spoken in the transcript. Use self-references, people addressed by name, who explains and who asks, and topic ownership. Until names surface, use role labels such as presenter or questioner.

## Live Loop

- Arm a Monitor (or, without one, a background command) on the command below with the live path; each event is a batch of new raw lines. It exits when recording ends; re-arm it if it expires.
- On each batch, attribute the new lines and append them to the speakers file. Rewrite only the trailing turn when a later line proves it wrong; earlier turns wait for the final pass.

Monitor command:

```bash
f=<live transcript path>; n=$(wc -l < "$f"); while true; do sleep 60; m=$(wc -l < "$f"); if [ "$m" -gt "$n" ]; then sed -n "$((n+1)),${m}p" "$f"; n=$m; fi; grep -q '^status: live' "$f" || { echo "[recording ended]"; exit 0; }; done
```

## Attribution Rules

- Ignore the engine's numbers; judge each utterance by content and flow.
- Label each turn with the speaker's name in brackets. Append a question mark when unsure, and join two candidates with a slash when they cannot be told apart.
- Merge consecutive fragments of one speaker's sentence; split a line that clearly holds two speakers.
- Keep the wording. Drop only lone filler hallucinations and empty dash lines.
- Replace spoken passwords, credentials, and account numbers with a placeholder.

## Finalizing

When the recording ends, or for a saved file, rewrite the whole speakers file in one pass so later evidence fixes earlier guesses. Copy the original frontmatter, set status to speakers, add a source_transcript field, and note that names are inferred. Report per-speaker turn counts, main uncertainties, and the path. Local markdown is the only output.

Naming example:

```bash
~/Documents/Transcript/2026-11-03-131258.md
~/Documents/Transcript/2026-11-03-131258.speakers.md
```
