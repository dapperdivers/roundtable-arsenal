---
name: knight-comms
description: Ask other Round Table knights for help during a task. Use when you need expertise from another domain — research, security analysis, financial data, infrastructure status, or household info.
---

# Knight-to-Knight Communication

Ask another knight for help using the `nats_request` tool. Use this when your task requires expertise from another domain.

## When to Use

- You need **research** on a topic → ask **Kay** (research)
- You need **security context** (CVEs, threats) → ask **Galahad** (security)
- You need **financial data** (documents, budgets) → ask **Percival** (finance)
- You need **infrastructure status** (pods, deployments) → ask **Tristan** (infra)
- You need **household info** (calendar, smart home) → ask **Bedivere** (home)
- You need **career/company intel** → ask **Lancelot** (career)

## Usage

Use the `nats_request` tool directly — it's a native tool in your tool loop:

```
nats_request(
  knight: "percival",
  domain: "finance",
  task: "Search Paperless for all W-2 documents from 2024",
  timeout_ms: 600000   // optional, default 10 min
)
```

The tool blocks until the target knight responds, then returns their full response as text. You can continue working with that data immediately.

### Examples

```
// Kay: research a topic
nats_request(knight: "kay", domain: "research", task: "What are the latest Alabama tax law changes for 2024 filers?")

// Galahad: security context
nats_request(knight: "galahad", domain: "security", task: "Any known security incidents involving Clipboard Health?")

// Percival: financial data
nats_request(knight: "percival", domain: "finance", task: "Search Paperless for all W-2 documents from 2024")

// Tristan: infrastructure status
nats_request(knight: "tristan", domain: "infra", task: "What's the current health of the security namespace?")
```

## Constraints

- **Max depth: 1** — You can ask another knight, but they should NOT chain further requests. Include "Do not delegate to other knights" in your sub-task.
- **Timeout** — Default 10 minutes. Most tasks complete in 1-5 minutes.
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
| vault | 🥥 Patsy | `fleet-a.tasks.vault.>` | Vault curation, metadata, cleanup |
| framework | ⚒️ Gawain | `fleet-a.tasks.framework.>` | Pi-knight runtime improvement, benchmarks, optimization |
