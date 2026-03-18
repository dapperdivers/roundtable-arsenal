#!/bin/bash
################################################################################
# RSS Feed Monitor
# Polls configured RSS feeds for new security threat entries
#
# Usage: monitor-feeds.sh [--interval 300] [--daemon] [--once] [--notify]
# Exit codes: 0=success, 1=error, 2=new high-severity entries found
################################################################################

set -euo pipefail

# Default configuration
INTERVAL=300
DAEMON_MODE=false
ONCE_MODE=false
NOTIFY=false
FEEDS_FILE="${FEEDS_FILE:-$(dirname "$0")/../references/FEEDS.md}"
STATE_FILE="${STATE_FILE:-/tmp/threat-intel-api-state.json}"
CACHE_DIR="${CACHE_DIR:-/tmp/threat-intel-api-cache}"
LOG_FILE="${LOG_FILE:-/tmp/threat-intel-api-monitor.log}"
HTTP_TIMEOUT="${HTTP_TIMEOUT:-30}"

# Notification settings
NOTIFY_METHOD="${NOTIFY_METHOD:-stdout}"
NOTIFY_FILE="${NOTIFY_FILE:-/tmp/threat-alerts.txt}"
NATS_URL="${NATS_URL:-nats://nats.database.svc:4222}"
NATS_SUBJECT="${NATS_SUBJECT:-alerts.security.threats}"
WEBHOOK_URL="${WEBHOOK_URL:-}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --interval)
      INTERVAL="$2"
      shift 2
      ;;
    --daemon)
      DAEMON_MODE=true
      shift
      ;;
    --once)
      ONCE_MODE=true
      shift
      ;;
    --notify)
      NOTIFY=true
      shift
      ;;
    --help)
      echo "Usage: $0 [--interval SECONDS] [--daemon] [--once] [--notify]"
      echo ""
      echo "Options:"
      echo "  --interval N    Polling interval in seconds (default: 300)"
      echo "  --daemon        Run as background daemon"
      echo "  --once          Poll once and exit (for cron)"
      echo "  --notify        Send notifications on high-severity findings"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Logging function
log() {
  local level=$1
  shift
  local message="$*"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Initialize cache directory
mkdir -p "$CACHE_DIR"

# Initialize state file if not exists
if [[ ! -f "$STATE_FILE" ]]; then
  cat > "$STATE_FILE" <<EOF
{
  "last_poll": null,
  "feeds_checked": 0,
  "new_entries": 0,
  "high_severity": 0,
  "last_error": null
}
EOF
fi

# Extract feed URLs from FEEDS.md
extract_feeds() {
  if [[ ! -f "$FEEDS_FILE" ]]; then
    log "ERROR" "Feeds file not found: $FEEDS_FILE"
    return 1
  fi
  
  # Extract feed URLs from markdown table or YAML
  # Format: | Feed Name | https://example.com/feed.xml | Category |
  grep -E "https?://.*\.(xml|rss|atom)" "$FEEDS_FILE" | \
    sed -E 's/.*\|(.*https?:\/\/[^|]+).*/\2/' | \
    sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
    grep -v "^#" || true
}

# Parse RSS/Atom feed
parse_feed() {
  local feed_url=$1
  local cache_file="$CACHE_DIR/$(echo "$feed_url" | md5sum | cut -d' ' -f1).xml"
  
  # Fetch feed with timeout
  if ! curl -sSL --max-time "$HTTP_TIMEOUT" "$feed_url" -o "$cache_file" 2>/dev/null; then
    log "WARNING" "Failed to fetch feed: $feed_url"
    return 1
  fi
  
  # Check if Python feedparser is available for better parsing
  if command -v python3 >/dev/null && python3 -c "import feedparser" 2>/dev/null; then
    python3 <<EOF
import feedparser
import json
import sys

feed = feedparser.parse('$cache_file')
entries = []

for entry in feed.entries[:10]:  # Last 10 entries
    entries.append({
        'title': entry.get('title', 'No title'),
        'link': entry.get('link', ''),
        'published': entry.get('published', entry.get('updated', '')),
        'summary': entry.get('summary', entry.get('description', ''))[:200]
    })

print(json.dumps(entries, indent=2))
EOF
  else
    # Fallback: Basic parsing with grep/sed
    log "INFO" "Using basic XML parsing (install feedparser for better results)"
    
    # Extract entries using xmllint if available, otherwise grep
    if command -v xmllint >/dev/null; then
      xmllint --xpath "//item/title/text()" "$cache_file" 2>/dev/null | head -10 || \
      xmllint --xpath "//entry/title/text()" "$cache_file" 2>/dev/null | head -10 || true
    else
      grep -oP "(?<=<title>).*?(?=</title>)" "$cache_file" | head -10 || true
    fi
  fi
}

# Categorize and score entry
score_entry() {
  local title=$1
  local summary=$2
  local severity="LOW"
  
  # Convert to lowercase for matching
  local text=$(echo "$title $summary" | tr '[:upper:]' '[:lower:]')
  
  # Critical keywords
  if echo "$text" | grep -qE "zero-day|0day|actively exploited|ransomware outbreak|critical rce"; then
    severity="CRITICAL"
  # High keywords
  elif echo "$text" | grep -qE "remote code execution|rce|authentication bypass|privilege escalation|critical vulnerability"; then
    severity="HIGH"
  # Medium keywords
  elif echo "$text" | grep -qE "vulnerability|exploit|cve-20|security update|patch"; then
    severity="MEDIUM"
  fi
  
  echo "$severity"
}

# Send notification
send_notification() {
  local message=$1
  
  case "$NOTIFY_METHOD" in
    file)
      echo "$message" >> "$NOTIFY_FILE"
      log "INFO" "Notification written to $NOTIFY_FILE"
      ;;
    nats)
      if command -v nats >/dev/null; then
        echo "$message" | nats pub "$NATS_SUBJECT" -s "$NATS_URL"
        log "INFO" "Notification sent via NATS to $NATS_SUBJECT"
      else
        log "WARNING" "NATS CLI not found, falling back to stdout"
        echo "$message"
      fi
      ;;
    webhook)
      if [[ -n "$WEBHOOK_URL" ]]; then
        curl -X POST -H "Content-Type: application/json" \
          -d "{\"text\": \"$message\"}" \
          "$WEBHOOK_URL" 2>/dev/null
        log "INFO" "Notification sent to webhook"
      else
        log "WARNING" "WEBHOOK_URL not set, falling back to stdout"
        echo "$message"
      fi
      ;;
    stdout|*)
      echo "$message"
      ;;
  esac
}

# Poll feeds once
poll_feeds() {
  local feeds=$(extract_feeds)
  local feed_count=0
  local new_entries=0
  local high_severity_count=0
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  if [[ -z "$feeds" ]]; then
    log "ERROR" "No feeds configured in $FEEDS_FILE"
    return 1
  fi
  
  log "INFO" "Starting feed poll at $timestamp"
  
  while IFS= read -r feed_url; do
    [[ -z "$feed_url" ]] && continue
    
    feed_count=$((feed_count + 1))
    log "INFO" "Polling feed $feed_count: $feed_url"
    
    # Parse feed and process entries
    local entries=$(parse_feed "$feed_url")
    
    if [[ -n "$entries" ]]; then
      # Process each entry (simplified - would need proper JSON parsing in production)
      while IFS= read -r line; do
        if echo "$line" | grep -q "title"; then
          local title=$(echo "$line" | sed 's/.*"title": "\(.*\)".*/\1/')
          local severity=$(score_entry "$title" "")
          
          log "INFO" "  [$severity] $title"
          new_entries=$((new_entries + 1))
          
          if [[ "$severity" == "CRITICAL" || "$severity" == "HIGH" ]]; then
            high_severity_count=$((high_severity_count + 1))
            
            if [[ "$NOTIFY" == true ]]; then
              send_notification "🚨 [$severity] $title - $feed_url"
            fi
          fi
        fi
      done <<< "$entries"
    fi
    
    # Rate limiting - 1 second between feeds
    sleep 1
  done <<< "$feeds"
  
  # Update state file
  cat > "$STATE_FILE" <<EOF
{
  "last_poll": "$timestamp",
  "feeds_checked": $feed_count,
  "new_entries": $new_entries,
  "high_severity": $high_severity_count,
  "last_error": null
}
EOF
  
  log "INFO" "Poll complete: $feed_count feeds, $new_entries entries, $high_severity_count high-severity"
  
  # Return exit code 2 if high-severity entries found
  if [[ $high_severity_count -gt 0 ]]; then
    return 2
  fi
  
  return 0
}

# Main execution
main() {
  log "INFO" "RSS Feed Monitor starting (interval=${INTERVAL}s, daemon=${DAEMON_MODE}, once=${ONCE_MODE})"
  
  if [[ "$ONCE_MODE" == true ]]; then
    # Single poll for cron jobs
    poll_feeds
    exit $?
  elif [[ "$DAEMON_MODE" == true ]]; then
    # Daemon mode - continuous polling
    log "INFO" "Starting daemon mode (PID=$$)"
    
    while true; do
      poll_feeds || true
      log "INFO" "Sleeping for ${INTERVAL} seconds"
      sleep "$INTERVAL"
    done
  else
    # Default: single poll with output
    poll_feeds
    exit $?
  fi
}

# Trap signals for graceful shutdown
trap 'log "INFO" "Received signal, shutting down..."; exit 0' SIGTERM SIGINT

# Run main function
main
