# CSitRep Generator

Multi-agent Situation Report generator for Claude Code. Dispatches 25 specialist AI agents to analyze your project documents and produces actionable status reports with interactive dashboards.

Supports **6 project types**: Construction, Software/IT, Development Programs, Product/Manufacturing, Consulting, and Custom.

## How It Works

1. Drop project documents into organized data folders
2. Run `/csitrep-generator:generate`
3. Five domain-specialist agents analyze your documents in parallel
4. The system synthesizes findings into a structured report with critical issues, watch items, and recommended actions
5. Optionally delivers to Slack and generates an interactive HTML dashboard

Each agent classifies findings as **CRITICAL** (needs decision today), **WATCH** (trending negative), or **ON TRACK** (within tolerance).

## Installation

```bash
/plugin marketplace add chiKeka/csitrep-generator
/plugin install csitrep-generator@pm-agent-marketplace
```

Restart Claude Code after installation for skills to load.

### Requirements

- Claude Code (Pro, Max, Teams, or Enterprise)

### Optional (for Office file conversion)

```bash
brew install pandoc
pip3 install pandas openpyxl python-docx python-pptx xlrd
```

Office files (.xlsx, .docx, .pptx) are auto-converted on session start. PDF, CSV, TXT, JSON, XML, YAML, and images work natively.

## Quick Start

```
/csitrep-generator:setup          # Configure your project
# Drop documents into data folders
/csitrep-generator:generate       # Generate your first report
```

New to the plugin? Run `/csitrep-generator:onboard` for a step-by-step walkthrough.

## Commands

### Core

| Command | Description |
|---------|-------------|
| `/csitrep-generator:generate` | Generate a full Situation Report |
| `/csitrep-generator:dashboard` | Quick one-line status per domain |
| `/csitrep-generator:dashboard-ui` | Interactive HTML dashboard |
| `/csitrep-generator:compare` | Compare reports and identify trends |

### Setup & Configuration

| Command | Description |
|---------|-------------|
| `/csitrep-generator:setup` | Configure a new project |
| `/csitrep-generator:team-setup` | One-stop admin setup (project + Slack + schedule) |
| `/csitrep-generator:onboard` | Guided walkthrough for new users |
| `/csitrep-generator:import` | Import from Jira, Procore, MS Project, Monday.com, Asana, Smartsheet |
| `/csitrep-generator:validate` | Check data quality before generating |

### Tracking

| Command | Description |
|---------|-------------|
| `/csitrep-generator:track-risks` | Manage project risk register |
| `/csitrep-generator:track-actions` | Track action items across reports |
| `/csitrep-generator:track-changes` | Log and analyze change orders |
| `/csitrep-generator:feedback` | Flag incorrect findings for future improvement |

### Automation

| Command | Description |
|---------|-------------|
| `/csitrep-generator:schedule` | Set up recurring report generation (daily/weekly/monthly) |

## Project Types and Domains

### Construction
Schedule, Cost & Budget, Safety, Contracts & Admin, Site Conditions

### Software/IT
Sprint & Roadmap, Budget & Resources, Quality & Testing, Dependencies & Blockers, Infrastructure & DevOps

### Development Programs
Workplan & Timeline, Budget & Grants, M&E, Stakeholders & Partners, Field Operations

### Product/Manufacturing
Development Timeline, Cost & Procurement, Quality & Compliance, Supply Chain, Production & Operations

### Consulting
Deliverables & Timeline, Budget & Billing, Client Satisfaction, Resource Allocation, Risk & Issues

### Custom
Define your own 5 domains with custom agent definitions generated during setup.

## Data Folder Structure

After setup, your project data folders are created based on project type. For example, a construction project:

```
data/
├── config/
│   └── project-info.json    # Project configuration
├── schedule/                # Baseline schedules, daily logs, look-aheads
├── cost/                    # Budget vs actual, change orders, invoices
├── safety/                  # Incident reports, inspections, corrective actions
├── contracts/               # RFIs, submittals, meeting minutes
├── site/                    # Field reports, weather logs, equipment logs
└── archive/                 # Timestamped snapshots (auto-created)
```

Drop any combination of PDF, CSV, Excel, Word, PowerPoint, images, or text files into the relevant folders.

## Output

Reports are saved to `output/csitrep/`:

- `YYYY-MM-DD-sitrep.md` — Full markdown report
- `YYYY-MM-DD-dashboard.html` — Interactive HTML dashboard (self-contained, no dependencies)

### Report Sections

1. Executive Summary
2. KPI Summary (Critical / Watch / On Track counts + key metrics)
3. Domain Status Summaries (status + metrics + findings per domain)
4. Critical Issues (numbered, with domain and impact)
5. Watch Items
6. Recommended Actions (owner, due date, priority)
7. Period-over-Period Trends (if prior reports exist)
8. Risk Summary
9. Open Actions Status

### HTML Dashboard

Professional consulting-style layout with:
- KPI indicator row
- Domain status cards with metrics
- Critical issues and watch items tables
- SVG trend charts (when quantitative data is available)
- Search/filter, collapsible sections, print-to-PDF optimization

## Slack Integration

Configure during setup to auto-deliver reports to a Slack channel. The plugin uses MCP Slack integration:
- Full report posted to channel
- Critical items highlighted with mentions
- Team members can reply in-thread with feedback
- Dashboard link included

## Automation

Set up recurring reports with `/csitrep-generator:schedule`:
- **Daily**: Weekdays at 4 PM
- **Weekly**: Friday at 4 PM
- **Monthly**: 1st of month at 9 AM
- **Custom**: Provide your own cron expression

Only the admin needs Claude Code installed. The team receives reports via Slack.

## Importing from PM Tools

The `/csitrep-generator:import` command supports:

- Jira (CSV/JSON export)
- MS Project (.mpp/.xml export)
- Primavera P6 (.xer/.xml export)
- Procore (report exports)
- Monday.com (CSV export)
- Asana (CSV export)
- Smartsheet (Excel export)

The import maps exported data to the correct data folders and saves the mapping for recurring imports.

## Architecture

The plugin uses a multi-agent architecture with 25 specialist agents (5 per project type) orchestrated by the generate skill:

1. **Preprocessing** — Office files converted to readable formats
2. **Archiving** — Current data snapshot preserved for version history
3. **Validation** — Data folders checked for content
4. **Parallel Dispatch** — All 5 domain agents run simultaneously
5. **Synthesis** — Findings merged into structured report with trend analysis
6. **Delivery** — Report saved and optionally posted to Slack

## License

MIT
