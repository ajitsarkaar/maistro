---
name: diagnosing-bugs
description: A disciplined loop for hard bugs and performance regressions - reproduce with a failing check, minimize, hypothesize, instrument, fix, and lock in a regression test. Use when a bug is not obvious after a first look, or when a fix attempt has already failed.
---

# Diagnosing bugs

Guessing at fixes wastes time and hides the real cause. Work through these phases in
order, and don't skip ahead.

1. **Reproduce.** Build a check that fails *because of this bug*: a test, a script, or a
   command with a clear pass/fail result. If you can't reproduce the bug, you can't know
   you fixed it. Say so, and gather more information instead of guessing.
2. **Minimize.** Shrink the failing case until removing anything more makes it pass.
   Smaller inputs, fewer steps, less code involved.
3. **Hypothesize.** Write down two or three candidate causes, each with a prediction you
   could check ("if X is the cause, then Y will show Z").
4. **Instrument.** Test the predictions with logs, assertions, a debugger, or bisection
   (`git bisect` for regressions). Discard hypotheses that the evidence contradicts.
   Change one thing at a time.
5. **Fix** the root cause, not the symptom. If you can only fix a symptom, say so and
   explain why.
6. **Lock it in.** Keep the reproduction as a regression test that fails without the fix
   and passes with it. Run the full suite. Remove temporary instrumentation.

Report the root cause in one or two sentences, the evidence that confirmed it, the fix,
and the regression test.

For performance problems, the reproduction is a measurement: record a baseline number,
change one thing, and measure again.
