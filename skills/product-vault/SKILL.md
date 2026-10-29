---
name: product-vault
description: Set up a Linear-style issue tracker inside Obsidian (a "product vault" with issues, triage inbox, kanban board, bugs, backlog, roadmap/milestones, discovery, decisions and progress notes) for a code project, and migrate the repo's TODO/task lists into it. Use when the user asks for a knowledge base, issue tracker, product vault or Linear replacement in Obsidian, wants to move a repo's TODO.md into Obsidian, or wants to improve the vault template.
---

# Product vault

One Obsidian vault per product, by default in `~/Obsidian/product/<slug>/` (override with `PRODUCT_VAULTS`), created from `template/` next to this file. The vault is the source of truth for **what is open or planned**: issues `<PREFIX>-NNN`, milestones, discovery notes, decisions, progress notes. The code repo keeps engineering history (devlog, specs). Dataview dashboards (`Dashboard/`: Home, Triage, Board, Bugs, Backlog, Roadmap, Launch, Discovery, Activity) read issue frontmatter and let the human edit status, priority and triage decisions in place. The vault's own `CLAUDE.md` is the schema and the working rules; read it before touching any vault.

## Setup steps

1. **Pick names.** `slug` = product name, lowercase; `PREFIX` = 2–4 capital letters (e.g. ACME). Choose sensible ones and say which; don't ask.
2. **Scaffold:** `<this skill dir>/setup-vault.sh <slug> <PREFIX> [<repo-path>] ["Display Name"]`
   It copies the template, fills `{{PROJECT}}`/`{{PREFIX}}`, downloads the community plugins (Dataview, Iconic, Custom File Explorer sorting) at pinned versions, runs `git init` + a first commit and, with a repo path, adds a git-ignored `./vault` symlink and wires `vault-changes.py` into the repo's `.claude/settings.local.json` (SessionStart, UserPromptSubmit, PostToolUse), so status changes the human makes in Obsidian reach you on the next prompt.
3. **Fill in the vault `CLAUDE.md`:** the project's real `## Areas` (lowercase) and repo paths. Fix the devlog filename if the repo uses another one. Fill `Reference/Product brief.md` from the repo's README and docs.
4. **Optional remote:** if the user wants the vault backed up, create a **private** repo (`gh repo create <name>-vault --private --source <vault> --push`). Never make it public without being told.
5. **Migrate the repo's open items** (TODO.md, tasks.md, issue lists) into issues. For more than ~30 items, delegate to one subagent with the brief below; review its report and spot-check notes.
6. **Repo pointers:** turn the old task file into a short pointer to the vault (keep the history if it is a log). In the repo's `CLAUDE.md`, replace "update TODO.md" style rules with "file/update an issue in the vault", and add a line: vault path, `./vault` symlink, read `vault/CLAUDE.md` first, a code like `ACME-012` means read `vault/Issues/ACME-012 *.md`, findings during work go to triage unasked.
7. **Tell the user:** open the folder in Obsidian ("Open folder as vault"), turn off Restricted mode when asked (the dashboards need the plugins), start at `Dashboard/Home`.

## Migration brief (fill in and hand to the subagent)

- Read the vault `CLAUDE.md` (schema) and `Templates/`.
- Only open items. One issue per top-level bullet; split bundles of unrelated follow-ups into a few themed issues; nested checkboxes become separate issues. Keep every concrete detail (paths, dates, commands, ids) so each issue stands alone.
- Map the source's priorities to `status`/`priority` (blockers → todo p0/p1, next work → backlog p2, polish → backlog p3; decisions the human must make → todo, `source: owner`, tag `decision`). Unconfirmed bugs → `status: triage`, tag `verify`, no milestone, keep the triage `dataviewjs` block under the H1 (remove it from non-triage issues).
- Exactly one `active` milestone in `Roadmap/`; never a milestone on triage issues.
- Ideas → `Discovery/`, decisions already made (date + reason) → `Decisions/`, a `Progress/<today> Vault created.md`.
- Every issue ends with `## Related` then `## Activity` (`- <date>: migrated from <file> (<section>)`); links both ways; no orphan notes; link text = exact filename without `.md`.
- Verify with a throwaway script outside the vault: frontmatter parses, ids unique and match filenames, values in the allowed sets, every wikilink resolves, section order, one active milestone. Report counts, the p0 list, skipped or merged source lines, and deviations.

## Improving the template

Change `template/` (placeholders `{{PROJECT}}`, `{{PREFIX}}`), then port the same change to existing vaults by hand (diff `Dashboard/`, `Templates/`, `.obsidian/snippets/`, `CLAUDE.md`).

## Gotchas
- When turning a vault back into the template, replace the project name and prefix as whole words in prose and in the `{{PREFIX}}-` id patterns only, then diff `Dashboard/`: a blind `s/Element/{{PROJECT}}/` once turned `document.createElement` into `document.create{{PROJECT}}` and crashed every dashboard. `setup-vault.sh` refuses to continue when that happens.
- YAML titles containing `:` must be quoted. Filenames have spaces: use `find -exec`, never `xargs`.
- Dataview JS must be enabled (`enableDataviewJs`, shipped in the template's plugin settings). In `dataviewjs`, `dv.el` children must be real DOM nodes; dashboards open pages in Reading view because Live Preview shows the source.
- The hook treats edits made with Edit/Write tools as yours; edits made with shell commands show up on the next prompt as the human's changes. The first hook run only records a snapshot.
- Don't auto-commit the vault; commit when asked or at the end of setup.
