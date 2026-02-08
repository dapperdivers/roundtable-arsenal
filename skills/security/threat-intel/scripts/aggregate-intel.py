#!/usr/bin/env python3
"""aggregate-intel.py — Aggregate threat intelligence from multiple sources."""

import argparse
import json
import sys
from collections import Counter
from datetime import datetime, timezone


def aggregate(feeds: list, cves: list, days: int = 1) -> dict:
    """Combine feeds and CVEs into a unified report."""
    now = datetime.now(timezone.utc).isoformat()

    # Count severities from feeds
    feed_severity = Counter(e.get("severity", "unknown") for e in feeds)

    # Count severities from CVEs
    cve_severity = Counter(e.get("severity", "UNKNOWN").lower() for e in cves)

    # Top threats: critical and high from both sources
    top_threats = []
    for entry in feeds:
        if entry.get("severity_score", 0) >= 3:
            top_threats.append({
                "source": "feed",
                "title": entry.get("title", ""),
                "severity": entry.get("severity", ""),
                "link": entry.get("link", ""),
                "categories": entry.get("categories", []),
            })
    for cve in cves:
        score = cve.get("cvssScore") or 0
        if score >= 7.0:
            top_threats.append({
                "source": "nvd",
                "title": cve.get("id", ""),
                "severity": cve.get("severity", ""),
                "cvssScore": score,
                "description": cve.get("description", "")[:200],
            })

    top_threats.sort(
        key=lambda x: x.get("cvssScore", 0) or (4 if x.get("severity") == "critical" else 3),
        reverse=True,
    )

    return {
        "generated": now,
        "period_days": days,
        "summary": {
            "total_feed_entries": len(feeds),
            "total_cves": len(cves),
            "feed_severity": dict(feed_severity),
            "cve_severity": dict(cve_severity),
        },
        "top_threats": top_threats[:20],
        "all_feeds": feeds,
        "all_cves": cves,
    }


def to_markdown(report: dict) -> str:
    """Render report as markdown."""
    lines = [
        f"# Threat Intelligence Report — {report['generated'][:10]}",
        f"\nReporting period: {report['period_days']} day(s)\n",
        "## Summary",
        f"- **Feed entries analyzed:** {report['summary']['total_feed_entries']}",
        f"- **CVEs reviewed:** {report['summary']['total_cves']}",
        f"- **Feed severity breakdown:** {report['summary']['feed_severity']}",
        f"- **CVE severity breakdown:** {report['summary']['cve_severity']}",
        "\n## Top Threats\n",
    ]
    for t in report["top_threats"]:
        if t["source"] == "nvd":
            lines.append(f"- **{t['title']}** ({t['severity']}, CVSS {t.get('cvssScore', '?')}): {t.get('description', '')}")
        else:
            lines.append(f"- **{t['title']}** [{t['severity']}] — {t.get('link', '')}")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Aggregate threat intelligence.")
    parser.add_argument("--feeds", help="JSON file from rss-analyzer")
    parser.add_argument("--cves", help="JSON file from cve-lookup")
    parser.add_argument("--feeds-stdin", action="store_true", help="Read feeds from stdin")
    parser.add_argument("--days", type=int, default=1, help="Reporting period")
    parser.add_argument("--format", choices=["json", "markdown", "brief"], default="json")
    args = parser.parse_args()

    feeds = []
    cves = []

    if args.feeds_stdin:
        feeds = json.load(sys.stdin)
    elif args.feeds:
        feeds = json.loads(open(args.feeds).read())

    if args.cves:
        cves = json.loads(open(args.cves).read())

    report = aggregate(feeds, cves, args.days)

    if args.format == "markdown":
        print(to_markdown(report))
    elif args.format == "brief":
        s = report["summary"]
        print(f"Feeds: {s['total_feed_entries']} | CVEs: {s['total_cves']} | Top threats: {len(report['top_threats'])}")
    else:
        json.dump(report, sys.stdout, indent=2)


if __name__ == "__main__":
    main()
