---
name: setup
description: >
  Set up a new project for SitRep generation. Use when the user wants to
  configure a new project, change project type, or set up the plugin for
  the first time. Supports construction, software, development programs,
  product/manufacturing, consulting, and custom project types.
disable-model-invocation: false
user-invocable: true
argument-hint: [project-type]
allowed-tools: Read, Write, Bash, Glob, AskUserQuestion
model: opus
---

# Project Setup

You are setting up a project for SitRep (Situation Report) generation.

## Step 1: Ask Project Type

If the user didn't provide a project type as an argument, present these options:

```
Which project type best fits your work?

1. Construction     - Buildings, infrastructure, civil works
2. Software/IT      - Software development, IT projects, product launches
3. Development Program - NGO, aid, government, social programs
4. Product/Manufacturing - Hardware, CPG, production, product development
5. Consulting       - Advisory, professional services, agency work
6. Custom           - Define your own tracking domains
```

Wait for their selection.

## Step 2: Collect Project Details

Ask for:
- Project name
- Project number (optional)
- Owner / client name
- Project lead / PM name
- Start date
- Planned completion date
- Total budget and currency
- Reporting period (weekly or monthly)

## Step 3: Configure Domains and Agents

Based on the project type selected, set up the 5 tracking domains:

### Construction
| Domain | Agent | Data Folder |
|--------|-------|-------------|
| Schedule | construction-schedule | data/schedule/ |
| Cost & Budget | construction-cost | data/cost/ |
| Safety | construction-safety | data/safety/ |
| Contracts & Admin | construction-contracts | data/contracts/ |
| Site Conditions | construction-site | data/site/ |

### Software/IT
| Domain | Agent | Data Folder |
|--------|-------|-------------|
| Sprint & Roadmap | software-sprint | data/sprint/ |
| Budget & Resources | software-budget | data/budget/ |
| Quality & Testing | software-quality | data/quality/ |
| Dependencies & Blockers | software-blockers | data/blockers/ |
| Infrastructure & DevOps | software-infra | data/infra/ |

### Development Program
| Domain | Agent | Data Folder |
|--------|-------|-------------|
| Workplan & Timeline | program-workplan | data/workplan/ |
| Budget & Grants | program-budget | data/budget/ |
| M&E (Monitoring & Evaluation) | program-mne | data/mne/ |
| Stakeholder & Partners | program-stakeholders | data/stakeholders/ |
| Field Operations | program-field | data/field/ |

### Product/Manufacturing
| Domain | Agent | Data Folder |
|--------|-------|-------------|
| Development Timeline | product-timeline | data/timeline/ |
| Cost & Procurement | product-cost | data/cost/ |
| Quality & Compliance | product-quality | data/quality/ |
| Supply Chain | product-supply | data/supply/ |
| Production & Operations | product-operations | data/operations/ |

### Consulting
| Domain | Agent | Data Folder |
|--------|-------|-------------|
| Deliverables & Timeline | consulting-deliverables | data/deliverables/ |
| Budget & Billing | consulting-budget | data/budget/ |
| Client Satisfaction | consulting-client | data/client/ |
| Resource Allocation | consulting-resources | data/resources/ |
| Risk & Issues | consulting-risks | data/risks/ |

### Custom
For custom projects, ask the user:
```
Name your 5 tracking domains (the key areas you monitor on this project):
1.
2.
3.
4.
5.
```

Then for each domain, ask:
- What types of documents will you put in this folder?
- What should the agent look for when analyzing these documents?

Create custom agent files in the agents/ directory. Each custom agent file should follow this format:

```markdown
---
name: custom-[domain-slug]
description: Analyzes [domain name] documents for [project name]
tools: Read, Glob, Grep, Bash
model: sonnet
maxTurns: 15
---

You are a [Domain Name] Analyst for the project "[Project Name]".

## Your Data Source
Read ALL files in ./data/[folder-name]/

## What You Analyze
[Based on what the user described]

## Output Format
Return structured findings with clear sections.
Flag items as CRITICAL, WATCH, or ON TRACK.

DOCUMENTS REVIEWED:
- [list files]
```

## Step 4: Create Data Folders

Create all 5 data folders under ./data/ based on the project type.
Use Bash to run mkdir -p for each folder.

## Step 5: Save Configuration

Write the complete config to ./data/config/project-info.json:

```json
{
  "project_name": "[name]",
  "project_type": "[construction|software|program|product|consulting|custom]",
  "reporting_period": "[weekly|monthly]",
  "project_number": "[number]",
  "owner": "[owner]",
  "lead": "[lead]",
  "start_date": "[YYYY-MM-DD]",
  "planned_completion": "[YYYY-MM-DD]",
  "budget": [number],
  "currency": "[USD|EUR|GBP|etc]",
  "domains": [
    {
      "name": "[Domain Name]",
      "agent": "[agent-name]",
      "folder": "data/[folder]/"
    }
  ],
  "notes": ""
}
```

## Step 6: Slack Team Delivery (Optional)

Ask the user:
```
Would you like reports automatically delivered to Slack?
This lets your whole team receive reports without needing Claude Code.

1. Yes - configure Slack delivery
2. No - I'll use reports locally only
```

If yes:
1. Ask which Slack channel (e.g., `#project-updates`, `#riverside-sitrep`)
2. Ask if they want the HTML dashboard attached as a link or just the text summary
3. Ask who should be @mentioned when critical issues are found (e.g., `@mike`, `@safety-team`)

Save the Slack config to project-info.json:
```json
{
  "slack_delivery": {
    "enabled": true,
    "channel": "#project-updates",
    "mention_on_critical": ["@project-lead"],
    "include_dashboard": true,
    "auto_post": true
  }
}
```

If no, save:
```json
{
  "slack_delivery": {
    "enabled": false
  }
}
```

## Step 7: Confirm Setup

Show the user a summary:

```
Project configured:

  Name:     [name]
  Type:     [type]
  Period:   [weekly/monthly]
  Budget:   [currency] [amount]
  Timeline: [start] to [end]

  Tracking Domains:
  1. [Domain] → data/[folder]/
  2. [Domain] → data/[folder]/
  3. [Domain] → data/[folder]/
  4. [Domain] → data/[folder]/
  5. [Domain] → data/[folder]/

  Slack:    [#channel or "Not configured"]

Next steps:
  1. Drop your documents into the data folders above
  2. Run /csitrep-generator:generate to create your first report
  3. Run /csitrep-generator:schedule to set up auto-delivery

Your team can receive reports in Slack without installing anything.
Only you (the admin) need Claude Code.
```

## Rules

- Always create the data folders — don't just tell the user to create them
- If project-info.json already exists, warn the user and ask if they want to overwrite
- For custom projects, generate the agent .md files and save them in the agents/ directory
- Keep domain names short and clear
- Always use lowercase with hyphens for folder names and agent names
- The Slack delivery config is what enables "configure once, team consumes" workflow
