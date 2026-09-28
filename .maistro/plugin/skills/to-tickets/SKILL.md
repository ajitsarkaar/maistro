---
name: to-tickets
description: Break a plan's spec into small tickets - thin end-to-end slices, each declaring which tickets block it - written as files in plans/<plan>/tickets/. Use at the end of a /maistro:plan session, or when the user wants work broken into tickets for parallel workers.
---

# To tickets

Good tickets make parallel work possible. Each ticket should be something one worker can
finish in one fresh session, and the blockers between tickets tell Maistro what can run
at the same time.

## Steps

1. Read `plans/<plan>/spec.md` in full, and `CONTEXT.md` if it exists. Respect the
   decisions in `plans/decisions/`.
2. Look at the code in the affected areas.
3. Look for **preparatory refactoring** that would make the feature simple to add. If it's
   worth doing, make it the first ticket.
4. Draft the tickets (rules below) and present them as a numbered list: title, what it
   delivers, and what blocks it.
5. Ask: Is the granularity right? Are the blockers right (each one truly needed first)?
   Should anything be merged or split? Iterate until the user approves.
6. Write one file per ticket: `plans/<plan>/tickets/<id>-<slug>.md`, with ids `01`, `02`,
   and so on, numbered so every blocker has a lower id than the tickets it blocks.
7. Run `maistro-ticket list <plan>` to check the files parse, then
   `maistro-ticket frontier <plan>` to show which tickets can start right away.

## Rules for slicing

- **Vertical, not horizontal.** Each ticket delivers a narrow but complete path through
  every layer it needs (data, logic, interface, tests), so it can be demonstrated or
  verified on its own. "Add the database table" is a horizontal slice; avoid it.
- **One fresh session.** Size each ticket so a worker can finish it without running out
  of context. If unsure, split it.
- **Honest blockers.** A ticket is blocked only by tickets whose results it genuinely
  needs. Fewer blockers means more parallelism.
- **Mind the overlap.** Two tickets that will edit the same files can't safely run in
  parallel. Note likely overlaps under "Notes" so Maistro can serialize them.

### Wide mechanical changes: expand, migrate, contract

Some changes (renaming a column, changing a widely used type) break everything at once
and can't be sliced vertically. Sequence them instead:
1. **Expand:** add the new form alongside the old, so nothing breaks.
2. **Migrate:** move callers over in batches (per package or directory), one ticket per
   batch, each blocked only by the expand ticket. These batches can run in parallel.
3. **Contract:** remove the old form, blocked by every migrate ticket.

## Ticket file format

The header between the `---` lines is read by `maistro-ticket`, so keep its fields
exactly as shown. `blocked_by` lists ticket ids from the same plan, or `none`.

```markdown
---
id: 03
title: Export trades as CSV
status: todo
blocked_by: 01, 02
task:
pr:
---

## What it delivers
<The end-to-end behaviour, from the user's point of view.>

## Acceptance criteria
- [ ] <criterion>

## Notes
<Likely file overlaps with other tickets, hints, gotchas. Optional.>
```

Leave out file paths and code in the body; they go stale. The exception is a
decision-carrying snippet from a prototype (a schema, a type, a state machine), marked as
such. Maistro fills in `status`, `task`, and `pr` as the work progresses.
