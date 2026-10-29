---
id: TRL-013
title: "Search ignores accents"
type: bug
status: triage
source: claude
priority: p2
severity: minor
area: app
milestone: 
created: 2026-10-29
updated: 2026-10-29
tags: ["verify"]
---
# Search ignores accents

```dataviewjs
await dv.view("Dashboard/triage-actions")
```

## Problem
Searching 'Cervinia' doesn't find 'Cervínia'.

## Acceptance
- [ ] Works on iOS and Android

## Related
- Milestone: 
- [[TRL-006 Crash when a trail has no photos]]
- [[TRL-007 Share a trail as a link]]

## Activity
- 2026-10-29: filed
