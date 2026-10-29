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
  const body = `---\nid: ${id}\ntitle: ${JSON.stringify(title)}\ntype: task\nstatus: triage\npriority: p2\narea: \nsource: owner\ncreated: ${day}\nupdated: ${day}\ntags: []\n---\n# ${title}\n\n\`\`\`dataviewjs\nawait dv.view("Dashboard/triage-actions")\n\`\`\`\n\n## Problem\n\n\n## Related\n- Milestone: \n\n## Activity\n- ${day}: filed in triage (owner)\n`;
  await app.vault.create(`Issues/${id} ${title.replace(/[\\/:*?"<>|]/g, "")}.md`, body);
  add.value = "";
  new Notice(`Filed ${id} in Triage`);
});
```

*Generated from `Issues/`. Edit the issue notes, not this page.*

```dataviewjs
const all = dv.pages('"Issues"').where(i => i.id);
const today = dv.date("today");
const isOpen = i => i.status != "done" && i.status != "cancelled";
const tri = all.where(i => i.status == "triage" && (!i.snooze_until || i.snooze_until <= today)).sort(i => i.created, "desc");
const active = all.where(i => i.status == "doing" || i.status == "blocked").sort(i => i.priority);
const urgent = all.where(i => isOpen(i) && i.status != "triage" && (i.priority == "p0" || i.priority == "p1")).sort(i => i.priority);
const next = all.where(i => i.status == "todo" && i.priority != "p0" && i.priority != "p1").sort(i => i.priority);
const bugsAll = all.where(i => i.type == "bug" && isOpen(i));
const bugs = bugsAll.where(i => i.status != "triage").sort(i => i.severity);
const link = i => dv.fileLink(i.file.path, false, `${i.id} ${i.title}`);
const chip = (v, cls) => { const s = document.createElement("span"); s.className = "kb-chip " + cls + "-" + v; s.textContent = String(v ?? "—").toUpperCase(); return s; };
const pc = i => chip(i.priority, "p");
const root = dv.el("div", "", { cls: "dash" });
const grid = root.createDiv({ cls: "dash-grid fill" });
function card(title, count, pages, cols, rowFn) {
  const c = grid.createDiv({ cls: "dash-card" });
  c.createEl("h4", { text: count == null ? title : `${title} · ${count}` });
  const body = c.createDiv({ cls: "dash-body" });
  const old = dv.container; dv.container = body;
  if (pages.length) dv.table(cols, pages.map(rowFn)); else dv.paragraph("Nothing here.");
  dv.container = old;
}
card("Triage — needs your decision", tri.length, tri.slice(0, 12), ["P", "Item", "Area"], i => [pc(i), link(i), i.area]);
card("Active (in progress / blocked)", active.length, active, ["P", "Issue", "Status"], i => [pc(i), link(i), i.status]);
card("P0 / P1 — launch-critical", urgent.length, urgent.slice(0, 12), ["P", "Issue", "Status"], i => [pc(i), link(i), i.status]);
card("Next up (p2 / p3 todo)", next.length, next.slice(0, 10), ["P", "Issue", "Area"], i => [pc(i), link(i), i.area]);
card("Accepted bugs", bugs.length, bugs.slice(0, 10), ["Sev", "Bug", "Status"], i => [chip(i.severity, "sev"), link(i), i.status]);
const ms = dv.pages('"Roadmap"').where(p => p.status != "released").sort(p => p.target);
card("Milestones", null, ms, ["Milestone", "Progress", "Target"], m => {
  const ii = all.where(i => i.milestone && String(i.milestone).includes(m.file.name));
  const d = ii.where(i => i.status == "done").length;
  const pct = ii.length ? Math.round(100 * d / ii.length) : 0;
  return [m.file.link, `${d}/${ii.length} · ${pct}%`, m.target ? m.target.toFormat("d LLL yyyy") : "—"];
});
const prog = dv.pages('"Progress"').sort(p => p.file.name, "desc").slice(0, 5);
card("Latest progress", null, prog, ["Note"], p => [p.file.link]);
const disc = dv.pages('"Discovery"').where(p => p.status && p.status != "rejected").sort(p => p.created, "desc").slice(0, 5);
card("Discovery", null, disc, ["Note", "Status"], p => [p.file.link, p.status]);
```
