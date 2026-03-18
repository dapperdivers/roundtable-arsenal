---
name: web-browser
description: Control a headless Chrome browser for web automation via agent-browser CLI. Use when curl is insufficient — JS-rendered pages, SPAs, form interaction, screenshots, or complex web scraping requiring a real browser engine.
allowed-tools: Bash(agent-browser:*)
metadata:
  author: roundtable
  version: "1.0"
  tier: shared
  compatibility: Requires browser capability enabled on knight (spec.capabilities.browser=true). Chrome sidecar must be running.
---

# Web Browser Automation

Control a headless Chrome browser using the `agent-browser` CLI. The browser runs as a sidecar container alongside your knight, connected via Chrome DevTools Protocol (CDP).

## When to Use Browser vs curl

| Use Browser | Use curl |
|-------------|----------|
| JS-rendered content (SPAs, React/Vue apps) | Static HTML pages |
| Form interaction (login, multi-step flows) | Simple GET/POST requests |
| Screenshots / visual evidence | JSON API responses |
| Dynamic content that loads after page render | RSS/XML feeds |
| Pages behind JavaScript-based auth | Token-based API auth |
| Web scraping with pagination | Direct data endpoints |

## Core Workflow

The fundamental pattern is: **Navigate → Snapshot → Interact → Extract**

```bash
# 1. Navigate to target
agent-browser open "https://example.com"

# 2. Get accessibility tree (see what's on the page)
agent-browser snapshot
# Returns refs like @e1, @e2, @e3...

# 3. Interact using refs
agent-browser click @e5          # Click a button
agent-browser fill @e3 "search"  # Fill an input
agent-browser press Enter        # Press a key

# 4. Extract data
agent-browser get text @e10      # Get text content
agent-browser screenshot         # Visual capture
agent-browser eval "document.title"  # Run JS
```

## Reading Snapshots

`agent-browser snapshot` returns an accessibility tree with refs:

```
@e1 heading "Dashboard"
@e2 navigation
  @e3 link "Home"
  @e4 link "Settings"
@e5 main
  @e6 heading "Welcome back"
  @e7 textbox "Search..."
  @e8 button "Search"
  @e9 list
    @e10 listitem "Item 1"
    @e11 listitem "Item 2"
```

- **Use refs** (`@e7`, `@e8`) for all interactions — they're stable within a page state
- **After navigation or clicks**, take a new snapshot — refs will change
- Refs are based on the accessibility tree, so they work even for complex UIs

## Common Patterns

### Pattern 1: Login Flow
```bash
agent-browser open "https://app.example.com/login"
agent-browser snapshot  # Find username/password fields
agent-browser fill @e3 "username"
agent-browser fill @e4 "password"
agent-browser click @e5  # Login button
agent-browser snapshot   # Verify logged in
```

### Pattern 2: Data Extraction
```bash
agent-browser open "https://example.com/data"
# Wait for JS to render
agent-browser snapshot
# Extract specific data
agent-browser get text @e10
# Or use JS for bulk extraction
agent-browser eval "JSON.stringify([...document.querySelectorAll('.item')].map(e => e.textContent))"
```

### Pattern 3: Form Submission
```bash
agent-browser open "https://example.com/form"
agent-browser snapshot
agent-browser fill @e3 "John Doe"
agent-browser select @e4 "Option 2"
agent-browser check @e5
agent-browser click @e6  # Submit
agent-browser snapshot   # Check result
```

### Pattern 4: Multi-Page Scraping
```bash
agent-browser open "https://example.com/page/1"
agent-browser snapshot
# Extract data...
agent-browser click @e20  # "Next" button
agent-browser snapshot
# Extract more...
```

### Pattern 5: Screenshot Evidence
```bash
agent-browser open "https://target.com"
agent-browser screenshot /tmp/evidence-homepage.png
agent-browser screenshot --full /tmp/evidence-full.png  # Full page
agent-browser screenshot --annotate /tmp/evidence-annotated.png  # With labels
```

## Commands Reference

See [references/COMMANDS.md](references/COMMANDS.md) for the complete CLI reference.

### Quick Reference

| Command | Description |
|---------|-------------|
| `open <url>` | Navigate to URL |
| `snapshot` | Get accessibility tree with refs |
| `click <ref>` | Click element |
| `fill <ref> <text>` | Clear and fill input |
| `type <ref> <text>` | Type into element (appends) |
| `press <key>` | Press key (Enter, Tab, Escape) |
| `hover <ref>` | Hover over element |
| `select <ref> <value>` | Select dropdown option |
| `check <ref>` | Check checkbox |
| `scroll down [px]` | Scroll down |
| `get text <ref>` | Get text content |
| `get html <ref>` | Get innerHTML |
| `get url` | Get current URL |
| `get title` | Get page title |
| `screenshot [path]` | Take screenshot |
| `eval <js>` | Run JavaScript |
| `close` | Close browser |

## Error Handling

- **Connection refused**: Chrome sidecar may not be ready. Wait a few seconds and retry.
- **Timeout**: Page load can be slow. The default timeout is 30s.
- **Element not found**: Take a fresh snapshot — refs change after navigation.
- **Chrome crash**: The sidecar auto-restarts via Kubernetes. Wait for readiness probe.

## Performance Tips

- Take snapshots sparingly — they're the most expensive operation
- Use `eval` for bulk data extraction instead of multiple `get text` calls
- Close the browser when done to free memory
- The Chrome sidecar has 512Mi memory limit — avoid opening many tabs

## Prerequisites

Your Knight CR must have browser capability enabled:

```yaml
spec:
  capabilities:
    browser: true
```

This injects the Chrome sidecar and sets `BROWSER_ENABLED=true`.
