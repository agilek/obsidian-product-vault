# Devlog

## 2026-10-29

### First public release
Debranded the private product-vault skill into this repo: template vault, `setup-vault.sh`, `install-plugins.sh` (pinned plugin downloads), `vault-changes.py` hook, Trailhead demo vault (plugins included) and README screenshots of the demo.

**Root cause / approach:** a blind `s/Element/{{PROJECT}}/` while deriving the template had turned `document.createElement` into `document.create{{PROJECT}}` in every dashboard. It's fixed, and `setup-vault.sh` now refuses to continue if the dashboard code changed. Dashboards need Reading view; the demo sets `defaultViewMode: preview`.

No new memory entries in this repo (notes live in the author's Claude memory).
