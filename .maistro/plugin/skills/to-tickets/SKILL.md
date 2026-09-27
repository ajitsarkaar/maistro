---
name: to-tickets
description: Break a spec, plan, or conversation into small tickets that are thin end-to-end slices, each declaring which tickets block it, and publish them to the configured tracker. Use when the user wants work broken down into tickets or tasks for parallel workers.
---

# To tickets

Good tickets make parallel work possible. Each ticket should be something a single worker
can finish in one fresh session, and the dependencies between tickets tell Maistro what
can run at the same time.

## Steps

1. Run `maistro-config` to learn the tracker and where tickets go.
2. Gather the source: the conversation, or the spec the user points to (read the whole
   issue or file, including comments).
3. Look at the code in the affected areas, and use the terms in `CONTEXT.md`. Respect
   existing ADRs.
4. Look for **preparatory refactoring** that would make the feature simple to add, and
   make it the first ticket if it's worth doing.
5. Draft the tickets (rules below), then present them to the user as a numbered list:
   title, what it delivers, and what blocks it.
6. Ask: Is the granularity right? Are the blockers right (each one should truly be needed
   first)? Should anything be merged or split? Iterate until approved.
7. Publish, in dependency order so blockers exist before the tickets that reference them:
   - **github:** one issue per ticket with `gh issue create`, labelled `maistro-ready`
     (create the label if missing). Put `Blocked by: #12, #14` (or `None`) in each body,
     and reference the parent spec issue if there is one.
   - **local:** one file `<docs_dir>/tickets/<slug>.md` containing every ticket in
     dependency order.
8. Summarize the **frontier**: the tickets with no blockers, which can start right away.

## Rules for slicing

- **Vertical, not horizontal.** Each ticket delivers a narrow but complete path through
  every layer it needs (data, logic, interface, tests) so it can be demonstrated or
  verified on its own. "Add the database table" is a horizontal slice; avoid it.
- **One fresh session.** Size each ticket so a worker can finish it without running out
  of context. If you're unsure, split it.
- **Honest blockers.** A ticket is blocked only by tickets whose results it genuinely
  needs. Fewer blockers means more parallelism.
- **Mind the overlap.** Two tickets that will edit the same files can't run in parallel
  safely. Note likely overlaps so Maistro can serialize them.

### Wide mechanical changes: expand, migrate, contract

Some changes (renaming a column, changing a widely used type) break everything at once
and can't be sliced vertically. Sequence them instead:
1. **Expand:** add the new form alongside the old, so nothing breaks.
2. **Migrate:** move callers over in batches (per package or directory), one ticket per
   batch, each blocked only by the expand ticket. These batches can run in parallel.
3. **Contract:** remove the old form, blocked by every migrate ticket.

## Ticket template

```markdown
## <Title>

**What it delivers:** <end-to-end behaviour, from the user's point of view>

**Acceptance criteria**
- [ ] <criterion>

**Blocked by:** <tickets, or "None">
```

Leave out file paths and code; they go stale. The exception is a decision-carrying
snippet from a prototype (schema, type, state machine), marked as such.
