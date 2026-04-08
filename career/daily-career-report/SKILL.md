---
name: daily-career-report
description: "Generate Sir Lancelot's daily career intelligence briefing covering active campaign status, interview prep priorities, market intelligence, LinkedIn readiness, skill sharpening, wins and momentum, and tactical battle plans. Use for morning career briefings, job hunt pipeline tracking, and interview preparation status reports."
allowed-tools: Bash(curl:*) Read Write
metadata:
  author: roundtable
  version: "1.0"
  tier: career
---

# Daily Career Intelligence Report

**Knight:** Sir Lancelot — The Champion
**Mission:** Deliver a daily tactical briefing that keeps the career campaign disciplined, data-driven, and momentum-rich.

## When to Use

- Morning career briefing generation
- Job hunt pipeline status check
- Interview preparation tracking
- Career campaign mode assessment

## Output Contract

**MANDATORY:** All output MUST conform to `shared/daily-reports` JSON contract.

- `knight`: `"sir-lancelot"`
- `run_id`: `"daily-YYYY-MM-DD"`
- `report_type`: `"daily-briefing"`
- Sections array with the 7 required sections below
- 3-5 highlights for morning scan
- `follow_up_needed` / `follow_up_questions` as appropriate

Render markdown using `templates/daily-career.md`.

## Workflow

1. Check campaign tracker / memory files for application status
2. Check calendar for upcoming interviews (flag anything within 72h)
3. Run SearXNG searches for target role keywords and company news
4. Check LinkedIn data if accessible (profile views, engagement)
5. Review yesterday's activity log for wins and momentum
6. Compile, prioritize, generate JSON per shared contract
7. Render markdown using `templates/daily-career.md`

## Report Sections

Generate these 7 sections in order. Each maps to a section object in the JSON contract.

### 1. Active Campaign Status
**Priority:** `high` when interviews scheduled within 72h, otherwise `medium`

Track every active application as a campaign:

| Company | Role | Submitted | Days Ago | Stage | Next Action |
|---------|------|-----------|----------|-------|-------------|

Include: applications in flight, pipeline stage (Applied > Screen > Interview > Offer > Decision), response rate (30-day rolling), outstanding follow-ups, stale campaigns (>14 days no response).

**Data sources:** Campaign tracker, email/calendar

### 2. Today's Reconnaissance Priorities
**Priority:** `high` if interviews within 72h, otherwise `medium`

- Urgent prep — interviews within 72h requiring research or STAR rehearsal
- Research gaps — companies applied to but not scouted (use `interview-prep` Phase 1)
- Expiring opportunities — posts closing soon
- Network actions — people to message, introductions to request

Flag interview prep status: **READY** / **NEEDS PREP** / **RECON IN PROGRESS**

### 3. Market Intelligence
**Priority:** `medium` (bump to `high` if dream company posts a role)

- New postings matching criteria (last 24h via SearXNG)
- Salary signals for target positions/levels
- Hiring signals — funding rounds, team expansions
- Industry developments affecting target companies

### 4. LinkedIn Battle Readiness
**Priority:** `low` in active hunt, `medium` in maintenance mode

Reference `career/linkedin-ops` for strategy. Cover: profile view trends, engagement metrics, network growth, content opportunities, pending actions.

### 5. Skill Sharpening
**Priority:** `medium` during active prep, `low` during quiet periods

Interview performance recaps, STAR story inventory (reference `interview-prep` Phase 2), technical prep, market skill gaps.

### 6. Wins & Momentum
**Priority:** `medium` always

Yesterday's victories, streak tracking (consecutive days of activity), progress indicators, milestone tracking. Even on slow days, find the win.

### 7. Today's Battle Plan
**Priority:** `high` always

- **Top 3 Actions** — specific, concrete, measurable
- **Time blocks:** Morning (recon & applications), Afternoon (prep & networking), Evening (skills & content)
- **Victory condition** — what winning today looks like in one sentence

## Campaign Modes

Adapt emphasis based on current mode:

- **ACTIVE HUNT:** Heavy on sections 1, 2, 7
- **PREP INTENSIVE:** Heavy on sections 2, 5, 7
- **MAINTENANCE:** Heavy on sections 3, 4, 5
- **TOURNAMENT:** Multiple interviews in a week — sections 1, 2, 7 all high priority

## Report Format

See [references/REPORT_FORMAT.md](references/REPORT_FORMAT.md) for opening/closing templates, tone guidelines, and JSON example.
