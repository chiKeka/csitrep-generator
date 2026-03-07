---
name: generate
description: >
  Generate a Situation Report (SitRep). Use when the user asks for a project
  status report, situation report, weekly report, SitRep, or CSitRep. Works
  across all project types: construction, software, development programs,
  product/manufacturing, consulting, and custom projects.
disable-model-invocation: false
user-invocable: true
argument-hint: [project-name]
allowed-tools: Read, Glob, Grep, Bash, Agent, Write, AskUserQuestion
model: opus
---

# SitRep Generator - Orchestrator

You are the orchestrator for generating Situation Reports. You read the project configuration, dispatch the right specialist agents for the project type, and synthesize their findings into a single report.

## Step 1: Load Project Configuration

Read `./data/config/project-info.json` for:
- `project_name` - The project name
- `project_type` - One of: construction, software, program, product, consulting, custom
- `reporting_period` - weekly or monthly
- `domains` - Array of {name, agent, folder} defining the 5 tracking domains
- Other metadata (owner, lead, budget, dates)

If the file is empty, has no `project_type`, or has no `domains`, tell the user:
"No project configured yet. Run /csitrep-generator:setup first."
Then stop.

If the user provided a project name as an argument, use that instead of what's in the config.

## Step 2: Validate Data Folders

Read the `domains` array from the config. For each domain, check its `folder` for documents.

For each folder:
- If it contains files (excluding README.md), note the count and types
- If it's empty, warn the user and ask if they want to proceed without that section

## Step 3: Dispatch Specialist Agents IN PARALLEL

Read the `domains` array. Spawn ALL agents simultaneously using the Agent tool.

For each domain in the config:
- Agent name: use the `agent` field from the domain config
- Prompt: "Analyze all documents in ./[folder] and produce [domain name] status findings. Flag items as CRITICAL, WATCH, or ON TRACK."

Example: if config says:
```json
{"name": "Schedule", "agent": "construction-schedule", "folder": "data/schedule/"}
```
Then dispatch: `@construction-schedule` with prompt about `./data/schedule/`

Dispatch ALL domains in parallel. Do NOT run them one at a time.

## Step 4: Synthesize Findings

Once all agents return, build the SitRep using the template in `reference.md`.

Adapt the report header based on project type:
- Construction: "CONSTRUCTION SITUATION REPORT (CSitRep)"
- Software: "SOFTWARE PROJECT SITUATION REPORT"
- Program: "PROGRAM SITUATION REPORT"
- Product: "PRODUCT DEVELOPMENT SITUATION REPORT"
- Consulting: "ENGAGEMENT SITUATION REPORT"
- Custom: "PROJECT SITUATION REPORT"

Apply these classification rules across all findings:
- **CRITICAL**: Needs a decision today, blocking progress, major breach, safety/compliance issue
- **WATCH**: Trending negative, needs attention this week, moderate variance
- **ON TRACK**: Within tolerance, progressing as planned

For the RECOMMENDED ACTIONS section:
- Prioritize by urgency (CRITICAL items first)
- Be specific: name the action, who should act, and by when
- Limit to 5-7 actions maximum
- Each action should be tied to a specific finding

## Step 5: Present Draft for Review

Display the complete SitRep to the user. Ask:
"Here's the draft SitRep. Would you like to make any changes before I save it?"

Wait for user confirmation or edits.

## Step 6: Save the Report

Save the final SitRep to `./output/csitrep/` with the filename format:
`YYYY-MM-DD-sitrep.md`

Use today's date.

After saving, ask the user if they'd like to:
- Send it to a Slack channel (if Slack MCP is available)
- Email it to stakeholders (if Gmail MCP is available)
- Just keep the local file

## Step 7: Slack Delivery (if requested or if triggered from Slack)

If the user asks to send to Slack, or if this session was initiated from a Slack mention:

1. Ask which Slack channel to post to
2. Format the report for Slack readability:
   - Post the EXECUTIVE SUMMARY and CRITICAL ISSUES as the main message
   - Post the full detailed report as a thread reply
3. Use the Slack MCP tools to send the messages
4. Confirm to the user that the report was posted

If the session was triggered by a Slack message, automatically post the report back to the same channel/thread.

## Important Rules

- ALWAYS dispatch agents in parallel, never sequentially
- If an agent fails or a folder is empty, still produce the report with available sections
- Mark any missing section as "NO DATA AVAILABLE FOR THIS PERIOD"
- Never fabricate data - only report what the agents found in the documents
- Keep the report factual and concise - no filler language
- When posting to Slack, never post raw markdown - format for Slack's mrkdwn syntax
- The domain sections in the report should match the project's configured domains, not hardcoded construction categories
