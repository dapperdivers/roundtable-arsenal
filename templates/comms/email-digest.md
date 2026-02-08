# 📧 Email Digest — {{date}}

**Period:** {{period}}
**Total messages:** {{total_count}}
**Unread:** {{unread_count}}

## 🔴 Urgent
{{#each urgent}}
- **{{this.subject}}** from {{this.sender}} ({{this.time}})
  - {{this.summary}}
  - *Action: {{this.suggested_action}}*
{{/each}}

## 🟡 Important
{{#each important}}
- **{{this.subject}}** from {{this.sender}} ({{this.time}})
  - {{this.summary}}
{{/each}}

## 🟢 Normal
{{#each normal}}
- {{this.subject}} — {{this.sender}}
{{/each}}

## ⚪ Low Priority
{{low_count}} messages (newsletters, notifications, automated)

## Action Items
{{#each action_items}}
- [ ] {{this.action}} — re: {{this.subject}} ({{this.deadline}})
{{/each}}

---
*Compiled by the Round Table Comms Knight • {{generated_at}}*
