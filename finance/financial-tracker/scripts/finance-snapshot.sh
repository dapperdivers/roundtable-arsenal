#!/bin/bash
#
# finance-snapshot.sh - Generate JSON snapshot of current financial state
#
# Usage:
#   ./finance-snapshot.sh [OPTIONS]
#
# Options:
#   --update-balance ACCOUNT AMOUNT    Update account balance
#   --add-payment ACCOUNT AMOUNT       Record a payment (reduces balance)
#   --set-apr ACCOUNT RATE             Update APR for account
#   --show                             Display current state
#   --help                             Show this help
#
# Example:
#   ./finance-snapshot.sh --update-balance discover 8250.00
#   ./finance-snapshot.sh --add-payment discover 200.00
#   ./finance-snapshot.sh --show
#

set -euo pipefail

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$SKILL_DIR/data"
CONFIG_DIR="$SKILL_DIR/config"

mkdir -p "$DATA_DIR" "$CONFIG_DIR"

STATE_FILE="$DATA_DIR/financial-state.json"
HISTORY_DIR="$DATA_DIR/history"

mkdir -p "$HISTORY_DIR"

# Initialize state file if doesn't exist
init_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        cat > "$STATE_FILE" << 'EOF'
{
  "last_updated": "",
  "total_debt": 0.00,
  "total_daily_interest": 0.00,
  "total_monthly_interest": 0.00,
  "total_annual_interest": 0.00,
  "accounts": {
    "discover": {
      "type": "credit_card",
      "balance": 8400.00,
      "apr": 27.24,
      "daily_interest": 0.00,
      "weekly_interest": 0.00,
      "monthly_interest": 0.00,
      "annual_interest": 0.00,
      "minimum_payment": 167.00,
      "due_date": "2026-04-05",
      "status": "active"
    },
    "wells_fargo_1": {
      "type": "credit_card",
      "balance": 11765.00,
      "apr": 0.00,
      "promo_expires": "2026-04-03",
      "post_promo_apr": 20.00,
      "daily_interest": 0.00,
      "post_promo_daily_interest": 0.00,
      "weekly_interest": 0.00,
      "monthly_interest": 0.00,
      "annual_interest": 0.00,
      "minimum_payment": 125.00,
      "due_date": "2026-03-28",
      "status": "promotional"
    },
    "wells_fargo_2": {
      "type": "credit_card",
      "balance": 9830.00,
      "apr": 26.24,
      "daily_interest": 0.00,
      "weekly_interest": 0.00,
      "monthly_interest": 0.00,
      "annual_interest": 0.00,
      "minimum_payment": 250.00,
      "due_date": "2026-04-11",
      "status": "active"
    },
    "amazon_synchrony": {
      "type": "credit_card",
      "balance": 1800.00,
      "apr": 24.49,
      "daily_interest": 0.00,
      "weekly_interest": 0.00,
      "monthly_interest": 0.00,
      "annual_interest": 0.00,
      "minimum_payment": 50.00,
      "due_date": "2026-04-15",
      "status": "active"
    },
    "chase_business": {
      "type": "credit_card",
      "balance": 0.00,
      "apr": 30.24,
      "daily_interest": 0.00,
      "weekly_interest": 0.00,
      "monthly_interest": 0.00,
      "annual_interest": 0.00,
      "minimum_payment": 0.00,
      "due_date": "",
      "status": "verify_needed"
    },
    "amex": {
      "type": "credit_card",
      "balance": 0.00,
      "apr": 0.00,
      "daily_interest": 0.00,
      "status": "eliminated",
      "eliminated_date": "2026-03-05"
    },
    "auto_loan": {
      "type": "loan",
      "balance": 0.00,
      "apr": 0.00,
      "daily_interest": 0.00,
      "status": "eliminated",
      "eliminated_date": "2026-03-05"
    },
    "chase_personal": {
      "type": "credit_card",
      "balance": 0.00,
      "apr": 0.00,
      "daily_interest": 0.00,
      "status": "eliminated",
      "eliminated_date": "2026-03-12"
    },
    "student_loans": {
      "type": "loan",
      "balance": 48858.96,
      "apr": 6.55,
      "daily_interest": 0.00,
      "monthly_payment": 315.00,
      "status": "pslf_eligible",
      "note": "DO NOT overpay - Public Service Loan Forgiveness eligible"
    },
    "heloc": {
      "type": "line_of_credit",
      "balance": 30000.00,
      "apr": 9.75,
      "daily_interest": 0.00,
      "monthly_payment": 244.00,
      "status": "active"
    }
  },
  "history": []
}
EOF
    fi
}

# Calculate interest for an account
calculate_interest() {
    local balance="$1"
    local apr="$2"
    
    # Daily interest = (Balance × APR) ÷ 365
    local daily=$(echo "scale=2; ($balance * $apr / 100) / 365" | bc)
    local weekly=$(echo "scale=2; $daily * 7" | bc)
    local monthly=$(echo "scale=2; $daily * 30" | bc)
    local annual=$(echo "scale=2; $balance * $apr / 100" | bc)
    
    echo "$daily|$weekly|$monthly|$annual"
}

# Recalculate all interest for all accounts
recalculate_all() {
    local state_file="$1"
    
    # Use jq to iterate accounts and recalculate
    jq --argjson timestamp "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" '
        .last_updated = $timestamp |
        .accounts |= with_entries(
            if .value.status == "active" or .value.status == "promotional" or .value.status == "verify_needed" then
                .value.balance as $bal |
                .value.apr as $apr |
                (($bal * $apr / 100) / 365) as $daily |
                .value.daily_interest = ($daily | tonumber | . * 100 | round / 100) |
                .value.weekly_interest = (($daily * 7) | tonumber | . * 100 | round / 100) |
                .value.monthly_interest = (($daily * 30) | tonumber | . * 100 | round / 100) |
                .value.annual_interest = (($bal * $apr / 100) | tonumber | . * 100 | round / 100) |
                
                # Calculate post-promo interest if promotional
                if .value.status == "promotional" and .value.post_promo_apr then
                    (($bal * .value.post_promo_apr / 100) / 365) as $post_daily |
                    .value.post_promo_daily_interest = ($post_daily | tonumber | . * 100 | round / 100)
                else . end
            else . end
        ) |
        # Calculate totals
        .total_debt = ([.accounts[] | select(.status == "active" or .status == "promotional" or .status == "verify_needed") | .balance] | add) |
        .total_daily_interest = ([.accounts[] | select(.status == "active" or .status == "promotional" or .status == "verify_needed") | .daily_interest] | add) |
        .total_monthly_interest = ([.accounts[] | select(.status == "active" or .status == "promotional" or .status == "verify_needed") | .monthly_interest] | add) |
        .total_annual_interest = ([.accounts[] | select(.status == "active" or .status == "promotional" or .status == "verify_needed") | .annual_interest] | add) |
        
        # Round totals
        .total_debt = (.total_debt | tonumber | . * 100 | round / 100) |
        .total_daily_interest = (.total_daily_interest | tonumber | . * 100 | round / 100) |
        .total_monthly_interest = (.total_monthly_interest | tonumber | . * 100 | round / 100) |
        .total_annual_interest = (.total_annual_interest | tonumber | . * 100 | round / 100)
    ' "$state_file" > "${state_file}.tmp" && mv "${state_file}.tmp" "$state_file"
}

# Update account balance
update_balance() {
    local account="$1"
    local new_balance="$2"
    
    # Update balance in JSON
    jq --arg acct "$account" --argjson bal "$new_balance" '
        .accounts[$acct].balance = $bal
    ' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    
    # Add to history
    add_history "balance_update" "$account" "$new_balance" "Balance updated to \$$new_balance"
    
    # Recalculate everything
    recalculate_all "$STATE_FILE"
    
    echo "✓ Updated $account balance to \$$new_balance"
}

# Add payment (reduces balance)
add_payment() {
    local account="$1"
    local payment_amount="$2"
    
    # Get current balance
    local current_balance=$(jq -r ".accounts.$account.balance" "$STATE_FILE")
    
    # Calculate new balance
    local new_balance=$(echo "$current_balance - $payment_amount" | bc)
    
    # Update balance
    jq --arg acct "$account" --argjson bal "$new_balance" '
        .accounts[$acct].balance = $bal
    ' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    
    # Add to history
    add_history "payment" "$account" "$payment_amount" "Payment of \$$payment_amount applied (balance: \$$current_balance → \$$new_balance)"
    
    # Recalculate everything
    recalculate_all "$STATE_FILE"
    
    echo "✓ Recorded payment of \$$payment_amount to $account"
    echo "  Previous balance: \$$current_balance"
    echo "  New balance: \$$new_balance"
}

# Set APR for account
set_apr() {
    local account="$1"
    local new_apr="$2"
    
    jq --arg acct "$account" --argjson apr "$new_apr" '
        .accounts[$acct].apr = $apr
    ' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    
    add_history "apr_change" "$account" "$new_apr" "APR updated to $new_apr%"
    
    recalculate_all "$STATE_FILE"
    
    echo "✓ Updated $account APR to $new_apr%"
}

# Add entry to history
add_history() {
    local action="$1"
    local account="$2"
    local amount="$3"
    local note="$4"
    
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local date_only=$(date +%Y-%m-%d)
    
    jq --arg ts "$timestamp" \
       --arg action "$action" \
       --arg acct "$account" \
       --argjson amt "$amount" \
       --arg note "$note" \
       '.history += [{
           timestamp: $ts,
           action: $action,
           account: $acct,
           amount: $amt,
           note: $note
       }]' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    
    # Also append to daily history log
    local history_file="$HISTORY_DIR/$date_only.log"
    echo "[$timestamp] $action | $account | \$$amount | $note" >> "$history_file"
}

# Display current state
show_state() {
    local state_file="$1"
    
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "           FINANCIAL STATE SNAPSHOT"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Last Updated: $(jq -r '.last_updated' "$state_file")"
    echo ""
    
    local total_debt=$(jq -r '.total_debt' "$state_file")
    local daily_int=$(jq -r '.total_daily_interest' "$state_file")
    local monthly_int=$(jq -r '.total_monthly_interest' "$state_file")
    local annual_int=$(jq -r '.total_annual_interest' "$state_file")
    
    echo "TOTAL DEBT: \$$total_debt"
    echo "TOTAL DAILY INTEREST: \$$daily_int/day (\$$monthly_int/month, \$$annual_int/year)"
    echo ""
    
    # Active accounts
    echo "ACTIVE ACCOUNTS:"
    jq -r '.accounts | to_entries[] | select(.value.status == "active" or .value.status == "promotional") | 
        "  " + .key + ": $" + (.value.balance | tostring) + " @ " + (.value.apr | tostring) + "% ($" + (.value.daily_interest | tostring) + "/day)" + 
        (if .value.status == "promotional" then " [PROMO ends " + .value.promo_expires + "]" else "" end)
    ' "$state_file"
    
    echo ""
    
    # Eliminated accounts
    echo "ELIMINATED ACCOUNTS:"
    jq -r '.accounts | to_entries[] | select(.value.status == "eliminated") | 
        "  ✅ " + .key + ": $0.00 (paid " + .value.eliminated_date + ")"
    ' "$state_file"
    
    echo ""
    
    # Other debts
    echo "OTHER DEBTS:"
    jq -r '.accounts | to_entries[] | select(.value.status == "pslf_eligible" or .value.type == "line_of_credit") | 
        "  " + .key + ": $" + (.value.balance | tostring) + " @ " + (.value.apr | tostring) + "%" + 
        (if .value.status == "pslf_eligible" then " [PSLF - do not overpay]" else "" end)
    ' "$state_file"
    
    echo ""
    echo "Data file: $state_file"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
}

# Main
main() {
    init_state
    
    if [[ $# -eq 0 ]]; then
        recalculate_all "$STATE_FILE"
        show_state "$STATE_FILE"
        exit 0
    fi
    
    case "${1:-}" in
        --update-balance)
            if [[ $# -lt 3 ]]; then
                echo "Error: --update-balance requires ACCOUNT and AMOUNT"
                exit 1
            fi
            update_balance "$2" "$3"
            show_state "$STATE_FILE"
            ;;
        --add-payment)
            if [[ $# -lt 3 ]]; then
                echo "Error: --add-payment requires ACCOUNT and AMOUNT"
                exit 1
            fi
            add_payment "$2" "$3"
            show_state "$STATE_FILE"
            ;;
        --set-apr)
            if [[ $# -lt 3 ]]; then
                echo "Error: --set-apr requires ACCOUNT and RATE"
                exit 1
            fi
            set_apr "$2" "$3"
            show_state "$STATE_FILE"
            ;;
        --show)
            show_state "$STATE_FILE"
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
