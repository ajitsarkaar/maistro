#!/usr/bin/env bash
# Install maistro into a git repository.
#
#   From a clone:   ./install.sh [--upgrade] [path/to/repo]
#   One-liner:      curl -fsSL https://raw.githubusercontent.com/ajitsarkaar/maistro/main/install.sh | bash
#                   curl -fsSL .../install.sh | bash -s -- --upgrade
#
# Installs everything into <repo>/.maistro/ and touches nothing else in your repo.
# --upgrade refreshes scripts, prompts and templates but keeps your config/.
set -euo pipefail

MAISTRO_REPO_URL="${MAISTRO_REPO_URL:-https://github.com/ajitsarkaar/maistro.git}"
upgrade=0; target="$PWD"
while [ $# -gt 0 ]; do
  case "$1" in
    --upgrade) upgrade=1; shift ;;
    -h|--help) sed -n '2,10p' "$0" 2>/dev/null || true; exit 0 ;;
    *) target="$1"; shift ;;
  esac
done

die() { printf 'maistro install: %s\n' "$*" >&2; exit 1; }
command -v git >/dev/null || die "git is required"

# Find the maistro source: next to this script, or a fresh shallow clone.
src=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/.maistro/bin/maistro" ]; then
  src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  git clone --quiet --depth 1 "$MAISTRO_REPO_URL" "$tmp/maistro" || die "could not clone $MAISTRO_REPO_URL"
  src="$tmp/maistro"
fi

root="$(git -C "$target" rev-parse --show-toplevel 2>/dev/null)" || die "$target is not inside a git repository"
[ "$root" != "$src" ] || die "refusing to install maistro into its own source checkout"
dest="$root/.maistro"

if [ -d "$dest" ] && [ "$upgrade" != 1 ]; then
  die "maistro is already installed at $dest (use --upgrade to refresh it)"
fi

mkdir -p "$dest"
if [ "$upgrade" = 1 ]; then
  for part in bin prompts templates; do rm -rf "${dest:?}/$part"; cp -R "$src/.maistro/$part" "$dest/$part"; done
  cp "$src/.maistro/.gitignore" "$dest/.gitignore"
  mkdir -p "$dest/config"
  for f in "$src"/.maistro/config/*; do
    name="$(basename "$f")"
    if [ -e "$dest/config/$name" ]; then
      cmp -s "$f" "$dest/config/$name" || cp "$f" "$dest/config/$name.new"
    else cp "$f" "$dest/config/$name"; fi
  done
else
  (cd "$src" && tar --exclude='.maistro/state' --exclude='.maistro/worktrees' -cf - .maistro) | (cd "$root" && tar -xf -)
fi
chmod +x "$dest"/bin/* "$dest"/bin/harness/* "$dest/config/setup-worktree.sh" 2>/dev/null || true
sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' "$src/package.json" 2>/dev/null | head -n 1 > "$dest/VERSION" || true

if [ "$upgrade" = 1 ]; then
  echo "maistro upgraded in $dest"
  ls "$dest"/config/*.new >/dev/null 2>&1 && echo "Newer default config saved as config/*.new; compare and merge by hand."
else
  cat <<MSG
maistro installed in $dest

Next steps:
  1. cd $root && .maistro/bin/maistro doctor
  2. git add .maistro && git commit -m "Add maistro"   (so workers' worktrees get it too)
  3. .maistro/bin/maistro                                 (starts Maistro in tmux)

Tip: alias maistro='./.maistro/bin/maistro' in your shell profile.
MSG
fi
