#!/usr/bin/env bash
# research-template.sh — Create a structured research output file
# Usage: ./research-template.sh "Research Question" ["tags"]

set -euo pipefail

QUESTION="${1:?Usage: research-template.sh \"Research Question\" [\"tags\"]}"
TAGS="${2:-general}"
DATE=$(date +%Y-%m-%d)
SLUG=$(echo "$QUESTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | head -c 60)
FILENAME="research-${DATE}-${SLUG}.md"

cat > "$FILENAME" << EOF
# Research: ${QUESTION}

**Date:** ${DATE}
**Researcher:** [Agent name]
**Confidence:** [Overall — ★☆☆☆☆ to ★★★★★]
**Scope:** [What's included/excluded]
**Tags:** ${TAGS}

## Executive Summary
[3-5 sentence overview of key findings]

## Sub-Questions
1. [ ] 
2. [ ] 
3. [ ] 

## Key Findings

### Finding 1: [Title]
**Confidence:** ★★★☆☆
[Detailed explanation with inline citations [1][2]]

### Finding 2: [Title]
**Confidence:** ★★★☆☆
[Detailed explanation]

### Finding 3: [Title]
**Confidence:** ★★☆☆☆
[Detailed explanation]

## Analysis
[Synthesis — what do the findings mean together? What patterns emerge?]

## Gaps & Limitations
- [ ] [What couldn't be determined]
- [ ] [Sources that were unavailable]
- [ ] [Areas needing further investigation]

## Recommendations
1. [Next steps or actions based on findings]
2. [Further research needed]

## Source Log
| # | Title | URL | Tier | Notes |
|---|-------|-----|------|-------|
| 1 |       |     |      |       |
| 2 |       |     |      |       |
| 3 |       |     |      |       |

## References
1. [Author, "Title," Source, Date. URL]
2. [Author, "Title," Source, Date. URL]

## Research Log
- ${DATE}: Research initiated — "${QUESTION}"
EOF

echo "Created: $FILENAME"
