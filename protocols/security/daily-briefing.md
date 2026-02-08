# Protocol: Daily Security Briefing

## When to Use
Execute every morning (recommended: 06:00–08:00 local time), or on demand when a comprehensive security overview is needed.

## Prerequisites
- Skills: `rss-analyzer`, `cve-lookup`, `threat-intel`, `report-generator`, `vault-writer`
- Templates: `templates/security/daily-briefing.md`
- Network access to RSS feeds and NVD API

## Steps

### 1. Fetch Security Feeds
Run the RSS feed fetcher for the last 24 hours:
```bash
python3 skills/security/rss-analyzer/scripts/fetch-feeds.py --since 24h --format json > /tmp/feeds.json
```
If any feed fails, note it but continue with available data.

### 2. Check Recent CVEs
Query NVD for high and critical CVEs from the past 24 hours:
```bash
python3 skills/security/cve-lookup/scripts/query-nvd.py --days 1 --severity high,critical --format json > /tmp/cves.json
```
If the NVD API is unavailable, note this and proceed with feed data only.

### 3. Analyze Feed Entries
Run the feed analyzer to score and categorize entries:
```bash
cat /tmp/feeds.json | python3 skills/security/rss-analyzer/scripts/analyze-feed.py --min-severity medium > /tmp/analyzed.json
```

### 4. Aggregate Intelligence
Combine all sources into a unified report:
```bash
python3 skills/security/threat-intel/scripts/aggregate-intel.py --feeds /tmp/analyzed.json --cves /tmp/cves.json --format json > /tmp/intel.json
```

### 5. Generate Report
Use the daily briefing template to produce the final report:
```bash
python3 skills/shared/report-generator/scripts/render-template.py --template templates/security/daily-briefing.md --data /tmp/intel.json
```

### 6. Review and Enrich
Before delivering, review the generated report:
- Are there any critical items that need immediate attention? Flag them prominently.
- Do any CVEs affect systems we're known to use? Call these out specifically.
- Are there trending threats across multiple sources? Highlight the pattern.
- Add your own executive summary based on the data.

### 7. Save to Vault
Save the final report:
```bash
./skills/shared/vault-writer/scripts/save-note.sh --path "Security/Daily/$(date +%Y-%m-%d).md" --stdin < report.md
```

### 8. Deliver
Post the briefing to the designated channel. For critical items (severity: critical with active exploitation), also send an immediate alert.

## Expected Output
A formatted daily security briefing saved to the vault and delivered to the team, containing:
- Executive summary
- Critical findings with severity ratings
- New CVEs of note
- Trending threats
- Recommended actions

## Error Handling
- **Feed fetch failures:** Continue with available feeds, note gaps in the report
- **NVD API down:** Skip CVE section, note unavailability
- **Template render failure:** Fall back to plain-text summary of key findings
- **Vault write failure:** Deliver report to channel anyway, retry vault write later
