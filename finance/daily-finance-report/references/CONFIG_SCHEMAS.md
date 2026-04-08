# Configuration File Schemas

Store configuration files in the `config/` directory within this skill.

## config/bills.json

```json
{
  "bills": [
    {
      "name": "Electric - TXU",
      "typical_amount": 156.00,
      "due_day": 15,
      "frequency": "monthly",
      "auto_pay": true,
      "category": "Utilities",
      "paperless_correspondent": "TXU Energy"
    }
  ]
}
```

## config/budget-targets.json

```json
{
  "month": "2026-02",
  "targets": {
    "Housing": 1800,
    "Utilities": 400,
    "Food": 800,
    "Transportation": 300,
    "Entertainment": 200,
    "Shopping": 300
  }
}
```

## config/tax-expectations.json

```json
{
  "tax_year": 2025,
  "expected_documents": [
    { "type": "W-2", "source": "Employer Name", "expected_by": "2026-01-31" },
    { "type": "1099-INT", "source": "Bank Name", "expected_by": "2026-01-31" }
  ],
  "filing_deadline": "2026-04-15",
  "quarterly_estimated": ["2026-01-15", "2026-04-15", "2026-06-15", "2026-09-15"]
}
```
