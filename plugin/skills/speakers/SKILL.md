---
name: speakers
description: Attributes each utterance of a Transcript transcript to a named speaker and fixes misheard terms from meeting context, live during a recording or as one pass over a saved file, writing a speakers sibling. Invoke on "화자 보정", "화자 분리", "누가 말했는지 정리해줘", or "speakers".
user-invocable: true
---

# Speaker Attribution

The engine's speaker numbers are unreliable: one voice splits across numbers, and one number covers several people. This skill hands the work to this plugin's speakers agent in the background, so the conversation stays free while it rebuilds who said what and writes a speakers sibling. The raw transcript stays immutable.

## Selecting the Target

- While recording, the target is the live path in the state file, in live mode.
- Otherwise use the named file, or the latest transcript excluding notes, memos, and corrected, speakers, or backfill copies, in saved mode.

Live target lookup:

```bash
cat "$HOME/Library/Application Support/Transcript/state.json"
```

## Knowing the Context

The agent cannot see the conversation, so gather its context here: attendees and roles from chat, the companion memo, names spoken in the transcript so far, the topic, and product, system, and team terms for the glossary.

## Launching the Agent

- Launch the speakers agent in the background with the target path, the mode, the last raw line already covered (zero for a fresh start), and the context, then end the turn.
- Names or terms the user mentions mid-recording go to the running agent as a message when the host supports it.
- The agent's final report arrives when it finishes: relay turn counts, notable fixes, uncertainties, and the path.
- On hosts without background subagents, follow the agent document inline.

Agent document:

```bash
../../agents/speakers.md
```
