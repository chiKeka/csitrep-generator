---
name: validate
description: >
  Validate project data before generating a report. Checks that files are in
  the correct folders, data is readable, and content matches the expected domain.
  Use before generating a report or when data quality is a concern.
disable-model-invocation: false
user-invocable: true
argument-hint:
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion
model: sonnet
---

# Data Validation

Check that all project data is correctly organized, readable, and domain-appropriate before generating a report.

## Step 1: Load Configuration

Read `./data/config/project-info.json` to get the domain-to-folder mapping.
If not configured, tell the user to run `/csitrep-generator:setup` first.

## Step 2: Check Each Domain Folder

For each domain in the config, validate its data folder:

### 2a. Folder Exists
Check that the folder path exists. If not, flag as ERROR.

### 2b. Has Files
Count files in the folder (excluding README.md and hidden files).
- 0 files: flag as WARNING - "No data for [Domain]"
- 1+ files: OK

### 2c. File Readability
For each file, verify it can be read:
- PDF, CSV, TXT, MD: try reading the first few lines
- XLSX, DOCX, PPTX: check if a converted version exists (.csv, .txt). If not, flag as WARNING - "needs preprocessing"
- Unknown extensions: flag as INFO - "unrecognized format, may not be analyzable"

### 2d. Content Relevance Check
Read the first 50 lines (or first page for PDFs) of each file and do a quick relevance check:
- Does the content relate to the domain it's in?
- Example: a safety inspection report in the cost folder = likely misplaced

Use these heuristics per project type:

**Construction:**
- schedule/: look for dates, activities, milestones, % complete, float, CPM
- cost/: look for dollar amounts, budget, actual, variance, line items, cost codes
- safety/: look for incidents, inspections, OSHA, PPE, hazard, injury
- contracts/: look for RFI, submittal, change order, contractor, specification
- site/: look for weather, workforce, equipment, delivery, conditions

**Software:**
- sprint/: look for stories, points, velocity, backlog, sprint, release
- budget/: look for hours, rates, burn, forecast, resource, cost
- quality/: look for bugs, tests, coverage, defects, regression, QA
- blockers/: look for dependency, blocked, risk, issue, impediment
- infra/: look for uptime, deploy, pipeline, server, incident, SLA

**General rule:** If less than 20% of keywords match, flag as WARNING - "may be in wrong folder."

### 2e. Duplicate Check
Flag if the same file appears in multiple domain folders.

### 2f. Stale Data Check
Flag files older than the reporting period:
- Weekly projects: files older than 14 days = WARNING "may be stale"
- Monthly projects: files older than 45 days = WARNING "may be stale"

## Step 3: Cross-Domain Checks

- Check that at least 3 of 5 domains have data (otherwise report will be thin)
- Check for extremely unbalanced data (e.g., 20 files in one folder, 0 in another)
- Verify `project-info.json` has all required fields (name, type, domains, lead)

## Step 4: Present Validation Report

```
DATA VALIDATION REPORT
======================

Project: [name]
Validated: [timestamp]

SUMMARY
  Domains with data:    [X] of 5
  Total files:          [X]
  Errors:               [X]
  Warnings:             [X]

DOMAIN STATUS
  [Domain 1]: OK (3 files) / WARNING (details) / ERROR (details)
  [Domain 2]: OK (2 files) / WARNING (details) / ERROR (details)
  ...

ISSUES FOUND
  [ERROR]   [description + suggested fix]
  [WARNING] [description + suggested fix]
  [INFO]    [description]

READY TO GENERATE: [YES / YES WITH WARNINGS / NO - fix errors first]
```

## Step 5: Offer Fixes

For common issues, offer to fix automatically:
- Misplaced file: "Move [file] from [folder] to [folder]?"
- Missing preprocessing: "Run preprocessing to convert [X] Office files?"
- Missing folders: "Create missing data folders?"

## Rules
- Never modify or delete data files without explicit user confirmation
- The relevance check is heuristic - flag as warning, not error
- A project with warnings can still generate a report
- A project with errors (missing config, no data at all) should not
- Run this automatically as part of the generate flow (called from generate Step 4)
