---
name: code-review
description: Review a diff on two separate axes, Standards (is it well written, by this repo's conventions) and Spec (does it do exactly what was asked), and report prioritized findings. Use before committing or merging, or when asked to review a branch or PR.
---

# Code review

A review mixes two questions that are easy to blur: *is this good code?* and *is this the
right code?* Answer them separately.

## 1. Establish the diff and the intent

- **The diff:** for a branch, `git diff origin/<base>...HEAD` (use the base branch from
  `maistro-config`); for a PR, `gh pr diff <url>`.
- **The intent:** the brief, ticket, spec, or issue the change is meant to satisfy. If you
  can't find one, ask. A Spec review without a spec is guesswork.

## 2. Review each axis separately

If you can run subagents, review the two axes in **parallel subagents**, one per axis, so
neither review colours the other. Give each subagent the diff, the axis instructions
below, and (for Spec) the intent. Otherwise, do the two passes one after the other.

### Standards: is it well written?
- Follows the repo's conventions: read nearby code, `CONTEXT.md` terms, lint config, and
  any contributing guide.
- Correctness risks: error handling, null and empty cases, off-by-one, resource cleanup,
  concurrency, injection and other security issues.
- Common smells: long functions, duplicated logic, unclear names, feature envy, deep
  nesting, magic numbers, dead code, leftover debugging output, commented-out code.
- Tests: meaningful, testing behaviour through public interfaces, covering edge cases.

### Spec: is it the right code?
- Every acceptance criterion is met, and you can point to where.
- Nothing extra: no scope creep, unrequested features, or unrelated refactors.
- Edge cases and error behaviour match what the spec says.
- Anything the spec left ambiguous is flagged rather than silently decided.

## 3. Report

Merge the findings into one list, most important first:

```markdown
## Review: <branch or PR>

**Verdict:** approve | approve with nits | changes requested

### Blocking
1. [Spec] <finding> (file:line). <why it matters>. Suggested fix: <fix>

### Should fix
1. [Standards] ...

### Nits
1. ...
```

Only mark something blocking if it is a real defect, a missed requirement, or a real risk.
Be specific: point at the line, explain the consequence, and suggest a fix.
