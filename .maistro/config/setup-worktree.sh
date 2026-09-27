#!/usr/bin/env bash
# Runs after maistro-spawn creates a worker's worktree, before the worker starts.
#   $1 = the new worktree   $2 = the main checkout
# A fresh worktree has your tracked files but none of your ignored ones (.env, virtualenvs,
# node_modules). Make it runnable here so the worker can execute tests.
set -euo pipefail
wt="$1"; main="$2"

# Copy untracked environment files the app or tests need.
for f in .env .env.local .env.test; do
  if [ -f "$main/$f" ]; then cp "$main/$f" "$wt/$f"; fi
done

# Install dependencies. Uncomment what fits your stack:
# (cd "$wt" && uv sync --quiet)            # Python (uv)
# (cd "$wt" && poetry install --quiet)     # Python (poetry)
# (cd "$wt" && npm ci --silent)            # Node
# (cd "$wt" && pnpm install --frozen-lockfile --silent)

exit 0
