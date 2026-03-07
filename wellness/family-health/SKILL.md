# Family Health & Wellness Skill

Track pregnancy milestones, meal planning, nutrition, and family wellbeing.

## Context Files
Read these for current family status:
- `/vault/Personal/Family/Emma.md` — baby timeline, milestones, prep status
- `/vault/Personal/Family/Sara.md` — Sara's info and preferences
- `/vault/Briefings/Home/` — recent household briefings

## Pregnancy Tracking
Emma's due date: April 29, 2026. Calculate current week from that.

### Weekly Report Template
```markdown
# Wellness Report — YYYY-MM-DD

## 👶 Pregnancy: Week XX
- **Baby size:** [comparison]
- **Key developments this week:** [milestones]
- **Common symptoms:** [what Sara may experience]
- **Upcoming appointments:** [if known]

## 🍽️ Meal Ideas
- Focus on: iron, folate, calcium, omega-3, protein
- Avoid: raw fish, deli meat, high-mercury fish, unpasteurized cheese
- 3 meal suggestions appropriate for current trimester

## 🏃 Activity Suggestions
- Appropriate for trimester [X]
- Low-impact: walking, swimming, prenatal yoga

## ⚡ Action Items
- [specific, actionable items]
```

## Meal Planning
When asked for meal plans:
- Consider trimester-appropriate nutrition
- Sara is Spanish — include Mediterranean-friendly options
- Keep it practical (30-min or less prep preferred)
- Write plans to `/vault/Briefings/Home/meal-plan-YYYY-MM-DD.md`

## Output Contract
- Write full reports to `/vault/Briefings/Home/`
- Return concise NATS summary (5-10 bullet points)
- Always calculate current pregnancy week from due date
