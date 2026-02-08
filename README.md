# ⚔️ Roundtable Arsenal

> *The shared armory for the [Knights of the Round Table](https://github.com/dapperdivers/roundtable)*

This repository contains **skills**, **protocols**, and **templates** used by Knight agents in the Round Table system. It is delivered to knight pods via **git-sync** and consumed by [OpenClaw](https://github.com/openclaw)-powered agents.

## Architecture

Each knight runs as a **3-container pod**:

| Container | Role |
|-----------|------|
| **openclaw** | The LLM agent runtime |
| **nats-bridge** | Message bus integration (inter-knight comms) |
| **git-sync** | Pulls this repo on a schedule, delivering skills to the agent |

Knights select which skills they need via `extraDirs` configuration in their Helm values. A security-focused knight like **Galahad** might mount `skills/security/*` and `skills/shared/*`, while a comms knight might only need `skills/comms/*`.

## Directory Structure

```
roundtable-arsenal/
├── skills/          # OpenClaw-compatible skill directories
│   ├── shared/      # Skills available to all knights
│   ├── security/    # Cybersecurity skills (feeds, CVEs, threat intel)
│   ├── comms/       # Communication skills (email, notifications)
│   └── intel/       # Intelligence gathering (weather, news, solar)
├── protocols/       # Natural language workflow instructions
├── templates/       # Output format definitions (Handlebars-style)
└── .github/         # CI/CD workflows
```

## Skills

Skills are **OpenClaw-compatible skill directories** — each contains a `SKILL.md` (with YAML frontmatter) and a `scripts/` directory with executable tools.

```yaml
# Example SKILL.md frontmatter
---
name: cve-lookup
description: Query NVD/CVE databases for vulnerability information.
---
```

The agent reads `SKILL.md` to understand what the skill does and how to invoke its scripts.

## Protocols

Protocols are **natural language workflow instructions** that knights follow step by step. They describe *when* to run, *what skills to use*, and *what output to produce*. Think of them as runbooks for LLM agents.

Example: The `security/daily-briefing.md` protocol tells a knight how to gather threat data, analyze it, and produce a formatted briefing using the daily briefing template.

## Templates

Templates define the **output format** for reports and digests. They use Handlebars-style placeholders (`{{variable}}`) that get filled in by the report-generator skill or by the agent directly.

## Delivery via git-sync

The git-sync sidecar in each knight's pod clones this repository and keeps it up to date. Skills appear as local directories that the OpenClaw agent can reference. Configuration example:

```yaml
# In knight's Helm values
gitSync:
  repo: https://github.com/dapperdivers/roundtable-arsenal.git
  branch: main
  period: 300s  # sync every 5 minutes

extraDirs:
  - /arsenal/skills/shared
  - /arsenal/skills/security
```

## Contributing

1. Add skills following the `SKILL.md` + `scripts/` convention
2. Ensure scripts have proper argument parsing and `--help` flags
3. Add protocols for any multi-step workflows
4. CI validates all `SKILL.md` files have required frontmatter

## License

[MIT](LICENSE)
