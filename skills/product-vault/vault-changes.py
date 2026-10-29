#!/usr/bin/env python3
"""Report product-vault issue changes to Claude (SessionStart / UserPromptSubmit / PostToolUse hook).

Usage: vault-changes.py <vault-dir>   (hook JSON on stdin)
- SessionStart / UserPromptSubmit: diff Issues/*.md frontmatter against a snapshot,
  print the changes as additionalContext, then update the snapshot.
- PostToolUse: refresh the snapshot for the file Claude just wrote (so its own edits are not
  reported back as owner changes).
Fields watched: status, priority, type, area, milestone, title.
"""
import json, os, re, sys, glob, hashlib

VAULT = sys.argv[1]
ISSUES = os.path.join(VAULT, "Issues")
STATE = os.path.expanduser("~/.claude/hooks/state/%s.json" % hashlib.md5(VAULT.encode()).hexdigest()[:8])
WATCH = ("status", "priority", "type", "area", "milestone", "title")


def read_issue(path):
    try:
        text = open(path, encoding="utf-8").read()
    except OSError:
        return None
    m = re.match(r"---\n(.*?)\n---", text, re.S)
    if not m:
        return None
    fm = {}
    for line in m.group(1).splitlines():
        k, sep, v = line.partition(":")
        if sep and not line.startswith((" ", "-")):
            fm[k.strip()] = v.strip().strip('"')
    if "id" not in fm:
        return None
    return {k: fm.get(k, "") for k in ("id",) + WATCH}


def scan():
    out = {}
    for p in glob.glob(os.path.join(ISSUES, "*.md")):
        i = read_issue(p)
        if i:
            out[i["id"]] = i
    return out


def load():
    try:
        return json.load(open(STATE))
    except (OSError, ValueError):
        return None


def save(snap):
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    json.dump(snap, open(STATE, "w"))


def emit(event, text):
    print(json.dumps({"hookSpecificOutput": {"hookEventName": event, "additionalContext": text}}))


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        data = {}
    event = data.get("hook_event_name", "UserPromptSubmit")

    if event == "PostToolUse":
        fp = (data.get("tool_input") or {}).get("file_path", "")
        if fp.startswith(ISSUES) and fp.endswith(".md"):
            snap = load() or scan()
            i = read_issue(fp)
            if i:
                snap[i["id"]] = i
            save(snap)
        return

    now = scan()
    before = load()
    save(now)
    lines = []
    if before is not None:
        for id_, i in sorted(now.items()):
            b = before.get(id_)
            if b is None:
                lines.append("NEW %s \"%s\" (%s, %s, %s)" % (id_, i["title"], i["type"], i["priority"], i["status"]))
                continue
            ch = ["%s %s -> %s" % (k, b.get(k) or "-", i[k] or "-") for k in WATCH if b.get(k) != i[k]]
            if ch:
                lines.append("%s \"%s\": %s" % (id_, i["title"], "; ".join(ch)))
        for id_ in sorted(set(before) - set(now)):
            lines.append("REMOVED/ARCHIVED %s" % id_)
    if event == "SessionStart":
        active = ["%s \"%s\" [%s]" % (id_, i["title"], i["status"]) for id_, i in sorted(now.items()) if i["status"] in ("doing", "blocked")]
        if active:
            lines.append("Currently doing/blocked: " + "; ".join(active))
    if lines:
        emit(event, "Product vault (%s) changed since last check, by the owner or outside this session:\n- %s\n"
                    "Act per the vault CLAUDE.md section 'Status changes made by the owner'." % (VAULT, "\n- ".join(lines)))


if __name__ == "__main__":
    main()
