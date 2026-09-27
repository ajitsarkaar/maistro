---
name: resolving-merge-conflicts
description: Resolve git merge conflicts hunk by hunk by understanding what each side intended, then finish the merge with tests passing. Use when a merge has conflicts, or when asked to bring a branch up to date with the base branch.
---

# Resolving merge conflicts

In maistro, branches are updated by **merging** the base branch in, never by rebasing,
so nothing ever needs a force push.

## Steps

1. Start (or continue) the merge: `git fetch origin && git merge origin/<base>` (the base
   branch is in `maistro-config`). List the conflicted files with `git status`.
2. For each conflicted hunk, **understand both sides before editing**:
   - What was your branch trying to do here? (Your commits, your brief.)
   - What was the base branch trying to do? Find the commit that changed it:
     `git log -p origin/<base> -- <file>` and read its message and any linked PR.
   - Decide the result that satisfies **both** intents. Usually that is a combination,
     not a choice of one side.
3. Never resolve by blindly taking "ours" or "theirs" for a whole file. That silently
   throws away someone's work.
4. After resolving all files, search for leftover markers (`<<<<<<<`, `=======`,
   `>>>>>>>`), then run the typechecker and the tests. Conflicts that compile can still
   be wrong.
5. `git add` the files and `git commit` to conclude the merge, with a message that notes
   any non-obvious resolutions.
6. Do not abort the merge to avoid a hard conflict. If a conflict truly needs a human
   decision (both sides changed the same behaviour in incompatible ways), stop and ask,
   explaining the two intents and your recommendation.
