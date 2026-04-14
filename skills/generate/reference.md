# SitRep Output Template

The report structure adapts to the project type. Use the following framework, replacing domain sections with the project's configured domains.

---

```
============================================================
[REPORT TITLE - Based on project type]
============================================================

PROJECT:  [Project Name]
TYPE:     [Project Type]
DATE:     [Today's Date]
PERIOD:   [Weekly/Monthly]
PREPARED: AI-Generated via SitRep Generator Plugin
LEAD:     [Project Lead from config]
BUDGET:   [Currency] [Amount]
TIMELINE: [Start Date] to [Planned Completion]

============================================================
EXECUTIVE SUMMARY
============================================================

[2-3 sentence overview of overall project health. State the
number of critical issues, watch items, and on-track areas.
Mention the most important item the reader needs to know.]

------------------------------------------------------------
CRITICAL ISSUES (Needs Decision Now)
------------------------------------------------------------

[Numbered list. Each item includes:]
1. [DOMAIN] - [Issue description]
   Source: [Document/data that flagged this]
   Impact: [What happens if not addressed]
   Action: [Recommended immediate action]

2. ...

If no critical issues: "No critical issues this period."

------------------------------------------------------------
WATCH ITEMS (Trending Negative)
------------------------------------------------------------

[Numbered list of items trending toward problems]
1. [DOMAIN] - [Item] - [Current trend]
2. ...

If no watch items: "No watch items this period."

------------------------------------------------------------
ON TRACK
------------------------------------------------------------

[Brief summary of domains performing within tolerance]

============================================================
DETAILED STATUS BY DOMAIN
============================================================

[For EACH domain configured in project-info.json, create a
section using this pattern:]

------------------------------------------------------------
[DOMAIN NAME] STATUS
------------------------------------------------------------

Overall: [CRITICAL / WATCH / ON TRACK]

[Agent findings for this domain - paste the agent's analysis]

Key Metrics:
[Domain-specific metrics from the agent's output]

[Repeat for all 5 domains]

============================================================
RECOMMENDED ACTIONS
============================================================

[Prioritized list of 5-7 actions. Each tied to a finding.]

| # | Action | Owner | Due By | Domain |
|---|--------|-------|--------|--------|
| 1 | [Action] | [Who] | [Date] | [Domain] |
| 2 | [Action] | [Who] | [Date] | [Domain] |
| ... | | | | |

============================================================
PERIOD-OVER-PERIOD TRENDS
============================================================

[If this is the first report:]
First report - baselines established. Trends will appear
in subsequent reports.

[If previous report exists:]

Status Trajectory:
- [Domain 1]: [Previous] -> [Current] (IMPROVING/DECLINING/STABLE)
- [Domain 2]: [Previous] -> [Current] (IMPROVING/DECLINING/STABLE)
- [Domain 3]: [Previous] -> [Current] (IMPROVING/DECLINING/STABLE)
- [Domain 4]: [Previous] -> [Current] (IMPROVING/DECLINING/STABLE)
- [Domain 5]: [Previous] -> [Current] (IMPROVING/DECLINING/STABLE)

Key Metric Movements:
| Metric | Previous | Current | Direction |
|--------|----------|---------|-----------|
| [Metric 1] | [value] | [value] | IMPROVING/DECLINING |
| [Metric 2] | [value] | [value] | IMPROVING/DECLINING |

Resolved Since Last Report:
- [Issues from last period that are now closed]

Persistent Issues:
- [Issue] - [X] consecutive periods - First flagged: [date]

New This Period:
- [Issues appearing for the first time]

Overall Trajectory: [IMPROVING / STABLE / DECLINING]

============================================================
RISK SUMMARY
============================================================

[If risk-register.json exists, include top 5 risks:]

| Risk | Likelihood | Impact | Score | Owner |
|------|-----------|--------|-------|-------|
| [Risk] | H/M/L | H/M/L | [Score] | [Owner] |

[If no risk register: "No risk register configured.
Run /csitrep-generator:track-risks to start tracking."]

============================================================
OPEN ACTIONS STATUS
============================================================

[If action-log.json exists, show open action summary:]

- Total Open: [X]
- Overdue: [X]
- Completed Since Last Report: [X]

[Top overdue actions listed]

[If no action log: "No action log configured.
Run /csitrep-generator:track-actions to start tracking."]

============================================================
APPENDIX
============================================================

Documents Analyzed:
[For each domain, list the files the agent reviewed]

- [Domain 1]: [file1, file2, ...]
- [Domain 2]: [file1, file2, ...]
- [Domain 3]: [file1, file2, ...]
- [Domain 4]: [file1, file2, ...]
- [Domain 5]: [file1, file2, ...]

Project Configuration:
- Type: [project_type]
- Domains: [list of domain names]
- Reporting Period: [weekly/monthly]

Report generated: [full timestamp]
Next report due:  [calculated from period]
Plugin version:   1.0.0

============================================================
END OF REPORT
============================================================
```

## Report Title by Project Type

| Type | Title |
|------|-------|
| construction | CONSTRUCTION SITUATION REPORT (CSitRep) |
| software | SOFTWARE PROJECT SITUATION REPORT |
| program | PROGRAM SITUATION REPORT |
| product | PRODUCT DEVELOPMENT SITUATION REPORT |
| consulting | ENGAGEMENT SITUATION REPORT |
| custom | PROJECT SITUATION REPORT |

## Formatting Rules

1. **CRITICAL items always appear first** in every section
2. **Metrics should be quantitative** wherever the data supports it (%, $, counts, days)
3. **Source attribution** - every finding should reference the document it came from
4. **No filler** - if a section has nothing to report, say "Nothing to report" not a paragraph of padding
5. **Actionable language** - findings should suggest what to do, not just describe what is
6. **Consistent status labels** - always use CRITICAL / WATCH / ON TRACK (never red/yellow/green in text)
