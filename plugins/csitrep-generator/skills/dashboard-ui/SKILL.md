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

Generate a McKinsey-style HTML dashboard from the latest (or specified) SitRep report.

## Step 1: Find the Report

If the user provided a date argument, look for `./output/csitrep/[date]-sitrep.md`.
Otherwise, find the most recent report in `./output/csitrep/`.

If no reports exist, tell the user to run `/csitrep-generator:generate` first.

Read the report file and also read `./data/config/project-info.json` for project metadata.

## Step 2: Parse the Report

Extract from the markdown report:
- Project name, date, period, lead, budget, timeline
- Executive summary
- Critical issues (count and details: domain, issue, impact, action)
- Watch items (count and details: domain, item, detail)
- On-track items (count)
- Each domain's overall status, key metrics (as key-value pairs), and top findings
- Recommended actions (action, owner, due date, domain)
- Risk summary (if available)
- Action items status (if available)

Also extract quantitative metrics for charts:
- % complete per activity (for schedule progress bars)
- Budget figures: spent, committed, contingency, pending COs (for cost bars)
- Earned value actual vs planned (for S-curve)
- Safety metrics: training %, toolbox talks %, PPE %, corrective actions
- RFI/Submittal counts: open, overdue, total

## Step 3: Generate HTML Dashboard

Create an HTML file at `./output/csitrep/[date]-dashboard.html` using this structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>[Project Name] - Situation Report</title>
<style>
  :root {
    --black: #1a1a1a;
    --dark-gray: #333333;
    --mid-gray: #666666;
    --light-gray: #999999;
    --border: #e0e0e0;
    --bg-light: #f7f7f7;
    --white: #ffffff;
    --red: #c62828;
    --red-light: #ffebee;
    --amber: #e65100;
    --amber-light: #fff3e0;
    --green: #2e7d32;
    --green-light: #e8f5e9;
    --blue: #1565c0;
    --blue-light: #e3f2fd;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: 'Georgia', 'Times New Roman', serif;
    background: var(--white);
    color: var(--black);
    line-height: 1.5;
    max-width: 1200px;
    margin: 0 auto;
    padding: 40px 48px;
  }

  /* Typography - serif for headers, sans-serif for data */
  h1 { font-size: 32px; font-weight: 400; letter-spacing: -0.5px; color: var(--black); }
  h2 { font-family: -apple-system, 'Helvetica Neue', Arial, sans-serif; font-size: 13px; font-weight: 700; text-transform: uppercase; letter-spacing: 1.5px; color: var(--mid-gray); margin-bottom: 16px; padding-bottom: 8px; border-bottom: 2px solid var(--black); }
  h3 { font-family: -apple-system, 'Helvetica Neue', Arial, sans-serif; font-size: 15px; font-weight: 600; color: var(--black); margin-bottom: 8px; }

  .sans { font-family: -apple-system, 'Helvetica Neue', Arial, sans-serif; }

  /* Header - left-aligned project title with date on the right */
  .header { border-bottom: 3px solid var(--black); padding-bottom: 24px; margin-bottom: 32px; }
  .header-top { display: flex; justify-content: space-between; align-items: flex-end; margin-bottom: 12px; }
  .header .subtitle { font-family: -apple-system, 'Helvetica Neue', Arial, sans-serif; font-size: 13px; color: var(--mid-gray); text-transform: uppercase; letter-spacing: 1.5px; margin-bottom: 4px; }
  .header-meta { display: flex; gap: 32px; font-family: -apple-system, 'Helvetica Neue', Arial, sans-serif; font-size: 13px; color: var(--mid-gray); }
  .header-meta span { display: flex; align-items: center; gap: 6px; }
  .header-meta strong { color: var(--black); font-weight: 600; }

  /* KPI Row - 5 indicators in a bordered grid */
  .kpi-row { display: grid; grid-template-columns: repeat(5, 1fr); gap: 0; margin-bottom: 32px; border: 1px solid var(--border); border-radius: 2px; overflow: hidden; }
  .kpi { padding: 20px 16px; text-align: center; border-right: 1px solid var(--border); }
  .kpi:last-child { border-right: none; }
  .kpi-value { font-family: -apple-system, 'Helvetica Neue', Arial, sans-serif; font-size: 32px; font-weight: 300; color: var(--black); }
  .kpi-value.red { color: var(--red); }
  .kpi-value.amber { color: var(--amber); }
  .kpi-value.green { color: var(--green); }
  .kpi-label { font-family: -apple-system, 'Helvetica Neue', Arial, sans-serif; font-size: 11px; text-transform: uppercase; letter-spacing: 1px; color: var(--light-gray); margin-top: 4px; }
  .kpi-sub { font-family: -apple-system, 'Helvetica Neue', Arial, sans-serif; font-size: 12px; color: var(--mid-gray); margin-top: 2px; }

  /* Status indicators */
  .status-dot { display: inline-block; width: 8px; height: 8px; border-radius: 50%; margin-right: 6px; vertical-align: middle; }
  .status-dot.critical { background: var(--red); }
  .status-dot.watch { background: var(--amber); }
  .status-dot.ontrack { background: var(--green); }

  .status-tag { font-family: -apple-system, 'Helvetica Neue', Arial, sans-serif; display: inline-block; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.8px; padding: 2px 8px; border-radius: 2px; }
  .status-tag.critical { background: var(--red-light); color: var(--red); }
  .status-tag.watch { background: var(--amber-light); color: var(--amber); }
  .status-tag.ontrack { background: var(--green-light); color: var(--green); }

  /* Executive Summary - left-bordered callout box */
  .exec-summary { background: var(--bg-light); padding: 24px 28px; margin-bottom: 32px; border-left: 4px solid var(--black); }
  .exec-summary p { font-size: 15px; line-height: 1.7; color: var(--dark-gray); }

  /* Layouts */
  .two-col { display: grid; grid-template-columns: 1fr 1fr; gap: 32px; margin-bottom: 32px; }
  .full-width { margin-bottom: 32px; }

  /* Progress bars */
  .bar-chart { margin: 8px 0; }
  .bar-row { display: flex; align-items: center; margin-bottom: 8px; font-family: -apple-system, 'Helvetica Neue', Arial, sans-serif; font-size: 13px; }
  .bar-label { width: 140px; color: var(--dark-gray); flex-shrink: 0; }
  .bar-track { flex: 1; height: 20px; background: var(--bg-light); border-radius: 2px; overflow: hidden; }
  .bar-fill { height: 100%; border-radius: 2px; }
  .bar-fill.green { background: var(--green); }
  .bar-fill.amber { background: var(--amber); }
  .bar-fill.red { background: var(--red); }
  .bar-fill.blue { background: var(--blue); }
  .bar-fill.gray { background: #bdbdbd; }
  .bar-value { width: 60px; text-align: right; color: var(--mid-gray); font-size: 12px; flex-shrink: 0; margin-left: 8px; }

  /* Cost breakdown bars */
  .cost-breakdown { margin: 12px 0; }
  .cost-row { display: flex; align-items: center; font-family: -apple-system, 'Helvetica Neue', Arial, sans-serif; font-size: 13px; margin-bottom: 6px; }
  .cost-label { width: 150px; color: var(--dark-gray); }
  .cost-bar-container { flex: 1; display: flex; align-items: center; gap: 8px; }
  .cost-bar { height: 18px; border-radius: 1px; }
  .cost-amount { font-size: 12px; color: var(--mid-gray); white-space: nowrap; }

  /* Domain cards - bordered boxes with header + metrics table + findings */
  .domain-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(340px, 1fr)); gap: 20px; margin-bottom: 32px; }
  .domain-card { border: 1px solid var(--border); padding: 20px; }
  .domain-card-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; padding-bottom: 8px; border-bottom: 1px solid var(--border); }
  .domain-card-header h3 { margin-bottom: 0; }
  .domain-metrics { font-family: -apple-system, 'Helvetica Neue', Arial, sans-serif; font-size: 13px; color: var(--dark-gray); }
  .domain-metrics table { width: 100%; }
  .domain-metrics td { padding: 3px 0; vertical-align: top; }
  .domain-metrics td:first-child { color: var(--light-gray); width: 45%; }
  .domain-metrics td:last-child { font-weight: 500; }
  .domain-findings { margin-top: 12px; padding-top: 12px; border-top: 1px solid var(--border); }
  .domain-findings li { font-family: -apple-system, 'Helvetica Neue', Arial, sans-serif; font-size: 13px; color: var(--mid-gray); margin-bottom: 6px; padding-left: 12px; position: relative; list-style: none; }
  .domain-findings li::before { content: ""; position: absolute; left: 0; top: 7px; width: 4px; height: 4px; background: var(--light-gray); border-radius: 50%; }

  /* Tables - clean, minimal borders */
  .issues-table { width: 100%; border-collapse: collapse; font-family: -apple-system, 'Helvetica Neue', Arial, sans-serif; font-size: 13px; margin-bottom: 8px; }
  .issues-table th { text-align: left; padding: 8px 12px; background: var(--bg-light); font-size: 11px; text-transform: uppercase; letter-spacing: 0.8px; color: var(--mid-gray); font-weight: 600; border-bottom: 1px solid var(--border); }
  .issues-table td { padding: 10px 12px; border-bottom: 1px solid var(--border); vertical-align: top; color: var(--dark-gray); }
  .issues-table tr:last-child td { border-bottom: none; }
  .issues-table .priority-cell { width: 28px; text-align: center; }
  .priority-num { display: inline-flex; width: 22px; height: 22px; align-items: center; justify-content: center; border-radius: 50%; font-size: 11px; font-weight: 700; color: var(--white); }
  .priority-num.p1 { background: var(--red); }
  .priority-num.p2 { background: var(--amber); }

  .actions-table { width: 100%; border-collapse: collapse; font-family: -apple-system, 'Helvetica Neue', Arial, sans-serif; font-size: 13px; }
  .actions-table th { text-align: left; padding: 8px 12px; background: var(--bg-light); font-size: 11px; text-transform: uppercase; letter-spacing: 0.8px; color: var(--mid-gray); font-weight: 600; border-bottom: 2px solid var(--dark-gray); }
  .actions-table td { padding: 10px 12px; border-bottom: 1px solid var(--border); vertical-align: top; color: var(--dark-gray); }
  .actions-table tr:last-child td { border-bottom: none; }
  .actions-table .num { font-weight: 700; color: var(--black); }
  .actions-table .due-today { color: var(--red); font-weight: 600; }

  /* Footer */
  .footer { margin-top: 40px; padding-top: 16px; border-top: 2px solid var(--black); display: flex; justify-content: space-between; font-family: -apple-system, 'Helvetica Neue', Arial, sans-serif; font-size: 11px; color: var(--light-gray); }

  /* Print */
  @media print {
    body { padding: 20px; font-size: 12px; }
    .kpi-row { page-break-inside: avoid; }
    .domain-card { page-break-inside: avoid; }
    h2 { page-break-after: avoid; }
  }
</style>
</head>
<body>

<!-- HEADER -->
<div class="header">
  <div class="subtitle">[PROJECT_TYPE] Situation Report</div>
  <div class="header-top">
    <h1>[PROJECT_NAME]</h1>
    <span class="sans" style="font-size: 24px; font-weight: 300; color: var(--mid-gray);">[DATE_FORMATTED]</span>
  </div>
  <div class="header-meta">
    <span>Lead: <strong>[LEAD]</strong></span>
    <span>Period: <strong>[PERIOD]</strong></span>
    <span>Budget: <strong>[CURRENCY] [BUDGET]</strong></span>
    <span>Timeline: <strong>[START] - [END]</strong></span>
  </div>
</div>

<!-- KPI ROW -->
<div class="kpi-row">
  <div class="kpi">
    <div class="kpi-value red">[CRITICAL_COUNT]</div>
    <div class="kpi-label">Critical Issues</div>
    <div class="kpi-sub">Needs decision now</div>
  </div>
  <div class="kpi">
    <div class="kpi-value amber">[WATCH_COUNT]</div>
    <div class="kpi-label">Watch Items</div>
    <div class="kpi-sub">Trending negative</div>
  </div>
  <div class="kpi">
    <div class="kpi-value green">[ONTRACK_COUNT]</div>
    <div class="kpi-label">On Track</div>
    <div class="kpi-sub">Progressing as planned</div>
  </div>
  <div class="kpi">
    <div class="kpi-value">[KEY_METRIC_1_VALUE]</div>
    <div class="kpi-label">[KEY_METRIC_1_LABEL]</div>
    <div class="kpi-sub">[KEY_METRIC_1_CONTEXT]</div>
  </div>
  <div class="kpi">
    <div class="kpi-value">[KEY_METRIC_2_VALUE]</div>
    <div class="kpi-label">[KEY_METRIC_2_LABEL]</div>
    <div class="kpi-sub">[KEY_METRIC_2_CONTEXT]</div>
  </div>
</div>

<!-- EXECUTIVE SUMMARY -->
<div class="exec-summary">
  <p>[EXECUTIVE_SUMMARY_TEXT - use <strong> tags for key numbers]</p>
</div>

<!-- TWO-COLUMN CHARTS -->
<div class="two-col">

  <!-- Left chart: primary progress metric (e.g., schedule bars, sprint burndown) -->
  <div>
    <h2>[PRIMARY_CHART_TITLE]</h2>
    <div class="bar-chart">
      [FOR EACH ACTIVITY/ITEM:]
      <div class="bar-row">
        <div class="bar-label">[ACTIVITY_NAME]</div>
        <div class="bar-track"><div class="bar-fill [green|amber|red]" style="width: [PERCENT]%;"></div></div>
        <div class="bar-value">[PERCENT]%</div>
      </div>
    </div>
    <div style="font-family: -apple-system, sans-serif; font-size: 12px; color: var(--mid-gray); margin-top: 8px;">
      [CHART_FOOTNOTE_WITH_STATUS_DOTS]
    </div>
  </div>

  <!-- Right chart: budget/cost breakdown -->
  <div>
    <h2>[SECONDARY_CHART_TITLE]</h2>
    <div class="cost-breakdown">
      [FOR EACH COST CATEGORY:]
      <div class="cost-row">
        <div class="cost-label">[CATEGORY]</div>
        <div class="cost-bar-container">
          <div class="cost-bar" style="width: [PERCENT]%; background: var(--blue); height: 18px;"></div>
          <div class="cost-amount">[AMOUNT] ([PERCENT]%)</div>
        </div>
      </div>
    </div>
    <div style="font-family: -apple-system, sans-serif; font-size: 12px; color: var(--mid-gray); margin-top: 8px;">
      [COST_FOOTNOTE]
    </div>
  </div>
</div>

<!-- SVG CHART (if applicable - earned value, burndown, trend line) -->
[IF QUANTITATIVE TREND DATA IS AVAILABLE:]
<div class="full-width">
  <h2>[TREND_CHART_TITLE]</h2>
  [Generate an inline SVG chart. Use a viewBox of "0 0 600 120".
   Draw axis lines, grid lines, planned line (dashed gray), actual line (solid blue),
   a TODAY marker, data point labels, and a legend.
   Keep it simple - no JavaScript, pure SVG.]
</div>

<!-- CRITICAL ISSUES TABLE -->
<div class="full-width">
  <h2>Critical Issues Requiring Decision</h2>
  <table class="issues-table">
    <thead>
      <tr>
        <th class="priority-cell">P</th>
        <th>Domain</th>
        <th>Issue</th>
        <th>Impact</th>
        <th>Required Action</th>
      </tr>
    </thead>
    <tbody>
      [FOR EACH CRITICAL ISSUE:]
      <tr>
        <td class="priority-cell"><span class="priority-num p1">[N]</span></td>
        <td>[DOMAIN]</td>
        <td>[ISSUE]</td>
        <td>[IMPACT]</td>
        <td>[ACTION]</td>
      </tr>
    </tbody>
  </table>
</div>

<!-- DOMAIN STATUS CARDS -->
<h2>Domain Status</h2>
<div class="domain-grid">
  [FOR EACH DOMAIN:]
  <div class="domain-card">
    <div class="domain-card-header">
      <h3>[DOMAIN_NAME]</h3>
      <span class="status-tag [critical|watch|ontrack]">[STATUS]</span>
    </div>
    <div class="domain-metrics">
      <table>
        [FOR EACH KEY METRIC (3-5):]
        <tr><td>[METRIC_LABEL]</td><td>[METRIC_VALUE - add style="color: var(--red);" for bad values]</td></tr>
      </table>
    </div>
    <div class="domain-findings">
      <ul style="list-style: none;">
        [FOR EACH TOP FINDING (2-3):]
        <li>[FINDING]</li>
      </ul>
    </div>
  </div>
</div>

<!-- WATCH ITEMS TABLE -->
<div class="full-width">
  <h2>Watch Items</h2>
  <table class="issues-table">
    <thead>
      <tr>
        <th class="priority-cell">#</th>
        <th>Domain</th>
        <th>Item</th>
        <th>Detail</th>
      </tr>
    </thead>
    <tbody>
      [FOR EACH WATCH ITEM:]
      <tr>
        <td class="priority-cell"><span class="priority-num p2">[N]</span></td>
        <td>[DOMAIN]</td>
        <td>[ITEM]</td>
        <td>[DETAIL]</td>
      </tr>
    </tbody>
  </table>
</div>

<!-- RECOMMENDED ACTIONS TABLE -->
<div class="full-width">
  <h2>Recommended Actions</h2>
  <table class="actions-table">
    <thead>
      <tr><th style="width: 30px;">#</th><th>Action</th><th style="width: 130px;">Owner</th><th style="width: 100px;">Due</th><th style="width: 80px;">Domain</th></tr>
    </thead>
    <tbody>
      [FOR EACH ACTION:]
      <tr>
        <td class="num">[N]</td>
        <td>[ACTION]</td>
        <td>[OWNER]</td>
        <td [IF DUE TODAY: class="due-today"]>[DATE]</td>
        <td>[DOMAIN]</td>
      </tr>
    </tbody>
  </table>
</div>

<!-- SECONDARY PERFORMANCE CHARTS (two-column) -->
[IF APPLICABLE - e.g., safety bars + RFI bars, quality metrics + resource utilization:]
<div class="two-col">
  <div>
    <h2>[LEFT_PERF_TITLE]</h2>
    <div class="bar-chart">
      [FOR EACH METRIC:]
      <div class="bar-row">
        <div class="bar-label">[LABEL]</div>
        <div class="bar-track"><div class="bar-fill [green|amber|red]" style="width: [PERCENT]%;"></div></div>
        <div class="bar-value">[VALUE]</div>
      </div>
    </div>
  </div>
  <div>
    <h2>[RIGHT_PERF_TITLE]</h2>
    <div class="bar-chart">
      [FOR EACH METRIC:]
      <div class="bar-row">
        <div class="bar-label">[LABEL]</div>
        <div class="bar-track"><div class="bar-fill [green|amber|red]" style="width: [PERCENT]%;"></div></div>
        <div class="bar-value">[VALUE]</div>
      </div>
    </div>
  </div>
</div>

<!-- FOOTER -->
<div class="footer">
  <span>SitRep Generator Plugin v2.1.0</span>
  <span>Prepared: [DATE] | Next report: [NEXT_DATE]</span>
  <span>Project: [PROJECT_NUMBER]</span>
</div>

</body>
</html>
```

## Step 4: Fill the Template

Using the parsed report data, fill in every `[PLACEHOLDER]` in the template above.

**Design principles:**
- White background, clean professional consulting-style layout
- Georgia serif for headings, system sans-serif for data and metrics
- No emojis anywhere in the output
- Color-code negative values in domain metric tables using inline style

**Status tag mapping:**
- CRITICAL -> class="critical"
- WATCH -> class="watch"
- ON TRACK -> class="ontrack"

**KPI row (5 indicators):**
- Always show: Critical Issues count, Watch Items count, On Track count
- Pick 2 more KPIs from the report data that are most meaningful for this project type:
  - Construction: Earned Value %, Spent to Date
  - Software: Sprint Velocity, Defect Count
  - Program: Milestones On Track, Disbursement Rate
  - Product: Units Produced, Defect Rate
  - Consulting: Deliverables Complete, Utilization %
  - Custom: pick the 2 most impactful quantitative metrics

**Progress bar colors:**
- 80%+ complete or on track: green
- 40-79% or minor concern: amber
- Below 40% or critical: red
- Not started or blocked: gray

**Priority numbers:**
- Critical issues: p1 class (red circles)
- Watch items: p2 class (amber circles)

**SVG chart:**
- Only generate if the report has trend/comparison data (earned value, burndown, etc.)
- Use viewBox="0 0 600 120", no JavaScript, pure inline SVG
- Dashed gray line for planned, solid blue for actual, black dashed vertical for TODAY

**Cost/budget bars:**
- Width proportional to budget percentage
- Use min-width: 20px for small values so they remain visible

**For each domain card:**
- Extract the overall status for the tag
- Extract 3-5 key metrics as a two-column table
- Extract 2-3 top findings as a list

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
- White background, professional consulting-style layout
- Georgia serif for display headings, system sans-serif for all data/metrics/labels
- No emojis - use status dots, priority numbers, and color coding instead
- Print-optimized with @media print rules
- All data comes from the existing markdown report - never re-analyze documents
- Keep the dashboard to a single scrollable page
- Status colors: red (#c62828) for critical, amber (#e65100) for watch, green (#2e7d32) for on-track, blue (#1565c0) for neutral data
- Tables must have uppercase letter-spaced headers on light gray background
- Use bold/color inline styles to highlight concerning values in domain metric tables
