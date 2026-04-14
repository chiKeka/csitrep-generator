---
name: onboard
description: >
  Interactive onboarding walkthrough for new users. Guides non-technical PMs
  through installing dependencies, setting up their first project, and generating
  their first report step by step. Use when the user is new or confused.
disable-model-invocation: false
user-invocable: true
argument-hint:
allowed-tools: Read, Write, Bash, Glob, AskUserQuestion
model: sonnet
---

# Onboarding Walkthrough

Guide a new user through setup from zero to their first report. Designed for
project managers who may not be comfortable with the terminal.

## Step 1: Welcome and Check Environment

```
Welcome to SitRep Generator - your AI project reporting assistant.

I'll walk you through setup step by step. First, let me check your environment...
```

Run these checks silently:
```bash
python3 --version 2>/dev/null
pandoc --version 2>/dev/null | head -1
pip3 list 2>/dev/null | grep -E "pandas|openpyxl|python-docx|python-pptx"
```

Report what's ready and what needs installing:

```
Environment check:

  Claude Code:    OK (you're running it)
  Python 3:       [OK / MISSING - needed for Excel conversion]
  pandoc:         [OK / MISSING - needed for Word conversion]
  pandas:         [OK / MISSING]
  python-docx:    [OK / MISSING]

[If anything missing:]
  To install everything at once, run this in a separate terminal:
  brew install pandoc && pip3 install pandas openpyxl python-docx python-pptx xlrd

  You can continue setup now - these are only needed when you have
  Excel or Word files to analyze.
```

## Step 2: Project Setup

```
Let's set up your project. The fastest way is to drop a project document
(charter, scope, proposal, contract) and I'll extract the details.

Or I can ask you a few questions instead.

1. I have a document to upload
2. I'll enter details manually
```

Run `/csitrep-generator:setup` based on their choice. The setup skill handles
the rest of project configuration.

If setup is already complete (project-info.json exists), show:
```
You already have a project configured: [PROJECT_NAME]

1. Continue with this project
2. Start fresh with a new project
```

## Step 3: Explain the Data Folders

After setup completes, explain clearly where to put files:

```
Your project has 5 data folders. Here's what goes where:

  data/[folder1]/  - [Domain 1]
    Put: [specific examples for this project type]

  data/[folder2]/  - [Domain 2]
    Put: [specific examples for this project type]

  ...etc for all 5 folders.

Supported file types:
  - PDF (read directly)
  - Excel (.xlsx, .xls) (auto-converted to CSV)
  - Word (.docx, .doc) (auto-converted to text)
  - PowerPoint (.pptx) (auto-converted to text)
  - CSV, TXT (read directly)
  - Images (.png, .jpg) (read directly)

Just drop files into the right folder. Don't worry about naming or format.
```

For construction, give concrete examples:
```
  data/schedule/   - Schedule
    Put: Baseline schedule exports, daily logs, look-ahead schedules,
         MS Project exports, Primavera exports

  data/cost/       - Cost & Budget
    Put: Budget vs actual reports, cost tracking spreadsheets,
         change order logs, pay applications, invoices

  data/safety/     - Safety
    Put: Incident reports, inspection reports, toolbox talk records,
         safety observations, OSHA logs

  data/contracts/  - Contracts & Admin
    Put: RFI logs, submittal registers, meeting minutes,
         correspondence, transmittals, specification sections

  data/site/       - Site Conditions
    Put: Daily reports, weather logs, delivery tickets,
         equipment logs, site photos, progress photos
```

(Adapt examples for software, program, product, consulting types.)

## Step 4: Import from PM Tools (Optional)

```
Do you use any of these project management tools?

1. Jira / Jira Software
2. MS Project
3. Primavera P6
4. Procore
5. Monday.com / Asana / Smartsheet
6. None - I'll add files manually
```

If they select a tool, run `/csitrep-generator:import [tool]` to guide them
through exporting data from that tool.

## Step 5: Add Some Data

```
Now add at least a few documents to your data folders.

You can:
  a) Drag files into the folders using Finder
  b) Copy files from another location
  c) Paste a file path here and I'll copy it for you

Let me know when you've added some files, and I'll check them.
```

Wait for the user. When they say ready, run validation:
Run the logic from `/csitrep-generator:validate` to check the data.

## Step 6: Generate First Report

```
You're ready to generate your first report.

This will:
  1. Convert any Office files automatically
  2. Send 5 specialist AI agents to analyze your documents in parallel
  3. Synthesize findings into a structured Situation Report
  4. Generate a visual HTML dashboard

Ready? (yes/no)
```

If yes, run `/csitrep-generator:generate`.

## Step 7: Next Steps

After the first report is generated:

```
Your first SitRep is ready.

What to do next:
  1. Review the report and dashboard
  2. Run /csitrep-generator:feedback to flag anything that needs adjusting
  3. Run /csitrep-generator:team-setup to configure Slack delivery for your team
  4. Run /csitrep-generator:schedule to automate recurring reports

Your team can receive reports in Slack without installing anything.

Quick reference:
  /csitrep-generator:generate      - Generate a new report
  /csitrep-generator:dashboard-ui  - Visual HTML dashboard
  /csitrep-generator:compare       - Compare reports over time
  /csitrep-generator:feedback      - Flag incorrect findings
  /csitrep-generator:import        - Import from Jira, Procore, etc.
  /csitrep-generator:validate      - Check data quality
  /csitrep-generator:track-risks   - Manage risk register
  /csitrep-generator:track-actions - Track action items
```

## Rules
- Use plain, non-technical language throughout
- Never assume the user knows terminal commands
- If a step fails, explain what happened and how to fix it simply
- Don't overwhelm with options - guide one step at a time
- Celebrate small wins ("Your data looks good!" "First report generated!")
- The onboard skill should feel like a friendly colleague walking them through it
- Adapt the folder examples to the specific project type they selected
