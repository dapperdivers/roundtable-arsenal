# Round Table Arsenal

Skills, templates, and resources for Knights of the Round Table agents.

All skills follow the open [Agent Skills](https://agentskills.io) standard.

## Structure

```
roundtable-arsenal/
├── shared/                    # Tier 1: Base capabilities (ALL knights)
│   ├── nats-comms/            # NATS JetStream messaging
│   ├── web-search/            # SearXNG metasearch
│   ├── web-fetch/             # URL content extraction
│   └── report-generator/      # Template-based report rendering
│
├── security/                  # Tier 2: Security domain (Galahad)
│   ├── opencti-intel/         # OpenCTI GraphQL queries
│   ├── threat-briefing/       # Daily/weekly briefing generation
│   ├── cve-deep-dive/         # CVE vulnerability analysis
│   └── rss-analyzer/          # Security RSS feed analysis
│
├── intel/                     # Tier 2: Intelligence domain
│   ├── news-aggregator/       # Tech/security news feeds
│   ├── solar-weather/         # NOAA space weather
│   └── weather-fetch/         # Weather data
│
└── comms/                     # Tier 2: Communications domain
    ├── email-triage/          # Outlook email triage
    └── notification-digest/   # Notification aggregation
```

## Skill Tiers

| Tier | Directory | Delivery | Who Gets It |
|------|-----------|----------|-------------|
| **Shared** | `shared/` | git-sync to all knights | Every knight |
| **Domain** | `security/`, `intel/`, `comms/` | git-sync per knight config | Knights with matching domain |

## Skill Format (agentskills.io)

Each skill is a directory with:

```
skill-name/
├── SKILL.md              # Required — frontmatter + instructions
├── scripts/              # Executable helpers (bash, python)
├── references/           # On-demand documentation
└── assets/               # Templates, schemas, static data
```

### SKILL.md Frontmatter

```yaml
---
name: skill-name
description: What this skill does and when to use it.
allowed-tools: Bash(curl:*) Read
metadata:
  author: roundtable
  version: "1.0"
  tier: shared|security|intel|comms
---
```

### Progressive Disclosure

1. **Startup** — Only `name` + `description` loaded (~100 tokens per skill)
2. **Activation** — Full SKILL.md instructions loaded when task matches
3. **Execution** — `references/` and `assets/` loaded on-demand by the agent

## Git-Sync Configuration

Knights use git-sync sidecars to pull skills. Configure which tiers each knight receives:

```yaml
# Example: Galahad (security knight)
gitSync:
  repo: https://github.com/dapperdivers/roundtable-arsenal
  paths:
    - shared      # Base capabilities
    - security    # Domain expertise
```

```yaml
# Example: Future herald (intel knight)
gitSync:
  repo: https://github.com/dapperdivers/roundtable-arsenal
  paths:
    - shared
    - intel
    - comms
```

## Validation

```bash
# Validate all skills
npx agentskills validate shared/ security/ intel/ comms/
```

## License

MIT
