#!/usr/bin/env python3
"""solar-check.py — Query NOAA SWPC APIs for space weather data."""

import argparse
import json
import sys
from urllib.request import urlopen

SWPC_BASE = "https://services.swpc.noaa.gov"

ENDPOINTS = {
    "current": "/products/summary/solar-wind-mag-field.json",
    "forecast": "/products/forecast/three-day-forecast.json",
    "alerts": "/products/alerts.json",
    "aurora": "/products/noaa-planetary-k-index-forecast.json",
    "solarwind": "/products/summary/solar-wind-speed.json",
}


def fetch(endpoint: str) -> dict:
    """Fetch data from a SWPC endpoint."""
    url = f"{SWPC_BASE}{endpoint}"
    try:
        with urlopen(url, timeout=15) as resp:
            return json.loads(resp.read())
    except Exception as e:
        print(f"Error fetching {url}: {e}", file=sys.stderr)
        return {}


def cmd_current():
    data = fetch(ENDPOINTS["current"])
    json.dump(data, sys.stdout, indent=2)


def cmd_forecast():
    data = fetch(ENDPOINTS["forecast"])
    json.dump(data, sys.stdout, indent=2)


def cmd_alerts():
    data = fetch(ENDPOINTS["alerts"])
    json.dump(data, sys.stdout, indent=2)


def cmd_aurora():
    data = fetch(ENDPOINTS["aurora"])
    json.dump(data, sys.stdout, indent=2)


def cmd_solarwind():
    data = fetch(ENDPOINTS["solarwind"])
    json.dump(data, sys.stdout, indent=2)


def cmd_summary():
    print("=== Space Weather Summary ===\n")

    mag = fetch(ENDPOINTS["current"])
    if mag:
        print(f"Solar Wind Magnetic Field: {json.dumps(mag, indent=2)}\n")

    wind = fetch(ENDPOINTS["solarwind"])
    if wind:
        print(f"Solar Wind Speed: {json.dumps(wind, indent=2)}\n")

    alerts = fetch(ENDPOINTS["alerts"])
    if alerts:
        count = len(alerts) if isinstance(alerts, list) else 0
        print(f"Active Alerts: {count}")
        if isinstance(alerts, list):
            for a in alerts[:5]:
                msg = a.get("message", a.get("product_id", ""))
                print(f"  - {msg[:100]}")
    print()


def main():
    parser = argparse.ArgumentParser(description="Space weather from NOAA SWPC.")
    parser.add_argument("command", choices=["current", "forecast", "alerts", "aurora", "solarwind", "summary"],
                        help="Data to fetch")
    args = parser.parse_args()

    handlers = {
        "current": cmd_current,
        "forecast": cmd_forecast,
        "alerts": cmd_alerts,
        "aurora": cmd_aurora,
        "solarwind": cmd_solarwind,
        "summary": cmd_summary,
    }
    handlers[args.command]()


if __name__ == "__main__":
    main()
