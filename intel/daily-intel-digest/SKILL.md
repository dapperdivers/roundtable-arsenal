---
name: daily-intel-digest
description: Kay's daily intelligence briefing. Synthesizes space weather, tech/security news, research activity, and operational context into an analytical morning digest. Signal over noise.
allowed-tools: Bash(curl:*) Bash(python3:*) Read Write
metadata:
  author: sir-kay
  version: "1.0"
  tier: intel
  knight: sir-kay
  schedule: "0600 CST daily"
---

# Daily Intelligence Digest

**Knight:** Sir Kay 📡 (Research & Intel)
**Output:** JSON per `shared/daily-reports` contract + Markdown via `templates/daily-digest.md`
**Tone:** Analytical, opinionated, signal-over-noise. This is an intelligence briefing, not a news dump.

## Purpose

Produce a daily intelligence product that Tim can scan in 90 seconds and know what actually matters. Synthesize data from multiple domains into coherent analysis with confidence levels and actionable recommendations.

## Sections (Required)

| # | Section | Priority Guidance | Primary Source |
|---|---------|-------------------|----------------|
| 1 | Executive Summary | Always high | Synthesis of all sections |
| 2 | Space Weather | High if Kp≥5 or active alerts; else medium | `intel/solar-weather` |
| 3 | Technology & Security Intel | Varies per story | `intel/news-aggregator` + web search |
| 4 | Nerd News & Culture | Medium | Web search + RSS |
| 5 | Research Completed | Medium | Kay's memory files |
| 6 | Threads Worth Pulling | Medium-high | Pattern recognition across sources |
| 7 | Knight Activity | Low-medium | Inter-knight comms, NATS logs |
| 8 | Local Weather | Low | `intel/weather-fetch` |

## Data Collection Procedure

### 1. Space Weather
```bash
cd /home/node/molty/repos/roundtable-arsenal/intel/solar-weather
python3 scripts/solar-check.py summary
python3 scripts/solar-check.py alerts
python3 scripts/solar-check.py aurora
```
Extract: Kp index, solar wind speed, Bz, active alerts, aurora forecast, flare activity.

**Analysis requirements:**
- Don't just report numbers. Interpret them. "Kp 6 = moderate geomagnetic storm, potential GPS/comm impacts, aurora visible to mid-latitudes."
- Flag anything Kp≥5 as high priority.
- Note solar wind >500 km/s as elevated.
- Negative Bz = geomagnetic coupling worth mentioning.

### 2. News Aggregation
```bash
cd /workspace/skills/intel/news-aggregator
bash scripts/fetch-news.sh --hours 24 --category all --limit 15
# OR if python3+feedparser available:
# python3 scripts/fetch-news.py --hours 24 --category all
```
Filter and rank by relevance to Round Table domains (homelab, security, AI, space, self-hosting).

**Analysis requirements:**
- Select top 3-5 stories. Quality over quantity.
- For each: 1-2 sentence analysis of *why it matters*, not just *what happened*.
- Identify **emerging threads** — when 3+ sources mention related topics, flag the pattern.
- Tag confidence per story.
- Wrap multiple links in `<>` for Discord embed suppression.

### 3. Nerd News & Culture
Search for the latest in gaming, movies, TV, and cool tech. Derek is a nerd — this section should feel like the fun part of the briefing.

```bash
# Use web search to find trending nerd culture news
bash /workspace/skills/shared/web-search/scripts/search.sh "gaming news today 2026"
bash /workspace/skills/shared/web-search/scripts/search.sh "new movie trailer announcements 2026"
bash /workspace/skills/shared/web-search/scripts/search.sh "cool tech gadgets edge of innovation 2026"
bash /workspace/skills/shared/web-search/scripts/search.sh "TV show renewals cancellations 2026"
```

**Topics to cover (pick 3-5 best):**
- 🎮 **Gaming** — New releases, trailers, major announcements, indie gems, Game Pass/PS+ additions
- 🎬 **Movies & TV** — Trailers, renewals/cancellations, streaming releases, franchise news (Star Wars, Marvel, LOTR, GOT/HOTD, Dune)
- 🐉 **Franchise watch** — House of the Dragon, Rings of Power, Dune, Blade Runner, Foundation, Fallout — anything in Derek's wheelhouse
- 🤖 **Cool tech** — Robotics, space exploration, quantum computing, AI breakthroughs, retro computing, maker projects
- 🔬 **Science** — Space discoveries, physics breakthroughs, cool biology, anything that makes you go "whoa"
- 🕹️ **Retro/nostalgia** — Emulation news, retro hardware, classic game remasters

**Tone:** Enthusiastic but curated. This is the section where Kay gets to be a nerd. Have opinions — "this looks incredible" or "hard pass, here's why." Don't just list headlines.

**Derek's known interests:** Monty Python, GoT/HotD, sci-fi, self-hosting, homelab, woodworking, diving, space

### 4. Research Log
Check Kay's memory files for completed research:
```bash
cat /home/node/molty/memory/$(date -d yesterday +%Y-%m-%d).md 2>/dev/null
```
Extract any deep-research tasks completed, findings, and source counts.

### 4. Weather
```bash
cd /home/node/molty/repos/roundtable-arsenal/intel/weather-fetch
bash scripts/get-weather.sh "Warrior, Alabama"
```
Brief conditions + forecast. Keep it tight — 2-3 lines max.

### 5. Knight Activity
Check for research requests from other knights (NATS topics, memory references, task queues). Summarize any inter-knight collaboration or pending requests.

### 6. Threads Worth Pulling
This is the analysis crown jewel. After reviewing all data:
- Identify 2-4 topics worth deeper investigation
- Each thread needs a rationale: *why* is this worth pulling?
- These become potential deep-research tasks for the next cycle

## Output Generation

### Step 1: Build JSON Envelope

Output MUST conform to `shared/daily-reports` contract:

```json
{
  "knight": "sir-kay",
  "run_id": "daily-YYYY-MM-DD",
  "report_type": "daily-briefing",
  "timestamp": "ISO-8601",
  "summary": "2-3 sentence executive summary synthesizing key intelligence.",
  "sections": [
    {
      "title": "Space Weather",
      "priority": "medium",
      "content": "Markdown analysis...",
      "data_sources": ["NOAA SWPC"],
      "confidence": "high"
    }
  ],
  "highlights": [
    "3-5 bullet points for morning scan"
  ],
  "follow_up_needed": false,
  "follow_up_questions": []
}
```

### Step 2: Render Markdown

Use `templates/daily-digest.md` to produce a human-readable vault report. Save to:
- `/home/node/molty/repos/roundtable-arsenal/intel/daily-intel-digest/output/YYYY-MM-DD.md`
- Optionally publish to Tim's Obsidian vault

## Confidence Methodology

Tag every analytical claim:

| Level | Criteria | Examples |
|-------|----------|---------|
| **HIGH** | Primary authoritative sources, verified data | NOAA APIs, NVD, official announcements |
| **MEDIUM** | Reliable secondary sources, consistent cross-reporting | Industry publications, multiple news outlets agreeing |
| **LOW** | Single source, unverified, speculative | One blog post, rumor, unconfirmed leak |

## Voice & Tone

Kay is an intelligence analyst, not a news anchor:
- **Be opinionated.** "This matters because..." not "This happened."
- **Be concise.** If it takes more than 2 sentences to explain why something matters, it probably doesn't.
- **Find patterns.** The value isn't in any single data point — it's in the connections between them.
- **Recommend action.** Every digest should answer: "What should Tim pay attention to today?"
- **Admit uncertainty.** Confidence levels are mandatory. "I don't know" beats false certainty.

## Schedule

- **Generation:** 0600 CST daily
- **Data window:** Previous 24 hours
- **Delivery:** JSON to output directory, markdown to vault, summary to Tim's morning channel

## Dependencies

| Skill | Purpose | Required |
|-------|---------|----------|
| `intel/solar-weather` | Space weather data | ✅ |
| `intel/news-aggregator` | News feeds | ✅ |
| `intel/weather-fetch` | Local weather | ✅ |
| `shared/daily-reports` | Output contract | ✅ |
| `intel/deep-research` | For follow-up threads | Optional |
