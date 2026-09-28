![maistro_image](assets/maistro.jpeg)

# maistro

**One agent to rule them all.** Talk to one agent; it conducts a crew of them.
*(The "ai" in maistro is the conductor's baton.)*

maistro turns Claude Code into an engineering team for your repository. You talk to one
agent, **Maistro**, who plans the work with you, breaks it into tickets, and dispatches
parallel **workers**. Each worker is a full Claude Code session with its own context, its
own git worktree, and its own branch. Maistro chooses a model and effort level for each
task, supervises the crew, reviews the pull requests, and merges them only when you say so.

Every worker leaves a short worklog on its branch, which becomes the PR description.

```
                you
                 │  "add CSV export and dark mode"
                 ▼
         ┌──────────────┐   plans waves · routes models · reviews PRs · merges on approval
         │   Maistro    │
         └──┬────┬────┬─┘
   maistro-spawn  │    │        (one tmux window each: watch or type into any of them)
            ▼    ▼    ▼
        ┌─────┐┌─────┐┌─────┐
        │ t01 ││ t02 ││ t03 │   opus/high · sonnet/medium · haiku
        └──┬──┘└──┬──┘└──┬──┘
           ▼      ▼      ▼
   .maistro/worktrees/<id>  on branch maistro/<id>  →  push  →  PR  →  your "merge it"
```

## Why maistro

- **One conversation.** You never juggle terminals; Maistro reports what needs you.
- **Real parallelism.** Workers run side by side in isolated worktrees, so they never
  touch each other's files or your checkout.
- **The right model for each job.** Routing rules live in plain English in
  `.maistro/config/dispatch.md`, so you can tune the cost/quality trade-off.
- **Safe by construction.** Maistro can't edit your code, push, or switch branches. Merges
  require a green, conflict-free PR *and* your approval at a Claude Code permission prompt.
- **One folder.** The tool lives in `.maistro/`. Your plans live in a visible `plans/`
  folder next to your code, as plain markdown you can read, edit, and review.
- **Batteries included.** A bundled skill set covers the whole workflow, from planning an
  idea into a spec and tickets to test-driven implementation and two-axis code review.
- **Plain bash.** About 830 lines of readable shell. No daemon, no database, no build step.

## Requirements

- [Claude Code](https://code.claude.com), logged in. maistro runs on Claude Code today;
  other coding agents are on the roadmap.
- `git`, `tmux`, and `bash` 4+ (macOS or Linux; on Windows, use WSL)
- Node.js 18+ for the `npx` installer (optional: there's a shell installer too)
- For pull requests: the [GitHub CLI](https://cli.github.com) (`gh auth login`) and `jq`

## Install

From the root of your project (any git repository):

```bash
npx @ajitsarkaar/maistro init        # installs .maistro/ into this repo
npx @ajitsarkaar/maistro doctor      # checks tmux, Claude Code, gh, and your config
git add .maistro && git commit -m "Add maistro"
npx @ajitsarkaar/maistro             # starts Maistro in tmux
```

Other ways to install (a global `maistro` command, straight from GitHub, or a shell
installer without Node), and complete uninstall steps, are in **[INSTALL.md](INSTALL.md)**.

**Commit `.maistro/`.** Workers run in worktrees made from your committed history, and
committing the folder shares your configuration with your team. Runtime state
(`.maistro/state/`) and worktrees (`.maistro/worktrees/`) are git-ignored.

On first launch, Maistro runs a short setup: it checks your tools, confirms the base
branch, and helps you fill in `setup-worktree.sh` so fresh worktrees can run your tests.

## How a feature flows

1. **Plan.** Run `/maistro:plan` and describe what you want. Maistro interviews you one
   question at a time until nothing is left to guess, then writes a spec and a set of
   tickets with dependencies into `plans/`.
2. **Plan a wave.** Maistro takes every ticket that isn't blocked, picks a model and effort
   for each, and checks that parallel tasks won't touch the same files. It shows you the
   plan and waits for your go.
3. **Dispatch.** Maistro writes a self-contained brief per task and spawns the workers.
4. **Supervise.** Maistro waits without spending tokens and wakes when a worker finishes,
   gets stuck, or has a question. It answers what it can and escalates the rest to you.
5. **Review.** Maistro opens each PR (the worklog becomes the description), reviews the
   diff against the brief, and sends feedback to the worker if needed.
6. **Merge.** You approve; Maistro merges and cleans up, then plans the next wave.

## Planning, locally

Plans are plain files in your repo, so they're versioned, reviewable, and readable by
humans and agents alike:

```
plans/
├── csv-export/
│   ├── spec.md                       what we're building and why
│   └── tickets/
│       ├── 01-export-endpoint.md
│       ├── 02-export-button.md
│       └── 03-large-file-streaming.md
└── decisions/
    └── 0001-stream-large-exports.md  decisions worth remembering
CONTEXT.md                            the project's shared vocabulary
```

Each ticket starts with a small header that maistro keeps up to date:

```markdown
---
id: 03
title: Stream exports larger than 10 MB
status: todo            # todo → in-progress → in-review → done (or dropped)
blocked_by: 01
task:
pr:
---
```

`maistro-ticket list` shows every ticket; `maistro-ticket frontier` shows the ones ready to
start. When Maistro dispatches a ticket it becomes `in-progress`, its PR moves it to
`in-review`, and merging marks it `done`. Commit `plans/` like any other code.

## Bundled skills

maistro ships its own skills as a Claude Code plugin inside `.maistro/plugin/`. They're
loaded into Maistro's and every worker's session automatically: nothing to install, and
nothing added to your global Claude Code setup.

| Skill | Started by | What it does |
|---|---|---|
| `/maistro:plan` | you | Interviews you one question at a time, builds the glossary and decision records, then writes the spec and tickets |
| `to-spec` | Maistro | Writes the agreed plan as `plans/<plan>/spec.md` |
| `to-tickets` | Maistro | Splits a spec into thin vertical-slice tickets with blockers, one file each, ready for parallel workers |
| `/maistro:implement` | you | Builds a spec or ticket in the current session, without dispatching workers |
| `/maistro:handoff` | you | Compresses a long session into a handoff document for a fresh one |
| `tdd` | workers | Red-green-refactor, one vertical slice at a time |
| `code-review` | workers, Maistro | Two separate reviews (Standards and Spec), run as parallel subagents |
| `diagnosing-bugs` | workers | Reproduce, minimize, hypothesize, instrument, fix, and add a regression test |
| `resolving-merge-conflicts` | workers | Resolves conflicts hunk by hunk by reading both sides' intent; merges, never rebases |

You can edit or add skills in `.maistro/plugin/skills/` like any other file.

## Using tmux

Maistro and each worker get their own window in one tmux session (`maistro-<repo>`):

| Keys | Action |
|---|---|
| `Ctrl-b w` | pick a window: Maistro or any worker |
| `Ctrl-b d` | detach; everything keeps running |
| `maistro attach` | come back later |

You can type into any worker's window to steer it directly.

## Configuration

Everything is in `.maistro/config/`:

| File | What it controls |
|---|---|
| `maistro.conf` | Base branch, parallel cap, worker permission mode, worklog folder, merge method |
| `dispatch.md` | Model-routing policy, in plain English. Maistro re-reads it every wave |
| `plugin/skills/` | The bundled skills. Edit them to fit your team's practices |
| `setup-worktree.sh` | Makes each fresh worktree runnable: copies `.env`, installs dependencies |
| `maistro-settings.json` | Maistro's permissions: read and plan freely; no pushes, merges, or branch switches |
| `worker-settings.json` | Worker permissions: commit and push their own branch; no force pushes or merges |

Workers run in Claude Code's `auto` permission mode by default. If you prefer to approve
their commands, set `MAISTRO_WORKER_PERMISSION_MODE="acceptEdits"`. Waiting workers are
visible in their windows and flagged by `maistro-status`.

## Commands

Maistro uses these itself; they're also handy for you.

| Command | Description |
|---|---|
| `maistro init` / `maistro upgrade` | Install maistro into a repo, or update it |
| `maistro` | Start Maistro in tmux, or attach if it's running |
| `maistro status [id]` | Task overview, or details plus the worker's live screen |
| `maistro doctor` | Check dependencies and configuration |
| `maistro stop` | Close the session (worktrees and branches are kept) |
| `maistro uninstall` | Remove maistro from the repo (plans and branches are kept) |
| `maistro-task new <id> --ticket <plan>/<id>` | Create a task from a ticket (the ticket and spec go into the brief) |
| `maistro-spawn <id> --model M --effort E` | Start a worker |
| `maistro-wait` | Block until a worker needs attention |
| `maistro-send <id> <msg>` | Message a worker |
| `maistro-pr <id>` | Open the task's pull request |
| `maistro-merge <id>` | Merge if open, conflict-free, and green (pinned to the verified head) |
| `maistro-teardown <id>` | Close the worker and remove its worktree (commits stay on the branch) |
| `maistro-ticket list\|frontier` | All tickets, or just the ones ready to start |
| `maistro-ticket set <plan>/<id> status=...` | Update a ticket by hand |
| `maistro-config` | Show resolved settings: base branch, harness, where plans and worklogs go |

## Safety model

- Maistro never edits product code, pushes, force-pushes, or switches branches in your
  checkout. These are denied in its Claude Code permissions, not just in its prompt.
- `maistro-merge` is intentionally absent from Maistro's allowlist, so **Claude Code asks
  you before every merge**. It also refuses drafts, conflicts, and any non-green check,
  and pins the merge to the head commit it verified.
- Workers can only push their own `maistro/<id>` branch. Force pushes, rebases, merges,
  and branch deletion are denied.
- Teardown never loses commits (they stay on the branch) and refuses to discard
  uncommitted work without `--force`.

## Upgrading and uninstalling

```bash
npx @ajitsarkaar/maistro@latest upgrade   # update maistro; your config is kept
maistro uninstall                         # remove it; your plans and branches are kept
```

See [INSTALL.md](INSTALL.md#5-uninstall) for the details.

## Roadmap

- **More coding agents.** Everything agent-specific lives in one adapter,
  `.maistro/bin/harness/claude-code.sh`, so adding Codex, OpenCode, and others means
  adding one file each.
- **Issue trackers.** Sync `plans/` tickets with GitHub Issues, then Linear and others.
- `claude --bg` background sessions as an alternative to tmux
- A turn-end hook so Maistro re-arms supervision automatically
- Multi-repo crews and GitLab support

## Credits

maistro stands on the shoulders of two projects:

- **[Matt Pocock's skills](https://github.com/mattpocock/skills)** (MIT). maistro's
  bundled skills are modelled on the engineering workflow Matt designed and popularized:
  grilling sessions (maistro's `plan`), a shared-language `CONTEXT.md`, specs and tracer-bullet tickets with
  blocking edges, red-green-refactor TDD, two-axis code review, disciplined bug diagnosis,
  intent-based merge-conflict resolution, and handoffs. The skill texts in maistro are
  original adaptations for a multi-agent setting, not copies. If you work in a single
  session, use Matt's originals: they're excellent.
- **[firstmate](https://github.com/kunchenguid/firstmate)** by Kun Chen (MIT) pioneered
  the "talk to one agent, ship with a crew" agent distro that inspired maistro's shape.

maistro includes no code from either project.

## License

MIT
