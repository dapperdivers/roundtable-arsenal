---
name: tax-prep
description: CSV transaction parsing, categorization, and tax deduction identification for financial planning
---

# Tax Prep — Transaction Categorization

Parse bank and credit card CSV exports, categorize transactions, and flag tax-relevant items.

## CSV Parsing

Most bank exports follow common formats. Detect columns automatically:

| Bank Style | Date Column | Description | Amount | Notes |
|------------|-------------|-------------|--------|-------|
| Chase | "Transaction Date" | "Description" | "Amount" | Negative = charge |
| Amex | "Date" | "Description" | "Amount" | Positive = charge |
| Generic | First date-like col | Longest string col | Numeric col | Varies |

### Parsing Steps
1. Read CSV, detect delimiter (comma, tab, semicolon)
2. Identify date, description, and amount columns by header names or content heuristics
3. Normalize: date → YYYY-MM-DD, amount → positive=income/negative=expense
4. Strip whitespace, deduplicate by date+amount+description

## Transaction Categories

Assign each transaction to exactly one category:

### Personal
- **Housing** — rent, mortgage, HOA, property tax, home insurance, repairs
- **Utilities** — electric, gas, water, internet, phone, trash
- **Transportation** — gas, car payment, insurance, parking, tolls, rideshare, transit
- **Food** — groceries, restaurants, coffee shops, delivery
- **Medical** — doctor, pharmacy, dental, vision, hospital, therapy
- **Insurance** — health, life, disability (non-employer)
- **Entertainment** — streaming, games, movies, concerts, hobbies
- **Shopping** — clothing, electronics, household goods, Amazon
- **Education** — tuition, books, courses, certifications
- **Personal Care** — gym, haircut, spa
- **Subscriptions** — recurring SaaS, memberships
- **Transfers** — bank transfers, Venmo/Zelle (exclude from totals)

### Business
- **Business:Software** — SaaS tools, hosting, domains
- **Business:Hardware** — computers, peripherals, networking
- **Business:Services** — contractors, consultants, legal, accounting
- **Business:Travel** — flights, hotels, meals while traveling
- **Business:Office** — supplies, furniture, co-working
- **Business:Education** — conferences, training, certs

## Keyword Matching Rules

Use substring matching on description (case-insensitive):

```
# Housing
mortgage, rent, hoa, property tax, homeowner

# Utilities
electric, power, gas company, water, internet, comcast, att, verizon, tmobile

# Transportation
shell, exxon, chevron, bp, uber, lyft, parking, toll

# Food
grocery, kroger, heb, walmart grocer, whole foods, restaurant, mcdonald, starbucks, doordash, grubhub

# Medical
pharmacy, cvs, walgreens, doctor, hospital, dental, optom, therapy, labcorp

# Business:Software
aws, azure, google cloud, digitalocean, github, cloudflare, namecheap

# Charitable
donation, charity, united way, red cross, church, tithe
```

## Tax Flags

Flag transactions with tax relevance:

| Flag | Criteria | Tax Form |
|------|----------|----------|
| `deductible` | Charitable donations, state/local taxes | Schedule A |
| `business_expense` | Any Business:* category | Schedule C |
| `hsa` | HSA contributions or qualified medical | Form 8889 |
| `education` | Tuition, student loan interest | Form 8863/1098-E |
| `home_office` | Internet, utilities (pro-rated if WFH) | Form 8829 |
| `estimated_tax` | IRS/state tax payments | Form 1040-ES |

## Usage

```bash
python3 scripts/categorize.py transactions.csv --output categorized.json
python3 scripts/categorize.py transactions.csv --output categorized.json --year 2025
```

### Output Format
```json
{
  "summary": {
    "total_income": 85000.00,
    "total_expenses": 42000.00,
    "by_category": {"Food": -5200.00, "Housing": -18000.00},
    "tax_flags": {"deductible": -3200.00, "business_expense": -8500.00}
  },
  "transactions": [
    {
      "date": "2025-01-15",
      "description": "STARBUCKS #1234",
      "amount": -5.75,
      "category": "Food",
      "tax_flags": [],
      "confidence": "high"
    }
  ],
  "uncategorized": []
}
```

## Review Workflow

1. Run categorize.py on all CSV exports
2. Review `uncategorized` list — add keywords or manually assign
3. Review `business_expense` flags — ensure legitimacy
4. Cross-reference `deductible` totals with tax software
5. Archive CSVs and JSON output in Paperless (see `finance/paperless-ops`)

## Notes
- Always review automated categorization — this is a starting point, not tax advice
- Keep original CSVs as source of truth
- For joint accounts, add `--split` flag to separate by cardholder if supported
