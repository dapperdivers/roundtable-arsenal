# Career Context Aggregator

**Knight:** Lancelot (Career Coach)

A skill that scans the vault for career-related context and produces a consolidated JSON summary. Designed to give Lancelot a single, up-to-date view of the user's career landscape.

## Scripts

### `aggregate-context.sh`
Scans vault directories for career data and outputs a consolidated JSON file:
- Active opportunities (company, role, status, next steps)
- Skills inventory
- Interview prep material paths
- Career goals and strategy notes

**Output:** `/data/career-context.json`

### `delta-briefing.sh`
Compares the current context snapshot with the previous one and outputs only what changed:
- New items added
- Items removed
- Status changes on existing items

**Output:** JSON delta to stdout

## Vault Directories Scanned
- `/vault/Roundtable/Career-Strategy/`
- `/vault/Work/`
- `/vault/Personal/`

## Usage
```bash
# Generate fresh context snapshot
./aggregate-context.sh

# See what changed since last run
./delta-briefing.sh
```
