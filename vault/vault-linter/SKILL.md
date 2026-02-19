---
name: vault-linter
description: Scan the Obsidian vault for structural issues — missing frontmatter, broken tags, orphan notes, stale content, duplicates. Produces actionable health reports.
allowed-tools: Bash Read Glob Grep
metadata:
  author: roundtable
  version: "1.0"
  tier: vault
---

# Vault Linter

Scanning tools for vault health. Use these scripts to identify issues, then use the `vault-curator` skill to fix them.

## Scripts

### vault-health.sh — Full vault health scan

Scans the entire vault and produces a structured report.

```bash
bash /workspace/skills/vault/vault-linter/scripts/vault-health.sh /vault
```

### frontmatter-check.sh — Check frontmatter on specific files or folders

```bash
bash /workspace/skills/vault/vault-linter/scripts/frontmatter-check.sh /vault/Projects
```

### find-orphans.sh — Find notes with no incoming or outgoing links

```bash
bash /workspace/skills/vault/vault-linter/scripts/find-orphans.sh /vault
```

### find-duplicates.sh — Find notes with similar titles or content

```bash
bash /workspace/skills/vault/vault-linter/scripts/find-duplicates.sh /vault
```
