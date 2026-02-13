---
name: solar-weather
description: Monitor space weather from NOAA SWPC including solar flares, geomagnetic storms, CMEs, and aurora forecasts. Use for morning reports or when space weather conditions are relevant.
allowed-tools: Bash(curl:*) Bash(python3:*) Read
metadata:
  author: roundtable
  version: "2.0"
  tier: intel
---

# Solar Weather

Queries NOAA Space Weather Prediction Center (SWPC) APIs for solar and geomagnetic data.

## Scripts

```bash
python3 scripts/solar-check.py [current|forecast|aurora|alerts|summary]
```

## Key Metrics
- **Kp Index** — geomagnetic disturbance (0-9, ≥5 = storm)
- **Solar flare class** — A/B/C/M/X (X = most powerful)
- **Solar wind speed** — >500 km/s = elevated
- **Bz component** — negative = geomagnetic coupling
