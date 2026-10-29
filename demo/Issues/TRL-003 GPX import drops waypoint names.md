---
id: TRL-003
title: "GPX import drops waypoint names"
type: bug
status: doing
source: claude
priority: p0
severity: major
area: import
milestone: "[[1.0 launch]]"
created: 2026-10-21
updated: 2026-10-29
tags: []
---
# GPX import drops waypoint names

## Problem
Waypoints from Garmin exports arrive as 'Waypoint 1, 2, 3'. The `<name>` child is read only when it is the first child.

## Acceptance
- [ ] Works on iOS and Android

## Related
- Milestone: [[1.0 launch]]

## Activity
- 2026-10-21: filed
- 2026-10-29: status triage → doing
