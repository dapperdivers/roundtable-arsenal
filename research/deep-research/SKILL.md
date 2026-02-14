---
name: deep-research
description: Structured deep research methodology — systematic investigation with source evaluation and confidence levels
---

# Deep Research

A systematic approach to investigating complex questions with rigor and transparency.

## Research Workflow

### 1. Define the Question
- State the core question clearly and specifically
- Identify sub-questions that must be answered
- Define scope boundaries (time period, geography, domain)
- Set expected output format and depth

### 2. Initial Search (Breadth)
- Cast a wide net with 3-5 varied search queries
- Use SearXNG for aggregated results:
  ```bash
  curl -s "http://searxng.selfhosted.svc.cluster.local:8080/search?q=QUERY&format=json" | jq '.results[:10] | .[] | {title, url, content}'
  ```
- Scan titles and snippets — identify promising sources
- Note recurring themes, key authors, and organizations
- Flag contradictions early

### 3. Source Identification & Evaluation
- Collect 10-20 candidate sources
- Evaluate each against the source quality tiers (below)
- Prioritize primary sources over secondary
- Check publication dates — freshness matters for evolving topics

### 4. Deep Dive (Depth)
- Read primary sources thoroughly
- Extract key claims with supporting evidence
- Note methodology for any studies cited
- Cross-reference claims across multiple sources
- Document disagreements between sources

### 5. Synthesize
- Organize findings by sub-question
- Identify consensus vs. contested points
- Assess overall confidence level
- Note gaps — what couldn't be answered?

### 6. Cite & Deliver
- Use the output template (below)
- Include inline citations `[1]` with full references
- State confidence levels explicitly
- Separate facts from analysis/opinion

## Source Quality Tiers

### Tier 1 — Primary Sources (Highest trust)
- Original research papers (peer-reviewed)
- Official government data and reports
- Court documents and legal filings
- First-party documentation (official docs, RFCs, specs)
- Direct interviews or statements from involved parties
- Raw datasets from authoritative sources

### Tier 2 — Strong Secondary Sources
- Major news outlets with editorial oversight (Reuters, AP, NYT, WSJ)
- Industry analyst reports (Gartner, Forrester — note potential bias)
- Technical publications (ACM, IEEE, USENIX)
- Established trade publications (Ars Technica, The Register)
- Books by recognized domain experts
- Reputable think tank publications

### Tier 3 — Supporting Sources (Use with caution)
- Blog posts from domain experts (verify credentials)
- Conference talks and presentations
- Wikipedia (use for orientation, then follow citations)
- Community forums (Stack Overflow, Reddit — check vote counts)
- Social media posts from verified experts
- Podcasts and interviews

### Do Not Cite
- Anonymous blog posts without verifiable claims
- Content farms and SEO-optimized listicles
- Social media rumors without primary source backup
- Outdated information (>2 years for fast-moving fields)
- Sources with clear undisclosed conflicts of interest

## Confidence Levels

Rate each finding:

| Level | Label | Meaning |
|-------|-------|---------|
| ★★★★★ | **Confirmed** | Multiple Tier 1 sources agree; no credible dissent |
| ★★★★☆ | **High confidence** | Strong evidence from reliable sources; minor gaps |
| ★★★☆☆ | **Moderate** | Credible sources support it, but some uncertainty or conflicting info |
| ★★☆☆☆ | **Low confidence** | Limited evidence; based on Tier 2-3 sources or extrapolation |
| ★☆☆☆☆ | **Speculative** | Educated guess; insufficient evidence to confirm |

## Output Template

```markdown
# Research: [Question]

**Date:** YYYY-MM-DD
**Researcher:** [Agent name]
**Confidence:** [Overall level]
**Scope:** [What's included/excluded]

## Executive Summary
[3-5 sentence overview of key findings]

## Key Findings

### Finding 1: [Title]
**Confidence:** ★★★★☆
[Detailed explanation with inline citations [1][2]]

### Finding 2: [Title]
**Confidence:** ★★★☆☆
[Detailed explanation]

## Analysis
[Your synthesis — what do the findings mean together?]

## Gaps & Limitations
- [What couldn't be determined]
- [Sources that were unavailable]
- [Areas needing further investigation]

## Recommendations
1. [Next steps or actions based on findings]

## References
1. [Author, "Title," Source, Date. URL]
2. [Author, "Title," Source, Date. URL]
```

## Research Anti-Patterns
- **Confirmation bias** — Don't just search for evidence supporting your hypothesis
- **Source laundering** — Multiple outlets citing the same original source ≠ multiple sources
- **Recency bias** — Newer isn't always better; foundational works matter
- **Authority bias** — Experts can be wrong; check their evidence, not just credentials
- **Scope creep** — Stay focused on the original question; note tangents for future research

## Usage

```bash
# Create a structured research output file
bash scripts/research-template.sh "What is the impact of AI on cybersecurity hiring?" "security, AI, careers"
```

## Notes
- Time-box research: 80% of value comes from 20% of the effort
- Always state what you DON'T know — uncertainty is information
- Save raw search results and source material for reproducibility
- Update research documents when new information emerges
