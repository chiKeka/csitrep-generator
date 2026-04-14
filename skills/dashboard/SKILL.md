---
name: dashboard
description: >
  Quick one-line status per domain. Use when the user asks for a quick
  status, dashboard, summary, or health check without a full report.
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
model: sonnet
---

# Quick Dashboard

Provide a fast, at-a-glance project status without running the full agent pipeline.

## Step 1: Load Config

Read `./data/config/project-info.json`. If no project is configured, tell the user to run setup first.

## Step 2: Check for Latest SitRep

Look in `./output/csitrep/` for the most recent report file.

### If a recent report exists:
Parse it and extract the overall status for each domain. Display:

```
PROJECT DASHBOARD: [Project Name]
Last Report: [date]
Period: [weekly/monthly]

  [Domain 1]     [CRITICAL / WATCH / ON TRACK]
  [Domain 2]     [CRITICAL / WATCH / ON TRACK]
  [Domain 3]     [CRITICAL / WATCH / ON TRACK]
  [Domain 4]     [CRITICAL / WATCH / ON TRACK]
  [Domain 5]     [CRITICAL / WATCH / ON TRACK]

  Critical Issues: [count]
  Watch Items:     [count]
  Open Actions:    [count] ([count] overdue)
  Open Risks:      [count] ([count] critical)

  Next report due: [date based on period]
```

Also check `./data/config/action-log.json` and `./data/config/risk-register.json` for counts.

### If no report exists:
Quickly scan the data folders and show:

```
PROJECT DASHBOARD: [Project Name]
No SitRep generated yet.

  Data Folders:
  [Domain 1]  [X files]
  [Domain 2]  [X files]
  [Domain 3]  [X files]
  [Domain 4]  [X files]
  [Domain 5]  [X files]

  Run /csitrep-generator:generate to create your first report.
```

## Rules
- This should be FAST - no agent dispatching, just file reads
- Pull status from the latest report, don't re-analyze documents
- Keep output compact - this is a glance, not a report
- If report is older than 2x the reporting period, warn that it's stale
