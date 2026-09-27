#!/usr/bin/env bash
# Shared helpers for maistro scripts. Sourced by every maistro-* command, never executed directly.
# shellcheck disable=SC2034  # variables are used by the scripts that source this file
set -euo pipefail

MAISTRO_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAISTRO_HOME="$(cd "$MAISTRO_BIN/.." && pwd)"
REPO_ROOT="$(cd "$MAISTRO_HOME/.." && pwd)"
MAISTRO_STATE="$MAISTRO_HOME/state"
MAISTRO_TASKS="$MAISTRO_STATE/tasks"
MAISTRO_WORKTREES="$MAISTRO_HOME/worktrees"
export MAISTRO_HOME MAISTRO_BIN REPO_ROOT

# Defaults; overridden by .maistro/config/maistro.conf
MAISTRO_BASE_BRANCH=""
MAISTRO_MAX_PARALLEL=4
MAISTRO_WORKER_PERMISSION_MODE="auto"
MAISTRO_WORKLOG_DIR="docs/worklogs"
MAISTRO_SESSION=""
MAISTRO_MERGE_METHOD="squash"
MAISTRO_MAISTRO_MODEL=""
MAISTRO_TRACKER="auto"
MAISTRO_DOCS_DIR="docs"
# shellcheck source=/dev/null
[ -f "$MAISTRO_HOME/config/maistro.conf" ] && . "$MAISTRO_HOME/config/maistro.conf"
export MAISTRO_WORKLOG_DIR MAISTRO_DOCS_DIR

die()  { printf 'maistro: %s\n' "$*" >&2; exit 1; }
info() { printf 'maistro: %s\n' "$*" >&2; }
now()  { date -u +%Y-%m-%dT%H:%M:%SZ; }

require() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1${2:+ ($2)}"; }

session_name() {
  if [ -n "$MAISTRO_SESSION" ]; then printf '%s\n' "$MAISTRO_SESSION"; return; fi
  printf 'maistro-%s\n' "$(printf '%s' "$(basename "$REPO_ROOT")" | tr -c 'A-Za-z0-9_-' '-')"
}

has_origin() { git -C "$REPO_ROOT" remote get-url origin >/dev/null 2>&1; }

base_branch() {
  if [ -n "$MAISTRO_BASE_BRANCH" ]; then printf '%s\n' "$MAISTRO_BASE_BRANCH"; return; fi
  local b
  b="$(git -C "$REPO_ROOT" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [ -n "$b" ]; then printf '%s\n' "${b#origin/}"; return; fi
  for b in main master; do
    if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$b"; then printf '%s\n' "$b"; return; fi
  done
  git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD
}

valid_id() {
  [[ "${1:-}" =~ ^[a-z0-9][a-z0-9-]{0,39}$ ]] || die "invalid task id '${1:-}' (lowercase letters, digits, dashes; max 40 chars)"
}

task_dir() { printf '%s/%s\n' "$MAISTRO_TASKS" "$1"; }
require_task() { [ -d "$(task_dir "$1")" ] || die "no such task: $1 (see maistro-task list)"; }

# meta is an append-only key=value file; the last value for a key wins.
meta_get() {
  local f; f="$(task_dir "$1")/meta"
  [ -f "$f" ] || return 0
  sed -n "s/^$2=//p" "$f" | tail -n 1
}
meta_set() { printf '%s=%s\n' "$2" "$3" >> "$(task_dir "$1")/meta"; }

last_verb() {
  local log; log="$(task_dir "$1")/status.log"
  [ -s "$log" ] || { printf 'none\n'; return; }
  tail -n 1 "$log" | cut -f2
}

window_alive() {
  local names
  names="$(tmux list-windows -t "=$(session_name)" -F '#{window_name}' 2>/dev/null || true)"
  printf '%s\n' "$names" | grep -qx -- "$1"
}

ensure_session() {
  local s; s="$(session_name)"
  if ! tmux has-session -t "=$s" 2>/dev/null; then
    tmux new-session -d -s "$s" -n shell -c "$REPO_ROOT"
  fi
}

# Where planning skills publish specs and tickets: github or local.
tracker() {
  case "$MAISTRO_TRACKER" in
    github|local) printf '%s\n' "$MAISTRO_TRACKER"; return ;;
  esac
  local url; url="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || true)"
  if [[ "$url" == *github.com* ]] && command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    printf 'github\n'
  else
    printf 'local\n'
  fi
}
