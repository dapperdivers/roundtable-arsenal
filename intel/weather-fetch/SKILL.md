---
name: weather-fetch
description: Fetch current weather and forecast data for any location. Use for morning reports or when weather information is needed.
allowed-tools: Bash(curl:*)
metadata:
  author: roundtable
  version: "2.0"
  tier: intel
---

# Weather Fetch

Retrieves weather data from wttr.in (no API key needed).

## Scripts

```bash
bash scripts/get-weather.sh [location]
```

Default location: Warrior, Alabama.
