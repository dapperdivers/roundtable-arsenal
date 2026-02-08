# Protocol: Morning Intelligence Report

## When to Use
Execute every morning (recommended: 06:00–07:00 local time) before the daily security briefing. Provides the broad context for the day.

## Prerequisites
- Skills: `weather-fetch`, `news-aggregator`, `solar-weather`, `email-triage`, `report-generator`, `vault-writer`
- Templates: `templates/intel/morning-report.md`

## Steps

### 1. Weather
```bash
./skills/intel/weather-fetch/scripts/get-weather.sh --location "Dallas,TX" --format json --days 2
```
Note anything unusual: severe weather, extreme temps, weather advisories.

### 2. Space Weather
```bash
python3 skills/intel/solar-weather/scripts/solar-check.py summary
```
Flag if Kp index ≥ 5 (geomagnetic storm) or if there are active SWPC alerts.

### 3. News Headlines
```bash
python3 skills/intel/news-aggregator/scripts/fetch-news.py --sources tech,general --since 12h --limit 10 --format json
```
Identify top stories relevant to the user's interests (tech, security, space).

### 4. Email Preview
```bash
./skills/comms/email-triage/scripts/fetch-emails.sh --since 12h --unread --format json
```
Quick count and any urgent items.

### 5. Compile Report
Assemble findings into the morning report template:
```bash
python3 skills/shared/report-generator/scripts/render-template.py --template templates/intel/morning-report.md --data /tmp/morning-data.json
```

### 6. Deliver
Post the morning report. Keep it concise — this is a "start of day" briefing, not a deep dive. Link to deeper analysis where appropriate.

### 7. Save
```bash
./skills/shared/vault-writer/scripts/save-note.sh --path "Intel/Morning/$(date +%Y-%m-%d).md" --stdin < report.md
```

## Expected Output
A concise morning briefing covering weather, space weather, news headlines, and email status.

## Error Handling
- **Any source fails:** Include what's available, note gaps
- **All sources fail:** Deliver a minimal "systems check failed" notice with retry plan
