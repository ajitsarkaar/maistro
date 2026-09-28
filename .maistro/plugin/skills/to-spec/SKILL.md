---
name: to-spec
description: Write the agreed plan as a spec at plans/<plan>/spec.md. Use at the end of a /maistro:plan session, or when the user asks to write up or spec out what was discussed.
---

# To spec

Synthesize what has already been discussed. Don't start a new interview: if something
important is genuinely missing, ask at most three targeted questions, then write.

## Steps

1. Run `maistro-config` to confirm where plans live. Use the plan name agreed with the
   user; if there isn't one yet, propose a short one (lowercase, dashes) and confirm it.
2. Read `CONTEXT.md` if it exists, and use its terms throughout.
3. Identify which modules or areas of the codebase the work touches (look, don't guess),
   and confirm them with the user.
4. Write `plans/<plan>/spec.md` using the template below. Describe behaviour, not
   implementation: leave out file paths and code, unless a prototype produced a snippet
   that captures a decision (a schema, a type, a state machine) more precisely than prose.
5. Show the spec and revise until the user approves it.

## Template

```markdown
# <Title>

## Problem
<Who has the problem and why it matters, in two to four sentences.>

## Outcome
<What is true when this is done, from the user's point of view.>

## Behaviour
<The user-visible behaviour, including edge cases and error handling.>

## Out of scope
<What we are deliberately not doing.>

## Areas affected
<Modules and systems this touches.>

## Acceptance criteria
- [ ] <Observable, testable statement>

## Decisions
<Key decisions with one-line reasons. Link to plans/decisions/ entries if any.>

## Open questions
<Anything deferred, or "None".>
```
