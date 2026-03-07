---
name: import
description: >
  Import data from common PM tools (Jira, MS Project, Primavera, Procore,
  Monday.com, Asana, Smartsheet). Converts exports into the folder structure
  expected by the SitRep agents. Use when users have data in external tools.
disable-model-invocation: false
user-invocable: true
argument-hint: [tool-name]
allowed-tools: Read, Write, Bash, Glob, Grep, AskUserQuestion
model: opus
---

# PM Tool Data Import

Import project data from external PM tools and place it in the correct domain folders.

## Step 1: Identify the Source Tool

If the user provided a tool name as argument, use that. Otherwise ask:

```
Which tool are you importing from?

1. Jira / Jira Software      - Sprint data, issues, boards
2. MS Project (.mpp/.xml)    - Schedule, Gantt, resources
3. Primavera P6 (.xer/.xml)  - CPM schedule, resources, costs
4. Procore                    - Construction: daily logs, RFIs, submittals, budget
5. Monday.com                - Boards, timelines, dashboards
6. Asana                     - Tasks, projects, portfolios
7. Smartsheet                - Sheets, reports, dashboards
8. Excel / CSV               - Generic spreadsheet import
9. Other                     - I'll describe the format
```

## Step 2: Guide the Export

For each tool, tell the user exactly how to export their data:

### Jira
```
In Jira, export your data:
1. Board view -> Export -> CSV (for sprint/backlog data)
2. Filters -> Search -> Export -> CSV (for issues/bugs)
3. Project Settings -> Reports -> Burndown -> Export

Drop the CSV files into the appropriate data folders:
- Sprint/backlog exports  -> data/sprint/ (or data/schedule/)
- Bug/defect exports      -> data/quality/
- Time tracking exports   -> data/budget/
```

### MS Project
```
In MS Project:
1. File -> Save As -> XML (.xml) for full schedule
2. Or File -> Export -> CSV for simplified data
3. Reports -> Cost -> Export for cost data

Drop the files:
- Schedule XML/CSV  -> data/schedule/ (or data/timeline/)
- Resource sheets   -> data/budget/ (or data/resources/)
- Cost reports      -> data/cost/
```

### Primavera P6
```
In Primavera P6:
1. File -> Export -> XER (full project) or XML
2. Reports -> Schedule -> Export -> CSV
3. Reports -> Resource -> Export -> CSV

Drop the files:
- XER/XML exports   -> data/schedule/
- Resource reports   -> data/cost/
```

### Procore
```
In Procore, export from each module:
1. Daily Log -> Export PDF/CSV           -> data/site/
2. Budget -> Export CSV                  -> data/cost/
3. RFIs -> Export CSV                    -> data/contracts/
4. Submittals -> Export CSV              -> data/contracts/
5. Observations/Safety -> Export CSV     -> data/safety/
6. Schedule -> Export CSV                -> data/schedule/
7. Change Orders -> Export CSV           -> data/cost/
```

### Monday.com
```
In Monday.com:
1. Board -> Menu (...) -> Export to CSV
2. Dashboard -> Export

Map boards to folders based on content:
- Timeline/schedule boards  -> data/schedule/ (or data/timeline/)
- Budget/finance boards     -> data/budget/ (or data/cost/)
- Issue tracking boards     -> data/blockers/ (or data/risks/)
```

### Asana
```
In Asana:
1. Project -> Export -> CSV
2. Or use the Advanced Search -> Export

Map to folders based on content:
- Task lists with dates     -> data/schedule/ (or data/deliverables/)
- Workload/resource data    -> data/resources/
```

### Smartsheet
```
In Smartsheet:
1. Sheet -> File -> Export -> CSV or Excel
2. Reports -> Export -> CSV

Map to folders based on sheet content.
```

### Excel / CSV (Generic)
```
Drop your spreadsheet files into the data folder that best matches the content:
- Schedule/timeline data    -> data/[schedule folder]/
- Budget/cost data          -> data/[cost folder]/
- Issues/risks/quality      -> data/[relevant domain folder]/

The preprocessing script will convert .xlsx to .csv automatically.
```

### Other
Ask the user to describe:
1. What tool they're exporting from
2. What format the export is in
3. What data it contains

Then map it to the appropriate domain folders.

## Step 3: Verify the Import

After the user drops files, verify:
1. Files are in the expected folders
2. Files are readable (run preprocess if needed)
3. Quick content check to confirm the mapping is correct

```bash
bash ./scripts/preprocess.sh
```

## Step 4: Auto-Map Columns (for CSV/Excel)

If the imported files are CSV/Excel, read the headers and map them to what the agents expect:

- Date columns -> schedule/timeline context
- Dollar/currency columns -> cost/budget context
- Status columns -> progress tracking
- Name/assignee columns -> resource/responsibility context

If columns don't map obviously, show the user the headers and ask which domain they belong to.

## Step 5: Confirm Import

```
Import complete:

  Source:     [Tool name]
  Files:      [X] files imported
  Domains:
    [Domain 1]: [X] files ([file names])
    [Domain 2]: [X] files ([file names])
    ...

  Ready to generate a report with /csitrep-generator:generate
```

## Step 6: Save Import Config (for recurring imports)

If the user will import from this tool regularly, save the mapping:

Add to `project-info.json`:
```json
{
  "import_source": {
    "tool": "procore",
    "last_import": "2026-03-07",
    "mapping": {
      "daily-log": "data/site/",
      "budget": "data/cost/",
      "rfis": "data/contracts/",
      "safety": "data/safety/"
    }
  }
}
```

This way, next time the user can just drop new exports and the system knows where things go.

## Rules
- Never modify the source files - only copy or move them to data folders
- Always run preprocessing after import to convert formats
- The import skill is a guide + validator, not a direct API integration
- Support the export formats each tool actually provides (CSV, XML, PDF, Excel)
- If a tool provides API access, mention it but don't require it
- Make the folder mapping clear so users can repeat without the skill
- For Primavera XER files: these are text-based and agents can read them directly
