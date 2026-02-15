# 🏠 Daily Home Status — {{date_long}}

> {{summary}}

---

## 🔴 Today's Priorities

{{#each priorities}}
- {{urgency_icon}} **{{title}}** — {{detail}}
{{/each}}
{{#if no_priorities}}
- 🟢 Clear day — nothing urgent on the radar.
{{/if}}

---

## 📅 This Week Ahead ({{week_range}})

{{#each milestone_countdowns}}
{{icon}} **{{name}}** in {{days_remaining}} days ({{target_date}})
{{/each}}

{{#each days}}
### {{day_label}}
{{#each events}}
- {{time}} — {{description}}{{#if location}} *({{location}})*{{/if}}{{#if who}} — {{who}}{{/if}}
{{/each}}
{{#if no_events}}
- *Nothing scheduled*
{{/if}}
{{/each}}

---

## 🏠 Home Systems

{{#if all_clear}}
✅ **All systems normal**
{{/if}}

{{#if device_issues}}
### ⚠️ Devices Needing Attention
| Device | Status | Since |
|--------|--------|-------|
{{#each device_issues}}
| {{name}} | {{status}} | {{since}} |
{{/each}}
{{/if}}

{{#if automation_failures}}
### 🔧 Automation Failures (Last 24h)
{{#each automation_failures}}
- **{{name}}** — {{error}} ({{timestamp}})
{{/each}}
{{/if}}

### Climate & Energy
{{#each climate_notes}}
- {{note}}
{{/each}}

### Maintenance Due
{{#each maintenance_items}}
- {{urgency_icon}} {{task}} — {{due_info}}
{{/each}}
{{#if no_maintenance}}
- ✅ Nothing due this week
{{/if}}

---

## ✅ Tasks & Decisions

### Waiting on You
{{#each waiting_on_user}}
- [ ] {{task}}{{#if deadline}} *(by {{deadline}})*{{/if}}{{#if context}} — {{context}}{{/if}}
{{/each}}
{{#if no_waiting_on_user}}
- ✅ No decisions needed right now
{{/if}}

### Waiting on Others
{{#each waiting_on_others}}
- ⏳ **{{who}}:** {{what}}{{#if expected}} *(expected {{expected}})*{{/if}}
{{/each}}
{{#if no_waiting_on_others}}
- ✅ Nothing pending
{{/if}}

### Completed Yesterday
{{#each completed}}
- ✓ {{task}}
{{/each}}
{{#if no_completed}}
- *Rest day — nothing logged*
{{/if}}

---

## 📊 Household Intelligence

{{#each intelligence_items}}
- {{icon}} **{{category}}:** {{insight}}
{{/each}}

---

## 🛡️ Knight Updates

{{#each knight_updates}}
- **{{knight}}:** {{update}}
{{/each}}
{{#if no_knight_updates}}
- All quiet on the roundtable front.
{{/if}}

---

## 💭 Notes

{{notes}}

---

*The hearth is tended. — Bedivere 🏠*
