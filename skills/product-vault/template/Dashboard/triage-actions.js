// Shared by every issue note in triage: ```dataviewjs await dv.view("Dashboard/triage-actions") ```
// Shows Todo / Backlog / Snooze / Decline while status is triage. Writes the Activity line and removes the block from the note.
const i = dv.current();
if (i && i.status == "triage") {
  const BLOCK = /```dataviewjs\s*\n\s*await dv\.view\("Dashboard\/triage-actions"\)\s*\n```\n*/;
  const today = () => window.moment().format("YYYY-MM-DD");
  const now = () => window.moment().format("YYYY-MM-DD HH:mm");
  const snoozed = i.snooze_until && i.snooze_until > dv.date("today");
  const bar = dv.el("div", "", { cls: "dash" }).createDiv({ cls: "triage-bar" });
  bar.createSpan({ cls: "triage-label", text: snoozed ? `Triage · snoozed until ${i.snooze_until.toFormat("d LLL yyyy")}` : "Triage · decide" });
  async function apply(label, change, leave) {
    bar.querySelectorAll("button").forEach(b => { b.disabled = true; });
    const f = app.vault.getAbstractFileByPath(i.file.path);
    const prev = { status: i.status, snooze_until: i.snooze_until?.toFormat ? i.snooze_until.toFormat("yyyy-MM-dd") : i.snooze_until };
    const changes = [];
    await app.fileManager.processFrontMatter(f, fm => {
      const before = { status: fm.status, snooze_until: fm.snooze_until };
      change(fm);
      for (const k of Object.keys(before)) if (String(before[k] ?? "") != String(fm[k] ?? "")) changes.push(`${k}: ${before[k] ?? "—"} → ${fm[k] ?? "—"}`);
      fm.updated = today();
    });
    await app.vault.process(f, t => {
      if (leave) t = t.replace(BLOCK, "");
      const line = `- ${now()}: ${changes.join("; ")} (decided on the note)`;
      return /\n## Activity\n/.test(t) ? t.trimEnd() + "\n" + line + "\n" : t.trimEnd() + "\n\n## Activity\n" + line + "\n";
    });
    const n = new Notice("", 8000);
    n.noticeEl.createSpan({ text: `${i.id} → ${label}   ` });
    n.noticeEl.createEl("button", { text: "Undo" }).addEventListener("click", async () => {
      await app.fileManager.processFrontMatter(f, fm => {
        fm.status = prev.status;
        if (prev.snooze_until) fm.snooze_until = prev.snooze_until; else delete fm.snooze_until;
        fm.updated = today();
      });
      n.hide();
    });
  }
  const add = (label, title, change, leave) => bar.createEl("button", { cls: "dash-btn", text: label, attr: { title } }).addEventListener("click", () => apply(label, change, leave));
  add("Todo", "Accept: status → todo", fm => { fm.status = "todo"; }, true);
  add("Backlog", "Accept: status → backlog", fm => { fm.status = "backlog"; }, true);
  add("Snooze 7d", "Hide from Triage for a week", fm => { fm.snooze_until = window.moment().add(7, "days").format("YYYY-MM-DD"); }, false);
  add("Decline", "status → cancelled", fm => { fm.status = "cancelled"; }, true);
}
