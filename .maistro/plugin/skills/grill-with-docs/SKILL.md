---
name: grill-with-docs
description: A grilling session that also builds the project's shared vocabulary (CONTEXT.md) and records hard-to-reverse decisions as ADRs. Use when starting significant work in a codebase, or when the user asks for grill-with-docs.
disable-model-invocation: true
---

# Grill with docs

Run the `grill` process (one question at a time, walk the decision tree, recommend,
push back), and while you do it, maintain two kinds of documents. Run `maistro-config`
to find where they live (`glossary=` and `adrs=`).

## 1. A shared vocabulary: CONTEXT.md

Agents and humans waste words and make mistakes when they use different names for the same
thing. A glossary fixes that: one agreed term per concept, used everywhere, in
conversation, in code, and in tickets.

- Read `CONTEXT.md` first if it exists. Use its terms in your questions.
- When the user describes a concept with a phrase ("the thing that happens when an order
  is only partly filled"), propose a term ("partial fill") and ask them to confirm it.
- Challenge terms that are ambiguous, overloaded, or clash with existing ones.
- Update `CONTEXT.md` as terms are agreed. Keep it tight:

```markdown
# Context

## Glossary
- **Partial fill**: an order executed for less than its full quantity. The remainder stays open.

## Relationships
- An **Order** has zero or more **Fills**.
```

## 2. Architecture Decision Records (ADRs)

Record a decision as an ADR when it is hard to reverse, surprising to a newcomer, or the
result of a real trade-off. Do not record trivia. Number them sequentially:

```markdown
# NNNN. <Decision in a few words>

- Status: accepted
- Date: <YYYY-MM-DD>

## Context
<What forced the decision. Two to five sentences.>

## Decision
<What we chose.>

## Consequences
<What gets easier, what gets harder, what we are giving up.>
```

## Finish

Summarize as in `grill`, then list the glossary terms added or changed and the ADRs
written. Remind the user that these files are in the main checkout and must be committed
to the base branch before workers are dispatched, because workers branch from there.
