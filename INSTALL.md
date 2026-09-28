# Installing and uninstalling maistro

- [1. Install the requirements](#1-install-the-requirements)
- [2. Install maistro into a repository](#2-install-maistro-into-a-repository)
- [3. First run](#3-first-run)
- [4. Upgrade](#4-upgrade)
- [5. Uninstall](#5-uninstall)
- [Troubleshooting](#troubleshooting)

maistro is installed **per repository**: it adds one folder, `.maistro/`, to the repo you
want to work in. It doesn't install anything into your global Claude Code setup.

## 1. Install the requirements

| Tool | Why | Required? |
|---|---|---|
| [Claude Code](https://code.claude.com) | Runs Maistro and every worker | Yes |
| git | Worktrees and branches for each worker | Yes |
| tmux | One window per agent | Yes |
| bash 4+ | The maistro scripts | Yes (macOS ships an old bash 3.2; the Homebrew step below adds a current one) |
| Node.js 18+ | The `npx` installer | Only for the npm install methods |
| GitHub CLI (`gh`) and `jq` | Opening and merging pull requests | For PRs; planning and building work without them |

**macOS** (with [Homebrew](https://brew.sh)):

```bash
brew install git tmux bash node gh jq
```

**Ubuntu / Debian:**

```bash
sudo apt update && sudo apt install -y git tmux jq
```

For Node.js, use a current version from [nodejs.org](https://nodejs.org/en/download) or
[nvm](https://github.com/nvm-sh/nvm): the `nodejs` package in older Ubuntu releases is too
old. For the GitHub CLI, follow [cli.github.com](https://github.com/cli/cli#installation).

**Windows:** use [WSL](https://learn.microsoft.com/windows/wsl/install) and follow the
Ubuntu steps inside it.

Then install and log in to Claude Code (see [code.claude.com](https://code.claude.com)),
and log in to GitHub if you'll use pull requests:

```bash
claude --version     # confirm Claude Code is installed
gh auth login        # optional: for pull requests
```

## 2. Install maistro into a repository

Go to the root of the git repository you want to use maistro in, then pick **one**
method.

### Option A: npx (recommended)

```bash
npx @ajitsarkaar/maistro init
```

### Option B: global install, for a shorter command

```bash
npm install -g @ajitsarkaar/maistro
maistro init
```

After this, `maistro` works in any repository on your machine.

### Option C: straight from GitHub

Installs the latest code on `main`, even if it hasn't been published to npm yet:

```bash
npx github:ajitsarkaar/maistro init
```

### Option D: shell installer, no Node needed

```bash
curl -fsSL https://raw.githubusercontent.com/ajitsarkaar/maistro/main/install.sh | bash
```

### Then, whichever option you used

```bash
maistro doctor       # or: npx @ajitsarkaar/maistro doctor, or: .maistro/bin/maistro doctor
git add .maistro && git commit -m "Add maistro"
```

**Commit `.maistro/`.** Workers run in fresh checkouts made from your committed history,
so they only see maistro's files if they're committed. It also shares your configuration
with your team. Runtime state (`.maistro/state/`) and worker checkouts
(`.maistro/worktrees/`) are git-ignored automatically.

## 3. First run

```bash
maistro              # or: npx @ajitsarkaar/maistro, or: .maistro/bin/maistro
```

This opens a tmux session with Maistro in the first window. On the first run, Maistro
checks your setup and helps you fill in `.maistro/config/setup-worktree.sh`, the script
that makes each worker's fresh checkout runnable (copying `.env`, installing
dependencies). Then run `/maistro:plan` to plan your first feature.

tmux basics: `Ctrl-b w` switches between Maistro and the workers, `Ctrl-b d` detaches
(everything keeps running), and `maistro attach` brings you back.

## 4. Upgrade

```bash
npx @ajitsarkaar/maistro@latest upgrade
# or, with a global install:
npm update -g @ajitsarkaar/maistro && maistro upgrade
```

This replaces maistro's scripts, prompts, templates and skills. Your settings in
`.maistro/config/` are kept; when a default changed, the new version is saved beside
yours as `<file>.new` so you can compare and merge. Your plans and any running tasks are
never touched. Commit the result: `git add .maistro && git commit -m "Upgrade maistro"`.

## 5. Uninstall

### Remove maistro from a repository

From anywhere inside the repository, **outside** the maistro tmux session (detach first
with `Ctrl-b d`):

```bash
maistro uninstall
# or: npx @ajitsarkaar/maistro uninstall, or: .maistro/bin/maistro uninstall
```

It shows exactly what it will do and asks for confirmation, then:

1. closes the tmux session (Maistro and every worker window)
2. removes every worker checkout in `.maistro/worktrees/`
3. deletes `.maistro/`

It **keeps** everything that's yours: `plans/`, `CONTEXT.md`, the worklogs in
`docs/worklogs/`, and every `maistro/*` branch with its commits. If a worker has
uncommitted changes, it stops and tells you which one, so nothing is lost by accident.

| Flag | Effect |
|---|---|
| `--delete-branches` | Also delete the local `maistro/*` branches |
| `--force` | Proceed even if a worker has uncommitted changes (they are discarded) |
| `--yes` | Skip the confirmation prompt |

Then commit the removal:

```bash
git add -A .maistro && git commit -m "Remove maistro"
```

### Optional: clean up the rest

```bash
# maistro branches you pushed to GitHub
git push origin --delete maistro/<task-id>

# planning files, if you no longer want them (they're ordinary files in your repo)
git rm -r plans CONTEXT.md docs/worklogs && git commit -m "Remove maistro plans"
```

### Remove the maistro command from your machine

If you installed it globally (Option B):

```bash
npm uninstall -g @ajitsarkaar/maistro
```

If you only used `npx` (Options A and C), nothing stays installed. npx keeps a download
cache, which you can clear with `rm -rf ~/.npm/_npx` if you want it gone too.

maistro never changes your global Claude Code configuration, so there's nothing to clean
up there. The conversations Maistro and the workers had are stored with your other Claude
Code sessions, like any conversation.

## Troubleshooting

**`npm error 404 Not Found` for `@ajitsarkaar/maistro`.** The version you asked for isn't
on npm (for example, before the first release). Use Option C to install from GitHub.

**`maistro: command not found`.** You haven't installed globally. Use
`npx @ajitsarkaar/maistro` or `.maistro/bin/maistro` instead, or run Option B.

**`maistro is not installed in this repository`.** Run the command from inside a repo
where you ran `init`, or run `maistro init` first.

**`is not inside a git repository`.** maistro needs git. Run `git init` (and make a first
commit) first.

**Workers can't run tests.** Their fresh checkout lacks your ignored files (`.env`,
virtualenvs, `node_modules`). Fill in `.maistro/config/setup-worktree.sh`; Maistro offers
to help on first run.

**Something looks wrong.** `maistro doctor` checks every requirement and setting and says
what to fix.
