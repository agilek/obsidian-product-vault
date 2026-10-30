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
  const id = `{{PREFIX}}-${String(Math.max(0, ...nums) + 1).padStart(3, "0")}`;
  const day = window.moment().format("YYYY-MM-DD");
  const stamp = window.moment().format("YYYY-MM-DD HH:mm");
  const body = `---\nid: ${id}\ntitle: ${JSON.stringify(title)}\ntype: task\nstatus: triage\npriority: p2\narea: \nsource: owner\ncreated: ${day}\nupdated: ${day}\ntags: []\n---\n# ${title}\n\n\`\`\`dataviewjs\nawait dv.view("Dashboard/triage-actions")\n\`\`\`\n\n## Problem\n\n\n## Related\n- Milestone: \n\n## Activity\n- ${stamp}: filed in triage (owner)\n`;
  await app.vault.create(`Issues/${id} ${title.replace(/[\\/:*?"<>|]/g, "")}.md`, body);
  add.value = "";
  new Notice(`Filed ${id} in Triage`);
});
```

*Milestones and the feature horizon.*

```dataviewjs
const all = dv.pages('"Issues"').where(i => i.id);
const today = dv.date("today");
const isOpen = i => i.status != "done" && i.status != "cancelled";
const link = i => dv.fileLink(i.file.path, false, `${i.id} ${i.title}`);
const chip = (v, cls) => { const s = document.createElement("span"); s.className = "kb-chip " + cls + "-" + v; s.textContent = String(v ?? "—").toUpperCase(); return s; };
const pc = i => chip(i.priority, "p");
const root = dv.el("div", "", { cls: "dash" });
const grid = () => root.createDiv({ cls: "dash-grid" });
const msName = m => m?.display ?? (m?.path ? m.path.split("/").pop().replace(/\.md$/, "") : String(m ?? "").replace(/[\[\]"]/g, ""));
const nowStamp = () => window.moment().format("YYYY-MM-DD");
const nowTime = () => window.moment().format("YYYY-MM-DD HH:mm");
async function editFM(i, fn) {
  const f = app.vault.getAbstractFileByPath(i.file.path);
  const changes = [];
  await app.fileManager.processFrontMatter(f, fm => {
    const before = { status: fm.status, priority: fm.priority, type: fm.type, area: fm.area, snooze_until: fm.snooze_until };
    fn(fm);
    for (const k of Object.keys(before)) if (String(before[k] ?? "") != String(fm[k] ?? "")) changes.push(`${k}: ${before[k] ?? "—"} → ${fm[k] ?? "—"}`);
    fm.updated = nowStamp();
  });
  if (changes.length) await app.vault.process(f, t => {
    const line = `- ${nowTime()}: ${changes.join("; ")}`;
    return /\n## Activity\n/.test(t) ? t.trimEnd() + "\n" + line + "\n" : t.trimEnd() + "\n\n## Activity\n" + line + "\n";
  });
}
function statusSelect(parent, i) {
  const s = parent.createEl("select", { cls: "dash-select kb-status", attr: { title: "Move to…" } });
  for (const o of ["triage", "backlog", "todo", "doing", "blocked", "done", "cancelled"]) { const op = s.createEl("option", { text: o, value: o }); if (i.status == o) op.selected = true; }
  const fit = () => { if (!CSS.supports("field-sizing", "content")) s.style.width = (s.value.length + 2) + "ch"; };
  fit();
  s.addEventListener("change", () => { fit(); editFM(i, fm => { fm.status = s.value; }); });
}
function prioSelect(parent, i) {
  const s = parent.createEl("select", { cls: "dash-select" });
  const paint = () => { s.className = "dash-select p-" + s.value; };
  for (const o of ["p0", "p1", "p2", "p3"]) { const op = s.createEl("option", { text: o, value: o }); if (i.priority == o) op.selected = true; }
  paint();
  s.addEventListener("change", () => { paint(); editFM(i, fm => { fm.priority = s.value; }); });
}
function card(g, title, count, pages, cols, rowFn) {
  const c = g.createDiv({ cls: "dash-card" });
  c.createEl("h4", { text: count == null ? title : `${title} · ${count}` });
  const body = c.createDiv({ cls: "dash-body" });
  const old = dv.container; dv.container = body;
  if (pages.length) dv.table(cols, pages.map(rowFn)); else dv.paragraph("Nothing here.");
  dv.container = old;
}
function kbCard(list, i) {
  const c = list.createDiv({ cls: "kb-card" });
  const top = c.createDiv({ cls: "kb-top" });
  top.appendChild(pc(i));
  if (i.type == "bug") top.createSpan({ cls: "kb-chip bug", text: "BUG" });
  if (i.area) top.createSpan({ cls: "kb-area", text: String(i.area) });
  top.createSpan({ cls: "kb-id", text: i.id });
  statusSelect(top, i);
  c.createDiv({ cls: "kb-title" }).createEl("a", { cls: "internal-link", text: String(i.title), attr: { "data-href": i.file.path, href: i.file.path } });
  if (i.severity) c.createDiv({ cls: "kb-meta", text: String(i.severity) });
}
function noteCard(list, p, extra) {
  const c = list.createDiv({ cls: "kb-card" });
  c.createDiv({ cls: "kb-title" }).createEl("a", { cls: "internal-link", text: p.file.name, attr: { "data-href": p.file.path, href: p.file.path } });
  const meta = c.createDiv({ cls: "kb-meta" });
  for (const x of extra) if (x) meta.createSpan({ text: String(x) });
}
function kanban(cols, render) {
  const k = root.createDiv({ cls: "kb" });
  k.style.gridTemplateColumns = `repeat(${cols.length}, minmax(210px, 1fr))`;
  for (const [label, items] of cols) {
    const col = k.createDiv({ cls: "kb-col" });
    col.createEl("h4", { text: `${label} · ${items.length}` });
    const list = col.createDiv({ cls: "kb-list" });
    for (const i of items) render(list, i);
    if (!items.length) list.createDiv({ cls: "kb-empty", text: "—" });
  }
}

const ms = dv.pages('"Roadmap"').sort(p => p.target);
const feats = all.where(i => i.type == "feature" && isOpen(i) && i.status != "triage").sort(i => i.priority);
function msCard(list, m) {
  const ii = all.where(i => i.milestone && String(i.milestone).includes(m.file.name));
  const d = ii.where(i => i.status == "done").length;
  const pct = ii.length ? Math.round(100 * d / ii.length) : 0;
  const c = list.createDiv({ cls: "kb-card" });
  c.createDiv({ cls: "kb-title" }).createEl("a", { cls: "internal-link", text: m.file.name, attr: { "data-href": m.file.path, href: m.file.path } });
  const bar = c.createDiv({ cls: "dash-bar" }); bar.createDiv().style.width = pct + "%";
  const meta = c.createDiv({ cls: "kb-meta" });
  meta.createSpan({ text: `${d}/${ii.length} done · ${pct}%` });
  meta.createSpan({ text: m.target ? m.target.toFormat("d LLL yyyy") : "no target" });
  if (m.goal) c.createDiv({ cls: "kb-meta", text: String(m.goal) });
}
root.createEl("h3", { text: "Milestones" });
kanban([["Planned", ms.where(p => p.status == "planned")], ["Active", ms.where(p => p.status == "active")], ["Released", ms.where(p => p.status == "released")]], msCard);
root.createEl("h3", { text: "Features" });
kanban([["Now", feats.where(i => i.horizon == "now")], ["Next", feats.where(i => i.horizon == "next")], ["Later", feats.where(i => !i.horizon || i.horizon == "later")]], kbCard);
```
