# SitRep Generator

A Claude Code plugin that reads your project documents and generates structured Situation Reports (SitReps) using multi-agent AI analysis.

**5 specialist agents** analyze your documents in parallel across 5 project domains, then synthesize findings into a single actionable report with critical issues, watch items, and recommended actions.

## Supported Project Types

| Type | Domains |
|------|---------|
| **Construction** | Schedule, Cost, Safety, Contracts, Site Conditions |
| **Software/IT** | Sprint/Roadmap, Budget, Quality/Testing, Blockers, Infrastructure |
| **Development Program** | Workplan, Budget/Grants, M&E, Stakeholders, Field Operations |
| **Product/Manufacturing** | Timeline, Cost/Procurement, Quality, Supply Chain, Production |
| **Consulting** | Deliverables, Budget/Billing, Client Satisfaction, Resources, Risks |
| **Custom** | Define your own 5 domains for any industry |

## Install

Add the marketplace:
```
/plugin marketplace add chiKeka/csitrep-generator
```

Install the plugin:
```
/plugin install csitrep-generator@pm-agent-marketplace
```

Restart Claude Code for skills to load.

## Quick Start

### 1. Set up your project
```
/csitrep-generator:setup
```
Select your project type and enter project details. This creates your data folders and configures the right agents.

### 2. Add documents
Drop your project documents into the data folders created during setup:
- PDFs, CSVs, text files, and images are supported natively
- Excel (.xlsx) and Word (.docx) are auto-converted on session start

### 3. Generate a report
```
/csitrep-generator:generate
```
5 agents analyze your documents in parallel. You review the draft, then save or send via Slack.

## All Skills

| Command | What It Does |
|---------|-------------|
| `/csitrep-generator:setup` | Configure project type, name, budget, timeline, and domains |
| `/csitrep-generator:generate` | Generate a full Situation Report |
| `/csitrep-generator:dashboard` | Quick at-a-glance status (no agents, just reads last report) |
| `/csitrep-generator:track-risks` | View, add, or update project risks |
| `/csitrep-generator:track-actions` | Track action items from reports |
| `/csitrep-generator:compare` | Compare reports over time for trend analysis |

## Try It With Sample Data

Sample construction project data is included. To load it:

```bash
cd ~/.claude/plugins/cache/pm-agent-marketplace/csitrep-generator/2.0.0
chmod +x sample-data/load-sample.sh
./sample-data/load-sample.sh construction
```

Then run `/csitrep-generator:generate` to see a full report.

## What It Reads

| Format | Support |
|--------|---------|
| PDF | Native (up to 100 pages) |
| CSV | Native |
| Text / Markdown | Native |
| Images (PNG/JPG) | Native (AI vision for site photos) |
| JSON / XML / YAML | Native |
| Excel (.xlsx) | Auto-converted to CSV |
| Word (.docx) | Auto-converted to text |

## Slack Integration

The plugin can post reports to Slack channels. Set up:
1. Run `/mcp` and authenticate the Slack server
2. After generating a report, choose "Send to Slack"
3. Or use `@Claude` in Slack to trigger report generation directly

## Report Output

Reports are saved to `output/csitrep/` as dated markdown files. Each report includes:

- Executive Summary
- Critical Issues (needs decision now)
- Watch Items (trending negative)
- Detailed status per domain with key metrics
- Recommended Actions (prioritized, assigned, with deadlines)
- Risk Summary
- Open Actions Status
- Appendix (documents analyzed)

## How It Works

```
You: /csitrep-generator:generate

Plugin reads project config
    |
    ├── Agent 1: Analyzes domain 1 documents ──┐
    ├── Agent 2: Analyzes domain 2 documents ──┤
    ├── Agent 3: Analyzes domain 3 documents ──┼── All run in parallel
    ├── Agent 4: Analyzes domain 4 documents ──┤
    └── Agent 5: Analyzes domain 5 documents ──┘
                                                |
                                    Synthesize into SitRep
                                                |
                                    Present draft for review
                                                |
                                    Save + optional Slack delivery
```

## Requirements

- Claude Code (Pro, Max, Teams, or Enterprise plan)
- Python 3 + pandas (for Excel conversion, optional)
- pandoc (for Word conversion, optional)

## Author

Bruno Chikeka

## License

MIT
