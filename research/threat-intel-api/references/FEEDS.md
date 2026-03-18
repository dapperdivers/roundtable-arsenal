# RSS Feed Configuration

This document lists all configured RSS feeds for automated monitoring.

## Feed List

### Vulnerability Intelligence

| Feed Name | URL | Category | Priority | Update Frequency |
|-----------|-----|----------|----------|------------------|
| BleepingComputer | https://www.bleepingcomputer.com/feed/ | vulnerability | high | Hourly |
| The Hacker News | https://feeds.feedburner.com/TheHackersNews | vulnerability | high | Hourly |
| Krebs on Security | https://krebsonsecurity.com/feed/ | vulnerability | high | Daily |
| SecurityWeek Vulnerabilities | https://www.securityweek.com/category/vulnerabilities/feed/ | vulnerability | medium | Daily |
| Tenable Blog | https://www.tenable.com/blog/feed | vulnerability | medium | Daily |

### Malware & Threat Actor Intelligence

| Feed Name | URL | Category | Priority | Update Frequency |
|-----------|-----|----------|----------|------------------|
| Malwarebytes Labs | https://blog.malwarebytes.com/feed/ | malware | high | Daily |
| Unit 42 (Palo Alto) | https://unit42.paloaltonetworks.com/feed/ | threat-actor | high | Weekly |
| Securelist (Kaspersky) | https://securelist.com/feed/ | threat-actor | high | Weekly |
| Talos Intelligence | https://blog.talosintelligence.com/rss/ | threat-actor | high | Daily |
| ESET Research | https://www.welivesecurity.com/feed/ | malware | medium | Daily |

### Security Research & Analysis

| Feed Name | URL | Category | Priority | Update Frequency |
|-----------|-----|----------|----------|------------------|
| The Record | https://therecord.media/feed/ | research | medium | Daily |
| Dark Reading | https://www.darkreading.com/rss_simple.asp | research | medium | Hourly |
| Graham Cluley | https://grahamcluley.com/feed/ | research | low | Daily |
| Schneier on Security | https://www.schneier.com/blog/atom.xml | research | medium | Weekly |

### Cloud & Container Security

| Feed Name | URL | Category | Priority | Update Frequency |
|-----------|-----|----------|----------|------------------|
| Sysdig Blog | https://sysdig.com/blog/feed/ | cloud | medium | Weekly |
| Aqua Security Blog | https://blog.aquasec.com/rss.xml | cloud | medium | Weekly |
| Wiz Blog | https://www.wiz.io/blog/rss.xml | cloud | high | Weekly |

### Incident Response & Forensics

| Feed Name | URL | Category | Priority | Update Frequency |
|-----------|-----|----------|----------|------------------|
| SANS ISC InfoSec | https://isc.sans.edu/rssfeed.xml | incident-response | high | Daily |
| CISA Alerts | https://www.cisa.gov/cybersecurity-advisories/all.xml | incident-response | critical | Real-time |

## Feed Format

Feeds are expected to be in RSS 2.0 or Atom format with the following fields:

### Required Fields
- `<title>` or `<entry><title>` — Article title
- `<link>` or `<entry><link>` — Article URL
- `<pubDate>` or `<entry><published>` — Publication date

### Optional Fields
- `<description>` or `<entry><summary>` — Article summary/excerpt
- `<author>` or `<entry><author>` — Author name
- `<category>` or `<entry><category>` — Article categories/tags

## Priority Levels

| Priority | Description | Polling Frequency | Notification |
|----------|-------------|-------------------|--------------|
| **critical** | Real-time alerts (CISA, vendor advisories) | Every 5 minutes | Always notify |
| **high** | Breaking vulnerabilities, active campaigns | Every 15 minutes | Notify if severity ≥ HIGH |
| **medium** | General security news, research | Every 30 minutes | Notify if severity = CRITICAL |
| **low** | Opinion pieces, educational content | Every 60 minutes | No notifications |

## Severity Scoring Keywords

The monitor uses keyword matching to assign severity scores:

### CRITICAL Keywords
- zero-day, 0day
- actively exploited
- ransomware outbreak
- critical rce (remote code execution)
- supply chain compromise
- nation-state attack

### HIGH Keywords
- remote code execution, rce
- authentication bypass
- privilege escalation
- critical vulnerability
- data breach
- apt (advanced persistent threat)

### MEDIUM Keywords
- vulnerability
- security update
- patch available
- exploit published
- cve-20

### LOW Keywords
- security tip
- best practice
- tutorial
- announcement
- opinion

## Adding New Feeds

To add a new feed:

1. **Validate feed URL** — Ensure it returns valid RSS/Atom XML
   ```bash
   curl -sL "https://example.com/feed.xml" | xmllint --format - | head -50
   ```

2. **Test parsing** — Run the monitor in test mode
   ```bash
   bash scripts/monitor-feeds.sh --once --test-feed "https://example.com/feed.xml"
   ```

3. **Add to this document** — Update the appropriate category table above

4. **Configure priority** — Set polling frequency and notification rules

5. **Monitor reliability** — Track uptime and update frequency over 7 days

## Feed Reliability Metrics

Tracked metrics (updated weekly):

| Feed | Uptime (7d) | Avg Latency | False Positives | Last Update |
|------|-------------|-------------|-----------------|-------------|
| BleepingComputer | 99.8% | 120ms | Low | 2026-03-14 |
| The Hacker News | 99.5% | 250ms | Medium | 2026-03-14 |
| Krebs on Security | 98.2% | 180ms | Low | 2026-03-13 |
| CISA Alerts | 100% | 90ms | None | 2026-03-14 |

### Reliability Thresholds

- **Good**: ≥98% uptime, <500ms latency
- **Fair**: 95-98% uptime, 500-1000ms latency
- **Poor**: <95% uptime, >1000ms latency (consider removing)

## Troubleshooting

### Feed not updating
1. Check if feed URL is still valid (some feeds change URLs)
2. Verify feed is still publishing content (check in browser)
3. Check for rate limiting or IP blocking
4. Review feed's historical reliability

### High false positive rate
1. Adjust keyword filters in `monitor-feeds.sh`
2. Add feed-specific exclusion rules
3. Lower priority of feed
4. Consider removing if quality doesn't improve

### Parsing errors
1. Validate XML structure: `xmllint --noout feed.xml`
2. Check for non-standard date formats
3. Verify character encoding (should be UTF-8)
4. Report issue to feed maintainer if malformed

## Feed Categories

### vulnerability
Feeds focused on CVE disclosures, security advisories, and patch information.

### malware
Feeds covering malware analysis, new malware families, and threat campaigns.

### threat-actor
Feeds tracking APT groups, cyber espionage, and attribution research.

### research
Feeds publishing security research, whitepapers, and technical analysis.

### cloud
Feeds specific to cloud security, containers, Kubernetes, and cloud-native threats.

### incident-response
Feeds covering active incidents, breach notifications, and emergency advisories.

### policy
Feeds about security policy, regulations, compliance, and governance.

## Historical Notes

- **2026-03-01**: Added Wiz Blog for cloud security coverage
- **2026-02-15**: Removed SecurityFocus (site discontinued)
- **2026-02-01**: Increased CISA polling to every 5 minutes
- **2026-01-15**: Initial feed configuration with 18 sources
