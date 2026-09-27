# Dispatch rules

Maistro reads this file before every wave and uses it to choose a model and effort level
for each task. It is plain language on purpose: edit it to match your codebase and budget.

## Tiers

- **Heavy: `opus`, effort `high`** (use `xhigh` for the hardest work).
  Ambiguous requirements, cross-cutting design, concurrency, auth or security, money or
  payments, data migrations, or anything where a subtle bug is expensive.
- **Standard: `sonnet`, effort `medium`.** The default. A well-specified vertical slice
  with clear acceptance criteria.
- **Light: `haiku`, effort `default`.** Mechanical work: renames, expand–contract
  migration batches, test scaffolding, docs, dependency bumps.

## Rules

1. When unsure between two tiers, choose the higher one.
2. Never use Light for anything touching auth, money, or database schemas.
3. Escalate: if a worker reports `failed`, or its work fails review twice, tear it down and
   re-spawn the same task one tier higher. It continues on the same branch.
4. In every wave plan, name the tier and the rule you applied for each task.
