# agent-browser CLI Reference

Complete command reference for the agent-browser CLI.

## Navigation

```bash
agent-browser open <url>         # Navigate to URL
agent-browser close              # Close browser
```

## Interaction

```bash
agent-browser click <sel>        # Click element
agent-browser dblclick <sel>     # Double-click
agent-browser fill <sel> <text>  # Clear and fill input
agent-browser type <sel> <text>  # Type into element (appends)
agent-browser press <key>        # Press key (Enter, Tab, Escape, Control+a)
agent-browser hover <sel>        # Hover element
agent-browser select <sel> <val> # Select dropdown option
agent-browser check <sel>        # Check checkbox
agent-browser uncheck <sel>      # Uncheck checkbox
agent-browser scroll <dir> [px]  # Scroll (up/down/left/right)
agent-browser drag <src> <tgt>   # Drag and drop
agent-browser upload <sel> <files>  # Upload files
agent-browser focus <sel>        # Focus element
```

## Data Extraction

```bash
agent-browser snapshot                # Accessibility tree with refs
agent-browser get text <sel>          # Text content
agent-browser get html <sel>          # innerHTML
agent-browser get value <sel>         # Input value
agent-browser get attr <sel> <attr>   # Element attribute
agent-browser get title               # Page title
agent-browser get url                 # Current URL
agent-browser get count <sel>         # Count matching elements
agent-browser get box <sel>           # Bounding box
agent-browser get styles <sel>        # Computed styles
```

## Screenshots & PDF

```bash
agent-browser screenshot [path]       # Screenshot (temp dir if no path)
agent-browser screenshot --full       # Full page screenshot
agent-browser screenshot --annotate   # Annotated with element labels
agent-browser pdf <path>              # Save page as PDF
```

## State Checks

```bash
agent-browser is visible <sel>   # Check visibility
agent-browser is enabled <sel>   # Check if enabled
agent-browser is checked <sel>   # Check if checked
```

## Semantic Locators

```bash
agent-browser find role <role> [value]    # By ARIA role
agent-browser find text <text>            # By text content
agent-browser find label [value]          # By label
agent-browser find placeholder [value]    # By placeholder
agent-browser find testid [value]         # By data-testid
```

## JavaScript

```bash
agent-browser eval <js>           # Evaluate JavaScript
agent-browser eval -b <base64>    # Evaluate base64-encoded JS
```

## Selectors

Selectors can be:
- **Refs**: `@e1`, `@e2` (from snapshot — preferred for AI)
- **CSS**: `#submit`, `.btn-primary`, `input[name="email"]`
- **Text**: `text=Submit`, `text="Click here"`

## Tips

- Always use `snapshot` first to get refs
- Refs change after navigation — re-snapshot
- Use `--new-tab` with `click` to open in new tab
- `keyboard type <text>` types at current focus (no selector needed)
