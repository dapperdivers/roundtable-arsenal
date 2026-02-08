# Templates

Output format definitions for reports and digests. Templates use **Handlebars-style** placeholders that get filled by the `report-generator` skill or by the knight agent directly.

## Syntax

- `{{variable}}` — Simple variable substitution
- `{{#each list}}...{{/each}}` — Iterate over arrays
- `{{this.field}}` — Access fields within an iteration

## Usage

```bash
python3 skills/shared/report-generator/scripts/render-template.py \
  --template templates/security/daily-briefing.md \
  --data report-data.json
```

## Organization

```
templates/
├── security/    # Security briefing and CVE report formats
├── comms/       # Email digest and notification formats
└── intel/       # Morning report and intelligence formats
```
