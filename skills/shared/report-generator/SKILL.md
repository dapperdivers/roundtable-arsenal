---
name: report-generator
description: Generate formatted markdown reports from templates and structured data. Use when producing standardized output documents.
---

# Report Generator

Renders Handlebars-style markdown templates with structured data to produce formatted reports.

## Scripts

### `render-template.py`

```bash
python3 scripts/render-template.py --template templates/security/daily-briefing.md --data data.json
python3 scripts/render-template.py --template templates/security/daily-briefing.md --data-stdin < data.json
```

**Arguments:**
| Flag | Required | Description |
|------|----------|-------------|
| `--template` | Yes | Path to the Handlebars-style markdown template |
| `--data` | No | Path to JSON data file |
| `--data-stdin` | No | Read JSON data from stdin |
| `--output` | No | Output file path (default: stdout) |

**Input:** JSON object matching the template's expected variables.

**Output:** Rendered markdown to stdout or specified output file.
