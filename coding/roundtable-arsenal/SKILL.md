---
name: roundtable-arsenal
description: Work within the roundtable-arsenal repo. Use when creating, editing, or organizing knight skills in dapperdivers/roundtable-arsenal.
---

# roundtable-arsenal Codebase Guide

## Quick Reference

| Aspect | Detail |
|--------|--------|
| Format | AgentSkills (SKILL.md + scripts/references/assets) |
| CI | `.github/workflows/validate-skills.yaml` |
| Git-synced | Operator clones to knight pods via `spec.arsenal` |

## Repository Layout

Skills are organized by domain folder, each containing one or more skills:

```
career/           Career management skills
  daily-career-report/    context-aggregator/    interview-prep/    linkedin-ops/
coding/           Coding agent guidance
  coding-agent.md         frontend.md
comms/            Communication skills
  email-triage/           notification-digest/
finance/          Financial skills
  daily-finance-report/   paperless-ops/    tax-prep/
  config/                 (shared finance config: bills.json, budget-targets.json)
home/             Home management
  daily-home-report/
infra/            Infrastructure & DevOps
intel/            Threat intelligence
operator/         Operator-specific skills
pentest/          Security testing
project/          Project management
research/         Research skills
security/         Security skills
shared/           Cross-cutting skills (used by all knights)
vault/            Obsidian vault operations
wellness/         Health & wellness
```

## Skill Structure

Every skill MUST have a `SKILL.md` with YAML frontmatter:

```
skill-name/
├── SKILL.md              # Required: frontmatter (name, description) + instructions
├── scripts/              # Optional: executable code (bash, python)
├── references/           # Optional: docs loaded into context as needed
├── templates/            # Optional: output templates (markdown, etc.)
└── assets/               # Optional: static files (icons, fonts)
```

### SKILL.md Format

```markdown
---
name: my-skill
description: Clear description of what this skill does and when to use it.
---

# Skill Title

Instructions, workflows, and guidance here.
```

## Creating Skills — Key Principles

1. **Concise is key** — context window is shared. Only add what the model doesn't already know.
2. **Match freedom to fragility** — fragile operations need specific scripts; flexible tasks need guidance.
3. **Prefer examples over explanations** — show, don't tell.
4. **Scripts for repeatability** — if you'd rewrite the same code twice, make it a script.
5. **Templates for consistent output** — daily reports, briefings, etc.

## Conventions

- Domain folders are lowercase, hyphenated
- Skill folders are lowercase, hyphenated
- Scripts should be executable (`chmod +x`) with shebangs
- Config shared across skills goes in `<domain>/config/`
- `shared/` skills are mounted by ALL knights — keep them lean

## CI Validation

The `validate-skills.yaml` workflow checks:
- Every skill directory has a `SKILL.md`
- Frontmatter has `name` and `description`
- No broken references

## Git Sync

The operator clones this repo to knight pods based on `spec.arsenal.repo` and `spec.arsenal.ref`. Skills appear at `SKILLS_DIR` in the knight runtime. Changes here auto-sync on the configured `spec.arsenal.period`.
