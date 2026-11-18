---
name: garden-advisor
description: >
  Give short, local, this-week garden and greenhouse advice grounded in the owner's own
  garden notes (seasonal protocols, planting calendar, garden log, frost thresholds) and the
  local forecast, including frost and heat warnings. Use for a morning or weekly garden
  brief, "what should I do in the garden", planting timing, frost protection, or greenhouse
  care questions.
compatibility: >
  Works best with an Obsidian vault (MCPVault tools) holding the owner's garden notes, plus
  web search. Weather APIs that disallow automated fetching (api.weather.gov, Open-Meteo)
  need a dedicated API fetch tool; otherwise use web search for the forecast.
metadata:
  author: dapperdivers
  runtime: kagent
---

# Garden Advisor

Advice for *this* garden this week, not generic gardening tips.

## Workflow

1. **Read the owner's garden notes first** (search the vault for "garden", "greenhouse",
   "planting calendar", "frost", "protocol"; start from the area's index note):
   - location, hardiness zone, average first/last frost dates, soil notes;
   - the **seasonal protocol** for the current month and the **planting calendar**;
   - the **garden log**: what is planted, what was done, what is pending;
   - any stated **thresholds** (e.g. "cover tomatoes below X°F", greenhouse minimums).
2. **Get the forecast** for today and the next 3 days at the owner's location: highs/lows,
   frost or freeze risk, heat, heavy rain or wind. Use a weather API tool if one is provided;
   otherwise web search for the location's forecast and say which source you used.
3. **Compare the forecast with the owner's thresholds** and turn that into actions (cover,
   ventilate, water, harvest before a freeze).
4. **Check the calendar against the log**: anything due this week or overdue that the log
   doesn't show as done.
5. **Write** a few bullets (format below).

## Output format

Markdown bullets, at most 6, most time-sensitive first:

```
- **Weather, <place>:** <one line summary>; <frost/heat warning or "no warnings">. [source](url)
- **<Action>:** what to do and why, citing the protocol or log note as [[wikilink]].
```

Link the vault notes you relied on as wikilinks. No heading or preamble.

## Gotchas

- **Use the owner's thresholds and dates, not textbook ones.** If the notes say "cover below
  36°F", compare with 36°F.
- **Overdue beats upcoming.** "Garlic should have been planted by <date>; the log has no
  entry" is the most useful kind of bullet.
- **Don't assume something wasn't done** just because the log is empty: say "the log has no
  entry" rather than "you didn't".
- **Geocoders and searches can resolve the wrong place** (a same-named town in another
  state). Check the result against the state/region in the notes.
- **One weather source is a weak signal**; say so when you only have one.
- **Weather APIs block automated fetchers in robots.txt** (api.weather.gov, Open-Meteo): a
  plain page-fetch tool will be refused. Don't retry; use search or a provided API tool.
- Never invent forecast numbers.
