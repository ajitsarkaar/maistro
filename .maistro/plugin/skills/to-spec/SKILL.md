---
name: to-spec
description: Turn the current conversation into a written spec and publish it to the configured tracker (a GitHub issue or a local markdown file). Use after a grilling session, or when the user asks to write up or spec out what was discussed.
---

# To spec

Synthesize what has already been discussed. Do not start a new interview: if something
important is genuinely missing, ask at most three targeted questions, then write.

## Steps

1. Run `maistro-config` to learn the tracker and where specs go.
2. Read `CONTEXT.md` if it exists, and use its terms throughout.
3. Identify which modules or areas of the codebase the work touches (look, don't guess),
   and ask the user to confirm them. This keeps the work in the right places.
4. Write the spec using the template below. Describe behaviour, not implementation;
   leave file paths and code out unless a prototype produced a snippet that captures a
   decision (a schema, a state machine, a type) more precisely than prose.
5. Show the spec to the user and revise until they approve it.
6. Publish:
   - **github:** `gh issue create --title "Spec: <title>" --label spec --body-file <file>`
     (create the `spec` label first with `gh label create spec` if it doesn't exist).
   - **local:** write `<docs_dir>/specs/<slug>.md`.
7. Report where it was published and suggest `/maistro:to-tickets` next.

## Template

```markdown
# <Title>

## Problem
<Who has the problem and why it matters. Two to four sentences.>

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
<Key decisions with one-line reasons. Link ADRs if any.>

## Open questions
<Anything deferred, or "None".>
```
