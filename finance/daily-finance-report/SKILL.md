---
name: daily-finance-report
description: "Generate Percival's daily finance briefing covering urgent bills, 7-day obligation forecasts, budget health, tax readiness, Paperless-ngx document status, debt and savings tracking, and strategic reminders. Use for morning financial briefings, bill anomaly detection, tax compliance tracking, and household budget monitoring."
allowed-tools: Bash(curl:*) Read Write
metadata:
  author: roundtable
  version: "1.0"
  tier: finance
---

# The Steward's Ledger — Daily Finance Report

Percival's daily briefing on household finances, bills, budgets, documents, and fiscal health.

## When to Use

- Morning financial briefing generation
- Bill payment tracking and anomaly detection
- Tax season document completeness checks
- Budget vs actual spending analysis
- Paperless-ngx document processing status

## Output Contract

**All output MUST conform to `shared/daily-reports` JSON contract.**

- `knight`: `"percival"`
- `run_id`: `"daily-YYYY-MM-DD"`
- `report_type`: `"daily-briefing"`
- Omit any section with no data
- 3-5 highlights for morning briefing
- `follow_up_needed`: true if any high-priority section exists

Render markdown using `templates/daily-ledger.md`.

## Workflow

1. Query Paperless-ngx for recent documents, untagged items, tax docs
2. Load bill tracking config (`config/bills.json`)
3. Load latest transaction categorization (from `finance/tax-prep`)
4. Check calendar for deadlines
5. Run anomaly detection on bills (flag >20% deviation from rolling average)
6. Calculate budget vs actual spending
7. Assess tax document completeness
8. Build sections, omit empty ones, generate JSON and markdown

## Report Sections

Generate in order. **Omit any section with no data.**

### I. Immediate Attention Required
**Priority: high**

Items demanding action within 48 hours: bills due within 3 days, financial deadlines (tax filing, enrollment periods), unprocessed Paperless documents tagged `needs-review`, failed auto-payments.

**Data sources:** Paperless-ngx, bill tracking config, calendar

### II. Bills & Obligations
**Priority: medium (high if anomalies detected)**

7-day forward view: all bills grouped by date with payee, amount, due date, auto-pay status. Recently paid (last 24h) — verify auto-pays executed.

**Anomaly detection:** Flag bills deviating >20% from rolling average: `"Electric bill $247 vs avg $156 (+58%)"`

### III. Budget Pulse
**Priority: medium**

Month-to-date spending by category (uses `finance/tax-prep` categories). Compare actual vs budget targets (`config/budget-targets.json`). Percentage of month elapsed vs budget consumed. Flag unusual transactions (>$200 or unfamiliar merchants). Basic cash flow: income vs outflow.

### IV. Tax & Compliance
**Priority: medium (high during Jan-Apr)**

Tax document inventory (W-2s, 1099s, receipts in Paperless). Missing expected documents. Days until tax deadline (prominent Jan 1 - Apr 15). Deductible items captured. Quarterly estimated tax reminders.

**Prominence rule:** Moves to position II during January-April.

### V. Document Processing
**Priority: low (medium if backlog > 10)**

Paperless-ngx health: documents added (24h), categorized vs pending, documents needing attention (missing tags/correspondent/type).

**API calls:**
```bash
# Recent untagged documents
curl -s -H "$AUTH" "$PAPERLESS/documents/?tags__id__isnull=true&ordering=-added&page_size=25"

# Documents needing review
curl -s -H "$AUTH" "$PAPERLESS/documents/?tags__name=needs-review"
```

### VI. Debt & Savings Progress
**Priority: low** — Full detail on Mondays, brief status other days.

Outstanding balances with week-over-week change, savings balances, interest accrued/paid.

### VII. Strategic Reminders
**Priority: low** — Only include when relevant.

Quarterly tasks, annual review dates, optimization opportunities, subscription audit reminders.

### VIII. Steward's Notes
**Priority: low**

Patterns noticed, recommendations, milestone celebrations. Tone: professional, warm, precise — like a trusted family accountant.

## Anomaly Detection

For each recurring bill, maintain a rolling average (last 6 months):
- Current > 120% of average: `Higher than usual`
- Current < 80% of average: `Lower than usual (verify)`
- Bill missing when expected: `Expected bill not received`

## Configuration

See [references/CONFIG_SCHEMAS.md](references/CONFIG_SCHEMAS.md) for `config/bills.json`, `config/budget-targets.json`, and `config/tax-expectations.json` schemas.
