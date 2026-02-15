---
title: "The Steward's Ledger — {{date}}"
date: {{timestamp}}
tags: [daily-report, finance, percival]
knight: percival
---

# 📋 The Steward's Ledger
**{{date}}** · Generated {{timestamp}}

---

> *{{summary}}*

---

{{#if sections.immediate_attention}}
## 🚨 Immediate Attention Required

{{#each immediate_attention_items}}
- **{{this.item}}** — {{this.detail}}
{{/each}}

{{#if unpaid_bills_due_soon}}
| Bill | Amount | Due | Status |
|------|-------:|-----|--------|
{{#each unpaid_bills_due_soon}}
| {{this.name}} | ${{this.amount}} | {{this.due_date}} | ⚠️ {{this.status}} |
{{/each}}
{{/if}}

{{#if documents_needing_review}}
📄 **{{documents_needing_review_count}} document(s)** in Paperless awaiting review
{{/if}}

---
{{/if}}

{{#if sections.bills}}
## 📅 Bills & Obligations (Next 7 Days)

| Payee | Amount | Due Date | Auto-Pay | Notes |
|-------|-------:|----------|:--------:|-------|
{{#each upcoming_bills}}
| {{this.name}} | ${{this.amount}} | {{this.due_date}} | {{#if this.auto_pay}}✅{{else}}❌{{/if}} | {{this.notes}} |
{{/each}}

{{#if recently_paid}}
### ✅ Recently Paid (24h)
{{#each recently_paid}}
- {{this.name}} — ${{this.amount}} on {{this.paid_date}}
{{/each}}
{{/if}}

{{#if anomalies}}
### ⚠️ Anomalies Detected
{{#each anomalies}}
- **{{this.name}}:** ${{this.current}} vs avg ${{this.average}} ({{this.percent_change}})
{{/each}}
{{/if}}

---
{{/if}}

{{#if sections.budget}}
## 💰 Budget Pulse — {{month_name}}

**Month Progress:** {{days_elapsed}}/{{days_in_month}} days ({{month_percent}}%)

| Category | Budget | Spent | Remaining | Pace |
|----------|-------:|------:|----------:|------|
{{#each budget_categories}}
| {{this.name}} | ${{this.budget}} | ${{this.spent}} | ${{this.remaining}} | {{this.pace_indicator}} |
{{/each}}

**Cash Flow:** ${{income}} in · ${{expenses}} out · **Net: ${{net}}**

{{#if unusual_transactions}}
### 🔍 Unusual Transactions
{{#each unusual_transactions}}
- {{this.date}} — **${{this.amount}}** at {{this.merchant}} ({{this.category}})
{{/each}}
{{/if}}

---
{{/if}}

{{#if sections.tax}}
## 📋 Tax & Compliance{{#if tax_deadline_days}} — ⏰ {{tax_deadline_days}} days to filing deadline{{/if}}

{{#if tax_documents}}
| Document | Source | Status |
|----------|--------|--------|
{{#each tax_documents}}
| {{this.type}} | {{this.source}} | {{this.status}} |
{{/each}}
{{/if}}

- **Documents captured:** {{tax_docs_captured}} of {{tax_docs_expected}} expected
- **Deductible items this week:** {{deductible_count}} (${{deductible_total}})

{{#if quarterly_tax_reminder}}
📌 **{{quarterly_tax_reminder}}**
{{/if}}

---
{{/if}}

{{#if sections.documents}}
## 📄 Document Processing

| Metric | Count |
|--------|------:|
| Added (24h) | {{docs_added_24h}} |
| Categorized | {{docs_categorized}} |
| Pending Classification | {{docs_pending}} |
| Needs Attention | {{docs_needs_attention}} |

{{#if docs_attention_list}}
**Requiring attention:**
{{#each docs_attention_list}}
- [{{this.title}}]({{this.url}}) — {{this.issue}}
{{/each}}
{{/if}}

---
{{/if}}

{{#if sections.debt_savings}}
## 📊 Debt & Savings Progress{{#if is_monday}} (Weekly Detail){{/if}}

{{#each debt_items}}
- **{{this.name}}:** ${{this.balance}} ({{this.change_direction}} ${{this.change}} from last week)
{{/each}}

{{#if savings_items}}
{{#each savings_items}}
- **{{this.name}}:** ${{this.balance}}
{{/each}}
{{/if}}

{{#if milestone}}
🎉 **{{milestone}}**
{{/if}}

---
{{/if}}

{{#if sections.strategic}}
## 🎯 Strategic Reminders

{{#each strategic_reminders}}
- {{this.emoji}} **{{this.title}}** — {{this.detail}}
{{/each}}

---
{{/if}}

{{#if sections.stewards_notes}}
## 📝 Steward's Notes

{{stewards_notes}}

---
{{/if}}

## Highlights

{{#each highlights}}
- {{this}}
{{/each}}

{{#if follow_up_needed}}
## ❓ Follow-Up Questions

{{#each follow_up_questions}}
- {{this}}
{{/each}}
{{/if}}

---
*The Steward's Ledger · Percival · "A well-managed household is built on clarity, not surprises."*
