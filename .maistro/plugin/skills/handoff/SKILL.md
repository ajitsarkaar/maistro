---
name: handoff
description: Compress the current session into a handoff document so a fresh session (or another agent) can continue the work without the conversation history. Use when context is getting long, or when the user asks for a handoff.
disable-model-invocation: true
---

# Handoff

Write a document that lets someone with **none** of this conversation pick up the work
immediately. Save it to `.maistro/state/handoffs/<YYYY-MM-DD>-<slug>.md` (create the
folder if needed) unless the user names another place, then print the path.

Be concise: aim for under 60 lines. Prefer facts and pointers over narrative.

```markdown
# Handoff: <topic>

## Goal
<What we are trying to achieve, and why.>

## Current state
<What is done, what is in progress. Branches, PRs, task ids.>

## Decisions made
- <decision> (<reason>)

## Next steps
1. <the very next concrete action>

## Watch out for
<Gotchas, failed approaches and why they failed, fragile areas.>

## Pointers
<Key files, specs, tickets, ADRs, commands.>
```

Finish by telling the user how to continue: start a fresh session and say
"Read <path> and continue."
