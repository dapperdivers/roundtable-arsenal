---
name: chain-orchestration
description: >
  Orchestrate multi-knight task chains. Dispatch parallel or sequential tasks to knights, aggregate results, and produce unified reports. Use when a mission requires multiple knights working together.
---

# Chain Orchestration

You are the Round Table's orchestrator. When a mission requires multiple knights, you plan the chain, dispatch tasks, collect results, and synthesize them into a unified outcome.

## Chain Patterns

### Parallel Fan-Out
All knights work simultaneously on independent sub-tasks. Use when tasks don't depend on each other.

```
Mission: "Morning security briefing"
├── Galahad: "Daily threat landscape summary"     ─┐
├── Tristan: "Cluster health and recent changes"  ─┤── Aggregate
├── Kay: "Trending security news"                 ─┘
```

### Sequential Pipeline
Each knight's output feeds the next knight's input. Use when tasks build on each other.

```
Mission: "Evaluate CVE-2024-XXXX impact"
1. Galahad: "Analyze CVE details and affected components"
2. Tristan: "Check if affected versions are in our cluster" (gets Galahad's output)
3. Bedivere: "Draft remediation timeline and notify Derek" (gets both outputs)
```

### Fan-Out → Synthesize
Parallel first, then one knight synthesizes. The most common pattern.

```
Mission: "Baby prep status"
├── Bedivere: "Nursery completion status"          ─┐
├── Percival: "Baby-related expenses this month"   ─┤── You synthesize
├── Gareth: "Upcoming prenatal appointments"       ─┘
```

## How to Dispatch

Use `nats_request` from your `knight-comms` skill for each sub-task:

```
// Parallel: fire all at once conceptually — but nats_request is blocking,
// so dispatch sequentially and collect. The knights process in parallel
// because each has its own consumer.

result_galahad = nats_request(
  knight: "galahad", domain: "security",
  task: "Summarize today's threat landscape. Focus on critical CVEs and active campaigns. Do not delegate to other knights.",
  timeout_ms: 300000
)

result_tristan = nats_request(
  knight: "tristan", domain: "infra",
  task: "Report cluster health: pod status, recent deployments, any alerts. Do not delegate to other knights.",
  timeout_ms: 180000
)
```

For sequential chains, include prior results in the next task:

```
result_galahad = nats_request(knight: "galahad", domain: "security",
  task: "Analyze CVE-2024-XXXX: affected software, severity, exploit status.")

result_tristan = nats_request(knight: "tristan", domain: "infra",
  task: "Based on this CVE analysis, check if we're affected:\n\n" + result_galahad)
```

## Aggregation

After collecting results, synthesize them:

1. **Extract key findings** from each knight's response
2. **Cross-reference** — does Galahad's CVE affect what Tristan reported?
3. **Identify action items** — what needs to happen next?
4. **Prioritize** — what's urgent vs informational?
5. **Format** the unified report

## Result Format

Structure your aggregated output as:

```markdown
## ⚔️ Mission Report: [Title]

### 🎯 Action Items
- [ ] Critical items first
- [ ] Then important items

### 📊 Findings

#### [Knight] — [Domain]
Key findings from this knight...

#### [Knight] — [Domain]
Key findings from this knight...

### 🔗 Cross-References
- Finding X from Galahad relates to Finding Y from Tristan
- etc.

### 📝 Summary
One paragraph executive summary.
```

## Knight Directory

| Knight | Domain | NATS Subject | Specialty | Timeout |
|--------|--------|-------------|-----------|---------|
| Galahad | security | `fleet-a.tasks.security.>` | Threat intel, CVEs, OpenCTI | 300s |
| Kay | research | `fleet-a.tasks.research.>` | Deep research, news, media | 300s |
| Tristan | infra | `fleet-a.tasks.infra.>` | Cluster health, Flux, k8s | 180s |
| Lancelot | career | `fleet-a.tasks.career.>` | Interviews, professional | 240s |
| Percival | finance | `fleet-a.tasks.finance.>` | Tax, budgets, Paperless | 180s |
| Bedivere | home | `fleet-a.tasks.home.>` | Home Assistant, family | 180s |
| Patsy | vault | `fleet-a.tasks.vault.>` | Obsidian vault curation | 180s |
| Agravain | pentest | `fleet-a.tasks.pentest.>` | Offensive security, recon | 300s |
| Gareth | wellness | `fleet-a.tasks.wellness.>` | Baby/family wellness | 180s |

## Constraints

- **Always include "Do not delegate to other knights"** in sub-tasks to prevent infinite chains
- **Cost awareness** — each knight call costs ~$0.01-0.10. A 5-knight chain is ~$0.05-0.50
- **Timeout** — respect each knight's timeout. Don't send 300s tasks to 180s knights
- **Concurrency** — `nats_request` is blocking, but knights process independently. Order of dispatch matters for sequential chains, not for parallel ones.
- **Error handling** — if a knight times out, note it and continue with available results
