---
name: tdd
description: Test-driven development with a red-green-refactor loop, building one thin vertical slice at a time. Use when implementing a feature or fixing a bug where tests can pin down the behaviour.
---

# Test-driven development

Tests are your feedback loop. Without a fast, trustworthy signal about whether the code
works, you are guessing. Work in small cycles.

## The loop

1. **Red:** write one small test for the next piece of behaviour. Run it and watch it
   fail, for the reason you expect. A test you never saw fail proves nothing.
2. **Green:** write the simplest code that makes it pass. Resist building ahead.
3. **Refactor:** with the test green, clean up names, duplication, and structure. Run the
   tests again.
4. Commit when a slice is complete and green. Repeat.

## Slice vertically

Start with the thinnest end-to-end path that does something real (one input, one output,
all the way through), then widen it case by case: edge cases, errors, limits.

## What makes a good test

- It tests **behaviour through a public interface**, not private internals, so you can
  refactor without rewriting tests.
- Its name states the behaviour: `rejects orders above the account's buying power`.
- It is deterministic: no real clocks, randomness, or network unless the test is about
  them. Inject or fake those.
- It has one reason to fail, and its failure message tells you what broke.
- It uses realistic data, and covers the boundaries (zero, empty, one, many, maximum).

## What to avoid

- Tests that mirror the implementation line by line, or assert on how rather than what.
- Mocking the thing under test, or mocking so much that the test proves nothing.
- Snapshot tests of large outputs nobody reads.
- Skipping or loosening a failing test to get to green. If a test is wrong, fix it
  deliberately and say why.

## When TDD doesn't fit

For exploratory spikes, UI layout, or glue code with no logic, write the code first and add
tests for the behaviour that matters afterwards. Say explicitly that you did this.
