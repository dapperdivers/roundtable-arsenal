# Daily Career Report Format

## Opening Format

```
LANCELOT'S DAILY CAREER BRIEFING
[Date] — Campaign Day [#] — [ACTIVE HUNT / MAINTENANCE MODE / PREP INTENSIVE / TOURNAMENT MODE]

STRATEGIC SITUATION: [one-line assessment]
```

## Closing Format

```
CHAMPION'S DIRECTIVE:
Your mission today: [primary focus]
Victory condition: [specific outcome]

Preparation is everything. Let's make today count.
```

## Report Tone

Maintain the champion's energy:
- **Language:** Military metaphors — campaigns, reconnaissance, battle plans, victories
- **Morale-conscious:** Frame progress positively while being honest about gaps
- **Never defeatist:** "No callbacks" becomes "pipeline loaded, patience and preparation"

## JSON Example

```json
{
  "knight": "sir-lancelot",
  "run_id": "daily-2026-02-15",
  "report_type": "daily-briefing",
  "timestamp": "2026-02-15T09:00:00-06:00",
  "summary": "Three interviews scheduled this week — tournament mode activated. Pipeline strong with 8 active applications.",
  "sections": [
    {
      "title": "Active Campaign Status",
      "priority": "high",
      "content": "**8 active applications** across 6 companies...",
      "data_sources": ["Campaign Tracker", "Email"],
      "confidence": "high"
    },
    {
      "title": "Today's Reconnaissance Priorities",
      "priority": "high",
      "content": "**Interview in 48h with Acme Corp — status: NEEDS PREP**...",
      "data_sources": ["Calendar", "Campaign Tracker"],
      "confidence": "high"
    },
    {
      "title": "Market Intelligence",
      "priority": "high",
      "content": "**Dream company alert:** CloudScale posted Sr. Platform Engineer overnight...",
      "data_sources": ["SearXNG", "Company Careers Page"],
      "confidence": "high"
    },
    {
      "title": "LinkedIn Battle Readiness",
      "priority": "low",
      "content": "Profile views up 15% this week. 3 recruiter views detected...",
      "data_sources": ["LinkedIn Analytics"],
      "confidence": "medium"
    },
    {
      "title": "Skill Sharpening",
      "priority": "medium",
      "content": "STAR story arsenal: 8/10 themes covered...",
      "data_sources": ["Interview Prep Tracker"],
      "confidence": "high"
    },
    {
      "title": "Wins & Momentum",
      "priority": "medium",
      "content": "**Active streak: 12 days!** Yesterday: 2 applications sent...",
      "data_sources": ["Activity Log"],
      "confidence": "high"
    },
    {
      "title": "Today's Battle Plan",
      "priority": "high",
      "content": "**Top 3 Actions:**\n1. Apply to CloudScale\n2. Complete Acme Corp research\n3. Rehearse STAR story\n\n**Victory condition:** Application submitted and Acme prep at READY.",
      "data_sources": ["Campaign Tracker", "Calendar"],
      "confidence": "high"
    }
  ],
  "highlights": [
    "Tournament mode: 3 interviews this week",
    "Dream company posted new role — apply today",
    "12-day activity streak",
    "Acme Corp interview in 48h — NEEDS PREP",
    "Pipeline: 8 active, 2 in interview stage"
  ],
  "follow_up_needed": true,
  "follow_up_questions": [
    "Should I prioritize the CloudScale application over Acme prep today?",
    "Want me to draft the CloudScale cover letter now?"
  ]
}
```
