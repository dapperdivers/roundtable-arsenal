# Protocol: Weekly Security Briefing

## When to Use
Execute every Monday morning, or on demand for weekly trend analysis. Covers the previous 7 days.

## Prerequisites
- Skills: `rss-analyzer`, `cve-lookup`, `threat-intel`, `report-generator`, `vault-writer`
- Templates: `templates/security/weekly-briefing.md`
- Access to previous daily briefings in the vault

## Steps

### 1. Gather Week's Data
Fetch feeds and CVEs for the past 7 days:
```bash
python3 skills/security/rss-analyzer/scripts/fetch-feeds.py --since 7d > /tmp/weekly-feeds.json
python3 skills/security/cve-lookup/scripts/query-nvd.py --days 7 --severity medium,high,critical > /tmp/weekly-cves.json
```

### 2. Analyze and Aggregate
```bash
cat /tmp/weekly-feeds.json | python3 skills/security/rss-analyzer/scripts/analyze-feed.py --min-severity low > /tmp/weekly-analyzed.json
python3 skills/security/threat-intel/scripts/aggregate-intel.py --feeds /tmp/weekly-analyzed.json --cves /tmp/weekly-cves.json --days 7 > /tmp/weekly-intel.json
```

### 3. Review Daily Briefings
Read the past 7 daily briefings from `Security/Daily/` in the vault. Extract:
- Recurring themes
- Escalating threats
- Resolved items

### 4. Trend Analysis
Compare this week to previous weeks:
- Are certain threat categories increasing?
- Any new threat actors or campaigns?
- Patch compliance — were recommended patches applied?

### 5. Generate Report
```bash
python3 skills/shared/report-generator/scripts/render-template.py --template templates/security/weekly-briefing.md --data /tmp/weekly-intel.json
```

### 6. Enrich with Analysis
Add sections for:
- Week-over-week trend comparison
- Top 5 threats of the week
- Recommendations for the coming week
- Action items from previous week — status update

### 7. Save and Deliver
Save to vault at `Security/Weekly/YYYY-WNN.md` and deliver to the team channel.

## Expected Output
Comprehensive weekly security summary with trend analysis, top threats, and forward-looking recommendations.

## Error Handling
- **Missing daily briefings:** Generate from raw data instead of referencing dailies
- **Incomplete data:** Note coverage gaps, provide best-effort analysis
