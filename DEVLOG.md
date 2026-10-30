# Devlog

## 2026-10-30

### Activity lines carry a time
Several status changes to one issue on one day were impossible to order on the Activity dashboard. Activity lines are now `- YYYY-MM-DD HH:MM: text`; the dashboard shows the time per line and sorts newest first by date and time (untimed legacy lines sort after timed ones of the same day). Every writer (dashboards' status/priority editing, the new-issue input, `triage-actions.js`, the Issue/Bug/Feature templates) writes the time.

**Root cause / approach:** `nowStamp()` also feeds the `updated:` frontmatter, so the Activity writers got a separate `nowTime()` and `updated` stays date-only. The parse/sort logic is two pure functions in `Dashboard/Activity.md` between marker comments, so a node script can extract and test the shipped code.

No new memory entries in this repo.

## 2026-10-29

### First public release
Debranded the private product-vault skill into this repo: template vault, `setup-vault.sh`, `install-plugins.sh` (pinned plugin downloads), `vault-changes.py` hook, Trailhead demo vault (plugins included) and README screenshots of the demo.

**Root cause / approach:** a blind `s/Element/{{PROJECT}}/` while deriving the template had turned `document.createElement` into `document.create{{PROJECT}}` in every dashboard. It's fixed, and `setup-vault.sh` now refuses to continue if the dashboard code changed. Dashboards need Reading view; the demo sets `defaultViewMode: preview`.

No new memory entries in this repo (notes live in the author's Claude memory).
