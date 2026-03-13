---
name: knight-comms
description: Ask other Round Table knights for help during a task. Use when you need expertise from another domain — research, security analysis, financial data, infrastructure status, or household info.
---

# Knight-to-Knight Communication

Ask another knight for help using the `nats_request` tool. Use this when your task requires expertise from another domain.

## When to Use

- You need help from a knight with different expertise
- Your task requires data or analysis you can't do yourself
- You want to delegate a sub-task to a specialist

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

## ⚠️ CRITICAL: Know Your Table

You belong to a specific RoundTable. Check your NATS subject prefix to know which table you're on:

- **`fleet-a`** prefix → you're on the **personal** table
- **`rt-dev`** prefix → you're on the **roundtable-dev** table

**Only request knights within your own table.** Cross-table requests will timeout because the result subscription won't match.

If you're on `rt-dev` and need help from a personal-table knight (or vice versa), say so in your task output — let the orchestrator (Tim or a chain) handle cross-table coordination.

## Knight Directory — Personal Table (`fleet-a`)

| Domain | Knight | Specialty |
|--------|--------|-----------|
| security | 🛡️ Galahad | Threat intel, CVEs, OpenCTI |
| finance | 📋 Percival | Tax prep, Paperless, budgets |
| career | ⚔️ Lancelot | Interviews, LinkedIn, company research |
| infra | 🏗️ Tristan | Cluster health, Flux, deployments |
| home | 🏠 Bedivere | Home Assistant, family, calendar |
| research | 📡 Kay | Deep research, news, solar weather |
| vault | 🥥 Patsy | Vault curation, metadata, cleanup |
| project | ⚒️ Gawain | Orchestration, GitHub PM, chain dispatch |
| pentest | 🗡️ Agravain | Offensive security, nmap, recon |
| wellness | 🌿 Gareth | Baby/family wellness, health |
| coding | ⚙️ coder-1/coder-2 | General-purpose coding |

## Knight Directory — Round Table Dev Team (`rt-dev`)

| Domain | Knight | Specialty |
|--------|--------|-----------|
| lead | 🏰 rt-lead | Architecture, planning, cross-repo coordination |
| operator | ⚙️ rt-operator | roundtable repo (Go operator, CRDs) |
| runtime | 🔧 rt-runtime | pi-knight repo (TS runtime SDK) |
| skills | 📜 rt-arsenal | roundtable-arsenal repo (skill authoring) |
| frontend | 🖥️ rt-ui | roundtable-ui repo (React dashboard) |

## Constraints

- **Max depth: 1** — You can ask another knight, but they should NOT chain further requests. Include "Do not delegate to other knights" in your sub-task.
- **Stay in your table** — Only request knights that share your NATS prefix.
- **Timeout** — Default 10 minutes. Most tasks complete in 1-5 minutes.
- **Cost awareness** — Each cross-knight request costs tokens. Only ask when the expertise genuinely helps your task.
- **Be specific** — Give the other knight a clear, focused question. Don't dump your entire task on them.
