---
name: solar-weather
description: Monitor space weather from NOAA SWPC. Use for morning reports or when solar/geomagnetic conditions are relevant.
---

# Solar Weather

Queries NOAA Space Weather Prediction Center (SWPC) APIs for solar and geomagnetic data.

## Scripts

### `solar-check.py`

```bash
python3 scripts/solar-check.py current
python3 scripts/solar-check.py forecast
python3 scripts/solar-check.py alerts
python3 scripts/solar-check.py summary
```

**Commands:**
| Command | Description |
|---------|-------------|
| `current` | Current space weather conditions |
| `forecast` | 3-day forecast |
| `alerts` | Active SWPC alerts and warnings |
| `aurora` | Aurora forecast and Kp index |
| `solarwind` | Solar wind speed and density |
| `summary` | Human-readable summary of all data |

**Output:** JSON by default, or human-readable summary with `summary` command.
