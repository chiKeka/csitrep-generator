---
name: feedback
description: >
  Flag a finding in a SitRep as incorrect, inaccurate, or needing adjustment.
  Use when a team member disagrees with a report finding, wants to correct data,
  or wants to improve future reports. Builds a learning log that agents reference.
disable-model-invocation: false
user-invocable: true
argument-hint: [report-date]
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
model: sonnet
---

# Report Feedback

Allow users to flag findings in generated reports as incorrect, inaccurate, or needing context. Feedback is stored and used to improve future report accuracy.

## Step 1: Find the Report

If the user provided a date, look for `./output/csitrep/[date]-sitrep.md`.
Otherwise, use the most recent report in `./output/csitrep/`.

Read the report and display a numbered summary of all findings:
```
Findings from [DATE] report:

CRITICAL ISSUES:
  C1. [Domain] - [Issue summary]
  C2. [Domain] - [Issue summary]

WATCH ITEMS:
  W1. [Domain] - [Item summary]
  W2. [Domain] - [Item summary]
  ...

RECOMMENDED ACTIONS:
  A1. [Action summary]
  A2. [Action summary]
  ...

Which finding do you want to provide feedback on? (e.g., C1, W3, A2)
Or type "general" for overall report feedback.
```

## Step 2: Collect Feedback

Once the user selects a finding, ask:

```
What's the issue with this finding?

1. Incorrect   - The data or conclusion is wrong
2. Overstated  - The severity is too high (e.g., flagged CRITICAL but should be WATCH)
3. Understated - The severity is too low (e.g., flagged ON TRACK but should be WATCH/CRITICAL)
4. Missing context - The finding is technically correct but missing important context
5. Outdated    - This has already been resolved since the data was collected
6. Other       - Free text
```

Then ask for details:
```
Please explain what should be different:
```

Optionally ask:
```
Should future reports account for this? (yes/no)
```

## Step 3: Save Feedback

Load or create `./data/config/feedback-log.json`:

```json
{
  "feedback": [
    {
      "id": "FB-001",
      "report_date": "2026-03-07",
      "finding_ref": "C1",
      "domain": "Schedule",
      "original_finding": "Structural steel delivery delayed 12 days",
      "feedback_type": "outdated",
      "details": "Fabricator confirmed partial delivery on 03/08, only 5 days delayed now",
      "submitted_by": "user",
      "submitted_date": "2026-03-08",
      "apply_to_future": true,
      "status": "open"
    }
  ]
}
```

Auto-increment the ID (FB-001, FB-002, etc.).

## Step 4: Confirm

```
Feedback recorded:

  ID:       FB-[XXX]
  Report:   [date]
  Finding:  [ref] - [summary]
  Type:     [type]
  Details:  [user's explanation]
  Future:   [Will / Will not] be referenced in future reports

This feedback will be available to agents in the next report generation.
```

## Step 5: How Agents Use Feedback

When the generate skill runs, it should check `feedback-log.json` for any feedback with `apply_to_future: true` and `status: "open"`. This context is passed to agents so they can:

- Adjust severity if feedback says a finding was overstated/understated
- Note resolved items if feedback says something is outdated
- Include additional context if feedback says context was missing
- Avoid repeating incorrect conclusions

Agents receive feedback as:
```
PREVIOUS FEEDBACK (consider when analyzing):
- [FB-001] Schedule: "Steel delivery was partially resolved, now 5 days delayed not 12"
- [FB-003] Cost: "Rock excavation CO was approved at $72K not $85K"
```

## Slack Feedback (Team Members Without CLI)

When a report is posted to Slack, include a feedback prompt at the end of the main message:

```
To flag a finding, reply to this thread with:
  "feedback C1: [your correction]"
  "feedback W3: severity should be lower, issue was resolved yesterday"
  "feedback general: missing context about the new subcontractor"
```

When the generate skill detects a Slack thread reply matching the `feedback [ref]: [text]` pattern:
1. Parse the reference (C1, W3, A2, general) and the text
2. Auto-classify the feedback type from the text:
   - Contains "wrong" / "incorrect" / "not true" -> incorrect
   - Contains "resolved" / "fixed" / "done" / "closed" -> outdated
   - Contains "should be lower" / "overstated" / "not that bad" -> overstated
   - Contains "should be higher" / "understated" / "worse than" -> understated
   - Contains "missing" / "also" / "context" -> missing_context
   - Default: other
3. Save to feedback-log.json with `submitted_by: "slack-[username]"` and `source: "slack"`
4. Reply in the Slack thread confirming: "Feedback FB-[XXX] recorded. This will be factored into the next report."

This allows team members to provide feedback directly from Slack without ever opening a terminal.

## Rules
- Never delete or modify the original report based on feedback
- Feedback is additive - it enriches future reports, doesn't change past ones
- Keep feedback log entries forever (they're lightweight and valuable for learning)
- If feedback contradicts source documents, note both perspectives
- Mark feedback as "resolved" when a subsequent report addresses it correctly
- Slack feedback must be just as easy as CLI feedback - one-line reply in thread
- Always confirm feedback receipt in Slack so the user knows it was captured
