---
name: compare
description: >
  Compare current SitRep against previous reports to identify trends.
  Use when the user asks about trends, progress over time, or wants
  to compare reports.
disable-model-invocation: false
user-invocable: true
argument-hint: [number-of-reports]
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion
model: opus
---

# SitRep Trend Analysis

You compare the current or most recent SitRep against previous reports to identify trends.

## Step 1: Find Available Reports

Use Glob to find all files in `./output/csitrep/` matching `*-sitrep.md` or `*-csitrep.md`.
Sort by date (filename contains the date).
List them for the user.

If there are fewer than 2 reports, tell the user:
"Need at least 2 SitReps to compare. Generate more reports first."

## Step 2: Select Reports to Compare

If the user provided a number argument, compare the last N reports.
Otherwise, default to comparing the 2 most recent reports.

Read all selected reports.

## Step 3: Analyze Trends

For each domain tracked in the reports, identify:

1. **Status Changes** - Did any domain move from ON TRACK to WATCH to CRITICAL (or vice versa)?
2. **Recurring Issues** - Issues that appear in multiple consecutive reports
3. **Resolved Items** - Critical/Watch items from previous reports no longer appearing
4. **New Issues** - Items appearing for the first time
5. **Metric Trends** - Any quantitative metrics trending in a direction (budget variance, schedule %, etc.)

## Step 4: Present Trend Report

```
SITREP TREND ANALYSIS
=======================

Period: [oldest report date] to [newest report date]
Reports Compared: [N]

STATUS TRAJECTORY:
- [Domain]: [Previous Status] -> [Current Status] [arrow up/down/stable]

IMPROVING:
- [Items that got better]

WORSENING:
- [Items that got worse]

PERSISTENT ISSUES (appeared in [X] consecutive reports):
- [Issue] - First flagged: [date] - Still unresolved

RESOLVED (no longer flagged):
- [Issue] - Flagged: [date] - Resolved by: [date]

NEW THIS PERIOD:
- [Items appearing for first time]

METRIC TRENDS:
- [Metric]: [value then] -> [value now] ([direction])

OVERALL PROJECT TRAJECTORY: [Improving / Stable / Declining]
```

## Rules
- Be specific about which report dates you're comparing
- Persistent issues across 3+ reports should be highlighted strongly
- Always note if critical items from last report were resolved
- If metrics are available, calculate the rate of change
- Never fabricate trend data - only compare what's explicitly in the reports
