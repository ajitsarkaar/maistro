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
MAISTRO_SESSION=""
MAISTRO_MERGE_METHOD="squash"
MAISTRO_MAISTRO_MODEL=""
MAISTRO_HARNESS="claude-code"
MAISTRO_REVIEW_MODE="auto"
MAISTRO_TMUX_STATUS="minimal"
MAISTRO_TMUX_MOUSE="on"
MAISTRO_TMUX_HISTORY=50000
# shellcheck source=/dev/null
[ -f "$MAISTRO_HOME/config/maistro.conf" ] && . "$MAISTRO_HOME/config/maistro.conf"

# Everything maistro writes lives inside .maistro/, so the rest of the repo is never touched.
# These are fixed (set after the config is sourced) and relative to the repo root.
MAISTRO_PLANS_DIR=".maistro/plans"
MAISTRO_GLOSSARY="$MAISTRO_PLANS_DIR/CONTEXT.md"
MAISTRO_WORKLOG_DIR=".maistro/worklogs"
export MAISTRO_WORKLOG_DIR MAISTRO_PLANS_DIR MAISTRO_GLOSSARY
MAISTRO_PLANS="$REPO_ROOT/$MAISTRO_PLANS_DIR"

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
    # symbolic-ref names the current branch even before the first commit.
    git -C "$REPO_ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null || git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD
}

# review_mode: how PRs are opened and merged. "github" when origin is a GitHub remote and the gh CLI is
# installed and logged in; otherwise "local" (review the branch diff, merge with git). Decided on every call,
# so connecting a remote later switches modes without any migration. MAISTRO_REVIEW_MODE can pin it.
review_mode() {
    case "$MAISTRO_REVIEW_MODE" in github|local) printf '%s\n' "$MAISTRO_REVIEW_MODE"; return ;; esac
    if has_origin && git -C "$REPO_ROOT" remote get-url origin | grep -qi 'github' \
        && command -v gh >/dev/null 2>&1 && gh auth token >/dev/null 2>&1; then
        printf 'github\n'
    else
        printf 'local\n'
    fi
}

# base_ref [base]: the newest version of the base branch to build on. That is origin/<base> when it is
# strictly ahead of the local branch (work merged on GitHub), otherwise the local branch (work merged
# locally, perhaps not pushed yet). Callers fetch first when they need an up-to-date origin.
base_ref() {
    local base="${1:-$(base_branch)}" remote_ref local_ref
    remote_ref="$(git -C "$REPO_ROOT" rev-parse --verify --quiet "refs/remotes/origin/$base" || true)"
    local_ref="$(git -C "$REPO_ROOT" rev-parse --verify --quiet "refs/heads/$base" || true)"
    if [ -z "$local_ref" ]; then
        if [ -n "$remote_ref" ]; then printf 'origin/%s\n' "$base"; else printf '%s\n' "$base"; fi
        return
    fi
    if [ -n "$remote_ref" ] && [ "$remote_ref" != "$local_ref" ]; then
        if git -C "$REPO_ROOT" merge-base --is-ancestor "$local_ref" "$remote_ref"; then
            printf 'origin/%s\n' "$base"; return
        fi
        if ! git -C "$REPO_ROOT" merge-base --is-ancestor "$remote_ref" "$local_ref"; then
            info "local $base and origin/$base have diverged; using local $base (run git pull to reconcile)"
        fi
    fi
    printf '%s\n' "$base"
}

# unpushed_count <base>: commits on local <base> that origin/<base> does not have (0 without a remote).
unpushed_count() {
    git -C "$REPO_ROOT" rev-parse --verify --quiet "refs/remotes/origin/$1" >/dev/null || { echo 0; return; }
    git -C "$REPO_ROOT" rev-list --count "origin/$1..refs/heads/$1" 2>/dev/null || echo 0
}

# merge_tree <into> <from>: merges in memory with git merge-tree, touching no checkout. Sets MERGE_TREE (the
# merged tree) and MERGE_CONFLICTS (conflicted files, one per line). Returns 0 if clean, 1 on conflicts.
merge_tree() {
    local output status=0
    output="$(git -C "$REPO_ROOT" merge-tree --write-tree --name-only --no-messages "$1" "$2" 2>/dev/null)" \
        || status=$?
    [ "$status" -le 1 ] || die "git merge-tree failed; local merges need git 2.38 or newer ($(git --version))"
    MERGE_TREE="$(printf '%s\n' "$output" | head -n 1)"
    MERGE_CONFLICTS="$(printf '%s\n' "$output" | tail -n +2)"
    return "$status"
}

# conflict_help <task-id> <base>: how to resolve conflicts between a task's branch and the base branch.
conflict_help() {
    cat <<HELP
To resolve, either:
  - ask the worker:      maistro-send $1 "Merge $2 into your branch, resolve the conflicts, run the tests, commit."
  - or do it yourself in the worker's tmux window or in .maistro/worktrees/$1: git merge $2, fix, git commit.
Then run maistro-pr $1 again and retry the merge.
HELP
}

# worktree_of <branch>: path of the checkout that has <branch> checked out, if any.
worktree_of() {
    git -C "$REPO_ROOT" worktree list --porcelain \
        | awk -v want="branch refs/heads/$1" '/^worktree /{path=substr($0, 10)} $0 == want {print path; exit}'
}

valid_id() {
    [[ "${1:-}" =~ ^[a-z0-9][a-z0-9-]{0,39}$ ]] \
        || die "invalid task id '${1:-}' (lowercase letters, digits, dashes; max 40 chars)"
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

# Name of the window a new session starts with. history-limit only applies to panes created after it is
# set, so the session is created with this placeholder, configured, and the placeholder is removed as soon
# as the first real window exists (see add_window).
MAISTRO_PLACEHOLDER_WINDOW="_maistro_starting"

# ensure_session: create the maistro tmux session if needed, and (re)apply its options.
ensure_session() {
    local s; s="$(session_name)"
    if ! tmux has-session -t "=$s" 2>/dev/null; then
        tmux new-session -d -s "$s" -n "$MAISTRO_PLACEHOLDER_WINDOW" -c "$REPO_ROOT"
    fi
    configure_session "$s"
}

# configure_session <session>: terminal-like scrolling and a quiet status line. Every option is set on
# this session only, so the user's own tmux configuration and other sessions are left alone.
configure_session() {
    local s="$1"
    tmux set-option -t "$s" history-limit "$MAISTRO_TMUX_HISTORY"
    # Mouse mode: the wheel scrolls back through output (and returns to live output at the bottom),
    # clicking a window name switches to it. Hold Option (iTerm2) or Fn (Terminal.app) to select text natively.
    tmux set-option -t "$s" mouse "$MAISTRO_TMUX_MOUSE"
    tmux set-option -t "$s" base-index 1
    tmux set-option -t "$s" renumber-windows on
    case "$MAISTRO_TMUX_STATUS" in
        off) tmux set-option -t "$s" status off ;;
        tmux) ;;
        *)
            tmux set-option -t "$s" status on
            # Terminal's own background and text color; secondary text is greyed out explicitly.
            tmux set-option -t "$s" status-style "bg=default,fg=default"
            tmux set-option -t "$s" status-left "#[bold]maistro#[nobold]#[fg=colour240] · "
            tmux set-option -t "$s" status-left-length 20
            # After the prefix key is pressed, say so; otherwise show the two keys people need most.
            local prefix_hint="#{?client_prefix,#[bold]waiting for a key#[nobold] · ,}"
            local prefix_key="#{s/C-/Ctrl-/:prefix}"
            tmux set-option -t "$s" status-right \
                "#[fg=colour245]$prefix_hint$prefix_key w windows · $prefix_key d detach "
            tmux set-option -t "$s" status-right-length 80
            ;;
    esac
}

# style_window <session:window>: how a window appears in the minimal status line (window options are
# per window, so each window maistro creates is styled as it is added).
style_window() {
    [ "$MAISTRO_TMUX_STATUS" = minimal ] || return 0
    tmux set-option -w -t "$1" window-status-format "#[fg=colour240]#I #[fg=colour245]#W"
    tmux set-option -w -t "$1" window-status-current-format "#[fg=colour240]#I #[fg=default,bold]#W#[nobold]"
    tmux set-option -w -t "$1" window-status-separator "   "
    # A worker waiting for input rings the terminal bell; show which window rang.
    tmux set-option -w -t "$1" window-status-bell-style "fg=colour214,bold"
}

# add_window <name> [new-window options...] <command>: open a detached window in the maistro session.
add_window() {
    local s name="$1"; shift
    ensure_session; s="$(session_name)"
    tmux new-window -d -t "=$s:" -n "$name" "$@"
    style_window "$s:$name"
    if window_alive "$MAISTRO_PLACEHOLDER_WINDOW"; then tmux kill-window -t "=$s:$MAISTRO_PLACEHOLDER_WINDOW"; fi
}


load_harness() {
    local f="$MAISTRO_BIN/harness/$MAISTRO_HARNESS.sh"
    [ -f "$f" ] || die "unknown harness '$MAISTRO_HARNESS' (no $f)"
    # shellcheck source=/dev/null
    . "$f"
}
