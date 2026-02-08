---
name: weather-fetch
description: Fetch current weather and forecast data. Use for morning reports or when weather information is needed.
---

# Weather Fetch

Retrieves weather data from wttr.in or configured weather APIs.

## Scripts

### `get-weather.sh`

```bash
./scripts/get-weather.sh --location "Dallas,TX"
./scripts/get-weather.sh --location "Dallas,TX" --format json --days 3
```

**Arguments:**
| Flag | Description |
|------|-------------|
| `--location` | Location string (default: auto-detect) |
| `--format` | Output: `json`, `text`, `oneline` |
| `--days` | Forecast days (1-3) |

**Output:** Weather data including temperature, conditions, wind, and forecast.
