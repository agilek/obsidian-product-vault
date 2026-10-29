#!/usr/bin/env bash
# Create a product vault for a project from the template next to this script.
# Usage: setup-vault.sh <slug> <PREFIX> [repo-path] [Display Name]
#   slug        vault folder name under $PRODUCT_VAULTS (default ~/Obsidian/product)
#   PREFIX      issue code prefix, e.g. ACME -> ACME-001
#   repo-path   optional code repo: gets a ./vault symlink, a .gitignore line and the
#               Claude Code hook that reports issue changes you make in Obsidian
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
root=${PRODUCT_VAULTS:-$HOME/Obsidian/product}
template=$here/template
hook_dir=$HOME/.claude/hooks
hook=$hook_dir/vault-changes.py

slug=${1:?slug}; prefix=${2:?PREFIX}; repo=${3:-}
name=${4:-$(tr '[:lower:]' '[:upper:]' <<<"${slug:0:1}")${slug:1}}
vault=$root/$slug

[ -e "$vault" ] && { echo "vault already exists: $vault" >&2; exit 1; }
[ -z "$repo" ] || [ -d "$repo" ] || { echo "repo not found: $repo" >&2; exit 1; }

mkdir -p "$root"
rsync -a --exclude .DS_Store "$template/" "$vault/"
for d in Issues Roadmap Discovery Decisions Progress Archive; do mkdir -p "$vault/$d"; touch "$vault/$d/.gitkeep"; done
# filenames contain spaces: find -exec, never xargs
find "$vault" -type f \( -name '*.md' -o -name '*.js' \) -not -path '*/.obsidian/*' \
  -exec sed -i.bak -e "s/{{PREFIX}}/$prefix/g" -e "s/{{PROJECT}}/$name/g" {} +
find "$vault" -name '*.bak' -delete
"$here/install-plugins.sh" "$vault"

# sanity: a placeholder swap must never touch code (e.g. "Element" inside document.createElement)
grep -q 'document.createElement' "$vault/Dashboard/Home.md" || { echo "dashboard code was altered by the placeholder swap" >&2; exit 1; }
git -C "$vault" init -q -b main
git -C "$vault" add -A
git -C "$vault" commit -qm "Initial $name product vault"

if [ -n "$repo" ]; then
  [ -e "$repo/vault" ] || ln -s "$vault" "$repo/vault"
  grep -qx '/vault' "$repo/.gitignore" 2>/dev/null || \
    printf '\n# Obsidian product vault (symlink, its own repo)\n/vault\n' >> "$repo/.gitignore"

  # stable copy of the hook, so plugin updates don't break the command path
  mkdir -p "$hook_dir"; cp "$here/vault-changes.py" "$hook"
  mkdir -p "$repo/.claude"
  python3 - "$repo/.claude/settings.local.json" "$vault" "$hook" <<'PY'
import json, os, sys
path, vault, hook = sys.argv[1:]
s = json.load(open(path)) if os.path.exists(path) else {}
cmd = f'python3 -I "{hook}" "{vault}"'
h = {"type": "command", "command": cmd, "timeout": 10}
hooks = s.setdefault("hooks", {})
def has(event):
    return any(x.get("command") == cmd for e in hooks.get(event, []) for x in e.get("hooks", []))
for event, extra in (("SessionStart", {}), ("UserPromptSubmit", {}), ("PostToolUse", {"matcher": "Edit|Write|MultiEdit"})):
    if not has(event):
        hooks.setdefault(event, []).append({**extra, "hooks": [h]})
json.dump(s, open(path, "w"), indent=2)
PY
  git -C "$repo" check-ignore -q .claude/settings.local.json 2>/dev/null || \
    echo "note: add .claude/settings.local.json to $repo/.gitignore (it holds your local vault path)" >&2
fi

echo "vault: $vault"
echo "next: open it in Obsidian (Open folder as vault), trust the plugins, start at Dashboard/Home."
echo "      fill in Areas in $vault/CLAUDE.md"
