---
name: listen
description: Follows a live Transcript recording alongside the user by reading the new lines of the live transcript every minute, so questions about what is being said get answered from context. Starts only on an explicit request — never together with a recording. Invoke on "같이 들어", "같이 듣자", "같이 들어줘", or "listen".
user-invocable: true
---

# Listen Along

This skill keeps the conversation itself up to date with a live recording. A monitor reads the live transcript once a minute and hands the new lines to the conversation, so the user can ask what the speaker is covering at any moment. It starts only when the user asks; starting a recording never starts it.

## Catching Up

- The target is the live path in the state file; without an active recording, tell the user and stop.
- Read the whole transcript so far once, then note its line count as the covered position.

State and line count:

```bash
cat "$HOME/Library/Application Support/Transcript/state.json"
wc -l < <live_transcript>
```

## Following

- Arm a background monitor with the poll script below, given the live path and the covered position.
- Every minute it emits the new lines under a header naming their line range, and it exits with an end line once the status leaves recording or paused.
- Monitors expire after thirty minutes on most hosts; re-arm from the last line range seen.
- On hosts without a monitor tool, read the new lines on each user question instead.

Poll script:

```bash
f=<live_transcript>; n=<covered_lines>
s="$HOME/Library/Application Support/Transcript/state.json"
while :; do
  sleep 60
  t=$(($(wc -l < "$f")))
  if [ "$t" -gt "$n" ]; then echo "[listen] lines $((n+1))-$t"; sed -n "$((n+1)),${t}p" "$f"; n=$t; fi
  grep -Eq '"status":"(recording|paused)"' "$s" || { echo "[listen] recording ended at line $n"; exit 0; }
done
```

## Using the Context

- Absorb each batch silently: no summary per batch, and at most one short line when a reply is required.
- Read through misheard terms with the topic in mind; the speakers agent owns the written corrections.
- Answer questions from what has been heard so far, naming the time or line range they draw on.
- On "그만 들어" or "stop listening", stop the monitor. When the end line arrives, say that listening has ended.
