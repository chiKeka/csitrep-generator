---
name: track-cost
description: >
  Track project budget, costs, commitments, and forecast. Use when the user
  wants to view budget status, log an expense, update cost forecasts, track
  contingency, or get a cost summary between report periods.
disable-model-invocation: false
user-invocable: true
argument-hint: [action: view|log|forecast|contingency]
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
model: sonnet
---

# Cost and Budget Tracker

Manage project cost data stored at `./data/config/cost-tracker.json`.
This provides a living budget view between full SitRep reports.

## Actions

### View Budget Status (`/csitrep-generator:track-cost view`)

1. Read `./data/config/cost-tracker.json`
2. Read `./data/config/project-info.json` for original budget
3. Display a formatted budget summary:

```
BUDGET STATUS - [Project Name]
Updated: [last_updated]

                        Budget      Committed    Spent       Remaining
Original Contract:      $[X]
Approved Changes:       $[X]
Current Budget:         $[X]        $[X]         $[X]        $[X]
                                    [X]%         [X]%        [X]%

COST BY CATEGORY:
| Category          | Budget    | Committed | Spent     | Variance  | Status |
|-------------------|-----------|-----------|-----------|-----------|--------|
| [Category 1]      | $[X]      | $[X]      | $[X]      | $[X] (X%) | [OK/OVER/WATCH] |
| [Category 2]      | $[X]      | $[X]      | $[X]      | $[X] (X%) | [OK/OVER/WATCH] |
| ...               |           |           |           |           |        |

CONTINGENCY:
  Original:          $[X]
  Used:              $[X]
  Remaining:         $[X] ([X]% of budget)
  Pending claims:    $[X]
  Projected remaining: $[X]

FORECAST:
  Estimate at Completion (EAC):   $[X]
  Variance at Completion (VAC):   $[X] ([over/under])
  Burn Rate:                      $[X]/[period]
  Projected Overrun/Underrun:     $[X]

ALERTS:
- [Any categories over budget]
- [Contingency below 5% warning]
- [Burn rate above plan]
```

### Log Cost Entry (`/csitrep-generator:track-cost log`)

Ask the user for:
- Category (from existing categories, or create new)
- Description (what is the cost for)
- Amount
- Type: committed / spent / adjustment
- Date (default today)
- Reference (PO number, invoice number, etc.) - optional

Add to cost-tracker.json:
```json
{
  "id": "COST-001",
  "category": "Site Work",
  "description": "Additional soil stabilization",
  "amount": 45000,
  "type": "spent",
  "date": "2026-03-07",
  "reference": "INV-2026-0234",
  "logged_by": "user",
  "logged_date": "2026-03-07"
}
```

After logging, show updated category total and overall budget status.

### Update Forecast (`/csitrep-generator:track-cost forecast`)

1. Show current budget status
2. Ask which categories need forecast updates
3. For each selected category, ask:
   - Estimated cost to complete
   - Reason for change (scope change, market conditions, productivity, etc.)
4. Recalculate:
   - Estimate at Completion (EAC) = Spent + Committed + Estimated to Complete
   - Variance at Completion (VAC) = Budget - EAC
5. Save updated forecast
6. Flag if EAC exceeds budget

### Contingency Status (`/csitrep-generator:track-cost contingency`)

1. Show contingency breakdown:
   - Original contingency amount
   - Approved draws (list each with date, amount, reason)
   - Pending claims against contingency
   - Remaining contingency
   - Projected remaining after pending claims
2. If contingency is below 5%, flag as critical
3. If contingency is below 10%, flag as watch

## Cost Tracker Format (cost-tracker.json)

```json
{
  "last_updated": "2026-03-07",
  "original_budget": 12800000,
  "approved_changes": 155000,
  "current_budget": 12955000,
  "contingency": {
    "original": 500000,
    "draws": [
      {
        "date": "2026-02-15",
        "amount": 85000,
        "reason": "Soil stabilization - unforeseen conditions",
        "reference": "CO-001"
      }
    ],
    "pending_claims": 192000,
    "remaining": 350000
  },
  "categories": [
    {
      "name": "General Conditions",
      "budget": 1200000,
      "committed": 1150000,
      "spent": 580000
    },
    {
      "name": "Site Work",
      "budget": 1370000,
      "committed": 1440000,
      "spent": 620000
    }
  ],
  "entries": [
    {
      "id": "COST-001",
      "category": "Site Work",
      "description": "Additional excavation - rock conditions",
      "amount": 45000,
      "type": "spent",
      "date": "2026-03-05",
      "reference": "INV-2026-0234",
      "logged_by": "user",
      "logged_date": "2026-03-07"
    }
  ],
  "forecast": {
    "eac": 13100000,
    "vac": -145000,
    "updated": "2026-03-07"
  }
}
```

If the file doesn't exist, create it from project-info.json budget data with empty categories and entries.

## Initial Setup

When run for the first time (no cost-tracker.json exists):
1. Read project-info.json for budget amount
2. Ask the user for their cost categories (or suggest defaults based on project type):

**Construction defaults:**
General Conditions, Site Work, Concrete, Structural Steel, MEP (Mechanical/Electrical/Plumbing), Envelope, Interiors, Contingency

**Software defaults:**
Personnel, Infrastructure/Cloud, Licenses/Tools, Contractors, QA/Testing, Contingency

**Program defaults:**
Personnel, Travel, Equipment, Subgrants, M&E, Overhead, Contingency

**Product defaults:**
R&D, Tooling, Raw Materials, Manufacturing, QA/Compliance, Contingency

**Consulting defaults:**
Senior Staff, Junior Staff, Travel, Subcontractors, Technology, Contingency

3. Ask for budget allocation per category
4. Save the initial cost-tracker.json

## Integration with SitRep

The cost agent in the generate skill should read cost-tracker.json (if it exists) alongside the documents in the cost data folder. This gives the agent both:
- Document-based analysis (invoices, pay apps, budget reports)
- Tracker-based data (logged entries, forecast, contingency status)

## Rules
- Always show variance as both dollar amount and percentage
- Flag categories over budget in the display
- Contingency below 5% = CRITICAL, below 10% = WATCH
- Never delete cost entries - they form an audit trail
- When logging costs, update the category committed/spent totals automatically
- EAC calculation: Spent to Date + Remaining Committed + Estimated Remaining Work
- Sort categories by variance (worst first) when displaying
- Currency follows project-info.json currency setting
