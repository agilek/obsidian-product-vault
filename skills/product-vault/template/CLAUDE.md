# {{PROJECT}} vault — rules for Claude

This vault is the **source of truth for tasks, bugs, roadmap, discovery and decisions** of {{PROJECT}}. The code repo keeps engineering history (`devlog.md`); everything "what is open / planned" lives here. Start every project session by reading `Dashboard/Home.md` (or the Issues frontmatter via Grep).

## Issues (`Issues/`)
- One note per item, filename `{{PREFIX}}-NNN title.md`. Next number = highest existing + 1 (Glob first). Create from `Templates/Issue|Bug|Feature.md`.
- Frontmatter is the data; Dataview dashboards read it. Keep values lowercase from these sets:
  - `type`: task | bug | feature | chore
  - `status`: triage | backlog | todo | doing | blocked | done | cancelled
  - `priority`: p0 (launch blocker) | p1 | p2 | p3
  - `severity` (bugs): critical | major | minor | cosmetic
  - `area`: PROJECT-SPECIFIC, listed in "Areas" below
  - `milestone`: `"[[milestone note name]]"`; empty = backlog
  - `source`: owner | claude | external (who raised it); `found_in`: short context (file, task, session)
  - `snooze_until`: YYYY-MM-DD (triage only)
  - `duplicate_of`: wikilink (cancelled duplicates)
  - `horizon` (features): now | next | later
  - tag `verify` when a bug is reported but not reproduced on current code
- When work starts/finishes/blocks: set `status`, set `updated` to today. Done items stay in place; sweep `done`/`cancelled` older than 60 days into `Archive/`.
- Keep a `## Activity` section as the **last** section of every issue: append one dated line per change, `- YYYY-MM-DD: status triage → todo (why)`; also log priority/area/milestone changes and meaningful findings. The dashboards write the same lines when the owner edits status/priority there. Never rewrite earlier lines.
- Check for an existing issue before creating one. Prefer updating over duplicating.

## Other folders
- `Roadmap/`: one note per milestone/release (`status`: planned | active | released; exactly one `active`; `target` date). Exit criteria as checkboxes.
- `Discovery/`: ideas, research, competitors, user feedback. `status`: idea | exploring | accepted | rejected. An accepted idea becomes an issue (link both ways).
- `Decisions/`: one ADR per significant decision (why, not just what). Superseded ones get `status: superseded` and a link to the replacement.
- `Progress/`: short dated notes, one per release or week (`YYYY-MM-DD title.md`): shipped / learned / next.
- `Reference/`: product brief, links, glossary. Stable facts only.

## Task codes
When the owner mentions a code like `{{PREFIX}}-012` (any case, with or without a dash), look it up before answering: Glob `Issues/<PREFIX>-012 *.md` in this vault (from the repo: `vault/Issues/...`) and read it, plus the milestone and linked notes it references. Treat the note as the full context for "that task". If no file matches, say so and check `Archive/`. After working on it, update its `status` and `updated`.

## Triage (Linear semantics)
`status: triage` = unplanned work nobody has reviewed. It is an inbox, not a plan: triage items stay out of Board, Backlog and milestone work until the owner accepts them (see `Dashboard/Triage.md` for accept / decline / duplicate / snooze).
- **Automatic filing:** whenever you find something during work (a bug you notice, a follow-up, tech debt, a missing doc, a risky assumption, a failing test unrelated to the task), file it as a triage issue right then, without asking and without interrupting the task. Set `source: claude`, `found_in`, a suggested `priority`/`area`, and a body with evidence (file:line, repro, why it matters). Unconfirmed bugs also get tag `verify`.
- Owner remarks that are not "do it now" also land in triage (`source: owner`) with your best-guess priority/area; the owner remarks in the capture section below keep their routing for ideas (Discovery) and decisions (Decisions).
- Every triage issue carries a `dataviewjs` block under its H1 (`await dv.view("Dashboard/triage-actions")`, see `Templates/*.md`): it shows Todo / Backlog / Snooze 7d / Decline on the note and removes itself once decided. Include it when filing a triage issue; never remove it myself.
- Do not accept, decline or schedule triage items yourself. Never set a milestone on a triage item.
- Duplicates: search Triage and open issues first; add evidence to the existing note instead.
- End of a work session: one line listing what was filed (e.g. "Filed {{PREFIX}}-031, {{PREFIX}}-032 in triage").

## Status changes made by the owner
The owner moves issues in Obsidian (dashboards or frontmatter) and may tell me about it ("I moved {{PREFIX}}-007 to doing"). I only see changes on disk, never live, so:
- **Session start:** Grep `Issues/` for `status: doing|blocked` and for `updated:` within the last 7 days, and read the newest `## Activity` lines, so I know what moved since last time. Mention anything relevant in one line.
- **When told, or when I notice a change:** read the issue (+ Related notes and Activity), then act by the new status:
  - `doing`: the owner took it or wants it started. If it is code or docs work I can do, start it now; if it is manual (DNS, mailboxes, decisions), prepare what I can (checklist, commands, drafts) and say what is left for the owner.
  - `blocked`: ask for the blocker only if the note doesn't say; otherwise record it in Activity and suggest what unblocks it.
  - `done`: verify if cheap (tests, grep, page check), log it in Activity, check Related notes/milestone exit criteria that should now tick.
  - `todo` / `backlog`: just acknowledge, no work.
  - `cancelled`: ensure a reason is in the note, remove dependents' blocked state.
- Always update `updated` and append an Activity line for what I did.

## Capture: plain-language remarks become notes
When the owner says something in passing ("we should replace the icon for tool XYZ", "the table feels slow", "what if we offered X", "we decided Y"), triage and record it yourself. Never ask "now or later?".
- Concrete change or fix -> issue (`task`/`bug`/`feature`/`chore`) in **triage** (priority and area inferred, no milestone), unless the owner says to plan or do it, then `todo` with the milestone.
- Something broken, not yet reproduced -> `bug` tagged `verify`.
- Vague idea, question or research -> `Discovery/` note.
- A choice made, with a reason -> `Decisions/` ADR.
- Search for an existing note first and update it instead of duplicating.
- Quick and clearly requested to be done now (typo, tiny tweak in the current task) -> just do it, no issue unless it leaves follow-up work.
- Otherwise capture it and continue the current work. Mention in one line what was filed (e.g. "Filed as {{PREFIX}}-031, p3 ui").

## Linking: always connect the dots
Every note you create or touch should link to everything it plausibly relates to. Before saving, ask: what is this connected to? Check by Grep/Glob over the vault, then add `[[wikilinks]]`.
- Every issue ends with a `## Related` section: milestone, parent/sibling issues (same area, same root cause, blocks/blocked-by), the Discovery note that spawned it, the Decision that constrains it, duplicates.
- Link both ways: when A links to B, add the backlink to B's `## Related` (append only).
- Discovery notes link to the issues they produced; decisions link to the issues they affect and the notes they supersede; progress notes link every issue shipped or filed that period; milestones link their key issues.
- Use the issue's code and title in links (`[[{{PREFIX}}-003 Align licence copy ...]]`), and mention code files, PRs, commits and docs as paths or URLs. Mention areas and people as plain text unless a note exists.
- Prefer linking on first mention in the body too, not only in Related. No orphan notes: a new note with no inbound link is a bug.

## Rules
- The owner edits notes too. Never rewrite owner prose; change frontmatter and append sections.
- Dashboards in `Dashboard/` are generated; don't hand-edit queries unless improving them.  `Activity` aggregates every issue's `## Activity` lines (no separate log: append lines to the issue only).
- Write in English. Link between notes with `[[wikilinks]]`; link to repo files by path/URL.

## Areas
(fill in per project, e.g. `core`, `ui`, `docs`, `site`, `infra`, `launch`)

Repos: (paths of the code repos; engineering history stays in their devlog)

