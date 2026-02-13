#!/usr/bin/env python3
"""analyze-feed.py — Analyze feed entries for threats and severity scoring."""

import argparse
import json
import re
import sys

SEVERITY_KEYWORDS = {
    "critical": ["critical", "zero-day", "0-day", "rce", "remote code execution", "actively exploited"],
    "high": ["high", "ransomware", "breach", "exploit", "vulnerability", "cve-"],
    "medium": ["medium", "phishing", "malware", "update", "patch"],
    "low": ["low", "advisory", "disclosure", "research"],
}

SEVERITY_ORDER = {"critical": 4, "high": 3, "medium": 2, "low": 1}

CATEGORIES = {
    "vulnerability": ["cve", "vulnerability", "exploit", "zero-day", "0-day", "rce", "buffer overflow"],
    "ransomware": ["ransomware", "ransom", "lockbit", "blackcat", "clop"],
    "breach": ["breach", "leak", "data exposure", "compromised"],
    "malware": ["malware", "trojan", "botnet", "rat", "backdoor"],
    "phishing": ["phishing", "social engineering", "spear-phishing"],
    "patch": ["patch", "update", "fix", "security update"],
    "policy": ["regulation", "compliance", "policy", "gdpr", "nist"],
}


def classify_entry(entry: dict) -> dict:
    """Add severity and category to a feed entry."""
    text = f"{entry.get('title', '')} {entry.get('summary', '')}".lower()

    # Determine severity
    severity = "low"
    for level in ["critical", "high", "medium", "low"]:
        if any(kw in text for kw in SEVERITY_KEYWORDS[level]):
            severity = level
            break

    # Determine categories
    cats = []
    for cat, keywords in CATEGORIES.items():
        if any(kw in text for kw in keywords):
            cats.append(cat)

    entry["severity"] = severity
    entry["severity_score"] = SEVERITY_ORDER[severity]
    entry["categories"] = cats or ["general"]
    return entry


def main():
    parser = argparse.ArgumentParser(description="Analyze feed entries for threats.")
    parser.add_argument("--input", help="JSON file of entries (default: stdin)")
    parser.add_argument("--min-severity", choices=["low", "medium", "high", "critical"], default="low")
    parser.add_argument("--categories", help="Filter by categories (comma-separated)")
    args = parser.parse_args()

    if args.input:
        entries = json.loads(open(args.input).read())
    else:
        entries = json.load(sys.stdin)

    min_score = SEVERITY_ORDER[args.min_severity]
    filter_cats = set(args.categories.split(",")) if args.categories else None

    analyzed = []
    for entry in entries:
        entry = classify_entry(entry)
        if entry["severity_score"] < min_score:
            continue
        if filter_cats and not set(entry["categories"]) & filter_cats:
            continue
        analyzed.append(entry)

    analyzed.sort(key=lambda x: x["severity_score"], reverse=True)
    json.dump(analyzed, sys.stdout, indent=2)


if __name__ == "__main__":
    main()
