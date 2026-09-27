---
name: implement
description: Implement a spec or ticket in this session, without dispatching workers. Use when the user wants to build something directly in the current session.
disable-model-invocation: true
---

# Implement

Build the work described by the spec or ticket the user points to, in this session.

1. Read the spec or ticket in full, and `CONTEXT.md` if it exists.
2. If you're on the base branch, create a feature branch first.
3. Agree on the **seams** with the user in one short message: the few interfaces where
   tests will pin the behaviour down.
4. Build with the `tdd` skill at those seams, one vertical slice at a time.
5. Run the typechecker and focused tests often; run the full test suite once at the end.
6. Review your own diff with the `code-review` skill and fix what it finds.
7. Commit in small, logical commits, then summarize what changed and how it was verified.

Inside a maistro worker session, follow your worker instructions instead; they already
include these steps.
