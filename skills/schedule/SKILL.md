---
name: schedule
description: >
  Set up automated recurring SitRep generation. Use when the user wants
  reports generated automatically on a schedule (daily, weekly, monthly).
disable-model-invocation: false
user-invocable: true
argument-hint: [frequency: daily|weekly|monthly|remove]
allowed-tools: Read, Write, Bash, AskUserQuestion
model: sonnet
---

# Auto-Schedule SitRep Generation

Set up automated recurring report generation using the system scheduler.

## Step 1: Read Current Config

Read `./data/config/project-info.json` to verify a project is configured.
If not configured, tell the user to run `/csitrep-generator:setup` first.

Also check if a schedule already exists:
```bash
crontab -l 2>/dev/null | grep "csitrep-generator"
```

## Step 2: Get Schedule Preference

If the user passed an argument, use that. Otherwise ask:

```
How often should reports be generated automatically?

1. Daily (every weekday at 4:00 PM)
2. Weekly (every Friday at 4:00 PM)
3. Monthly (1st of each month at 9:00 AM)
4. Custom (specify your own cron schedule)
5. Remove existing schedule
```

## Step 3: Determine Paths

Get the absolute paths needed:
```bash
PLUGIN_DIR=$(pwd)
CLAUDE_PATH=$(which claude)
```

## Step 4: Create the Cron Job

Build the cron entry based on selection:

### Daily (weekdays at 4 PM)
```
0 16 * * 1-5 cd "[PLUGIN_DIR]" && [CLAUDE_PATH] -p "Run /csitrep-generator:generate and save the report. Do not ask for review - auto-save." --output-format text >> "[PLUGIN_DIR]/output/csitrep/auto-run.log" 2>&1
```

### Weekly (Friday at 4 PM)
```
0 16 * * 5 cd "[PLUGIN_DIR]" && [CLAUDE_PATH] -p "Run /csitrep-generator:generate and save the report. Do not ask for review - auto-save." --output-format text >> "[PLUGIN_DIR]/output/csitrep/auto-run.log" 2>&1
```

### Monthly (1st at 9 AM)
```
0 9 1 * * cd "[PLUGIN_DIR]" && [CLAUDE_PATH] -p "Run /csitrep-generator:generate and save the report. Do not ask for review - auto-save." --output-format text >> "[PLUGIN_DIR]/output/csitrep/auto-run.log" 2>&1
```

### Custom
Ask the user for their cron expression and validate it.

### Remove
```bash
crontab -l 2>/dev/null | grep -v "csitrep-generator" | crontab -
```

## Step 5: Install the Cron Job

```bash
# Add to existing crontab without removing other entries
(crontab -l 2>/dev/null | grep -v "csitrep-generator"; echo "[CRON_ENTRY]") | crontab -
```

Verify installation:
```bash
crontab -l | grep "csitrep-generator"
```

## Step 6: Slack Delivery

Check if `slack_delivery` is already configured in project-info.json.

**If already configured:** Show the existing config and ask if they want to change it.

**If not configured:** Ask:
```
Would you like reports automatically posted to a Slack channel?
This is the recommended way for your team to receive reports.

1. Yes - my team gets reports via Slack (recommended)
2. No - local files only
```

If yes:
1. Ask which Slack channel (e.g., `#project-updates`)
2. Ask who to @mention on critical issues (e.g., `@mike @safety-team`)
3. Save to project-info.json under `slack_delivery`

The cron command uses auto-save mode, which triggers the auto-delivery in the generate skill:
```
... && [CLAUDE_PATH] -p "Run /csitrep-generator:generate and auto-save the report." --output-format text ...
```

Since `slack_delivery.auto_post` is true in the config, the generate skill handles Slack delivery automatically. No need for a separate Slack command in cron.

## Step 7: Save Schedule Config

Update `./data/config/project-info.json` with schedule info:
```json
{
  "auto_schedule": {
    "frequency": "weekly",
    "cron": "0 16 * * 5",
    "enabled": true,
    "created": "2026-03-07"
  }
}
```

## Step 8: Confirm

```
Auto-schedule configured:

  Frequency:     [Weekly / Friday at 4:00 PM]
  Next Run:      [calculated next occurrence]
  Output:        ./output/csitrep/ (auto-saved)
  Slack:         [#channel] (auto-delivered)
  Mentions:      [@user1, @user2] on critical issues
  Dashboard:     HTML generated with each report
  Log:           ./output/csitrep/auto-run.log

How it works:
  - Cron triggers Claude Code on schedule
  - 5 specialist agents analyze your latest documents
  - Report + dashboard are saved locally
  - Summary + full report posted to Slack automatically
  - Your team sees the report without installing anything

To check schedule: crontab -l
To remove: /csitrep-generator:schedule remove
```

## Rules
- Always preserve existing crontab entries (never wipe the crontab)
- Use absolute paths in cron entries (cron doesn't inherit PATH)
- Always add logging (>> auto-run.log) so the user can debug
- The cron command must include --output-format text to avoid interactive prompts
- Warn the user that their machine must be running for cron to fire
- On macOS, mention that the user may need to grant cron Full Disk Access in System Preferences
- Recommend Slack delivery as the primary team consumption method
- Make it clear: only the admin needs Claude Code, the team just reads Slack
