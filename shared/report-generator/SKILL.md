---
name: report-generator
description: Generate formatted markdown reports from templates and structured data. Use when producing standardized output documents like briefings, assessments, or digests.
allowed-tools: Bash Read Write
metadata:
  author: roundtable
  version: "2.0"
  tier: shared
---

# Report Generator

Renders markdown reports using templates with variable substitution. Templates use `{{variable}}` placeholders and `{{#each list}}...{{/each}}` for iteration.

## When to Use

- Producing standardized briefings or assessments
- Any output that should follow a consistent format
- When a template exists in a skill's `assets/` directory

## How It Works

1. Load a template from the requesting skill's `assets/` directory
2. Substitute variables from your structured data
3. Output the rendered markdown

## Template Syntax

```markdown
# Report — {{title}}

## Summary
{{summary}}

## Items
{{#each items}}
### {{this.name}}
- Severity: {{this.severity}}
- Details: {{this.details}}
{{/each}}

---
*Generated {{generated_at}}*
```

## Usage

Templates are co-located with the skill that uses them under `assets/`. To render:

1. Read the template file
2. Replace `{{variable}}` with your data
3. Expand `{{#each}}` blocks for arrays
4. Write the result to the output location

## Scripts

See [scripts/render-template.py](scripts/render-template.py) for a Python renderer.
