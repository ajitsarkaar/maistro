---
name: grill
description: Interview the user relentlessly about a plan, feature, or decision until every open question is resolved. Use when the user asks to be grilled, or wants to pressure-test an idea before building it.
disable-model-invocation: true
---

# Grill

The most common reason software goes wrong is that the builder and the person who wanted
it had different pictures in their heads. Your job is to close that gap *before* any code
is written, by asking questions until there is nothing left to guess.

## How to run the session

1. **Restate the idea** in two or three sentences and ask the user to correct it.
2. **Ask one question at a time.** Never send a list of questions. Wait for the answer.
3. **Walk the decision tree.** Every answer opens or closes branches. Keep going down each
   branch until it is resolved, then move to the next. Cover, as they apply:
   - who uses this, and what they are trying to get done
   - the happy path, step by step
   - edge cases, empty states, errors, limits, and concurrency
   - what is explicitly *not* included
   - data: what is stored, where, for how long, and who can see it
   - how we will know it works (acceptance criteria and how to test them)
   - constraints: performance, security, compatibility, deadlines
4. **Offer your recommendation** with each question when you have one ("I'd suggest X
   because Y. Does that work?"). This makes answering fast.
5. **Push back** on vague answers ("it should be fast": how fast, measured how?), on
   contradictions with earlier answers, and on scope that is quietly growing.
6. **Explore the code** when a question can be answered by reading the repo instead of
   asking the user. Don't ask what you can look up.

## Keep a decision log

As you go, keep a running list of decisions in the conversation, one line each:
`Decided: <decision> (<reason>)`. When a later answer changes an earlier decision, say so
explicitly.

## Finish

Stop when every branch is resolved or the user explicitly defers it. Then present:
- a one-paragraph summary of what will be built
- the decision log
- open questions deferred by the user, if any

Suggest `/maistro:to-spec` as the next step.
