# Contributing Skills to the Arsenal

This guide covers how to create, structure, and contribute skills following the open [Agent Skills](https://agentskills.io) standard.

## Quick Start

1. Pick a tier: `shared/`, `security/`, `intel/`, or `comms/`
2. Create a directory: `<tier>/<skill-name>/`
3. Write a `SKILL.md` with YAML frontmatter
4. Add `scripts/`, `references/`, and `assets/` as needed
5. Open a PR

## Skill Tiers

| Tier | Directory | Who Gets It | Purpose |
|------|-----------|-------------|---------|
| **shared** | `shared/` | All knights | Base capabilities — communication, search, reporting |
| **security** | `security/` | Security knights (Galahad) | Threat intel, CVE analysis, SIEM integration |
| **intel** | `intel/` | Intelligence knights | News, weather, data gathering |
| **comms** | `comms/` | Communications knights | Email, notifications, messaging |

**Rule of thumb:** If every knight needs it → `shared/`. If only domain specialists need it → domain tier.

## Directory Structure (agentskills.io spec)

```
skill-name/
├── SKILL.md              # REQUIRED — Frontmatter + instructions
├── scripts/              # Optional — Executable code (bash, python, JS)
├── references/           # Optional — On-demand documentation
└── assets/               # Optional — Templates, schemas, static data
```

### SKILL.md — The Core File

Every skill MUST have a `SKILL.md` with YAML frontmatter:

```yaml
---
name: my-skill
description: What this skill does and when to use it. Be specific — this is how agents discover your skill.
allowed-tools: Bash(curl:*) Read Write
metadata:
  author: roundtable
  version: "1.0"
  tier: shared
  compatibility: Any environment requirements
---

# My Skill

Instructions for the agent go here as markdown.
```

#### Frontmatter Fields

| Field | Required | Rules |
|-------|----------|-------|
| `name` | ✅ | 1-64 chars, lowercase alphanumeric + hyphens, must match directory name |
| `description` | ✅ | 1-1024 chars, describe what AND when to use |
| `allowed-tools` | No | Space-delimited list of pre-approved tools |
| `license` | No | License name or reference to LICENSE file |
| `compatibility` | No | Environment requirements (max 500 chars) |
| `metadata` | No | Key-value pairs: author, version, tier, etc. |

#### Name Rules
- ✅ `cve-deep-dive`, `web-search`, `opencti-intel`
- ❌ `CVE-Deep-Dive` (no uppercase)
- ❌ `-web-search` (no leading hyphen)
- ❌ `web--search` (no consecutive hyphens)
- ❌ Name must match the parent directory exactly

#### Writing Good Descriptions

The description is the **primary signal** agents use to decide when to activate your skill. Be specific:

```yaml
# ❌ Bad — too vague
description: Helps with security stuff.

# ✅ Good — specific triggers and capabilities
description: Query the OpenCTI threat intelligence platform for STIX 2.1 data including indicators, vulnerabilities, malware, reports, and attack patterns. Use for threat briefings, CVE lookups, IOC searches, and platform statistics.
```

### scripts/ — Executable Code

Put runnable scripts here. They should be:
- **Self-contained** — minimal external dependencies
- **No jq** — OpenClaw/knight containers don't ship jq; use grep/sed/cut
- **Executable** — `chmod +x` all scripts
- **Documented** — include usage comments at the top

```bash
#!/usr/bin/env bash
# Query NVD API for CVE details
# Usage: query-nvd.sh CVE-2026-XXXXX
set -euo pipefail

CVE_ID="${1:?Usage: query-nvd.sh CVE-ID}"
# ... implementation
```

Supported languages: **Bash** (preferred for portability), **Python 3**, **JavaScript/Node**.

### references/ — On-Demand Documentation

Reference material the agent loads only when needed. Keep files focused — each one should cover ONE topic.

Good examples:
- `QUERIES.md` — GraphQL query reference for an API skill
- `nvd-api.md` — NVD API endpoint documentation
- `feeds.md` — List of configured RSS feeds with URLs

**Keep individual files under 500 lines.** If it's longer, split it.

### assets/ — Static Resources

Templates, schemas, and data files:
- `daily-briefing.md` — Handlebars-style report template
- `cve-analysis.md` — Structured analysis output template
- `config.yaml` — Default configuration

Templates use `{{variable}}` syntax and `{{#each list}}...{{/each}}` for iteration.

## Progressive Disclosure

This is the key design principle. Don't front-load everything into context:

1. **Startup (~100 tokens/skill)** — Only `name` + `description` from frontmatter
2. **Activation (~500-2000 tokens)** — Full SKILL.md body loaded when agent picks the skill
3. **Execution (on-demand)** — `references/` and `assets/` loaded only when the agent reads them

**Why this matters:** A knight with 10 skills loads ~1000 tokens at startup instead of ~20,000. The agent only pays the context cost for skills it actually uses.

## Writing SKILL.md Instructions

The markdown body after frontmatter is your agent's playbook. Structure it for efficiency:

### Recommended Sections

```markdown
# Skill Name

Brief overview (1-2 sentences).

## When to Use
Specific triggers and scenarios.

## Quick Reference
Most common commands/patterns — the 80% case.

## Scripts
Document each script with usage examples.

## Configuration
Environment variables, endpoints, auth.

## Tips / Edge Cases
Things the agent should watch out for.

## Dependencies
Other skills this works best with.
```

### Keep SKILL.md Under 500 Lines

If your instructions are longer, move detailed content to `references/`:

```markdown
## Common Queries
See [references/QUERIES.md](references/QUERIES.md) for the full query reference.
```

## Example: Creating a New Skill

Let's say you want a skill for querying a Wazuh SIEM:

```
security/wazuh-siem/
├── SKILL.md
├── scripts/
│   ├── wazuh-alerts.sh      # Fetch recent alerts
│   ├── wazuh-agents.sh      # List connected agents
│   └── wazuh-search.sh      # Search events
├── references/
│   ├── api-endpoints.md     # Wazuh API reference
│   └── alert-levels.md      # Severity level mapping
└── assets/
    └── siem-report.md       # Report template
```

```yaml
---
name: wazuh-siem
description: Query the Wazuh SIEM for security alerts, agent status, and event searches. Use for incident investigation, compliance checks, and security monitoring dashboards.
allowed-tools: Bash(curl:*) Read Write
metadata:
  author: roundtable
  version: "1.0"
  tier: security
  compatibility: Requires WAZUH_URL and WAZUH_TOKEN environment variables
---
```

## Git-Sync Delivery

Each knight's pod has a git-sync sidecar that pulls from this repo. The knight's HelmRelease config specifies which tier directories to sync:

```yaml
# Galahad (security) — gets shared + security
gitSync:
  repo: https://github.com/dapperdivers/roundtable-arsenal
  paths:
    - shared
    - security

# Herald (intel/comms) — gets shared + intel + comms
gitSync:
  repo: https://github.com/dapperdivers/roundtable-arsenal
  paths:
    - shared
    - intel
    - comms
```

Skills land in `/workspace/skills/` where the knight-agent runtime discovers them automatically.

## Validation

Before submitting a PR:

```bash
# Check frontmatter is valid
python3 -c "
import yaml, sys
with open('SKILL.md') as f:
    content = f.read()
parts = content.split('---', 2)
meta = yaml.safe_load(parts[1])
assert meta.get('name'), 'Missing name'
assert meta.get('description'), 'Missing description'
print(f'✓ {meta[\"name\"]}: {meta[\"description\"][:60]}...')
"

# Check scripts are executable
find scripts/ -type f \( -name "*.sh" -o -name "*.py" \) ! -executable

# Check shell scripts parse
find scripts/ -name "*.sh" -exec bash -n {} \;
```

The CI workflow validates all of this automatically on PRs.

## Checklist

Before submitting:

- [ ] `SKILL.md` has valid YAML frontmatter with `name` and `description`
- [ ] `name` matches the directory name exactly
- [ ] `description` is specific enough for agents to discover
- [ ] Scripts are executable (`chmod +x`)
- [ ] Scripts don't depend on `jq`
- [ ] No hardcoded secrets (use environment variables)
- [ ] SKILL.md body is under 500 lines
- [ ] Placed in the correct tier directory
- [ ] `metadata.tier` matches the actual directory tier
