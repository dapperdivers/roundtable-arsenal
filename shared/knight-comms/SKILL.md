---
name: knight-comms
description: Ask other Round Table knights for help during a task. Use when you need expertise from another domain — research, security analysis, financial data, infrastructure status, or household info.
---

# Knight-to-Knight Communication

Ask another knight for help directly via NATS. Use this when your task requires expertise from another domain.

## When to Use

- You need **research** on a topic → ask **Kay** (research)
- You need **security context** (CVEs, threats) → ask **Galahad** (security)
- You need **financial data** (documents, budgets) → ask **Percival** (finance)
- You need **infrastructure status** (pods, deployments) → ask **Tristan** (infra)
- You need **household info** (calendar, smart home) → ask **Bedivere** (home)
- You need **career/company intel** → ask **Lancelot** (career)

## Usage

```bash
# Ask a knight and wait for their response (default 60s timeout)
RESULT=$(bash /workspace/skills/shared/knight-comms/scripts/ask-knight.sh <domain> "<question>" [timeout_seconds])
echo "$RESULT"
```

### Examples

```bash
# Kay: research a topic
RESULT=$(bash /workspace/skills/shared/knight-comms/scripts/ask-knight.sh research "What are the latest Alabama tax law changes for 2024 filers?" 90)

# Galahad: security context
RESULT=$(bash /workspace/skills/shared/knight-comms/scripts/ask-knight.sh security "Any known security incidents involving Clipboard Health?" 60)

# Percival: financial data
RESULT=$(bash /workspace/skills/shared/knight-comms/scripts/ask-knight.sh finance "Search Paperless for all W-2 documents from 2024" 60)

# Tristan: infrastructure status
RESULT=$(bash /workspace/skills/shared/knight-comms/scripts/ask-knight.sh infra "What's the current health of the security namespace?" 60)
```

## How It Works

1. Your script publishes a task to `fleet-a.tasks.<domain>.<taskId>`
2. The target knight picks it up via its NATS consumer
3. The target knight processes and publishes the result
4. Your script retrieves the result from `fleet_a_results` stream
5. The result is returned as the script's stdout

## Constraints

- **Max depth: 1** — You can ask another knight, but they should NOT chain further requests. Include "Do not delegate to other knights" in your sub-task.
- **Timeout** — Default 60 seconds. Complex research may need 90-120s.
- **Cost awareness** — Each cross-knight request costs tokens. Only ask when the expertise genuinely helps your task.
- **Be specific** — Give the other knight a clear, focused question. Don't dump your entire task on them.

## Knight Directory

| Domain | Knight | Topics | Specialty |
|--------|--------|--------|-----------|
| security | 🛡️ Galahad | `fleet-a.tasks.security.>` | Threat intel, CVEs, OpenCTI |
| finance | 📋 Percival | `fleet-a.tasks.finance.>` | Tax prep, Paperless, budgets |
| career | ⚔️ Lancelot | `fleet-a.tasks.career.>` | Interviews, LinkedIn, company research |
| infra | 🏗️ Tristan | `fleet-a.tasks.infra.>` | Cluster health, Flux, deployments |
| home | 🏠 Bedivere | `fleet-a.tasks.home.>` | Home Assistant, family, calendar |
| research | 📡 Kay | `fleet-a.tasks.research.>` | Deep research, news, solar weather |
