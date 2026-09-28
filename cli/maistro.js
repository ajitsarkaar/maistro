#!/usr/bin/env node
// @ajitsarkaar/maistro (the maistro CLI): install maistro into a git repository, keep it up to date, and run it.
//
//   maistro init [path]      install .maistro/ into the repo containing [path] (default: here)
//   maistro upgrade [path]   refresh scripts, prompts, templates and skills; keep your config
//   maistro [command]        run the repo's own maistro (start, attach, status, doctor, stop, uninstall)
//
// No dependencies: Node's standard library only.
'use strict';

const fs = require('fs');
const path = require('path');
const { execFileSync, spawnSync } = require('child_process');

const PKG_ROOT = path.resolve(__dirname, '..');
const PAYLOAD = path.join(PKG_ROOT, '.maistro');
const VERSION = require(path.join(PKG_ROOT, 'package.json')).version;

// Replaced wholesale on upgrade. config/ is the user's and is never overwritten.
const TOOL_PARTS = ['bin', 'prompts', 'templates', 'plugin'];
// npm strips .gitignore files from published packages, so the CLI writes this one itself.
const GITIGNORE = '# Runtime state and worker checkouts are local to each machine.\nstate/\nworktrees/\n';
const REPO_COMMANDS = new Set(['start', 'attach', 'status', 'doctor', 'stop', 'uninstall']);

const out = (msg = '') => process.stdout.write(msg + '\n');
function fail(msg) {
  process.stderr.write(`maistro: ${msg}\n`);
  process.exit(1);
}

function repoRoot(dir) {
  try {
    return execFileSync('git', ['-C', dir, 'rev-parse', '--show-toplevel'], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch {
    return null;
  }
}

function copyTree(src, dest) {
  fs.cpSync(src, dest, {
    recursive: true,
    filter: (p) => !/[\\/](state|worktrees)([\\/]|$)/.test(path.relative(PAYLOAD, p)),
  });
}

function makeExecutable(dest) {
  const execs = [path.join(dest, 'config', 'setup-worktree.sh')];
  for (const dir of [path.join(dest, 'bin'), path.join(dest, 'bin', 'harness')]) {
    if (!fs.existsSync(dir)) continue;
    for (const f of fs.readdirSync(dir)) {
      const p = path.join(dir, f);
      if (fs.statSync(p).isFile()) execs.push(p);
    }
  }
  for (const p of execs) if (fs.existsSync(p)) fs.chmodSync(p, 0o755);
}

function finish(dest) {
  fs.writeFileSync(path.join(dest, '.gitignore'), GITIGNORE);
  fs.writeFileSync(path.join(dest, 'VERSION'), VERSION + '\n');
  makeExecutable(dest);
}

function checkPlatform() {
  if (process.platform === 'win32') {
    fail('maistro needs bash and tmux. On Windows, run it inside WSL: https://learn.microsoft.com/windows/wsl/');
  }
}

function resolveTarget(arg) {
  const target = path.resolve(arg || process.cwd());
  if (!fs.existsSync(target)) fail(`no such directory: ${target}`);
  const root = repoRoot(target);
  if (!root) fail(`${target} is not inside a git repository (run "git init" first)`);
  if (fs.realpathSync(root) === fs.realpathSync(PKG_ROOT)) {
    fail("refusing to install maistro into its own source checkout");
  }
  return root;
}

function init(arg) {
  checkPlatform();
  const root = resolveTarget(arg);
  const dest = path.join(root, '.maistro');
  if (fs.existsSync(dest)) fail(`maistro is already installed in ${root} (to update it: maistro upgrade)`);
  copyTree(PAYLOAD, dest);
  finish(dest);
  out(`maistro ${VERSION} installed in ${dest}\n`);
  out('Next steps:');
  out(`  cd ${root}`);
  out('  npx @ajitsarkaar/maistro doctor          # check dependencies');
  out('  git add .maistro && git commit -m "Add maistro"');
  out('  npx @ajitsarkaar/maistro                 # start Maistro in tmux\n');
  out('Tip: "npm install -g @ajitsarkaar/maistro" lets you type just "maistro".');
}

function upgrade(arg) {
  checkPlatform();
  const root = resolveTarget(arg);
  const dest = path.join(root, '.maistro');
  if (!fs.existsSync(dest)) fail(`maistro is not installed in ${root} (run: maistro init)`);
  const before = fs.existsSync(path.join(dest, 'VERSION'))
    ? fs.readFileSync(path.join(dest, 'VERSION'), 'utf8').trim()
    : 'unknown';

  for (const part of TOOL_PARTS) {
    fs.rmSync(path.join(dest, part), { recursive: true, force: true });
    copyTree(path.join(PAYLOAD, part), path.join(dest, part));
  }

  const newer = [];
  fs.mkdirSync(path.join(dest, 'config'), { recursive: true });
  for (const f of fs.readdirSync(path.join(PAYLOAD, 'config'))) {
    const src = path.join(PAYLOAD, 'config', f);
    const cur = path.join(dest, 'config', f);
    if (!fs.existsSync(cur)) {
      fs.copyFileSync(src, cur);
    } else if (!fs.readFileSync(src).equals(fs.readFileSync(cur))) {
      fs.copyFileSync(src, cur + '.new');
      newer.push(`config/${f}`);
    }
  }
  finish(dest);
  out(`maistro upgraded in ${dest}: ${before} -> ${VERSION}`);
  if (newer.length) {
    out('\nYour config was kept. Newer defaults were saved next to it; compare and merge by hand:');
    for (const f of newer) out(`  .maistro/${f}.new`);
  }
}

function runInRepo(args) {
  checkPlatform();
  const root = repoRoot(process.cwd());
  const launcher = root && path.join(root, '.maistro', 'bin', 'maistro');
  if (!launcher || !fs.existsSync(launcher)) {
    fail('maistro is not installed in this repository (run: npx @ajitsarkaar/maistro init)');
  }
  const r = spawnSync(launcher, args, { stdio: 'inherit' });
  if (r.error) fail(r.error.message);
  process.exit(r.status === null ? 1 : r.status);
}

function help() {
  out(`maistro ${VERSION}: one agent conducts a crew of Claude Code workers

Usage:
  maistro init [path]      install maistro into a git repository
  maistro upgrade [path]   update scripts, prompts, templates and skills (keeps your config)
  maistro                  start Maistro in tmux, or attach if it's running
  maistro status           show all tasks
  maistro doctor           check dependencies and configuration
  maistro attach | stop    re-attach to, or close, the tmux session
  maistro uninstall        remove maistro from this repo (keeps plans and branches)
  maistro --version

Docs: https://github.com/ajitsarkaar/maistro`);
}

const [cmd, ...rest] = process.argv.slice(2);
switch (cmd) {
  case 'init': init(rest[0]); break;
  case 'upgrade': upgrade(rest[0]); break;
  case '-v': case '--version': out(VERSION); break;
  case '-h': case '--help': case 'help': help(); break;
  case undefined: {
    const root = repoRoot(process.cwd());
    if (root && fs.existsSync(path.join(root, '.maistro', 'bin', 'maistro'))) runInRepo(['start']);
    else help();
    break;
  }
  default:
    if (REPO_COMMANDS.has(cmd)) runInRepo([cmd, ...rest]);
    else fail(`unknown command "${cmd}" (try: maistro --help)`);
}
