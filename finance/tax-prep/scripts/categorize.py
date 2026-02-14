#!/usr/bin/env python3
"""Transaction categorizer — reads bank/credit card CSVs and outputs categorized JSON."""

import csv
import json
import sys
import argparse
import re
from datetime import datetime
from pathlib import Path

KEYWORDS = {
    "Housing": ["mortgage", "rent", "hoa", "property tax", "homeowner", "home insurance"],
    "Utilities": ["electric", "power company", "gas company", "water", "internet", "comcast", "att ", "verizon", "tmobile", "t-mobile", "spectrum"],
    "Transportation": ["shell", "exxon", "chevron", "bp ", "uber", "lyft", "parking", "toll", "car wash"],
    "Food": ["grocery", "kroger", "heb ", "h-e-b", "walmart", "whole foods", "restaurant", "mcdonald", "starbucks", "doordash", "grubhub", "uber eats", "chipotle", "chick-fil"],
    "Medical": ["pharmacy", "cvs", "walgreens", "doctor", "hospital", "dental", "optom", "therapy", "labcorp", "quest diag"],
    "Insurance": ["insurance", "geico", "state farm", "allstate", "progressive"],
    "Entertainment": ["netflix", "spotify", "hulu", "disney+", "steam", "playstation", "xbox", "amc", "cinema"],
    "Shopping": ["amazon", "target", "best buy", "costco", "clothing", "nike", "home depot", "lowes"],
    "Education": ["tuition", "university", "udemy", "coursera", "books"],
    "Subscriptions": ["subscription", "monthly", "annual renewal"],
    "Business:Software": ["aws", "azure", "google cloud", "digitalocean", "github", "cloudflare", "namecheap", "vercel", "heroku", "openai"],
    "Business:Hardware": ["newegg computer", "dell tech", "apple store"],
    "Business:Services": ["contractor", "consultant", "legal", "accounting", "fiverr", "upwork"],
    "Business:Travel": ["airline", "delta air", "united air", "southwest", "marriott", "hilton", "airbnb"],
    "Business:Office": ["office depot", "staples", "co-working", "wework"],
    "Business:Education": ["conference", "training", "certification"],
    "Charitable": ["donation", "charity", "united way", "red cross", "church", "tithe", "nonprofit"],
    "Transfer": ["transfer", "venmo", "zelle", "paypal transfer", "ach transfer"],
}

TAX_FLAGS_RULES = {
    "deductible": ["Charitable"],
    "business_expense": ["Business:Software", "Business:Hardware", "Business:Services", "Business:Travel", "Business:Office", "Business:Education"],
    "hsa": ["Medical"],
    "education": ["Education"],
}


def detect_columns(headers):
    """Heuristically detect date, description, and amount columns."""
    date_col = desc_col = amount_col = None
    headers_lower = [h.lower().strip() for h in headers]

    for i, h in enumerate(headers_lower):
        if not date_col and any(k in h for k in ["date", "posted", "transaction date"]):
            date_col = i
        elif not desc_col and any(k in h for k in ["description", "memo", "merchant", "name", "payee"]):
            desc_col = i
        elif not amount_col and any(k in h for k in ["amount", "debit", "charge"]):
            amount_col = i

    return date_col, desc_col, amount_col


def parse_date(date_str):
    """Try common date formats."""
    for fmt in ("%m/%d/%Y", "%Y-%m-%d", "%m/%d/%y", "%m-%d-%Y", "%d/%m/%Y"):
        try:
            return datetime.strptime(date_str.strip(), fmt).strftime("%Y-%m-%d")
        except ValueError:
            continue
    return date_str.strip()


def categorize(description):
    """Match description against keyword rules."""
    desc_lower = description.lower()
    for category, keywords in KEYWORDS.items():
        for kw in keywords:
            if kw in desc_lower:
                return category, "high"
    return "Uncategorized", "low"


def get_tax_flags(category):
    """Determine tax flags from category."""
    flags = []
    for flag, categories in TAX_FLAGS_RULES.items():
        if category in categories:
            flags.append(flag)
    return flags


def process_csv(filepath, year=None):
    """Process a CSV file and return categorized transactions."""
    transactions = []
    uncategorized = []

    with open(filepath, "r", encoding="utf-8-sig") as f:
        # Detect delimiter
        sample = f.read(2048)
        f.seek(0)
        dialect = csv.Sniffer().sniff(sample, delimiters=",\t;|")
        reader = csv.reader(f, dialect)

        headers = next(reader)
        date_col, desc_col, amount_col = detect_columns(headers)

        if None in (date_col, desc_col, amount_col):
            print(f"Warning: Could not auto-detect all columns from headers: {headers}", file=sys.stderr)
            print(f"  Detected: date={date_col}, desc={desc_col}, amount={amount_col}", file=sys.stderr)
            # Fallback: assume first 3 columns
            date_col = date_col or 0
            desc_col = desc_col or 1
            amount_col = amount_col or 2

        for row in reader:
            if len(row) <= max(date_col, desc_col, amount_col):
                continue

            date = parse_date(row[date_col])
            description = row[desc_col].strip()
            try:
                amount = float(row[amount_col].replace(",", "").replace("$", "").strip())
            except ValueError:
                continue

            if year and not date.startswith(str(year)):
                continue

            category, confidence = categorize(description)
            tax_flags = get_tax_flags(category)

            txn = {
                "date": date,
                "description": description,
                "amount": amount,
                "category": category,
                "tax_flags": tax_flags,
                "confidence": confidence,
            }

            if category == "Uncategorized":
                uncategorized.append(txn)
            transactions.append(txn)

    return transactions, uncategorized


def build_summary(transactions):
    """Build summary statistics."""
    total_income = sum(t["amount"] for t in transactions if t["amount"] > 0 and t["category"] != "Transfer")
    total_expenses = sum(t["amount"] for t in transactions if t["amount"] < 0 and t["category"] != "Transfer")
    by_category = {}
    tax_flags_totals = {}

    for t in transactions:
        if t["category"] == "Transfer":
            continue
        by_category[t["category"]] = by_category.get(t["category"], 0) + t["amount"]
        for flag in t["tax_flags"]:
            tax_flags_totals[flag] = tax_flags_totals.get(flag, 0) + t["amount"]

    return {
        "total_income": round(total_income, 2),
        "total_expenses": round(total_expenses, 2),
        "by_category": {k: round(v, 2) for k, v in sorted(by_category.items())},
        "tax_flags": {k: round(v, 2) for k, v in sorted(tax_flags_totals.items())},
        "transaction_count": len(transactions),
    }


def main():
    parser = argparse.ArgumentParser(description="Categorize bank/credit card transactions from CSV")
    parser.add_argument("csv_file", help="Path to CSV file")
    parser.add_argument("--output", "-o", help="Output JSON file (default: stdout)")
    parser.add_argument("--year", "-y", type=int, help="Filter to specific tax year")
    args = parser.parse_args()

    if not Path(args.csv_file).exists():
        print(f"Error: {args.csv_file} not found", file=sys.stderr)
        sys.exit(1)

    transactions, uncategorized = process_csv(args.csv_file, args.year)
    summary = build_summary(transactions)

    result = {
        "summary": summary,
        "transactions": transactions,
        "uncategorized": uncategorized,
    }

    output = json.dumps(result, indent=2)
    if args.output:
        Path(args.output).write_text(output)
        print(f"Wrote {len(transactions)} transactions to {args.output}")
        if uncategorized:
            print(f"  ⚠ {len(uncategorized)} uncategorized — review needed")
    else:
        print(output)


if __name__ == "__main__":
    main()
