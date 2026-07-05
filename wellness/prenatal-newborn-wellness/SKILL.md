---
name: prenatal-newborn-wellness
description: >
  Track pregnancy milestones, nutrition, appointments, and newborn care through first 90 days. Use for weekly updates, hospital prep, warning signs, pediatric schedules, and postpartum wellness guidance.
---

# Prenatal & Newborn Wellness Skill

**Comprehensive support for pregnancy through first 90 days of newborn care.**

> ## ⚠️ CURRENT STATUS — READ FIRST
>
> **Emma was born April 14, 2026. The prenatal phase is OVER.**
> Compute her age in weeks/days from 2026-04-14 and use ONLY the
> postpartum/newborn guidance below. Never calculate pregnancy weeks, never
> reference the due date, hospital bags, or labor signs. If any instruction
> or prior report implies she is unborn, it is stale — trust this status
> (and the vault: `/vault/Personal/Family/Emma.md`).

## Overview

This skill enables AI agents to provide evidence-based wellness guidance through two critical phases:

**Phase 1 (Prenatal):** Week-by-week pregnancy tracking from current status through delivery  
**Phase 2 (Postpartum):** Newborn care and maternal recovery for first 90 days

## Capabilities

### Prenatal Phase (Current → Week 40)

- **Weekly Milestone Tracking**: Development, symptoms, nutrition by pregnancy week
- **Appointment Management**: OB visit schedules, tests, preparation checklists
- **Nutrition Guidance**: Macro targets, critical nutrients, meal planning by trimester
- **Warning Signs**: Red flags requiring immediate medical attention
- **Hospital Preparation**: Bag checklists, birth plan templates, labor signs
- **Timeline Management**: Critical windows for tasks, appointments, decisions

### Postpartum Phase (Birth → Day 90)

- **Newborn Milestones**: Development tracking by week (0-12 weeks)
- **Feeding Support**: Breastfeeding/formula guidance, schedules, tracking
- **Sleep Patterns**: Age-appropriate sleep guidance, safety, schedules
- **Pediatric Schedule**: Well-child visit timing, vaccines, growth monitoring
- **Maternal Recovery**: Postpartum wellness, warning signs, self-care
- **Partner Support**: Dad-specific tips, involvement strategies

## Usage

### Activate Skill

```
Use skill: prenatal-newborn-wellness
```

### Query Examples

**Prenatal:**
```
What are week 34 pregnancy milestones?
When is my next OB appointment due?
What should I pack in my hospital bag?
Create meal plan for third trimester
What warning signs require calling OB?
```

**Postpartum:**
```
What's normal for 2-week-old sleep?
When is the next pediatrician visit?
Breastfeeding troubleshooting tips
Postpartum warning signs for mom
Dad tips for first week home
```

## Skill Functions

### prenatal_milestone_lookup(week, day)
Returns development milestones, symptoms, nutrition focus for specific pregnancy week/day.

**Input:**
- `week` (int): Pregnancy week (1-42)
- `day` (int, optional): Day within week (0-6)

**Output:**
```yaml
week: 34
day: 0
trimester: 3
development:
  size: "4.75 lbs, 17.7 inches"
  major_milestones: ["Lung surfactant 95% complete", "Central nervous system maturing"]
  organs: {lungs: "95% mature", brain: "rapid growth", immune: "antibody transfer"}
symptoms:
  common: ["Braxton Hicks", "shortness of breath", "frequent urination"]
  concerning: ["Regular contractions 4+/hr", "bleeding", "decreased movement"]
nutrition:
  protein: "75-100g daily"
  hydration: "80-100 oz"
  focus: ["DHA for brain", "iron for blood volume", "calcium for bones"]
```

### appointment_schedule(current_week)
Returns expected OB appointments, tests, and preparation needs.

### nutrition_plan(week, dietary_restrictions)
Generates meal plan with macro targets for specific pregnancy week.

### hospital_bag_checklist(weeks_until_due)
Returns hospital bag checklist prioritized by urgency.

### warning_signs(trimester)
Returns warning signs requiring medical attention by trimester.

### newborn_milestone_lookup(age_weeks)
Returns newborn development and care guidance by age.

### pediatric_schedule(birth_date)
Returns well-child visit schedule and vaccine timeline.

### postpartum_wellness(days_postpartum)
Returns maternal recovery guidance and warning signs.

## Reference Files

Detailed guides in `/references/` directory:

- `pregnancy-weeks.yaml`: Week-by-week development, symptoms, nutrition (Weeks 1-42)
- `trimester-nutrition.md`: Detailed nutrition guidance by trimester
- `warning-signs.md`: Comprehensive warning signs (prenatal + postpartum)
- `hospital-preparation.md`: Hospital bag checklists, birth plan templates
- `labor-delivery.md`: Signs of labor, when to go to hospital, stages
- `newborn-weeks.yaml`: Week-by-week newborn care (Weeks 0-12)
- `feeding-guide.md`: Breastfeeding and formula feeding comprehensive guide
- `sleep-guide.md`: Safe sleep, schedules by age, troubleshooting
- `pediatric-schedule.yaml`: Well-child visits, vaccines, milestones
- `postpartum-recovery.md`: Maternal healing, warning signs, self-care
- `partner-guide.md`: Dad-specific tips, involvement strategies

## Configuration

```yaml
# User profile for personalization
pregnancy:
  status: "complete"  # Emma arrived — prenatal functions are historical only
  due_date: "2026-04-29"

baby:
  name: "Emma"
  birth_date: "2026-04-14"
  
mother:
  name: "Sara"
  dietary_restrictions: []
  
partner:
  name: "Derek"
  
preferences:
  measurement_system: "imperial"
  detail_level: "comprehensive"
```

## Evidence Base

All guidance based on:
- American College of Obstetricians and Gynecologists (ACOG) guidelines
- American Academy of Pediatrics (AAP) recommendations
- World Health Organization (WHO) maternal/child health guidelines

## Disclaimers

**This skill provides informational support only, not medical advice.**

Always defer to healthcare provider for medical decisions. Emergency situations require immediate emergency services (911).

## Version History

**1.0.0** (2026-03-17)
- Initial release
- Prenatal phase: Weeks 1-42 complete
- Postpartum phase: Days 0-90 complete

## License

MIT License

## Contact

Maintained by: Sir Bedivere  
Domain: Wellness  
Last Updated: 2026-03-17
