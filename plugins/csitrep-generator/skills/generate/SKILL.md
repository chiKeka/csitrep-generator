---
name: generate
description: >
  Generate a Construction Situation Report (CSitRep). Use when the user asks
  for a project status report, situation report, weekly report, or CSitRep.
  Reads project documents from data/ folders and produces a comprehensive
  multi-domain construction report.
disable-model-invocation: false
user-invocable: true
argument-hint: [project-name]
allowed-tools: Read, Glob, Grep, Bash, Agent, Write, AskUserQuestion
model: opus
---

# CSitRep Generator - Orchestrator

You are the orchestrator for generating Construction Situation Reports. You coordinate 5 specialist agents and synthesize their findings into a single report.

## Step 1: Load Project Configuration

Read `./data/config/project-info.json` for:
- Project name
- Reporting period (weekly or monthly)
- Key dates and milestones
- Any special notes for this period

If the file doesn't exist or is incomplete, ask the user for the project name and reporting period.

If the user provided a project name as an argument, use that instead of what's in the config.

## Step 2: Validate Data Folders

Check each of these folders for documents:
- `./data/schedule/`
- `./data/cost/`
- `./data/safety/`
- `./data/contracts/`
- `./data/site/`

For each folder:
- If it contains files, note the count and types
- If it's empty, warn the user and ask if they want to proceed without that section

## Step 3: Dispatch Specialist Agents IN PARALLEL

Spawn ALL 5 agents simultaneously. Do NOT run them one at a time. Use the Agent tool to dispatch each:

1. **@schedule-analyst** - "Analyze all documents in ./data/schedule/ and produce schedule status findings. Flag items as CRITICAL, WATCH, or ON TRACK."

2. **@cost-analyst** - "Analyze all documents in ./data/cost/ and produce cost status findings. Flag items as CRITICAL, WATCH, or ON TRACK."

3. **@safety-analyst** - "Analyze all documents in ./data/safety/ and produce safety status findings. Flag items as CRITICAL, WATCH, or ON TRACK."

4. **@contract-analyst** - "Analyze all documents in ./data/contracts/ and produce contract and admin status findings. Flag items as CRITICAL, WATCH, or ON TRACK."

5. **@site-analyst** - "Analyze all documents in ./data/site/ and produce site conditions findings. Flag items as CRITICAL, WATCH, or ON TRACK."

## Step 4: Synthesize Findings

Once all agents return their findings, build the CSitRep using the template in `reference.md`.

Apply these classification rules across all findings:
- **CRITICAL (red)**: Needs a decision today, blocking progress, safety violation, or budget breach >5%
- **WATCH (yellow)**: Trending negative, needs attention this week, variance 2-5%
- **ON TRACK (green)**: Within tolerance, progressing as planned

For the RECOMMENDED ACTIONS section:
- Prioritize by urgency (CRITICAL items first)
- Be specific: name the action, who should act, and by when
- Limit to 5-7 actions maximum
- Each action should be tied to a specific finding

## Step 5: Present Draft for Review

Display the complete CSitRep to the user. Ask:
"Here's the draft CSitRep. Would you like to make any changes before I save it?"

Wait for user confirmation or edits.

## Step 6: Save the Report

Save the final CSitRep to `./output/csitrep/` with the filename format:
`YYYY-MM-DD-csitrep.md`

Use today's date.

After saving, ask the user if they'd like to:
- Send it to a Slack channel (if Slack MCP is available)
- Email it to stakeholders (if Gmail MCP is available)
- Just keep the local file

## Step 7: Slack Delivery (if requested or if triggered from Slack)

If the user asks to send to Slack, or if this session was initiated from a Slack mention:

1. Ask which Slack channel to post to (e.g., #project-updates, #construction-team)
2. Format the report for Slack readability:
   - Post the EXECUTIVE SUMMARY and CRITICAL ISSUES as the main message
   - Post the full detailed report as a thread reply
3. Use the Slack MCP tools to send the messages:
   - Use `slack_send_message` to post to the channel
   - Keep the main message concise — lead with critical items
4. Confirm to the user that the report was posted

If the session was triggered by a Slack message (e.g., "@Claude generate a CSitRep"), automatically post the report back to the same channel/thread where it was requested.

## Important Rules

- ALWAYS dispatch agents in parallel, never sequentially
- If an agent fails or a folder is empty, still produce the report with available sections
- Mark any missing section as "NO DATA AVAILABLE FOR THIS PERIOD"
- Never fabricate data - only report what the agents found in the documents
- Keep the report factual and concise - no filler language
- When posting to Slack, never post raw markdown — format for Slack's mrkdwn syntax
