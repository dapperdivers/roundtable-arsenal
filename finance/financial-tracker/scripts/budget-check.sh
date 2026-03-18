#!/bin/bash
#
# budget-check.sh - Compare actual spending vs budget by category
#
# Usage:
#   ./budget-check.sh [OPTIONS]
#
# Options:
#   --category CATEGORY    Show specific category only
#   --period week|month    Time period (default: week)
#   --add-expense CATEGORY AMOUNT DESCRIPTION  Log an expense
#   --show                 Display budget status
#   --help                 Show this help
#
# Example:
#   ./budget-check.sh --period week
#   ./budget-check.sh --add-expense groceries 45.23 "Walmart"
#   ./budget-check.sh --category debt_payments
#

set -euo pipefail

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$SKILL_DIR/data"
CONFIG_DIR="$SKILL_DIR/config"

mkdir -p "$DATA_DIR" "$CONFIG_DIR"

BUDGET_FILE="$DATA_DIR/budget-state.json"
TRANSACTIONS_DIR="$DATA_DIR/transactions"

mkdir -p "$TRANSACTIONS_DIR"

# Initialize budget file if doesn't exist
init_budget() {
    if [[ ! -f "$BUDGET_FILE" ]]; then
        # Get current week period
        local start_date=$(date -d "last monday" +%Y-%m-%d 2>/dev/null || date -v-mon +%Y-%m-%d)
        local end_date=$(date -d "next sunday" +%Y-%m-%d 2>/dev/null || date -v+sun +%Y-%m-%d)
        local period="${start_date}_to_${end_date}"
        
        cat > "$BUDGET_FILE" << EOF
{
  "period": "$period",
  "period_type": "week",
  "start_date": "$start_date",
  "end_date": "$end_date",
  "categories": {
    "groceries": {
      "budgeted": 200.00,
      "spent": 0.00,
      "remaining": 200.00,
      "percentage_used": 0.00,
      "status": "on_track",
      "transactions": []
    },
    "gas": {
      "budgeted": 75.00,
      "spent": 0.00,
      "remaining": 75.00,
      "percentage_used": 0.00,
      "status": "on_track",
      "transactions": []
    },
    "debt_payments": {
      "budgeted": 1400.00,
      "spent": 0.00,
      "remaining": 1400.00,
      "percentage_used": 0.00,
      "status": "on_track",
      "transactions": []
    },
    "utilities": {
      "budgeted": 150.00,
      "spent": 0.00,
      "remaining": 150.00,
      "percentage_used": 0.00,
      "status": "on_track",
      "transactions": []
    },
    "subscriptions": {
      "budgeted": 120.00,
      "spent": 0.00,
      "remaining": 120.00,
      "percentage_used": 0.00,
      "status": "on_track",
      "transactions": []
    },
    "household": {
      "budgeted": 100.00,
      "spent": 0.00,
      "remaining": 100.00,
      "percentage_used": 0.00,
      "status": "on_track",
      "transactions": []
    },
    "dining": {
      "budgeted": 150.00,
      "spent": 0.00,
      "remaining": 150.00,
      "percentage_used": 0.00,
      "status": "on_track",
      "transactions": []
    },
    "entertainment": {
      "budgeted": 50.00,
      "spent": 0.00,
      "remaining": 50.00,
      "percentage_used": 0.00,
      "status": "on_track",
      "transactions": []
    },
    "baby_prep": {
      "budgeted": 100.00,
      "spent": 0.00,
      "remaining": 100.00,
      "percentage_used": 0.00,
      "status": "on_track",
      "transactions": []
    },
    "miscellaneous": {
      "budgeted": 100.00,
      "spent": 0.00,
      "remaining": 100.00,
      "percentage_used": 0.00,
      "status": "on_track",
      "transactions": []
    }
  },
  "totals": {
    "total_budgeted": 2445.00,
    "total_spent": 0.00,
    "total_remaining": 2445.00,
    "percentage_used": 0.00
  }
}
EOF
    fi
}

# Recalculate all budget totals
recalculate_budget() {
    local budget_file="$1"
    
    jq '
        .categories |= with_entries(
            .value.spent as $spent |
            .value.budgeted as $budgeted |
            .value.remaining = ($budgeted - $spent) |
            .value.percentage_used = (if $budgeted > 0 then (($spent / $budgeted) * 100) else 0 end) |
            .value.percentage_used = (.value.percentage_used | tonumber | . * 100 | round / 100) |
            .value.status = (
                if .value.percentage_used >= 100 then "over_budget"
                elif .value.percentage_used >= 90 then "warning"
                elif .value.percentage_used >= 75 then "watch"
                else "on_track"
                end
            )
        ) |
        .totals.total_budgeted = ([.categories[].budgeted] | add) |
        .totals.total_spent = ([.categories[].spent] | add) |
        .totals.total_remaining = (.totals.total_budgeted - .totals.total_spent) |
        .totals.percentage_used = (if .totals.total_budgeted > 0 then ((.totals.total_spent / .totals.total_budgeted) * 100) else 0 end) |
        .totals.percentage_used = (.totals.percentage_used | tonumber | . * 100 | round / 100) |
        
        # Round all monetary values
        .categories |= with_entries(
            .value.spent = (.value.spent | tonumber | . * 100 | round / 100) |
            .value.remaining = (.value.remaining | tonumber | . * 100 | round / 100)
        ) |
        .totals.total_budgeted = (.totals.total_budgeted | tonumber | . * 100 | round / 100) |
        .totals.total_spent = (.totals.total_spent | tonumber | . * 100 | round / 100) |
        .totals.total_remaining = (.totals.total_remaining | tonumber | . * 100 | round / 100)
    ' "$budget_file" > "${budget_file}.tmp" && mv "${budget_file}.tmp" "$budget_file"
}

# Add expense to category
add_expense() {
    local category="$1"
    local amount="$2"
    local description="$3"
    
    local date=$(date +%Y-%m-%d)
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # Check if category exists
    if ! jq -e ".categories.$category" "$BUDGET_FILE" > /dev/null 2>&1; then
        echo "Error: Category '$category' not found"
        echo "Available categories:"
        jq -r '.categories | keys[]' "$BUDGET_FILE"
        exit 1
    fi
    
    # Add transaction to category
    jq --arg cat "$category" \
       --arg date "$date" \
       --arg ts "$timestamp" \
       --argjson amt "$amount" \
       --arg desc "$description" \
       '.categories[$cat].transactions += [{
           date: $date,
           timestamp: $ts,
           amount: $amt,
           description: $desc
       }] |
       .categories[$cat].spent = ([.categories[$cat].transactions[].amount] | add)
    ' "$BUDGET_FILE" > "${BUDGET_FILE}.tmp" && mv "${BUDGET_FILE}.tmp" "$BUDGET_FILE"
    
    # Recalculate totals
    recalculate_budget "$BUDGET_FILE"
    
    # Log to transactions file
    local trans_file="$TRANSACTIONS_DIR/$(date +%Y-%m).log"
    echo "[$timestamp] $category | \$$amount | $description" >> "$trans_file"
    
    echo "✓ Logged expense: $category - \$$amount - $description"
    
    # Show updated category
    show_category "$category"
}

# Show specific category
show_category() {
    local category="$1"
    
    local budgeted=$(jq -r ".categories.$category.budgeted" "$BUDGET_FILE")
    local spent=$(jq -r ".categories.$category.spent" "$BUDGET_FILE")
    local remaining=$(jq -r ".categories.$category.remaining" "$BUDGET_FILE")
    local pct=$(jq -r ".categories.$category.percentage_used" "$BUDGET_FILE")
    local status=$(jq -r ".categories.$category.status" "$BUDGET_FILE")
    
    echo ""
    echo "CATEGORY: $category"
    echo "  Budgeted:  \$$budgeted"
    echo "  Spent:     \$$spent"
    echo "  Remaining: \$$remaining"
    echo "  Used:      ${pct}%"
    echo "  Status:    $status"
    echo ""
}

# Display full budget report
show_budget() {
    local budget_file="$1"
    
    local period=$(jq -r '.period' "$budget_file")
    local period_type=$(jq -r '.period_type' "$budget_file")
    
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "           BUDGET REPORT - $(echo $period_type | tr '[:lower:]' '[:upper:]')"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Period: $period"
    echo ""
    
    # Header
    printf "%-20s %10s %10s %10s %8s  %s\n" "CATEGORY" "BUDGET" "SPENT" "REMAINING" "% USED" "STATUS"
    echo "─────────────────────────────────────────────────────────────────────────"
    
    # Categories
    jq -r '.categories | to_entries[] | 
        .key as $cat |
        .value.budgeted as $budgeted |
        .value.spent as $spent |
        .value.remaining as $remaining |
        .value.percentage_used as $pct |
        .value.status as $status |
        [$cat, $budgeted, $spent, $remaining, $pct, $status] | @tsv
    ' "$budget_file" | while IFS=$'\t' read -r cat budgeted spent remaining pct status; do
        local status_icon
        case "$status" in
            on_track) status_icon="✓" ;;
            watch) status_icon="⚠" ;;
            warning) status_icon="⚠⚠" ;;
            over_budget) status_icon="❌" ;;
            *) status_icon="?" ;;
        esac
        
        printf "%-20s \$%9.2f \$%9.2f \$%9.2f %7.1f%%  %s %s\n" \
            "$cat" "$budgeted" "$spent" "$remaining" "$pct" "$status_icon" "$status"
    done
    
    echo "─────────────────────────────────────────────────────────────────────────"
    
    # Totals
    local total_budgeted=$(jq -r '.totals.total_budgeted' "$budget_file")
    local total_spent=$(jq -r '.totals.total_spent' "$budget_file")
    local total_remaining=$(jq -r '.totals.total_remaining' "$budget_file")
    local total_pct=$(jq -r '.totals.percentage_used' "$budget_file")
    
    printf "%-20s \$%9.2f \$%9.2f \$%9.2f %7.1f%%\n" \
        "TOTAL" "$total_budgeted" "$total_spent" "$total_remaining" "$total_pct"
    
    echo ""
    
    # Warnings
    local warnings=$(jq -r '.categories | to_entries[] | select(.value.status == "warning" or .value.status == "over_budget") | 
        "⚠ " + (.key | gsub("_"; " ") | ascii_upcase) + ": " + (.value.percentage_used | tostring) + "% of budget used"
    ' "$budget_file")
    
    if [[ -n "$warnings" ]]; then
        echo "ALERTS:"
        echo "$warnings"
        echo ""
    fi
    
    # Overall status
    if (( $(echo "$total_pct < 80" | bc -l) )); then
        echo "✓ Overall spending pace is healthy"
    elif (( $(echo "$total_pct < 95" | bc -l) )); then
        echo "⚠ Overall spending approaching budget limit"
    else
        echo "❌ Overall spending at or over budget"
    fi
    
    echo ""
    echo "Data file: $budget_file"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
}

# Reset budget for new period
reset_period() {
    local period_type="${1:-week}"
    
    # Archive current budget
    local archive_file="$DATA_DIR/archive/budget-$(jq -r '.period' "$BUDGET_FILE").json"
    mkdir -p "$DATA_DIR/archive"
    cp "$BUDGET_FILE" "$archive_file"
    echo "✓ Archived current budget to $archive_file"
    
    # Calculate new period dates
    local start_date end_date period
    if [[ "$period_type" == "week" ]]; then
        start_date=$(date -d "next monday" +%Y-%m-%d 2>/dev/null || date -v+mon +%Y-%m-%d)
        end_date=$(date -d "next sunday + 7 days" +%Y-%m-%d 2>/dev/null || date -v+sun -v+7d +%Y-%m-%d)
    else
        start_date=$(date -d "first day of next month" +%Y-%m-%d 2>/dev/null || date -v1d -v+1m +%Y-%m-%d)
        end_date=$(date -d "last day of next month" +%Y-%m-%d 2>/dev/null || date -v1d -v+2m -v-1d +%Y-%m-%d)
    fi
    period="${start_date}_to_${end_date}"
    
    # Reset all spent amounts to 0, keep budget amounts
    jq --arg period "$period" \
       --arg start "$start_date" \
       --arg end "$end_date" \
       --arg type "$period_type" \
       '.period = $period |
        .period_type = $type |
        .start_date = $start |
        .end_date = $end |
        .categories |= with_entries(
            .value.spent = 0 |
            .value.remaining = .value.budgeted |
            .value.percentage_used = 0 |
            .value.status = "on_track" |
            .value.transactions = []
        ) |
        .totals.total_spent = 0 |
        .totals.total_remaining = .totals.total_budgeted |
        .totals.percentage_used = 0
    ' "$BUDGET_FILE" > "${BUDGET_FILE}.tmp" && mv "${BUDGET_FILE}.tmp" "$BUDGET_FILE"
    
    echo "✓ Budget reset for new $period_type period: $period"
}

# Main
main() {
    init_budget
    
    if [[ $# -eq 0 ]]; then
        recalculate_budget "$BUDGET_FILE"
        show_budget "$BUDGET_FILE"
        exit 0
    fi
    
    case "${1:-}" in
        --add-expense)
            if [[ $# -lt 4 ]]; then
                echo "Error: --add-expense requires CATEGORY AMOUNT DESCRIPTION"
                exit 1
            fi
            add_expense "$2" "$3" "$4"
            ;;
        --category)
            if [[ $# -lt 2 ]]; then
                echo "Error: --category requires CATEGORY name"
                exit 1
            fi
            show_category "$2"
            ;;
        --period)
            if [[ $# -lt 2 ]]; then
                echo "Error: --period requires week|month"
                exit 1
            fi
            # For now, just show current period
            # Future: could filter to specific period
            show_budget "$BUDGET_FILE"
            ;;
        --reset)
            reset_period "${2:-week}"
            show_budget "$BUDGET_FILE"
            ;;
        --show)
            show_budget "$BUDGET_FILE"
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
