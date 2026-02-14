---
name: household-ops
description: Household management — Home Assistant control, family calendar, checklists, and home automation
---

# Household Operations

Home automation, family coordination, and household management via Home Assistant REST API.

## Home Assistant API

- **Base URL:** `http://home-assistant.home.svc.cluster.local:8123`
- **Auth:** `Authorization: Bearer $HOMEASSISTANT_TOKEN`

```bash
HA="http://home-assistant.home.svc.cluster.local:8123/api"
AUTH="Authorization: Bearer $HOMEASSISTANT_TOKEN"
```

### Entity Operations

```bash
# Get state of an entity
curl -s -H "$AUTH" "$HA/states/light.living_room" | jq '{state, brightness: .attributes.brightness}'

# List all entities (filter with jq)
curl -s -H "$AUTH" "$HA/states" | jq '[.[] | {entity_id, state}]'

# Search entities by keyword
curl -s -H "$AUTH" "$HA/states" | jq '[.[] | select(.entity_id | contains("living")) | {entity_id, state}]'
```

### Lights

```bash
# Turn on
curl -s -X POST -H "$AUTH" -H "Content-Type: application/json" \
  "$HA/services/light/turn_on" \
  -d '{"entity_id": "light.living_room"}'

# Turn on with brightness (0-255)
curl -s -X POST -H "$AUTH" -H "Content-Type: application/json" \
  "$HA/services/light/turn_on" \
  -d '{"entity_id": "light.living_room", "brightness": 150}'

# Turn on with color temp (mireds: 153=cool, 500=warm)
curl -s -X POST -H "$AUTH" -H "Content-Type: application/json" \
  "$HA/services/light/turn_on" \
  -d '{"entity_id": "light.living_room", "color_temp": 300}'

# Turn off
curl -s -X POST -H "$AUTH" -H "Content-Type: application/json" \
  "$HA/services/light/turn_off" \
  -d '{"entity_id": "light.living_room"}'

# Toggle
curl -s -X POST -H "$AUTH" -H "Content-Type: application/json" \
  "$HA/services/light/toggle" \
  -d '{"entity_id": "light.living_room"}'
```

### Climate

```bash
# Get thermostat state
curl -s -H "$AUTH" "$HA/states/climate.thermostat" | jq '{state: .state, current_temp: .attributes.current_temperature, target_temp: .attributes.temperature}'

# Set temperature
curl -s -X POST -H "$AUTH" -H "Content-Type: application/json" \
  "$HA/services/climate/set_temperature" \
  -d '{"entity_id": "climate.thermostat", "temperature": 72}'

# Set HVAC mode (heat, cool, auto, off)
curl -s -X POST -H "$AUTH" -H "Content-Type: application/json" \
  "$HA/services/climate/set_hvac_mode" \
  -d '{"entity_id": "climate.thermostat", "hvac_mode": "auto"}'
```

### Scenes

```bash
# Activate a scene
curl -s -X POST -H "$AUTH" -H "Content-Type: application/json" \
  "$HA/services/scene/turn_on" \
  -d '{"entity_id": "scene.movie_time"}'

# List all scenes
curl -s -H "$AUTH" "$HA/states" | jq '[.[] | select(.entity_id | startswith("scene.")) | .entity_id]'
```

### Switches & Covers

```bash
# Toggle switch
curl -s -X POST -H "$AUTH" -H "Content-Type: application/json" \
  "$HA/services/switch/toggle" \
  -d '{"entity_id": "switch.porch_light"}'

# Open/close cover (garage, blinds)
curl -s -X POST -H "$AUTH" -H "Content-Type: application/json" \
  "$HA/services/cover/open_cover" \
  -d '{"entity_id": "cover.garage_door"}'
```

### Sensors & History

```bash
# Get sensor value
curl -s -H "$AUTH" "$HA/states/sensor.outdoor_temperature" | jq '{state, unit: .attributes.unit_of_measurement}'

# Get history (last 24h)
curl -s -H "$AUTH" "$HA/history/period?filter_entity_id=sensor.outdoor_temperature" | jq '.[0] | length'
```

### Automations

```bash
# Trigger an automation
curl -s -X POST -H "$AUTH" -H "Content-Type: application/json" \
  "$HA/services/automation/trigger" \
  -d '{"entity_id": "automation.goodnight"}'

# Enable/disable automation
curl -s -X POST -H "$AUTH" -H "Content-Type: application/json" \
  "$HA/services/automation/turn_off" \
  -d '{"entity_id": "automation.motion_lights"}'
```

## Checklist Templates

### Weekly Shopping List
```markdown
## Groceries — Week of [DATE]
### Produce
- [ ] 
### Protein
- [ ] 
### Dairy
- [ ] 
### Pantry
- [ ] 
### Household
- [ ] 
### Notes
- 
```

### Wedding Planning Checklist
```markdown
## Wedding Planning — [MONTHS] Out
### Venue & Vendors
- [ ] Venue booked and deposit paid
- [ ] Caterer selected and menu finalized
- [ ] Photographer/videographer booked
- [ ] DJ/band booked
- [ ] Officiant confirmed
- [ ] Florist selected

### Logistics
- [ ] Guest list finalized
- [ ] Invitations sent (8 weeks before)
- [ ] RSVPs tracked
- [ ] Seating chart drafted
- [ ] Transportation arranged
- [ ] Hotel block reserved

### Personal
- [ ] Attire purchased and fitted
- [ ] Rings purchased
- [ ] Vows written
- [ ] Marriage license obtained
- [ ] Name change documents prepared (if applicable)

### Week-Of
- [ ] Final vendor confirmations
- [ ] Timeline distributed to wedding party
- [ ] Emergency kit packed
- [ ] Rehearsal dinner planned
```

### Baby Prep Checklist
```markdown
## Baby Prep — [WEEKS] Before Due Date
### Essentials
- [ ] Car seat (installed and inspected)
- [ ] Crib/bassinet with firm mattress
- [ ] Diapers and wipes (newborn + size 1)
- [ ] Onesies and sleepers (0-3 months)
- [ ] Swaddles and blankets
- [ ] Bottles and formula (even if breastfeeding — backup)

### Medical
- [ ] Pediatrician selected
- [ ] Hospital bag packed
- [ ] Insurance updated / baby added post-birth plan
- [ ] Birth plan discussed with provider

### Home
- [ ] Nursery set up
- [ ] Baby monitor installed
- [ ] Outlet covers and cabinet locks
- [ ] Freezer meals prepped (2 weeks worth)
- [ ] Pet introduction plan (if applicable)

### Admin
- [ ] FMLA/parental leave filed
- [ ] Birth certificate process understood
- [ ] SSN application ready
- [ ] Will/guardianship updated
- [ ] 529 account opened
```

## Notes
- Prefer Home Assistant MCP tools when available; fall back to REST API
- Use `jq` to filter large entity lists
- Store checklists in Obsidian or Paperless for persistence
- Climate automations should respect sleep schedules and away modes
