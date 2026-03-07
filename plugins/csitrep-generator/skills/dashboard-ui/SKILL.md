---
name: dashboard-ui
description: >
  Generate a visual HTML dashboard from the latest SitRep. Use when the user
  wants a visual report, HTML dashboard, PDF report, or browser-viewable status.
disable-model-invocation: false
user-invocable: true
argument-hint: [report-date]
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
model: opus
---

# Visual Dashboard Generator

Generate a styled HTML dashboard from the latest (or specified) SitRep report.

## Step 1: Find the Report

If the user provided a date argument, look for `./output/csitrep/[date]-sitrep.md`.
Otherwise, find the most recent report in `./output/csitrep/`.

If no reports exist, tell the user to run `/csitrep-generator:generate` first.

Read the report file and also read `./data/config/project-info.json` for project metadata.

## Step 2: Parse the Report

Extract from the markdown report:
- Project name, date, period
- Executive summary
- Critical issues (count and details)
- Watch items (count and details)
- On-track items
- Each domain's status and key metrics
- Recommended actions
- Risk summary (if available)
- Action items status (if available)

## Step 3: Generate HTML Dashboard

Create an HTML file at `./output/csitrep/[date]-dashboard.html` using this structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>[Project Name] - SitRep Dashboard</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f172a; color: #e2e8f0; padding: 24px; }
  .header { text-align: center; padding: 24px 0; border-bottom: 2px solid #334155; margin-bottom: 24px; }
  .header h1 { font-size: 28px; color: #f8fafc; }
  .header .meta { color: #94a3b8; font-size: 14px; margin-top: 8px; }
  .summary-cards { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-bottom: 24px; }
  .card { background: #1e293b; border-radius: 12px; padding: 20px; border-left: 4px solid; }
  .card.critical { border-left-color: #ef4444; }
  .card.watch { border-left-color: #f59e0b; }
  .card.ontrack { border-left-color: #22c55e; }
  .card .count { font-size: 36px; font-weight: 700; }
  .card.critical .count { color: #ef4444; }
  .card.watch .count { color: #f59e0b; }
  .card.ontrack .count { color: #22c55e; }
  .card .label { color: #94a3b8; font-size: 14px; margin-top: 4px; }
  .domains { display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 16px; margin-bottom: 24px; }
  .domain { background: #1e293b; border-radius: 12px; padding: 20px; }
  .domain h3 { font-size: 16px; margin-bottom: 12px; display: flex; align-items: center; gap: 8px; }
  .status-badge { display: inline-block; padding: 2px 10px; border-radius: 12px; font-size: 12px; font-weight: 600; text-transform: uppercase; }
  .status-badge.critical { background: #991b1b; color: #fca5a5; }
  .status-badge.watch { background: #92400e; color: #fcd34d; }
  .status-badge.ontrack { background: #166534; color: #86efac; }
  .domain .metrics { color: #cbd5e1; font-size: 14px; line-height: 1.8; }
  .domain .findings { margin-top: 12px; }
  .domain .finding { padding: 8px 0; border-top: 1px solid #334155; font-size: 13px; color: #94a3b8; }
  .actions { background: #1e293b; border-radius: 12px; padding: 20px; margin-bottom: 24px; }
  .actions h2 { font-size: 18px; margin-bottom: 16px; }
  .actions table { width: 100%; border-collapse: collapse; }
  .actions th { text-align: left; padding: 8px 12px; border-bottom: 2px solid #334155; color: #94a3b8; font-size: 12px; text-transform: uppercase; }
  .actions td { padding: 8px 12px; border-bottom: 1px solid #1e293b; font-size: 14px; }
  .executive { background: #1e293b; border-radius: 12px; padding: 20px; margin-bottom: 24px; }
  .executive h2 { font-size: 18px; margin-bottom: 12px; }
  .executive p { color: #cbd5e1; line-height: 1.6; }
  .issues-list { list-style: none; padding: 0; }
  .issues-list li { padding: 12px 0; border-bottom: 1px solid #334155; }
  .issues-list li:last-child { border-bottom: none; }
  .issue-domain { font-weight: 600; color: #f8fafc; }
  .issue-detail { color: #94a3b8; font-size: 14px; margin-top: 4px; }
  .footer { text-align: center; padding: 24px 0; color: #475569; font-size: 12px; border-top: 1px solid #334155; margin-top: 24px; }
  @media print { body { background: white; color: #1e293b; } .card, .domain, .actions, .executive { border: 1px solid #e2e8f0; } }
</style>
</head>
<body>

<div class="header">
  <h1>[PROJECT NAME]</h1>
  <div class="meta">Situation Report | [DATE] | [PERIOD] Report | Lead: [LEAD]</div>
  <div class="meta">Budget: [CURRENCY] [BUDGET] | Timeline: [START] to [END]</div>
</div>

<!-- Summary Cards -->
<div class="summary-cards">
  <div class="card critical">
    <div class="count">[X]</div>
    <div class="label">Critical Issues</div>
  </div>
  <div class="card watch">
    <div class="count">[X]</div>
    <div class="label">Watch Items</div>
  </div>
  <div class="card ontrack">
    <div class="count">[X]</div>
    <div class="label">On Track</div>
  </div>
</div>

<!-- Executive Summary -->
<div class="executive">
  <h2>Executive Summary</h2>
  <p>[EXECUTIVE SUMMARY TEXT]</p>
</div>

<!-- Critical Issues -->
[IF CRITICAL ISSUES EXIST:]
<div class="executive">
  <h2>Critical Issues</h2>
  <ul class="issues-list">
    <li>
      <span class="issue-domain">[DOMAIN]</span>
      <div class="issue-detail">[Issue description, impact, action needed]</div>
    </li>
  </ul>
</div>

<!-- Domain Status Cards -->
<div class="domains">
  [FOR EACH DOMAIN:]
  <div class="domain">
    <h3>[DOMAIN NAME] <span class="status-badge [critical|watch|ontrack]">[STATUS]</span></h3>
    <div class="metrics">
      [KEY METRICS FROM AGENT - as bullet points or key-value pairs]
    </div>
    <div class="findings">
      [TOP 2-3 FINDINGS - abbreviated]
    </div>
  </div>
</div>

<!-- Recommended Actions -->
<div class="actions">
  <h2>Recommended Actions</h2>
  <table>
    <thead>
      <tr><th>#</th><th>Action</th><th>Owner</th><th>Due</th><th>Domain</th></tr>
    </thead>
    <tbody>
      [FOR EACH ACTION:]
      <tr>
        <td>[N]</td>
        <td>[Action description]</td>
        <td>[Owner]</td>
        <td>[Date]</td>
        <td>[Domain]</td>
      </tr>
    </tbody>
  </table>
</div>

<div class="footer">
  Generated by SitRep Generator Plugin v2.0.0 | [TIMESTAMP]<br>
  Next report due: [NEXT DATE]
</div>

</body>
</html>
```

## Step 4: Generate the HTML

Using the parsed report data, fill in every `[PLACEHOLDER]` in the template above.

**Status badge mapping:**
- CRITICAL → class="critical"
- WATCH → class="watch"
- ON TRACK → class="ontrack"

**Count the items:**
- Count critical issues from the CRITICAL ISSUES section
- Count watch items from the WATCH ITEMS section
- Count on-track domains

**For each domain:**
- Extract the overall status
- Extract the top 3-5 key metrics
- Extract the top 2-3 findings (abbreviated)

Write the complete HTML to `./output/csitrep/[date]-dashboard.html`

## Step 5: Open in Browser

After saving the HTML file, open it:

```bash
open "./output/csitrep/[date]-dashboard.html"
```

On Linux: `xdg-open`, on macOS: `open`

## Step 6: Offer PDF Export

Ask the user if they want a PDF version:

If yes, attempt to convert using one of these methods:
1. `wkhtmltopdf` (if installed): `wkhtmltopdf [html] [pdf]`
2. Chrome headless: `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --print-to-pdf="[pdf]" [html]`
3. If neither available, tell the user they can print to PDF from the browser (Cmd+P)

## Rules
- The HTML must be self-contained (no external CSS/JS dependencies)
- Must look professional on both screen and print
- Dark theme for screen, auto-switches to light for print (@media print)
- All data comes from the existing markdown report - never re-analyze documents
- Keep the dashboard to a single scrollable page
- Status colors: red (#ef4444) for critical, amber (#f59e0b) for watch, green (#22c55e) for on-track
