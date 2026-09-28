---
name: plan
description: Start planning a feature or change - interview the user one question at a time until nothing is left to guess, build a shared vocabulary as you go, then write the plan (spec and tickets) into the local plans folder. Use when the user runs /maistro:plan or wants to plan work before building it.
disable-model-invocation: true
---

# Plan

The most common reason software goes wrong is that the builder and the person who wanted
it had different pictures in their heads. This session closes that gap *before* any code
is written, and ends with a plan on disk that Maistro can dispatch to workers.

Run `maistro-config` first to see where plans, the glossary, and decisions live.

## 1. Interview

1. **Restate the idea** in two or three sentences and ask the user to correct it.
2. **Ask one question at a time.** Never send a list of questions. Wait for each answer.
3. **Walk the decision tree.** Every answer opens or closes branches; follow each branch
   until it is resolved, then move to the next. Cover, as they apply:
   - who uses this, and what they are trying to get done
   - the happy path, step by step
   - edge cases, empty states, errors, limits, and concurrency
   - what is explicitly *not* included
   - data: what is stored, where, for how long, and who can see it
   - how we will know it works (acceptance criteria, and how to test them)
   - constraints: performance, security, compatibility, deadlines
4. **Recommend** with each question when you have a view ("I'd suggest X because Y. Does
   that work?"). This makes answering fast.
5. **Push back** on vague answers ("fast": how fast, measured how?), on contradictions
   with earlier answers, and on scope that is quietly growing.
6. **Look before you ask.** If the code can answer a question, read the code instead.

Keep a running decision log in the conversation, one line each:
`Decided: <decision> (<reason>)`. If a later answer changes an earlier decision, say so.

## 2. Build the shared vocabulary as you go

Agents and humans waste words and make mistakes when they use different names for the same
thing. Maintain `CONTEXT.md` at the repo root as the project's glossary:

- Read it first if it exists, and use its terms in your questions.
- When the user describes a concept with a phrase ("an order that only partly executed"),
  propose a term ("partial fill") and ask them to confirm it.
- Challenge terms that are ambiguous, overloaded, or clash with existing ones.
- Update the file as terms are agreed:

```markdown
# Context

## Glossary
- **Partial fill**: an order executed for less than its full quantity. The rest stays open.

## Relationships
- An **Order** has zero or more **Fills**.
```

## 3. Record the decisions that matter

When a decision is hard to reverse, surprising to a newcomer, or the result of a real
trade-off, record it in `plans/decisions/NNNN-<slug>.md` (numbered sequentially). Skip
trivia.

```markdown
# NNNN. <Decision in a few words>

- Status: accepted
- Date: <YYYY-MM-DD>

## Context
<What forced the decision, in two to five sentences.>

## Decision
<What we chose.>

## Consequences
<What gets easier, what gets harder, and what we are giving up.>
```

## 4. Write the plan

Stop interviewing when every branch is resolved or explicitly deferred by the user. Then:

1. Show a one-paragraph summary of what will be built, plus the decision log, and get a
   yes.
2. Choose a short plan name (lowercase, dashes, e.g. `csv-export`) and confirm it.
3. Write the spec with the `to-spec` skill.
4. Break it into tickets with the `to-tickets` skill.
5. Tell the user what was written, show `maistro-ticket list <plan>`, and suggest they
   commit `plans/` and `CONTEXT.md` to the base branch before Maistro dispatches workers:
   workers branch from there.

For a small, clear change, keep the interview short: a few questions, a brief spec, and
possibly a single ticket.
