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
- **One folder.** Everything lives in `.maistro/`. Nothing else in your repo changes.
- **Batteries included.** A bundled skill set covers the whole workflow, from grilling an
  idea into a spec to test-driven implementation and two-axis code review.
- **Plain bash.** About 650 lines of readable shell. No daemon, no database, no build step.

## Requirements

- [Claude Code](https://code.claude.com), logged in
- `git`, `tmux`, and `bash` 4+ (macOS or Linux; on Windows, use WSL)
- For pull requests: the [GitHub CLI](https://cli.github.com) (`gh auth login`) and `jq`

## Install

From the root of your project:

```bash
curl -fsSL https://raw.githubusercontent.com/ajitsarkaar/maistro/main/install.sh | bash
```

Or from a clone:

```bash
git clone https://github.com/ajitsarkaar/maistro && ./maistro/install.sh path/to/your/repo
```

Then:

```bash
.maistro/bin/maistro doctor              # check dependencies
git add .maistro && git commit -m "Add maistro"
.maistro/bin/maistro                     # start Maistro
```

**Commit `.maistro/`.** Workers run in worktrees made from your committed history, and
committing the folder shares your configuration with your team. Runtime state
(`.maistro/state/`) and worktrees (`.maistro/worktrees/`) are git-ignored.

On first launch, Maistro runs a short setup: it checks your tools, confirms the base
branch, and helps you fill in `setup-worktree.sh` so fresh worktrees can run your tests.

## How a feature flows

1. **Align.** Describe what you want, then run `/maistro:grill-with-docs`. Maistro
   interviews you until nothing is left to guess, then writes a spec and breaks it into
   tickets with dependencies (`to-spec`, `to-tickets`).
2. **Plan a wave.** Maistro takes every ticket that isn't blocked, picks a model and effort
   for each, and checks that parallel tasks won't touch the same files. It shows you the
   plan and waits for your go.
3. **Dispatch.** Maistro writes a self-contained brief per task and spawns the workers.
4. **Supervise.** Maistro waits without spending tokens and wakes when a worker finishes,
   gets stuck, or has a question. It answers what it can and escalates the rest to you.
5. **Review.** Maistro opens each PR (the worklog becomes the description), reviews the
   diff against the brief, and sends feedback to the worker if needed.
6. **Merge.** You approve; Maistro merges and cleans up, then plans the next wave.

## Bundled skills

maistro ships its own skills as a Claude Code plugin inside `.maistro/plugin/`. They're
loaded into Maistro's and every worker's session automatically: nothing to install, and
nothing added to your global Claude Code setup.

| Skill | Started by | What it does |
|---|---|---|
| `/maistro:grill` | you | Interviews you one question at a time until every open question in a plan is resolved |
| `/maistro:grill-with-docs` | you | A grill that also builds a shared vocabulary in `CONTEXT.md` and records decisions as ADRs |
| `to-spec` | you or Maistro | Turns the conversation into a spec, published as a GitHub issue or a markdown file |
| `to-tickets` | you or Maistro | Splits a spec into thin vertical-slice tickets with blocking edges, ready for parallel workers |
| `/maistro:implement` | you | Builds a spec or ticket in the current session, without dispatching workers |
| `/maistro:handoff` | you | Compresses a long session into a handoff document for a fresh one |
| `tdd` | workers | Red-green-refactor, one vertical slice at a time |
| `code-review` | workers, Maistro | Two separate reviews (Standards and Spec), run as parallel subagents |
| `diagnosing-bugs` | workers | Reproduce, minimize, hypothesize, instrument, fix, and add a regression test |
| `resolving-merge-conflicts` | workers | Resolves conflicts hunk by hunk by reading both sides' intent; merges, never rebases |

Specs and tickets go to GitHub issues when your repo is on GitHub and `gh` is logged in,
and to markdown files under `docs/` otherwise (set `MAISTRO_TRACKER` to choose). You can
edit or add skills in `.maistro/plugin/skills/` like any other file.

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
| `maistro` | Start Maistro in tmux, or attach if it's running |
| `maistro status [id]` | Task overview, or details plus the worker's live screen |
| `maistro doctor` | Check dependencies and configuration |
| `maistro stop` | Close the session (worktrees and branches are kept) |
| `maistro-task new <id>` | Create a task and its brief |
| `maistro-spawn <id> --model M --effort E` | Start a worker |
| `maistro-wait` | Block until a worker needs attention |
| `maistro-send <id> <msg>` | Message a worker |
| `maistro-pr <id>` | Open the task's pull request |
| `maistro-merge <id>` | Merge if open, conflict-free, and green (pinned to the verified head) |
| `maistro-teardown <id>` | Close the worker and remove its worktree (commits stay on the branch) |
| `maistro-config` | Show resolved settings: base branch, tracker, where specs and worklogs go |

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

## Upgrading

```bash
curl -fsSL https://raw.githubusercontent.com/ajitsarkaar/maistro/main/install.sh | bash -s -- --upgrade
```

This replaces scripts, prompts, and templates. Your `config/` is kept; newer defaults are
saved beside it as `*.new` for you to compare.

## Roadmap

- `claude --bg` background sessions as an alternative to tmux
- A turn-end hook so Maistro re-arms supervision automatically
- Multi-repo crews
- GitLab support

## Credits

maistro stands on the shoulders of two projects:

- **[Matt Pocock's skills](https://github.com/mattpocock/skills)** (MIT). maistro's
  bundled skills are modelled on the engineering workflow Matt designed and popularized:
  grilling sessions, a shared-language `CONTEXT.md`, specs and tracer-bullet tickets with
  blocking edges, red-green-refactor TDD, two-axis code review, disciplined bug diagnosis,
  intent-based merge-conflict resolution, and handoffs. The skill texts in maistro are
  original adaptations for a multi-agent setting, not copies. If you work in a single
  session, use Matt's originals: they're excellent.
- **[firstmate](https://github.com/kunchenguid/firstmate)** by Kun Chen (MIT) pioneered
  the "talk to one agent, ship with a crew" agent distro that inspired maistro's shape.

maistro includes no code from either project.

## License

MIT
