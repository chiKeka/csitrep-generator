---
name: track-changes
description: >
  Manage change orders, variations, and scope changes. Use when the user wants
  to log a change order, track CO status, view pending changes, or analyze
  change impact on budget and schedule. Works across all project types.
disable-model-invocation: false
user-invocable: true
argument-hint: [action: view|add|update|analyze]
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
model: sonnet
---

# Change Order / Change Management Tracker

Manage change orders and scope changes stored at `./data/config/change-log.json`.
Adapts terminology based on project type:
- Construction: Change Orders (CO)
- Software: Change Requests (CR)
- Program: Scope Modifications / Variations
- Product: Engineering Change Orders (ECO)
- Consulting: Scope Changes / Contract Amendments

## Actions

### View Changes (`/csitrep-generator:track-changes view`)

1. Read `./data/config/change-log.json`
2. Read `./data/config/project-info.json` for project type and budget
3. Display formatted summary:

```
CHANGE ORDER LOG - [Project Name]
Updated: [date]

SUMMARY:
  Total Changes:      [X]
  Approved:           [X]  ($[total])
  Pending:            [X]  ($[total])
  Rejected:           [X]  ($[total])
  Withdrawn:          [X]

  Budget Impact:      $[net approved] ([X]% of original budget)
  Schedule Impact:    [X] days (net approved)
  Pending Exposure:   $[total pending] / [X] days

CHANGE LOG:
| ID     | Description              | Cost      | Days | Status   | Date     | Owner    |
|--------|--------------------------|-----------|------|----------|----------|----------|
| CO-001 | Soil stabilization       | $85,000   | +5   | Approved | 03/01    | PM       |
| CO-002 | MEP routing change       | $70,000   | +3   | Approved | 03/03    | PM       |
| CO-003 | Rock excavation Zone B   | $85,000   | +6   | Pending  | 03/05    | PM       |
| CO-004 | Concrete mix upgrade     | $42,000   | 0    | Pending  | 03/06    | Supt     |
| CO-005 | Temporary shoring        | $65,000   | +5   | Pending  | 03/06    | PM       |

TREND:
  Changes this period:     [X]
  Changes last period:     [X]
  Avg cost per change:     $[X]
  Avg schedule impact:     [X] days
  Top category:            [most common reason]
```

### Add Change (`/csitrep-generator:track-changes add`)

Ask the user for:
- Description (what is changing)
- Reason / justification (one of: differing conditions, design change, owner request, regulatory, error/omission, value engineering, other)
- Cost impact (positive = increase, negative = savings, 0 = no cost impact)
- Schedule impact in days (positive = delay, negative = acceleration, 0 = none)
- Responsible party / owner
- Priority (urgent / normal)
- Supporting documents (optional - reference to files in data folders)

Auto-assign next ID based on project type:
- Construction: CO-001, CO-002...
- Software: CR-001, CR-002...
- Program: SM-001, SM-002...
- Product: ECO-001, ECO-002...
- Consulting: SC-001, SC-002...

Save with status "Pending" and today's date.

```json
{
  "id": "CO-006",
  "description": "Additional fire stopping at floor penetrations",
  "reason": "regulatory",
  "cost_impact": 38000,
  "schedule_impact": 0,
  "status": "Pending",
  "priority": "normal",
  "owner": "Mike Torres",
  "submitted_date": "2026-03-07",
  "decision_date": null,
  "decided_by": null,
  "notes": "",
  "supporting_docs": ["data/contracts/rfi-047.pdf"]
}
```

After adding, show the updated pending total and budget exposure.

### Update Change (`/csitrep-generator:track-changes update`)

1. Show all changes (or filter by status: pending, approved, rejected)
2. Ask which change to update (by ID)
3. Ask what changed:
   - **Approve**: Set status to "Approved", ask for decision date and decided_by. Update cost-tracker.json if it exists (adjust approved_changes and relevant category).
   - **Reject**: Set status to "Rejected", ask for reason
   - **Withdraw**: Set status to "Withdrawn", ask for reason
   - **Revise**: Update cost or schedule impact, add revision note
   - **Add note**: Append to notes field

4. If approved and cost-tracker.json exists:
   - Add the approved amount to `approved_changes` in cost-tracker
   - Update `current_budget`
   - Draw from contingency if applicable
   - Log as a cost entry automatically

5. Confirm the update with before/after comparison.

### Analyze Changes (`/csitrep-generator:track-changes analyze`)

Analyze change patterns across the change log:

```
CHANGE ANALYSIS - [Project Name]

COST IMPACT:
  Original Budget:           $[X]
  Approved Changes:          $[X] ([X]%)
  Pending Changes:           $[X] ([X]%)
  Projected Budget:          $[X] (if all pending approved)

SCHEDULE IMPACT:
  Original Duration:         [X] days
  Approved Extensions:       [X] days
  Pending Extensions:        [X] days
  Projected Duration:        [X] days (if all pending approved)

ROOT CAUSE BREAKDOWN:
| Reason              | Count | Cost      | % of Changes |
|---------------------|-------|-----------|-------------- |
| Differing conditions| [X]   | $[X]      | [X]%          |
| Design change       | [X]   | $[X]      | [X]%          |
| Owner request       | [X]   | $[X]      | [X]%          |
| Regulatory          | [X]   | $[X]      | [X]%          |
| Error/omission      | [X]   | $[X]      | [X]%          |
| Value engineering   | [X]   | $[X]      | [X]%          |

PATTERNS:
- [Identify clusters: e.g., "3 of 5 changes relate to unforeseen soil conditions"]
- [Identify acceleration: e.g., "Change frequency increasing - 1 last period, 3 this period"]
- [Identify cost trends: e.g., "Average change cost trending up: $70K -> $85K"]

RECOMMENDATIONS:
- [Based on patterns, suggest actions: e.g., "Differing conditions account for 60% of changes. Consider geotechnical review of remaining zones."]
- [If pending changes exceed contingency: "Pending COs ($192K) exceed remaining contingency ($158K). Budget discussion needed."]
```

## Change Log Format (change-log.json)

```json
{
  "last_updated": "2026-03-07",
  "project_type": "construction",
  "id_prefix": "CO",
  "changes": [
    {
      "id": "CO-001",
      "description": "Soil stabilization - unforeseen conditions",
      "reason": "differing_conditions",
      "cost_impact": 85000,
      "schedule_impact": 5,
      "status": "Approved",
      "priority": "urgent",
      "owner": "Mike Torres",
      "submitted_date": "2026-02-20",
      "decision_date": "2026-03-01",
      "decided_by": "Owner Rep",
      "notes": "Approved with condition to use lime stabilization method",
      "supporting_docs": [],
      "revisions": []
    }
  ]
}
```

If the file doesn't exist, create it with empty changes array and set id_prefix based on project type.

## Reason Codes (standardized across project types)

| Code | Construction | Software | Program | Product | Consulting |
|------|-------------|----------|---------|---------|-----------|
| differing_conditions | Unforeseen site conditions | Technical discovery | Field conditions | Material availability | Market change |
| design_change | Design modification | Requirements change | Program redesign | Design revision | Methodology change |
| owner_request | Owner/client request | Stakeholder request | Donor requirement | Customer request | Client request |
| regulatory | Code/regulation change | Compliance requirement | Policy change | Regulatory requirement | Regulatory change |
| error_omission | Design error/omission | Bug/defect | Planning error | Engineering error | Scope gap |
| value_engineering | Value engineering | Optimization | Efficiency improvement | Cost reduction | Process improvement |
| other | Other | Other | Other | Other | Other |

## Integration with SitRep

The generate skill's agents should read change-log.json (if it exists) alongside domain documents. This gives agents:
- Pending changes that may affect their domain
- Approved changes that explain budget/schedule shifts
- Change patterns that indicate systemic issues

## Integration with Cost Tracker

When a change order is approved:
1. Update change-log.json status
2. If cost-tracker.json exists, automatically:
   - Add approved amount to `approved_changes`
   - Recalculate `current_budget`
   - Draw from contingency if specified
   - Create a cost entry for audit trail

## Rules
- Never delete changes - status changes only (Pending -> Approved/Rejected/Withdrawn)
- Track all revisions to a change (if cost estimate changes before approval)
- Always show both cost AND schedule impact together
- Auto-assign IDs based on project type prefix
- Sort by status (Pending first, then Approved, then Rejected) when displaying
- The analyze function should identify actionable patterns, not just summarize data
- When pending changes exceed remaining contingency, flag as CRITICAL
- Currency follows project-info.json currency setting
