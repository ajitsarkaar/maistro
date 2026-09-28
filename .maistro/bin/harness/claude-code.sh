#!/usr/bin/env bash
# Harness adapter: Claude Code.
# shellcheck disable=SC2034  # HARNESS_* are read by the scripts that source this adapter
# Everything maistro knows about launching a specific coding agent lives in one adapter
# file like this. To support another harness, add bin/harness/<name>.sh defining the same
# three functions, and set MAISTRO_HARNESS=<name> in config/maistro.conf.
#
#   harness_check                         exit non-zero if the agent CLI is unavailable
#   harness_maistro_cmd <first-prompt>    fill HARNESS_CMD with the Maistro session command
#   harness_worker_cmd <id> <model> <effort> <task-dir> <prompt>
#                                         fill HARNESS_CMD with a worker session command

HARNESS_NAME="Claude Code"
HARNESS_CMD=()

harness_check() { command -v claude >/dev/null 2>&1; }

harness_maistro_cmd() {
  HARNESS_CMD=(claude --name maistro
    --plugin-dir "$MAISTRO_HOME/plugin"
    --settings "$MAISTRO_HOME/config/maistro-settings.json"
    --append-system-prompt-file "$MAISTRO_HOME/prompts/maistro.md")
  [ -n "$MAISTRO_MAISTRO_MODEL" ] && HARNESS_CMD+=(--model "$MAISTRO_MAISTRO_MODEL")
  [ -n "${1:-}" ] && HARNESS_CMD+=("$1")
  return 0
}

harness_worker_cmd() {
  local id="$1" model="$2" effort="$3" dir="$4" prompt="$5"
  HARNESS_CMD=(claude --model "$model")
  [ "$effort" = "default" ] || HARNESS_CMD+=(--effort "$effort")
  HARNESS_CMD+=(--permission-mode "$MAISTRO_WORKER_PERMISSION_MODE"
    --settings "$MAISTRO_HOME/config/worker-settings.json"
    --append-system-prompt-file "$MAISTRO_HOME/prompts/worker.md"
    --add-dir "$dir"
    --plugin-dir "$MAISTRO_HOME/plugin"
    --name "maistro-$id"
    "$prompt")
}
