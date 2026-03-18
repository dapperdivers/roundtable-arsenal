---
name: threat-briefing
description: Generate daily and weekly security threat intelligence briefings. Combines OpenCTI data, RSS feeds, and CVE analysis into structured reports. Use for scheduled briefing tasks or on-demand threat summaries.
allowed-tools: Bash(curl:*) Read Write
metadata:
  author: roundtable
  version: "2.2-exp2"
  tier: security
  compatibility: Requires opencti-intel skill and OPENCTI_TOKEN
---

# Threat Briefing Generator

Produces structured security intelligence briefings by combining data from OpenCTI, RSS feeds, and CVE databases.

## Workflow

1. **Gather** — Query OpenCTI for recent indicators, vulnerabilities, reports, and malware
2. **Analyze** — Prioritize by severity, relevance to tracked infrastructure, and novelty
3. **Synthesize** — Combine structured data with RSS context into a narrative briefing
4. **Format** — Render using the appropriate template (daily or weekly)
5. **Deliver** — Return via NATS for the orchestrator to distribute

## Templates

### Daily Briefing
Use [assets/daily-briefing.md](assets/daily-briefing.md) — covers last 24 hours, focused on actionable items.

### Weekly Summary
Use [assets/weekly-briefing.md](assets/weekly-briefing.md) — covers 7-day trends, strategic analysis.

### CVE Report
Use [assets/cve-report.md](assets/cve-report.md) — deep dive on specific vulnerabilities.

## Severity Classification

| Level | Criteria |
|-------|----------|
| 🔴 CRITICAL | Active exploitation, CVSS 9.0+, affects tracked stack |
| 🟠 HIGH | CVSS 7.0-8.9, proof-of-concept available, broad impact |
| 🟡 MEDIUM | CVSS 4.0-6.9, theoretical risk, limited exposure |
| 🟢 LOW/INFO | Informational, trend tracking, no immediate action |

## Stack Relevance

Prioritize findings related to:
- Kubernetes, Talos, Cilium, Flux
- Linux kernel, container runtimes
- NATS, RabbitMQ, OpenSearch, MinIO
- Home Assistant, network infrastructure
- Go, Node.js, Python dependencies

## Output Structure

Briefings should include:
1. Executive summary (2-3 sentences)
2. Critical/high findings with **threat intelligence context**
3. Notable CVEs with CVSS and affected products
4. Trending themes and threat actor activity
5. Recommended actions
6. Detection Engineering

## Threat Intelligence Context

For each CRITICAL and HIGH severity threat, provide:

### MITRE ATT&CK Mapping
- **Tactics**: Initial Access, Execution, Persistence, Privilege Escalation, etc.
- **Techniques**: Specific technique IDs (T1XXX) with sub-techniques
- **Procedures**: How this vulnerability fits into attack chains

Example format:
```
**MITRE ATT&CK:**
- Tactic: Privilege Escalation (TA0004)
- Technique: Escape to Host (T1611)
- Sub-technique: Container Escape via Misconfiguration (T1611.001)
```

### Threat Actor Intelligence
When available, include:
- Known threat actors exploiting this vulnerability
- Campaign names and attribution
- Geographic targeting patterns
- Observed exploitation timelines

Example:
```
**Threat Actors:**
- APT28 (Fancy Bear) - observed using this technique in Q4 2025
- Lazarus Group - targeting cloud infrastructure since Jan 2026
```

### Attack Chain / Kill Chain
Map the vulnerability to the cyber kill chain:
1. Reconnaissance → 2. Weaponization → 3. Delivery → 4. Exploitation → 5. Installation → 6. C2 → 7. Actions

Show where this vulnerability typically appears and subsequent attacker actions.

### Observed TTPs
Document specific tactics, techniques, and procedures seen in active exploitation:
- Initial access method
- Persistence mechanisms used post-exploitation
- Lateral movement patterns
- Data exfiltration methods
- Indicators of compromise (IOCs)

## Detection Engineering

For each CRITICAL and HIGH severity threat, provide specific detection methods:

### Required Detection Formats

1. **Sigma Rules** — SIEM detection logic in Sigma YAML format
   - Include rule title, description, logsource, and detection logic
   - Target common log sources (Windows Security, Linux audit, K8s audit)

2. **Kubernetes Audit Policies** — K8s audit rules for threat detection
   - Provide specific audit policy YAML for relevant threats
   - Include level (Metadata/Request/RequestResponse) and verbs

3. **Network Signatures** — Suricata or Zeek detection rules
   - Include rule SID, protocol, and pattern matching
   - Focus on C2 traffic, exploitation attempts, lateral movement

4. **YARA Rules** — File-based detection patterns for malware/tools
   - Include strings, conditions, and metadata
   - Cover both static and behavioral indicators

5. **Falco Rules** — Runtime security rules for container environments
   - Provide specific Falco rule YAML
   - Focus on container escape, privilege escalation, suspicious processes

### Detection Format Example

```yaml
# Sigma Rule
title: Kubernetes ServiceAccount Token Access
description: Detects unauthorized access to Kubernetes service account tokens
logsource:
  product: linux
  service: auditd
detection:
  selection:
    syscall: 'open'
    file: '/var/run/secrets/kubernetes.io/serviceaccount/token'
  condition: selection
fields:
  - user
  - process
  - file
falsepositives:
  - Legitimate pod activity
level: high
```

### Guidelines

- Provide **at least 2 detection methods** per CRITICAL threat
- Include **1-2 detection methods** per HIGH threat
- Use code blocks with syntax highlighting
- Add brief context on deployment and tuning
- Reference specific CVEs or TTPs in detection logic
- Map detection rules to MITRE ATT&CK techniques

## Dependencies

This skill works best when combined with:
- `opencti-intel` — for structured threat data
- `web-search` — for additional context on emerging threats
- `report-generator` — for template rendering
- `nats-comms` — for result delivery
