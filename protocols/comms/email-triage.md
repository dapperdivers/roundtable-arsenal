# Protocol: Email Triage

## When to Use
Execute periodically (every 2-4 hours during business hours) or on demand when checking for important messages.

## Prerequisites
- Skills: `email-triage`, `vault-writer`

## Steps

### 1. Fetch Recent Emails
```bash
./skills/comms/email-triage/scripts/fetch-emails.sh --since 4h --unread --format json
```

### 2. Categorize
Sort emails into priority buckets:
- **🔴 Urgent:** Security alerts, system outages, direct requests with deadlines
- **🟡 Important:** Meeting requests, project updates, team messages
- **🟢 Normal:** Newsletters, FYI emails, non-time-sensitive items
- **⚪ Low:** Marketing, automated notifications, spam that got through

### 3. Summarize
For each email, produce:
- One-line summary
- Sender and time
- Priority level
- Suggested action (reply, read later, archive, delegate)

### 4. Flag Action Items
Identify emails requiring a response or action. Note:
- What's needed
- Deadline (explicit or implied)
- Who should handle it

### 5. Deliver Digest
Present the triage summary to the user. Group by priority. Lead with urgent items.

## Expected Output
Prioritized email summary with action items highlighted.

## Error Handling
- **Bridge API down:** Report unavailability, suggest checking email directly
- **Authentication failure:** Alert user to re-authenticate the bridge
