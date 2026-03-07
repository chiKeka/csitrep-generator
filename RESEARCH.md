# CSitRep Generator - Research: Building as a Claude Code Plugin

---

## PART 1: WHAT IS A CLAUDE CODE PLUGIN?

A Claude Code plugin is a **distributable package** that bundles custom functionality into Claude Code. It's not a standalone app — it's an extension that lives inside Claude Code and gives it new abilities.

Think of it like a WordPress plugin: you install it, and Claude Code gains new skills, agents, commands, hooks, and data connections it didn't have before.

### What a Plugin Contains (Building Blocks)

A plugin is a folder with a `.claude-plugin/` directory and up to 6 types of components:

| Component | What It Does | File Location |
|-----------|-------------|---------------|
| **Skills** | Instructions Claude auto-loads when relevant, or invoked via `/slash-command` | `skills/<name>/SKILL.md` |
| **Subagents** | Specialist agents with their own system prompts, tools, and models | `agents/<name>.md` |
| **Hooks** | Shell scripts that run automatically on events (before/after tool use, session start, etc.) | `hooks/hooks.json` |
| **MCP Servers** | Connections to external services (Google Drive, Slack, databases) | `.mcp.json` |
| **Commands** | Simple slash commands (legacy, now unified with skills) | `commands/<name>.md` |
| **Settings** | Default configuration when plugin is enabled | `settings.json` |

### Plugin Folder Structure

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          # Manifest (ONLY file in this folder)
├── skills/                  # At plugin root, NOT inside .claude-plugin/
│   └── my-skill/
│       ├── SKILL.md         # Skill definition with YAML frontmatter
│       ├── reference.md     # Optional supporting docs
│       └── scripts/         # Optional helper scripts
├── agents/                  # Subagent definitions
│   └── my-agent.md
├── hooks/                   # Event-driven automation
│   └── hooks.json
├── .mcp.json                # External service connections
├── settings.json            # Default plugin settings
├── scripts/                 # Utility scripts (for hooks, preprocessing)
│   └── helper.sh
└── README.md
```

**Critical rule:** Only `plugin.json` goes inside `.claude-plugin/`. Everything else is at the plugin root.

### plugin.json Manifest

```json
{
  "name": "csitrep-generator",
  "version": "1.0.0",
  "description": "Multi-agent Construction Situation Report generator",
  "author": {
    "name": "Your Name"
  },
  "keywords": ["construction", "reporting", "project-management"],
  "skills": "./skills/",
  "agents": "./agents/",
  "hooks": "./hooks/hooks.json",
  "mcpServers": "./.mcp.json"
}
```

The `name` field is the only required field. It becomes the namespace prefix for all skills (e.g., `/csitrep-generator:generate-report`).

### How Skills Work (SKILL.md)

Skills are the primary abstraction. Each skill is a directory with a `SKILL.md` file:

```yaml
---
name: my-skill
description: When to use this skill (Claude matches this against conversation context)
disable-model-invocation: false    # true = only manual /slash invocation
user-invocable: true               # false = hidden from /menu, auto-only
allowed-tools: Read, Grep, Bash    # restrict tool access
model: sonnet                      # or opus, haiku, inherit
context: fork                      # run in isolated subagent context
---

Instructions Claude follows when this skill activates...
```

**Key distinction:**
- `disable-model-invocation: false` = Claude auto-loads this skill when it matches the conversation
- `disable-model-invocation: true` = User must explicitly type `/plugin-name:skill-name`

### How Subagents Work (agents/*.md)

```yaml
---
name: my-agent
description: When Claude should delegate to this agent
tools: Read, Grep, Glob, Bash
model: sonnet
maxTurns: 10
background: false
---

System prompt instructions for this agent...
```

Subagents run in **isolated context windows** — they don't bloat the main conversation. They return only their final findings.

### How Hooks Work (hooks.json)

Hooks are **deterministic automation** — they fire every time, no judgment involved:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [{ "type": "command", "command": "./scripts/validate.sh" }]
      }
    ],
    "Stop": [
      {
        "hooks": [{ "type": "command", "command": "./scripts/post-run.sh" }]
      }
    ]
  }
}
```

Available events: `SessionStart`, `PreToolUse`, `PostToolUse`, `Stop`, `SubagentStart`, `SubagentStop`, `Notification`, and more.

### How MCP Servers Work (.mcp.json)

MCP connects Claude Code to external services:

```json
{
  "mcpServers": {
    "google-drive": {
      "url": "sse://mcp.google.com/drive",
      "env": { "AUTH_TOKEN": "${GDRIVE_TOKEN}" }
    },
    "slack": {
      "command": "npx",
      "args": ["@anthropic-ai/mcp-slack"]
    }
  }
}
```

### How to Install & Test Plugins

```bash
# Test during development (loads from local folder)
claude --plugin-dir ./my-plugin

# Install from marketplace
claude plugin install csitrep-generator@my-marketplace

# Scoped installation
claude plugin install csitrep-generator --scope project   # team-shared
claude plugin install csitrep-generator --scope user       # personal
```

---

## PART 2: HOW THE CSITREP SYSTEM MAPS TO A PLUGIN

### Original Architecture vs. Plugin Architecture

The original idea had an orchestrator dispatching 5 specialist agents, then a synthesis agent producing the final report. Here's how that maps — and what needs to change:

**Original concept:**
```
Orchestrator Agent
  ├── Schedule Agent (reads schedule docs)
  ├── Cost Agent (reads cost docs)
  ├── Safety Agent (reads safety docs)
  ├── Contract Agent (reads contract docs)
  └── Site Agent (reads site docs)
        ↓
  Synthesis Agent → CSitRep Output
```

**Plugin-native architecture:**
```
Plugin: csitrep-generator/
  ├── Skill: /csitrep-generator:generate     ← User entry point (orchestrates everything)
  ├── Agent: schedule-agent.md               ← Dispatched by the skill
  ├── Agent: cost-agent.md                   ← Dispatched by the skill
  ├── Agent: safety-agent.md                 ← Dispatched by the skill
  ├── Agent: contract-agent.md               ← Dispatched by the skill
  ├── Agent: site-agent.md                   ← Dispatched by the skill
  ├── Hook: preprocess on SessionStart       ← Auto-convert xlsx/docx before analysis
  ├── MCP: google-drive / sharepoint         ← Pull docs from cloud storage
  └── MCP: slack / gmail                     ← Deliver the final report
```

### What Changes From the Original Architecture

| Original Concept | Plugin Reality | Why |
|-----------------|---------------|-----|
| Standalone orchestrator agent | **Skill** is the entry point | Skills are how users trigger workflows in plugins. The skill IS the orchestrator. |
| Separate synthesis agent | **The skill itself synthesizes** | After subagents return, the skill's context has all outputs. It can synthesize directly — no need for a 6th agent. |
| Manual document routing | **Folder-based + hooks** | A `SessionStart` hook can auto-preprocess files. Agents are told which folders to read in their system prompts. |
| External file connectors | **Bundled MCP servers** | The plugin's `.mcp.json` declares Google Drive / SharePoint connections, installed with the plugin. |
| Report delivery | **Bundled MCP servers** | Slack/Gmail MCP servers bundled in the plugin for output delivery. |
| Human-in-the-loop | **Built into the skill flow** | The skill asks the user to review before saving/sending. This is native to how skills work. |

### The Revised Architecture (Plugin-Native)

```
csitrep-generator/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── generate/
│       ├── SKILL.md                    # THE ORCHESTRATOR (entry point + synthesis)
│       └── reference.md                # CSitRep template, output format spec
├── agents/
│   ├── schedule-analyst.md             # Reads data/schedule/
│   ├── cost-analyst.md                 # Reads data/cost/
│   ├── safety-analyst.md               # Reads data/safety/
│   ├── contract-analyst.md             # Reads data/contracts/
│   └── site-analyst.md                 # Reads data/site/
├── hooks/
│   └── hooks.json                      # Auto-preprocess files on session start
├── scripts/
│   ├── preprocess.sh                   # Convert xlsx/docx/mpp to CSV/text
│   └── validate-data.sh               # Check data folders aren't empty
├── .mcp.json                           # Google Drive, SharePoint, Slack, Gmail
└── settings.json                       # Default config
```

---

## PART 3: DETAILED PLUGIN COMPONENT DESIGN

### 3.1 The Orchestrator Skill (skills/generate/SKILL.md)

This is the main entry point. The user types `/csitrep-generator:generate` or Claude auto-invokes it when the user asks for a situation report.

```yaml
---
name: generate
description: >
  Generate a Construction Situation Report (CSitRep). Use when the user asks
  for a project status report, situation report, or CSitRep. Reads project
  documents from data/ folders and produces a comprehensive report.
disable-model-invocation: false
user-invocable: true
argument-hint: [project-name]
allowed-tools: Read, Glob, Grep, Bash, Agent, Write
model: opus
---

# CSitRep Generator - Orchestrator

You are generating a Construction Situation Report (CSitRep).

## Step 1: Read project config
Read ./data/config/project-info.json for project name, reporting period, and key dates.

## Step 2: Validate data folders
Check that ./data/schedule/, ./data/cost/, ./data/safety/, ./data/contracts/,
and ./data/site/ contain documents. Warn the user if any folder is empty.

## Step 3: Dispatch specialist agents IN PARALLEL
Spawn ALL 5 agents simultaneously using the Agent tool:
- @schedule-analyst → analyze ./data/schedule/
- @cost-analyst → analyze ./data/cost/
- @safety-analyst → analyze ./data/safety/
- @contract-analyst → analyze ./data/contracts/
- @site-analyst → analyze ./data/site/

## Step 4: Synthesize findings
Once all agents return, synthesize their outputs into the CSitRep format
defined in reference.md. Apply these rules:
- CRITICAL (red): Any item needing a decision today or blocking progress
- WATCH (yellow): Trending negative, needs attention this week
- ON TRACK (green): Within tolerance

## Step 5: Present draft for review
Show the complete CSitRep to the user. Ask if they want changes before saving.

## Step 6: Save and optionally deliver
Save to ./output/csitrep/YYYY-MM-DD-csitrep.md
If the user requests, send via Slack or email using available MCP tools.
```

### 3.2 The Specialist Agents (agents/*.md)

Each agent has a focused role and reads only its domain folder.

**Example: agents/schedule-analyst.md**
```yaml
---
name: schedule-analyst
description: Analyzes construction schedule documents for delays, critical path issues, and milestone risks
tools: Read, Glob, Grep, Bash
model: sonnet
maxTurns: 15
---

You are a Construction Schedule Analyst.

## Your data source
Read ALL files in ./data/schedule/ (CSV, PDF, text files).

## What you look for
- Percent complete vs. planned (by major work package)
- Critical path activities (zero or negative float)
- Milestones at risk in the next 2-4 weeks
- Schedule variance (SV) and Schedule Performance Index (SPI)
- Weather or force majeure delays
- Look-ahead schedule conflicts

## Output format
Return structured findings with clear sections. For each finding, assign:
- CRITICAL: Behind schedule >5%, milestone at risk this week
- WATCH: Behind 2-5%, trending negative
- ON TRACK: Within tolerance

Be specific. Reference document names and data points.
```

**Similar pattern for all 5 agents**, each with domain-specific instructions:

| Agent File | Reads | Key Outputs |
|-----------|-------|-------------|
| `schedule-analyst.md` | `data/schedule/` | % complete, critical path, milestones at risk |
| `cost-analyst.md` | `data/cost/` | Budget burn rate, cost variance, change order exposure |
| `safety-analyst.md` | `data/safety/` | Open actions, hazard patterns, compliance gaps |
| `contract-analyst.md` | `data/contracts/` | Overdue RFIs, unanswered submittals, contract risks |
| `site-analyst.md` | `data/site/` | Workforce levels, access issues, material status |

### 3.3 Hooks (hooks/hooks.json)

Auto-preprocess files when a session starts and validate after the report is written:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/preprocess.sh",
            "timeout": 60
          }
        ]
      }
    ],
    "SubagentStop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Agent completed: check output quality'"
          }
        ]
      }
    ]
  }
}
```

### 3.4 MCP Servers (.mcp.json)

Bundle connections to document stores and communication channels:

```json
{
  "mcpServers": {
    "google-drive": {
      "url": "sse://mcp.google.com/drive",
      "env": {
        "AUTH_TOKEN": "${GDRIVE_AUTH_TOKEN}"
      }
    },
    "slack": {
      "command": "npx",
      "args": ["@anthropic-ai/mcp-slack"],
      "env": {
        "SLACK_TOKEN": "${SLACK_BOT_TOKEN}"
      }
    }
  }
}
```

---

## PART 4: FILE HANDLING — WHAT WORKS, WHAT DOESN'T

### Native Support in Claude Code

| Format | Works? | How |
|--------|--------|-----|
| PDF | Yes | Read tool, up to 100 pages, 32MB limit |
| CSV | Yes | Read as text, excellent for tabular data |
| Text / Markdown | Yes | Any plain text |
| Images (PNG/JPG) | Yes | Vision capability for site photos |
| JSON / XML / YAML | Yes | Structured data |
| Excel (.xlsx) | No - needs preprocessing | Convert to CSV via Python/pandas |
| MS Project (.mpp) | No - needs export | Export from MS Project to CSV or PDF |
| Word (.docx) | Partial | Convert to text via pandoc, or read as PDF |

### Preprocessing Script (scripts/preprocess.sh)

```bash
#!/bin/bash
# Auto-convert unsupported formats before agent analysis
DATA_DIR="${CLAUDE_PLUGIN_ROOT:-$(pwd)}/data"

# Excel to CSV
for f in "$DATA_DIR"/**/*.xlsx; do
  [ -f "$f" ] || continue
  python3 -c "
import pandas as pd
df = pd.read_excel('$f')
df.to_csv('${f%.xlsx}.csv', index=False)
" 2>/dev/null && echo "Converted: $f"
done

# Word to text
for f in "$DATA_DIR"/**/*.docx; do
  [ -f "$f" ] || continue
  pandoc "$f" -t plain -o "${f%.docx}.txt" 2>/dev/null && echo "Converted: $f"
done
```

### Community Plugin: claude-office-skills

An alternative to preprocessing — install `tfriedel/claude-office-skills` plugin which adds native XLSX, DOCX, PPTX, and PDF manipulation skills. This would let agents read spreadsheets directly.

### Token Budget Per Agent

Each agent gets its own ~200K context window. Budget estimate per agent:

| Content | Tokens | Notes |
|---------|--------|-------|
| Agent system prompt | ~500 | Small |
| 10 pages of PDF | 15,000-30,000 | Primary document |
| 5 CSV files (100 rows each) | ~5,000-10,000 | Tabular data |
| 3 text reports | ~3,000-6,000 | Daily logs etc. |
| **Total per agent** | **~25,000-50,000** | Well within 200K limit |

The synthesis step in the orchestrator skill receives ~5 agent summaries of ~2,000 tokens each = ~10,000 tokens. Very manageable.

---

## PART 5: WHAT'S IMPLEMENTABLE RIGHT NOW vs. LATER

### Fully Implementable Now (Phase 1)

| Component | Plugin Feature Used | Status |
|-----------|-------------------|--------|
| 5 specialist agents analyzing documents | Subagents (`agents/`) | Ready |
| Orchestrator dispatching agents in parallel | Skill (`skills/generate/`) | Ready |
| Synthesis into CSitRep format | Same skill, after agents return | Ready |
| Reading PDFs, CSVs, text, images | Native Claude Code Read tool | Ready |
| Folder-based document routing | Agent system prompts | Ready |
| User-triggered report generation | `/csitrep-generator:generate` | Ready |
| Human-in-the-loop review | Skill asks user before saving | Ready |
| Save report to local file | Write tool | Ready |

### Implementable With Setup (Phase 2)

| Component | Plugin Feature Used | What's Needed |
|-----------|-------------------|---------------|
| Auto-convert xlsx/docx | Hook on `SessionStart` | Python + pandas, pandoc installed |
| Slack delivery | MCP server in `.mcp.json` | Slack bot token |
| Email delivery | MCP server in `.mcp.json` | Gmail OAuth setup |
| Google Drive document pull | MCP server in `.mcp.json` | Google OAuth setup |
| SharePoint document pull | MCP server in `.mcp.json` | SharePoint MCP server + auth |

### Requires Workarounds (Phase 3)

| Component | Challenge | Workaround |
|-----------|-----------|-----------|
| MS Project files (.mpp) | No parser exists | Export to CSV/PDF from MS Project manually |
| Scheduled/automated runs | Plugins don't self-trigger | External cron job: `claude --plugin-dir ./csitrep -p "generate report"` |
| Real-time doc monitoring | No file watch capability | Cron or manual trigger |
| Cross-agent discussion | Subagents can't talk to each other | Use Agent Teams (experimental) or let synthesis handle conflicts |
| Historical trend analysis | No built-in memory across sessions | Save prior CSitReps in output/ and have agents read them |

---

## PART 6: RUNNING THE PLUGIN

### Development / Testing
```bash
# Test plugin from local folder
claude --plugin-dir "/Users/keka/Documents/PM Agent"

# Then type:
/csitrep-generator:generate My Project
```

### Production Use
```bash
# Install to user scope
claude plugin install csitrep-generator --scope user

# Run interactively
claude
> Generate a CSitRep for the highway project

# Run headless (automation)
claude -p "Generate a CSitRep for the highway project" --output-format json
```

### Scheduled Reports
```bash
# Weekly CSitRep every Friday at 4 PM
0 16 * * 5 cd ~/projects/highway && claude --plugin-dir ~/plugins/csitrep -p "Generate weekly CSitRep" > /dev/null
```

---

## PART 7: DISTRIBUTION

### Team Sharing Options

1. **Git repository** — Check the plugin folder into a repo. Team members clone and use `--plugin-dir`
2. **Plugin marketplace** — Create a `.claude-plugin/marketplace.json` and host on GitHub. Team installs via `/plugin marketplace add org/repo`
3. **Project-scoped** — Drop the plugin into a project's `.claude/` folder. Anyone who opens the project gets the plugin

### Marketplace Distribution

```json
// .claude-plugin/marketplace.json
{
  "plugins": [
    {
      "name": "csitrep-generator",
      "path": ".",
      "description": "Multi-agent Construction Situation Report generator"
    }
  ]
}
```

Team installs with:
```bash
/plugin marketplace add your-org/csitrep-generator
```

---

## SOURCES

### Official Documentation
- [Create Plugins - Claude Code Docs](https://code.claude.com/docs/en/plugins)
- [Plugins Reference - Claude Code Docs](https://code.claude.com/docs/en/plugins-reference)
- [Create Custom Subagents - Claude Code Docs](https://code.claude.com/docs/en/sub-agents)
- [Extend Claude with Skills - Claude Code Docs](https://code.claude.com/docs/en/skills)
- [Hooks Guide - Claude Code Docs](https://code.claude.com/docs/en/hooks)
- [Agent Teams - Claude Code Docs](https://code.claude.com/docs/en/agent-teams)
- [Plugin Marketplaces - Claude Code Docs](https://code.claude.com/docs/en/plugin-marketplaces)

### Tutorials & Guides
- [How to Build Claude Code Plugins (DataCamp)](https://www.datacamp.com/tutorial/how-to-build-claude-code-plugins)
- [Building My First Claude Code Plugin (alexop.dev)](https://alexop.dev/posts/building-my-first-claude-code-plugin/)
- [Claude Code Plugin Ecosystem (eesel.ai)](https://www.eesel.ai/blog/claude-code-plugin)
- [Skills vs Commands vs Subagents vs Plugins](https://www.youngleaders.tech/p/claude-skills-commands-subagents-plugins)
- [Claude Code Full Stack Explained (alexop.dev)](https://alexop.dev/posts/understanding-claude-code-full-stack/)

### Community & Tools
- [Claude Office Skills Plugin](https://github.com/tfriedel/claude-office-skills)
- [Anthropic Official Plugins](https://github.com/anthropics/claude-code/tree/main/plugins)
- [Claude Code Showcase (hooks, skills, agents)](https://github.com/ChrisWiles/claude-code-showcase)
- [Claude Code Multi-Agent Guide (Shipyard)](https://shipyard.build/blog/claude-code-multi-agent/)
- [Customize Claude Code with Plugins (Anthropic Blog)](https://claude.com/blog/claude-code-plugins)
