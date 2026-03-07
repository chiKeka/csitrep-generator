---
name: track-risks
description: >
  Maintain and analyze a project risk register. Use when the user asks about
  risks, wants to add/update risks, or needs a risk summary.
disable-model-invocation: false
user-invocable: true
argument-hint: [action: view|add|update]
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
model: sonnet
---

# Risk Register Manager

You manage the project risk register stored at `./data/config/risk-register.json`.

## Actions

### View Risks (`/csitrep-generator:track-risks view`)
1. Read `./data/config/risk-register.json`
2. Display all active risks in a formatted table:
   - ID, Description, Likelihood (H/M/L), Impact (H/M/L), Status, Owner, Mitigation, Last Updated
3. Highlight overdue mitigations
4. Show summary: total risks, critical count, new this period, closed this period

### Add Risk (`/csitrep-generator:track-risks add`)
1. Ask the user for: Description, Likelihood, Impact, Owner, Mitigation plan, Due date
2. Auto-assign next ID (RISK-001, RISK-002, etc.)
3. Add to risk-register.json with status "Open" and today's date
4. Confirm the addition

### Update Risk (`/csitrep-generator:track-risks update`)
1. Show current risks
2. Ask which risk to update (by ID)
3. Ask what changed (status, likelihood, impact, mitigation progress)
4. Update the entry with new data and today's date
5. Confirm the update

## Risk Register Format (risk-register.json)

```json
{
  "risks": [
    {
      "id": "RISK-001",
      "description": "Steel delivery delay",
      "likelihood": "High",
      "impact": "High",
      "score": "Critical",
      "status": "Open",
      "owner": "PM Name",
      "mitigation": "Expedite with alternate supplier",
      "due_date": "2026-03-15",
      "created": "2026-03-01",
      "updated": "2026-03-07",
      "notes": ""
    }
  ]
}
```

If the file doesn't exist, create it with an empty risks array.

## Auto-Scoring
- High Likelihood + High Impact = Critical
- High + Medium or Medium + High = High
- Medium + Medium = Medium
- Anything with Low = Low

## Rules
- Always sort by score (Critical first) when displaying
- Flag overdue mitigations in red
- Never delete risks - mark them as "Closed" with a resolution note
