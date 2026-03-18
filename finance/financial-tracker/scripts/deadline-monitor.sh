#!/bin/bash
#
# deadline-monitor.sh - Track and alert on upcoming financial deadlines
#
# Usage:
#   ./deadline-monitor.sh [OPTIONS]
#
# Options:
#   --alert-days DAYS      Alert window in days (default: 7)
#   --type TYPE            Show only specific type (payment, promo, tax, subscription)
#   --add TYPE ACCOUNT DATE DESCRIPTION  Add a deadline
#   --show                 Display all deadlines
#   --help                 Show this help
#
# Example:
#   ./deadline-monitor.sh --alert-days 30
#   ./deadline-monitor.sh --type promo
#   ./deadline-monitor.sh --add payment discover 2026-04-05 "Minimum payment due"
#

set -euo pipefail

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$SKILL_DIR/data"
CONFIG_DIR="$SKILL_DIR/config"

mkdir -p "$DATA_DIR" "$CONFIG_DIR"

DEADLINE_FILE="$DATA_DIR/deadlines.json"
STATE_FILE="$DATA_DIR/financial-state.json"

# Initialize deadlines file if doesn't exist
init_deadlines() {
    if [[ ! -f "$DEADLINE_FILE" ]]; then
        cat > "$DEADLINE_FILE" << 'EOF'
{
  "check_date": "",
  "alert_window_days": 7,
  "deadlines": [
    {
      "id": "tax_filing_2026",
      "type": "tax",
      "category": "filing",
      "deadline": "2026-04-15",
      "severity": "critical",
      "description": "Federal and state tax returns due (2024 & 2025)",
      "account": "n/a",
      "impact": "Penalties and interest if late",
      "recurring": false
    },
    {
      "id": "wells_fargo_1_promo",
      "type": "promo_expiration",
      "category": "interest_rate",
      "deadline": "2026-04-03",
      "severity": "high",
      "description": "Wells Fargo #1 promotional 0% APR expires",
      "account": "wells_fargo_1",
      "impact": "Balance will incur ~20% APR (est $6.34/day interest)",
      "recurring": false
    },
    {
      "id": "discover_payment",
      "type": "payment_due",
      "category": "minimum_payment",
      "deadline": "2026-04-05",
      "severity": "medium",
      "description": "Discover minimum payment due",
      "account": "discover",
      "amount": 167.00,
      "impact": "Late fee + credit score impact if missed",
      "recurring": true,
      "recurring_interval": "monthly"
    },
    {
      "id": "wells_fargo_1_payment",
      "type": "payment_due",
      "category": "minimum_payment",
      "deadline": "2026-03-28",
      "severity": "medium",
      "description": "Wells Fargo #1 minimum payment due",
      "account": "wells_fargo_1",
      "amount": 125.00,
      "impact": "Late fee + potential promo cancellation",
      "recurring": true,
      "recurring_interval": "monthly"
    },
    {
      "id": "wells_fargo_2_payment",
      "type": "payment_due",
      "category": "minimum_payment",
      "deadline": "2026-04-11",
      "severity": "medium",
      "description": "Wells Fargo #2 minimum payment due",
      "account": "wells_fargo_2",
      "amount": 250.00,
      "impact": "Late fee + credit score impact",
      "recurring": true,
      "recurring_interval": "monthly"
    },
    {
      "id": "amazon_payment",
      "type": "payment_due",
      "category": "minimum_payment",
      "deadline": "2026-04-15",
      "severity": "medium",
      "description": "Amazon Synchrony minimum payment due",
      "account": "amazon_synchrony",
      "amount": 50.00,
      "impact": "Late fee + credit score impact",
      "recurring": true,
      "recurring_interval": "monthly"
    },
    {
      "id": "student_loan_payment",
      "type": "payment_due",
      "category": "loan_payment",
      "deadline": "2026-03-25",
      "severity": "medium",
      "description": "Student loan payment due",
      "account": "student_loans",
      "amount": 315.00,
      "impact": "Late fee + PSLF qualifying payment missed",
      "recurring": true,
      "recurring_interval": "monthly"
    },
    {
      "id": "amazon_prime_renewal",
      "type": "subscription",
      "category": "subscription",
      "deadline": "2026-04-20",
      "severity": "low",
      "description": "Amazon Prime annual renewal",
      "account": "subscription",
      "amount": 140.19,
      "impact": "Automatic charge if not canceled",
      "recurring": true,
      "recurring_interval": "yearly"
    },
    {
      "id": "emma_arrival",
      "type": "milestone",
      "category": "life_event",
      "deadline": "2026-04-29",
      "severity": "high",
      "description": "Emma's estimated arrival date",
      "account": "n/a",
      "impact": "Financial prep deadline - all major tasks should be complete",
      "recurring": false
    }
  ]
}
EOF
    fi
}

# Calculate days until deadline
days_until() {
    local deadline="$1"
    local today=$(date +%Y-%m-%d)
    
    local deadline_epoch=$(date -d "$deadline" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$deadline" +%s)
    local today_epoch=$(date -d "$today" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$today" +%s)
    
    local days=$(( ($deadline_epoch - $today_epoch) / 86400 ))
    echo "$days"
}

# Categorize urgency based on days remaining
get_urgency_level() {
    local days="$1"
    
    if (( days <= 0 )); then
        echo "overdue"
    elif (( days <= 3 )); then
        echo "critical"
    elif (( days <= 7 )); then
        echo "urgent"
    elif (( days <= 14 )); then
        echo "upcoming"
    elif (( days <= 30 )); then
        echo "approaching"
    else
        echo "future"
    fi
}

# Get icon for urgency level
get_urgency_icon() {
    local level="$1"
    
    case "$level" in
        overdue) echo "🔴🔴" ;;
        critical) echo "🔴" ;;
        urgent) echo "🟠" ;;
        upcoming) echo "🟡" ;;
        approaching) echo "🟢" ;;
        future) echo "⚪" ;;
        *) echo "?" ;;
    esac
}

# Monitor deadlines
monitor_deadlines() {
    local alert_days="${1:-7}"
    local filter_type="${2:-all}"
    
    local today=$(date +%Y-%m-%d)
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # Update check date
    jq --arg date "$today" --argjson days "$alert_days" \
       '.check_date = $date | .alert_window_days = $days' \
       "$DEADLINE_FILE" > "${DEADLINE_FILE}.tmp" && mv "${DEADLINE_FILE}.tmp" "$DEADLINE_FILE"
    
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "           DEADLINE MONITOR - $(date +%Y-%m-%d)"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Alert Window: Next $alert_days days"
    echo ""
    
    # Arrays to hold categorized deadlines
    local -a overdue=()
    local -a critical=()
    local -a urgent=()
    local -a upcoming=()
    local -a approaching=()
    
    # Process each deadline
    while IFS=$'\t' read -r id type deadline severity description account amount impact; do
        # Skip if filtering by type and doesn't match
        if [[ "$filter_type" != "all" && "$type" != "$filter_type" ]]; then
            continue
        fi
        
        local days_remaining=$(days_until "$deadline")
        local urgency=$(get_urgency_level "$days_remaining")
        local icon=$(get_urgency_icon "$urgency")
        
        # Format the deadline line
        local line="$icon $description: $days_remaining days ($deadline)"
        if [[ -n "$amount" && "$amount" != "null" ]]; then
            line="$line - Amount: \$$amount"
        fi
        if [[ -n "$impact" && "$impact" != "null" ]]; then
            line="$line\n     Impact: $impact"
        fi
        
        # Categorize
        case "$urgency" in
            overdue) overdue+=("$line") ;;
            critical) critical+=("$line") ;;
            urgent) urgent+=("$line") ;;
            upcoming) upcoming+=("$line") ;;
            approaching) approaching+=("$line") ;;
        esac
        
    done < <(jq -r '.deadlines[] | 
        [.id, .type, .deadline, .severity, .description, .account, (.amount // ""), (.impact // "")] | @tsv
    ' "$DEADLINE_FILE")
    
    # Display categorized deadlines
    if [[ ${#overdue[@]} -gt 0 ]]; then
        echo "🔴🔴 OVERDUE:"
        printf '%b\n' "${overdue[@]}"
        echo ""
    fi
    
    if [[ ${#critical[@]} -gt 0 ]]; then
        echo "🔴 CRITICAL (0-3 days):"
        printf '%b\n' "${critical[@]}"
        echo ""
    fi
    
    if [[ ${#urgent[@]} -gt 0 ]]; then
        echo "🟠 URGENT (4-7 days):"
        printf '%b\n' "${urgent[@]}"
        echo ""
    fi
    
    if [[ ${#upcoming[@]} -gt 0 ]]; then
        echo "🟡 UPCOMING (8-14 days):"
        printf '%b\n' "${upcoming[@]}"
        echo ""
    fi
    
    if [[ ${#approaching[@]} -gt 0 && $alert_days -ge 30 ]]; then
        echo "🟢 APPROACHING (15-30 days):"
        printf '%b\n' "${approaching[@]}"
        echo ""
    fi
    
    if [[ ${#overdue[@]} -eq 0 && ${#critical[@]} -eq 0 && ${#urgent[@]} -eq 0 && ${#upcoming[@]} -eq 0 ]]; then
        echo "✓ No deadlines within $alert_days days"
        echo ""
    fi
    
    echo "Data file: $DEADLINE_FILE"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
}

# Add new deadline
add_deadline() {
    local type="$1"
    local account="$2"
    local deadline="$3"
    local description="$4"
    local amount="${5:-0}"
    local severity="${6:-medium}"
    
    # Generate ID
    local id="${type}_${account}_$(echo $deadline | tr -d '-')"
    
    # Add to deadlines array
    jq --arg id "$id" \
       --arg type "$type" \
       --arg acct "$account" \
       --arg date "$deadline" \
       --arg desc "$description" \
       --argjson amt "$amount" \
       --arg sev "$severity" \
       '.deadlines += [{
           id: $id,
           type: $type,
           category: $type,
           deadline: $date,
           severity: $sev,
           description: $desc,
           account: $acct,
           amount: $amt,
           recurring: false
       }]' "$DEADLINE_FILE" > "${DEADLINE_FILE}.tmp" && mv "${DEADLINE_FILE}.tmp" "$DEADLINE_FILE"
    
    echo "✓ Added deadline: $description ($deadline)"
}

# Remove deadline
remove_deadline() {
    local id="$1"
    
    jq --arg id "$id" '.deadlines |= map(select(.id != $id))' \
       "$DEADLINE_FILE" > "${DEADLINE_FILE}.tmp" && mv "${DEADLINE_FILE}.tmp" "$DEADLINE_FILE"
    
    echo "✓ Removed deadline: $id"
}

# List all deadlines
list_all() {
    echo ""
    echo "ALL DEADLINES:"
    echo ""
    
    jq -r '.deadlines[] | 
        [.id, .type, .deadline, .severity, .description] | @tsv
    ' "$DEADLINE_FILE" | while IFS=$'\t' read -r id type deadline severity desc; do
        local days_remaining=$(days_until "$deadline")
        printf "%-30s %-20s %-12s %-10s %4d days  %s\n" \
            "$id" "$type" "$deadline" "$severity" "$days_remaining" "$desc"
    done
    
    echo ""
}

# Generate JSON summary
generate_json_summary() {
    local alert_days="${1:-7}"
    local today=$(date +%Y-%m-%d)
    
    # Create summary with categorized deadlines
    jq --arg date "$today" --argjson days "$alert_days" '
        .check_date = $date |
        .alert_window_days = $days |
        .summary = {
            overdue: [],
            critical: [],
            urgent: [],
            upcoming: [],
            approaching: []
        } |
        .deadlines[] |= (
            . + {
                days_remaining: (
                    ((. deadline | fromdateiso8601) - ($date | fromdateiso8601)) / 86400 | floor
                ),
                urgency: (
                    ((. deadline | fromdateiso8601) - ($date | fromdateiso8601)) / 86400 | floor |
                    if . <= 0 then "overdue"
                    elif . <= 3 then "critical"
                    elif . <= 7 then "urgent"
                    elif . <= 14 then "upcoming"
                    elif . <= 30 then "approaching"
                    else "future"
                    end
                )
            }
        )
    ' "$DEADLINE_FILE" > "${DEADLINE_FILE}.tmp" && mv "${DEADLINE_FILE}.tmp" "$DEADLINE_FILE"
}

# Main
main() {
    init_deadlines
    
    local alert_days=7
    local filter_type="all"
    
    if [[ $# -eq 0 ]]; then
        monitor_deadlines "$alert_days" "$filter_type"
        exit 0
    fi
    
    case "${1:-}" in
        --alert-days)
            if [[ $# -lt 2 ]]; then
                echo "Error: --alert-days requires DAYS"
                exit 1
            fi
            alert_days="$2"
            shift 2
            monitor_deadlines "$alert_days" "${1:-all}"
            ;;
        --type)
            if [[ $# -lt 2 ]]; then
                echo "Error: --type requires TYPE"
                exit 1
            fi
            filter_type="$2"
            monitor_deadlines "$alert_days" "$filter_type"
            ;;
        --add)
            if [[ $# -lt 5 ]]; then
                echo "Error: --add requires TYPE ACCOUNT DATE DESCRIPTION [AMOUNT] [SEVERITY]"
                exit 1
            fi
            add_deadline "$2" "$3" "$4" "$5" "${6:-0}" "${7:-medium}"
            monitor_deadlines "$alert_days" "all"
            ;;
        --remove)
            if [[ $# -lt 2 ]]; then
                echo "Error: --remove requires ID"
                exit 1
            fi
            remove_deadline "$2"
            ;;
        --list)
            list_all
            ;;
        --show)
            monitor_deadlines "$alert_days" "all"
            ;;
        --json)
            generate_json_summary "${2:-7}"
            cat "$DEADLINE_FILE"
            ;;
        --help)
            head -n 20 "$0" | tail -n +3
            ;;
        *)
            echo "Error: Unknown option: $1"
            echo "Run with --help for usage"
            exit 1
            ;;
    esac
}

main "$@"
