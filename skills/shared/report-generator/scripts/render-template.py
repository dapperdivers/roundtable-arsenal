#!/usr/bin/env python3
"""render-template.py — Render a Handlebars-style markdown template with JSON data.

Usage:
    python3 render-template.py --template <path> --data <json-file>
    python3 render-template.py --template <path> --data-stdin < data.json
"""

import argparse
import json
import re
import sys
from pathlib import Path


def render_simple(template: str, data: dict) -> str:
    """Simple Handlebars-like renderer supporting {{var}} and {{#each list}}...{{/each}}."""
    # Handle {{#each key}}...{{/each}} blocks
    each_pattern = re.compile(
        r"\{\{#each\s+(\w+)\}\}(.*?)\{\{/each\}\}", re.DOTALL
    )

    def replace_each(match):
        key = match.group(1)
        block = match.group(2)
        items = data.get(key, [])
        rendered = []
        for item in items:
            rendered_block = block
            if isinstance(item, dict):
                for k, v in item.items():
                    rendered_block = rendered_block.replace(f"{{{{this.{k}}}}}", str(v))
            else:
                rendered_block = rendered_block.replace("{{this}}", str(item))
            rendered.append(rendered_block)
        return "".join(rendered)

    result = each_pattern.sub(replace_each, template)

    # Handle simple {{variable}} substitution
    for key, value in data.items():
        if isinstance(value, str):
            result = result.replace(f"{{{{{key}}}}}", value)

    return result


def main():
    parser = argparse.ArgumentParser(
        description="Render a Handlebars-style markdown template with JSON data."
    )
    parser.add_argument("--template", required=True, help="Path to template file")
    parser.add_argument("--data", help="Path to JSON data file")
    parser.add_argument("--data-stdin", action="store_true", help="Read JSON from stdin")
    parser.add_argument("--output", help="Output file path (default: stdout)")
    args = parser.parse_args()

    template_path = Path(args.template)
    if not template_path.exists():
        print(f"Error: Template not found: {template_path}", file=sys.stderr)
        sys.exit(1)

    template = template_path.read_text()

    if args.data_stdin:
        data = json.load(sys.stdin)
    elif args.data:
        data = json.loads(Path(args.data).read_text())
    else:
        print("Error: --data or --data-stdin required", file=sys.stderr)
        sys.exit(1)

    rendered = render_simple(template, data)

    if args.output:
        Path(args.output).write_text(rendered)
        print(f"Written to {args.output}", file=sys.stderr)
    else:
        print(rendered)


if __name__ == "__main__":
    main()
