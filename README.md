# Round Table Arsenal

Skills and resources for Knights of the Round Table — AI agents running on the [pi-knight](https://github.com/roundtable-k8s/pi-knight) runtime.

> **Round Table platform skills moved.** Skills for working on the Round Table
> itself (operator/UI/runtime coding, chain orchestration, fleet status,
> briefing synthesis, Night Watch, github-pm, the planner prompt) now live in
> [roundtable-k8s/arsenal](https://github.com/roundtable-k8s/arsenal). This repo
> keeps the personal domain packs plus `shared/`, which they depend on.

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
│   ├── morning-security-brief/ # Short daily brief: exploited vulns, KEV, your-stack CVEs (kagent)
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
│   ├── garden-advisor/        # This-week garden advice from your notes + forecast (kagent)
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
│   ├── obsidian-conventions/  # Reading/citing a vault via MCPVault; ready-to-paste edits (kagent)
│   ├── zettel-extraction/     # Atomic notes with verbatim takes, as JSON (kagent)
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

Knights run on the **pi-knight** runtime (Pi SDK). The operator delivers skills
from one or more **arsenals** (git repos of skills) and filters them per knight:

```
git-sync / git-sync-<name> (one sidecar per arsenal) → /arsenal/<name>   (full repo, read-only)
skill-filter sidecar → /skills/<category>/<skill> symlinks    (only categories in spec.skills)
pi-knight → discovers skills from /skills via Pi SDK
```

- **`spec.arsenal`** — the primary arsenal. Its fields default to
  `https://github.com/roundtable-k8s/arsenal` (`ref: main`, `period: 300s`), so
  `arsenal: {}` gives the platform arsenal. Leave `spec.arsenal` out entirely and
  only the `spec.arsenals` entries are synced.
- **`spec.arsenals`** — optional extra arsenals (`name`, `repo`, `ref`, `period`,
  `image`), merged after `spec.arsenal` in list order. `name` sets the sync path
  `/arsenal/<name>` and sidecar `git-sync-<name>`; it defaults to the repo basename.
- **Per-skill merge** — for every category in `spec.skills`, `/skills/<category>/<skill>`
  links to the **last** arsenal that provides `<category>/<skill>`, so later
  arsenals override individual skills without hiding the rest of the category.
  The links are refreshed every 60s; skills no arsenal provides any more are pruned.
- **Categories** — a knight only sees the categories listed in `spec.skills`
  (list `shared` explicitly).

This repo is meant to be layered **after** the platform arsenal: its domain packs
add categories, and its copy of `shared/` overrides same-named platform skills
per skill.

```yaml
apiVersion: ai.roundtable.io/v1alpha1
kind: Knight
metadata:
  name: galahad
spec:
  # …other Knight fields omitted
  skills: [shared, security]
  arsenal: {}                  # roundtable-k8s/arsenal @ main (defaults)
  arsenals:
    - name: personal
      repo: https://github.com/dapperdivers/roundtable-arsenal
      ref: main
```

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
