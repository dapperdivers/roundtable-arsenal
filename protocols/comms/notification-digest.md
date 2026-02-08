# Protocol: Notification Digest

## When to Use
Compile 2-3 times daily (morning, midday, evening) or on demand.

## Prerequisites
- Skills: `notification-digest`, `vault-writer`

## Steps

### 1. Collect Notifications
```bash
./skills/comms/notification-digest/scripts/collect-notifications.sh --sources all --since 4h
```

### 2. Deduplicate and Group
Group notifications by source and topic. Remove duplicates (e.g., multiple GitHub notifications for the same PR).

### 3. Prioritize
Rank by urgency:
- Direct mentions/replies → high
- Action required → high  
- Updates on watched items → medium
- Informational → low

### 4. Format Digest
Present as a concise digest:
- Count by source
- Top items requiring attention
- Summary of everything else

### 5. Deliver
Post digest to user. For high-priority items outside business hours, consider if they warrant an immediate alert.

## Expected Output
Concise notification digest grouped by source and priority.

## Error Handling
- **Source unavailable:** Skip and note in digest
- **High volume:** Summarize aggressively, link to full lists
