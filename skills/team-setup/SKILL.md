---
name: team-setup
description: >
  One-stop admin setup for team delivery. Configures the project, Slack channel,
  auto-schedule, and team notifications so the admin sets it up once and the
  whole team receives reports via Slack without needing Claude Code.
disable-model-invocation: false
user-invocable: true
argument-hint: [project-type]
allowed-tools: Read, Write, Bash, Glob, AskUserQuestion
model: opus
---

# Team Setup (Admin One-Time Configuration)

This is the streamlined setup for teams. One person (the admin) runs this once.
After that, the entire team receives professional SitRep reports via Slack on
a recurring schedule. No one else needs to install Claude Code.

## Step 1: Check Existing Config

Read `./data/config/project-info.json`. If a project is already configured:
```
A project is already configured: [PROJECT_NAME] ([TYPE])

1. Reconfigure everything from scratch
2. Just set up Slack delivery and scheduling for the existing project
```

If option 2, skip to Step 4.

## Step 2: Project Setup (Condensed)

Offer document-based setup first:

```
How would you like to provide project details?

1. From a document - Drop a charter, scope, proposal, or contract (fastest)
2. Enter manually  - I'll ask a few questions
```

### If from a document:
Ask for the file path. Run `bash ./scripts/preprocess.sh` to convert if needed.
Read the document and extract: project name, type (inferred from content), number,
owner, lead, start/end dates, budget, currency.

Present extracted details for confirmation. Only ask about fields that couldn't
be found. If the project type couldn't be inferred, present the 6 options.

### If manual:
```
Project type:
  1. Construction   2. Software/IT   3. Development Program
  4. Product/Mfg    5. Consulting    6. Custom

Project name:
Project lead:
Owner / client:
Budget (e.g., USD 5000000):
Start date (YYYY-MM-DD):
End date (YYYY-MM-DD):
Reporting period: weekly / monthly
```

Accept partial answers and ask follow-ups only for missing required fields (name, type, lead are required; others have sensible defaults).

## Step 3: Create Folders and Config

Based on the project type, create data folders and save project-info.json.
Use the same domain/agent mappings as the setup skill:
- Construction: schedule, cost, safety, contracts, site
- Software: sprint, budget, quality, blockers, infra
- Program: workplan, budget, mne, stakeholders, field
- Product: timeline, cost, quality, supply, operations
- Consulting: deliverables, budget, client, resources, risks
- Custom: ask for 5 domain names, create custom agents

```bash
mkdir -p ./data/config ./data/[folder1] ./data/[folder2] ... ./output/csitrep
```

Save the config to `./data/config/project-info.json`.

## Step 4: Slack Configuration

```
Now let's set up Slack delivery so your team gets reports automatically.

Which Slack channel should reports go to?
(e.g., #project-updates, #riverside-status)
```

Then ask:
```
Who should be @mentioned when critical issues are found?
(e.g., @mike @sarah @safety-team, or leave blank for no mentions)
```

Save to project-info.json:
```json
{
  "slack_delivery": {
    "enabled": true,
    "channel": "#[channel]",
    "mention_on_critical": ["@user1", "@user2"],
    "include_dashboard": true,
    "auto_post": true
  }
}
```

## Step 5: Auto-Schedule

```
How often should reports be generated and delivered?

1. Weekly  - Every Friday at 4:00 PM (most common)
2. Daily   - Every weekday at 4:00 PM
3. Monthly - 1st of each month at 9:00 AM
4. Custom  - Specify your own schedule
```

Set up the cron job using absolute paths:
```bash
PLUGIN_DIR=$(pwd)
CLAUDE_PATH=$(which claude)
```

Install the cron entry (preserving existing crontab):
```bash
(crontab -l 2>/dev/null | grep -v "csitrep-generator"; echo "[CRON_ENTRY]") | crontab -
```

The cron command should be:
```
[CRON_SCHEDULE] cd "[PLUGIN_DIR]" && [CLAUDE_PATH] -p "Run /csitrep-generator:generate and auto-save the report." --output-format text >> "[PLUGIN_DIR]/output/csitrep/auto-run.log" 2>&1
```

Save schedule config to project-info.json under `auto_schedule`.

## Step 6: Test Slack Connection

Attempt to send a test message to the configured channel:

```
Sending a test message to [#channel]...
```

Use the Slack MCP tools to post:
```
SitRep Generator connected.

Project: [PROJECT_NAME]
Schedule: [FREQUENCY] reports starting [NEXT_RUN_DATE]
Configured by: [ADMIN_NAME]

Reports will be posted to this channel automatically.
When critical issues are found, [MENTION_LIST] will be notified.
```

If the test message succeeds, confirm. If it fails, troubleshoot:
- Check if Slack MCP is authenticated
- Verify the channel exists
- Suggest the user run the Slack OAuth flow

## Step 7: Summary

```
Team setup complete.

PROJECT
  Name:       [name]
  Type:       [type]
  Budget:     [currency] [amount]
  Timeline:   [start] to [end]

DELIVERY
  Channel:    [#channel]
  Schedule:   [frequency] ([day/time])
  Next run:   [date]
  Mentions:   [list] (on critical issues)
  Dashboard:  HTML generated with each report

DATA FOLDERS
  1. [Domain] -> data/[folder]/
  2. [Domain] -> data/[folder]/
  3. [Domain] -> data/[folder]/
  4. [Domain] -> data/[folder]/
  5. [Domain] -> data/[folder]/

WHAT TO DO NOW
  1. Drop your project documents into the data folders above
  2. Run /csitrep-generator:generate to test your first report
  3. After that, reports run automatically on schedule

YOUR TEAM
  - Receives reports in [#channel] without installing anything
  - Gets @mentioned when critical issues need attention
  - Can view the visual dashboard link in each report thread
  - Only you (admin) need Claude Code installed
```

## Rules
- This skill replaces the need to run setup + schedule + Slack config separately
- Keep the flow fast -- collect info in bulk, don't ask one field at a time
- Default to weekly Friday 4 PM if the user doesn't have a strong preference
- Always test the Slack connection before confirming
- Make it crystal clear that team members do NOT need Claude Code
- If any step fails, don't abort -- complete what you can and tell the user what to fix
- On macOS, warn about granting cron Full Disk Access in System Preferences
- The machine running cron must stay on for scheduled reports to fire
