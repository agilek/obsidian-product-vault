#!/usr/bin/env bash
# Download the community plugins the vault's dashboards need into <vault>/.obsidian/plugins/.
# Usage: install-plugins.sh <vault-dir>
# Pinned versions; their settings (data.json) already ship with the template.
set -euo pipefail
vault=${1:?vault-dir}
plugins=(
  "dataview blacksmithgu/obsidian-dataview 0.5.64 main.js manifest.json styles.css"
  "iconic gfxholo/iconic 1.1.0 main.js manifest.json styles.css"
  "custom-sort SebastianMC/obsidian-custom-sort 3.2.0 main.js manifest.json"
)
for entry in "${plugins[@]}"; do
  read -r id repo version files <<<"$entry"
  dir="$vault/.obsidian/plugins/$id"
  mkdir -p "$dir"
  for f in $files; do
    curl -fsSL "https://github.com/$repo/releases/download/$version/$f" -o "$dir/$f"
  done
  echo "installed $id $version"
done
