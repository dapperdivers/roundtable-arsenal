# Round Table Arsenal

Skills and resources for Knights of the Round Table — AI agents running on the [pi-knight](https://github.com/dapperdivers/pi-knight) runtime.

All skills follow the open [Agent Skills](https://agentskills.io) standard.

## Structure

```
roundtable-arsenal/
├── shared/                    # Base capabilities (ALL knights)
│   ├── knight-comms/          # Cross-knight collaboration (nats_request)
│   ├── nats-comms/            # Out-of-band NATS messaging (nats_publish)
│   ├── daily-reports/         # Daily briefing templates
│   ├── report-generator/      # Template-based report rendering
│   ├── web-search/            # SearXNG metasearch
│   └── web-fetch/             # URL content extraction
│
├── security/                  # Galahad — Threat intel & security ops
│   ├── opencti-intel/         # OpenCTI GraphQL queries
│   ├── threat-briefing/       # Daily/weekly briefing generation
│   ├── cve-deep-dive/         # CVE vulnerability analysis
│   ├── shodan-recon/          # Shodan asset reconnaissance
│   ├── rss-analyzer/          # Security RSS feed analysis
│   └── daily-security-report/ # Security daily report
│
├── finance/                   # Percival — Tax prep & financial ops
│   ├── paperless-ops/         # Paperless-ngx document management
│   ├── tax-prep/              # Transaction categorization
│   └── daily-finance-report/  # Finance daily report
│
├── career/                    # Lancelot — Career & professional
│   ├── interview-prep/        # Interview preparation
│   ├── linkedin-ops/          # LinkedIn content management
│   └── daily-career-report/   # Career daily report
│
├── infra/                     # Tristan — Infrastructure & cluster ops
│   ├── flux-ops/              # Flux GitOps management
│   └── daily-ops-report/      # Infrastructure daily report
│
├── home/                      # Bedivere — Household & life admin
│   ├── household-ops/         # Home management
│   └── daily-home-report/     # Home daily report
│
├── research/                  # Kay — Deep research
│   └── deep-research/         # Multi-source research
│
├── intel/                     # Kay — Intelligence feeds
│   ├── daily-intel-digest/    # Intel daily digest
│   ├── news-aggregator/       # Tech/security news feeds
│   ├── solar-weather/         # NOAA space weather
│   └── weather-fetch/         # Weather data
│
├── vault/                     # Patsy — Vault curation
│   ├── vault-curator/         # Obsidian vault maintenance
│   └── vault-linter/          # Metadata & frontmatter linting
│
└── comms/                     # Communications
    ├── email-triage/          # Outlook email triage
    └── notification-digest/   # Notification aggregation
```

## Knight Roster

| Knight | Domain | Skills | Specialty |
|--------|--------|--------|-----------|
| 🛡️ Galahad | `security` | shared + security | Threat intel, CVEs, OpenCTI, Shodan |
| 📋 Percival | `finance` | shared + finance | Tax prep, Paperless, budgets |
| ⚔️ Lancelot | `career` | shared + career | Interviews, LinkedIn, company research |
| 🏗️ Tristan | `infra` | shared + infra | Cluster health, Flux, deployments |
| 🏠 Bedivere | `home` | shared + home | Home Assistant, family, calendar |
| 📡 Kay | `research` + `intel` | shared + research + intel | Deep research, news, solar weather |
| 🥥 Patsy | `vault` | shared + vault | Vault curation, metadata, cleanup |
| ⚒️ Gawain | `framework` | shared | Pi-knight runtime improvement |

## Architecture

Knights run on the **pi-knight** runtime (Pi SDK). Skills are delivered via git-sync sidecar with per-knight filtering:

```
git-sync → /arsenal (full repo)
skill-filter sidecar → symlinks SKILL_CATEGORIES → /skills
pi-knight → discovers skills from /skills via Pi SDK
```

Each knight only sees `shared/` plus its domain categories. Configured via `SKILL_CATEGORIES` env var on the skill-filter sidecar.

### Native Tools

Knights have three custom tools registered natively (not bash scripts):

- **`nats_publish`** — Fire-and-forget NATS messaging
- **`nats_request`** — Cross-knight collaboration (send task, wait for response)
- **`spawn_subagent`** — In-process sub-agent for focused subtasks

The `knight-comms` and `nats-comms` skills document when and how to use these tools.

## Skill Format (agentskills.io)

Each skill is a directory with:

```
skill-name/
├── SKILL.md              # Required — frontmatter + instructions
├── scripts/              # Executable helpers (bash, python)
├── references/           # On-demand documentation
└── assets/               # Templates, schemas, static data
```

### Progressive Disclosure

1. **Startup** — Only `name` + `description` loaded (~100 tokens per skill)
2. **Activation** — Full SKILL.md instructions loaded when task matches
3. **Execution** — `references/` and `assets/` loaded on-demand

## License

MIT
