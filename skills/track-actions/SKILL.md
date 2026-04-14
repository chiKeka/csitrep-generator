---
name: track-actions
description: >
  Track action items across SitReps. Use when the user asks about action
  items, wants to add/update actions, or check overdue items.
disable-model-invocation: false
user-invocable: true
argument-hint: [action: view|add|update|overdue]
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
model: sonnet
---

# Action Item Tracker

You manage the action item log stored at `./data/config/action-log.json`.

## Actions

### View All (`/csitrep-generator:track-actions view`)
1. Read `./data/config/action-log.json`
2. Display all open actions in a formatted table:
   - ID, Action, Owner, Due Date, Status, Source (which SitRep), Priority
3. Show summary: total open, overdue, completed this period

### View Overdue (`/csitrep-generator:track-actions overdue`)
1. Show only actions past their due date that aren't completed
2. Highlight how many days overdue each is
3. Group by owner

### Add Action (`/csitrep-generator:track-actions add`)
1. Ask for: Action description, Owner, Due date, Priority (High/Medium/Low), Source domain
2. Auto-assign ID (ACT-001, ACT-002, etc.)
3. Add to action-log.json with status "Open" and today's date
4. Confirm

### Update Action (`/csitrep-generator:track-actions update`)
1. Show current open actions
2. Ask which to update (by ID)
3. Ask for new status (In Progress, Completed, Cancelled) and any notes
4. Update with today's date
5. Confirm

## Action Log Format (action-log.json)

```json
{
  "actions": [
    {
      "id": "ACT-001",
      "description": "Escalate steel delivery with fabricator",
      "owner": "Project Manager",
      "due_date": "2026-03-10",
      "priority": "High",
      "status": "Open",
      "source_domain": "Schedule",
      "source_report": "2026-03-07-sitrep.md",
      "created": "2026-03-07",
      "updated": "2026-03-07",
      "completion_notes": ""
    }
  ]
}
```

If the file doesn't exist, create it with an empty actions array.

## Integration with SitRep

When the generate skill produces a SitRep with RECOMMENDED ACTIONS, those actions should be tracked here. After generating a SitRep, suggest the user run `/csitrep-generator:track-actions add` for each recommended action.

## Rules
- Sort by due date (soonest first) when displaying
- Overdue items always shown first
- Never delete actions - mark as Completed or Cancelled
- Include the source SitRep filename for traceability
