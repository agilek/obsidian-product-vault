---
cssclasses:
  - dashboard
---
```dataviewjs
const pages = [["Home", "Home", "home"], ["Triage", "Triage", "inbox"], ["Board", "Board", "kanban"], ["Bugs", "Bugs", "bug"], ["Backlog", "Backlog", "list-todo"], ["Roadmap", "Roadmap", "milestone"], ["Launch", "Launch", "rocket"], ["Discovery", "Discovery", "telescope"], ["Activity", "Activity", "activity"]];
const cur = dv.current().file.name;
const triN = dv.pages('"Issues"').where(i => i.status == "triage" && (!i.snooze_until || i.snooze_until <= dv.date("today"))).length;
const nav = dv.el("div", "", { cls: "dash-nav" });
let setIcon = null; try { setIcon = require("obsidian").setIcon; } catch (e) {}
for (const [f, l, ic] of pages) {
  const a = nav.createEl("a", { cls: "dash-nav-item" + (f == cur ? " active" : "") });
  if (setIcon) setIcon(a.createSpan({ cls: "dash-nav-icon" }), ic);
  a.appendText(l);
  if (f == "Triage" && triN) a.createSpan({ cls: "dash-nav-badge", text: String(triN) });
  a.addEventListener("click", e => {
    e.preventDefault(); e.stopPropagation();
    const file = app.vault.getAbstractFileByPath(`${dv.current().file.folder}/${f}.md`);
    if (file) app.workspace.getLeaf(false).openFile(file, { state: { mode: "preview" } });
  });
}
const add = nav.createEl("input", { cls: "dash-add", attr: { type: "text", placeholder: "+ New issue (title, Enter) → Triage" } });
add.addEventListener("keydown", async e => {
  if (e.key != "Enter" || !add.value.trim()) return;
  const title = add.value.trim();
  const nums = dv.pages('"Issues" or "Archive"').where(p => p.id).map(p => parseInt(String(p.id).split("-").pop())).values;
  const id = `TRL-${String(Math.max(0, ...nums) + 1).padStart(3, "0")}`;
  const day = window.moment().format("YYYY-MM-DD");
  const stamp = window.moment().format("YYYY-MM-DD HH:mm");
  const body = `---\nid: ${id}\ntitle: ${JSON.stringify(title)}\ntype: task\nstatus: triage\npriority: p2\narea: \nsource: owner\ncreated: ${day}\nupdated: ${day}\ntags: []\n---\n# ${title}\n\n\`\`\`dataviewjs\nawait dv.view("Dashboard/triage-actions")\n\`\`\`\n\n## Problem\n\n\n## Related\n- Milestone: \n\n## Activity\n- ${stamp}: filed in triage (owner)\n`;
  await app.vault.create(`Issues/${id} ${title.replace(/[\\/:*?"<>|]/g, "")}.md`, body);
  add.value = "";
  new Notice(`Filed ${id} in Triage`);
});
```

*Generated from the `## Activity` section of every issue (lines are `- YYYY-MM-DD HH:MM: text`; older lines may have no time). Edit the issue notes, not this page.*

```dataviewjs
const issues = dv.pages('"Issues" or "Archive"').where(i => i.id);
const root = dv.el("div", "", { cls: "dash" });
const bar = root.createDiv({ cls: "dash-nav" });
const q = bar.createEl("input", { cls: "dash-add", attr: { type: "text", placeholder: "Filter (issue, status, text)…" } });
const sel = (label, opts) => {
  const el = bar.createEl("select", { cls: "dash-select", attr: { title: label } });
  for (const [l, v] of opts) el.createEl("option", { text: l, value: v });
  return el;
};
const range = sel("Period", [["Last 7 days", "7"], ["Last 30 days", "30"], ["All time", "0"]]);
const uniq = k => [...new Set(issues.map(i => i[k]).filter(Boolean).map(String))].sort();
const fArea = sel("Area", [["All areas", ""], ...uniq("area").map(v => [v, v])]);
const fType = sel("Type", [["All types", ""], ...uniq("type").map(v => [v, v])]);
const fStatus = sel("Issue status now", [["Any status", ""], ...["triage", "backlog", "todo", "doing", "blocked", "done", "cancelled"].map(v => [v, v])]);
const fPrio = sel("Priority", [["Any priority", ""], ...["p0", "p1", "p2", "p3"].map(v => [v, v])]);
const fKind = sel("Kind", [["All entries", ""], ["Field changes", "change"], ["Notes & findings", "note"]]);
const out = root.createDiv({ cls: "dash-card" });
const body = out.createDiv({ cls: "dash-body" });

// --- Activity line parsing and ordering (pure functions; tested outside Obsidian) ---
// New lines: "- YYYY-MM-DD HH:MM: text". Old lines have no time: "- YYYY-MM-DD: text".
// Returns { day, time: "HH:MM" or "", msg } or null for anything else.
function parseActivityLine(line) {
  const e = String(line).match(/^- (\d{4}-\d{2}-\d{2})(?: ([01]?\d|2[0-3]):([0-5]\d))?:\s*(.+)$/);
  if (!e) return null;
  return { day: e[1], time: e[2] === undefined ? "" : `${e[2].padStart(2, "0")}:${e[3]}`, msg: e[4] };
}
// Newest first: day, then timed lines (latest time first) before untimed lines of that day,
// then issue id and file position (later line first), as before.
function compareActivity(a, b) {
  if (a.day !== b.day) return a.day < b.day ? 1 : -1;
  if (!a.time !== !b.time) return a.time ? -1 : 1;
  if (a.time !== b.time) return a.time < b.time ? 1 : -1;
  if (a.i.id !== b.i.id) return a.i.id < b.i.id ? 1 : -1;
  return b.n - a.n;
}
// --- end of pure functions ---

const entries = [];
for (const i of issues) {
  const f = app.vault.getAbstractFileByPath(i.file.path);
  const text = await app.vault.cachedRead(f);
  const m = text.match(/\n## Activity\n([\s\S]*?)(?=\n## |$)/);
  if (!m) continue;
  m[1].split("\n").forEach((line, n) => {
    const e = parseActivityLine(line);
    if (e) entries.push({ ...e, n, i });
  });
}
entries.sort(compareActivity);

function render() {
  body.empty();
  const days = Number(range.value), needle = q.value.trim().toLowerCase();
  const cutoff = days ? window.moment().subtract(days, "days").format("YYYY-MM-DD") : "";
  const isChange = e => /^(status|priority|type|area|snooze_until)\b/.test(e.msg);
  const rows = entries.filter(e => e.day >= cutoff
    && (!fArea.value || String(e.i.area) === fArea.value)
    && (!fType.value || String(e.i.type) === fType.value)
    && (!fStatus.value || String(e.i.status) === fStatus.value)
    && (!fPrio.value || String(e.i.priority) === fPrio.value)
    && (!fKind.value || (fKind.value === "change") === isChange(e))
    && (!needle || `${e.i.id} ${e.i.title} ${e.msg} ${e.i.area ?? ""}`.toLowerCase().includes(needle)));
  if (!rows.length) { body.createEl("p", { text: "Nothing here." }); return; }
  let day = null, list = null;
  for (const e of rows) {
    if (e.day !== day) {
      day = e.day;
      body.createEl("h4", { text: `${window.moment(day).format("ddd D MMM YYYY")}` });
      list = body.createEl("ul");
    }
    const li = list.createEl("li");
    if (e.time) li.createSpan({ text: `${e.time} `, attr: { style: "opacity: 0.6; font-variant-numeric: tabular-nums;" } });
    li.createEl("a", { cls: "internal-link", text: `${e.i.id} ${e.i.title}`, attr: { "data-href": e.i.file.path, href: e.i.file.path } });
    li.createSpan({ text: ` — ${e.msg}` });
  }
}
q.addEventListener("input", render);
for (const el of [range, fArea, fType, fStatus, fPrio, fKind]) el.addEventListener("change", render);
render();
```
