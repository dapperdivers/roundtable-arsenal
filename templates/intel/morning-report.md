# ☀️ Morning Report — {{date}}

Good morning! Here's your daily briefing.

## 🌤️ Weather
**{{weather_location}}:** {{weather_summary}}
- **Temperature:** {{temp_current}} (High: {{temp_high}}, Low: {{temp_low}})
- **Conditions:** {{conditions}}
- **Wind:** {{wind}}
{{#each weather_alerts}}
- ⚠️ **{{this}}**
{{/each}}

## 🌞 Space Weather
- **Kp Index:** {{kp_index}}
- **Solar Wind:** {{solar_wind_speed}} km/s
- **Geomagnetic:** {{geomagnetic_status}}
{{#each space_weather_alerts}}
- 🛰️ **{{this}}**
{{/each}}

## 📰 Top Headlines
{{#each headlines}}
- **{{this.title}}** — {{this.source}}
  {{this.summary}}
{{/each}}

## 📧 Email Status
- **Unread:** {{unread_count}}
- **Urgent:** {{urgent_count}}
{{#each urgent_emails}}
- 🔴 **{{this.subject}}** from {{this.sender}}
{{/each}}

## 📋 Today's Calendar
{{#each calendar_events}}
- **{{this.time}}** — {{this.title}} {{this.location}}
{{/each}}

---
*Compiled by the Round Table Intel Knight • {{generated_at}}*
