#!/usr/bin/env bash
# cluster-health.sh — Quick cluster health check for Flux-managed clusters
# Usage: ./cluster-health.sh [--json]

set -euo pipefail

JSON_OUTPUT=false
[[ "${1:-}" == "--json" ]] && JSON_OUTPUT=true

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
ISSUES=0

header() { echo -e "\n${YELLOW}=== $1 ===${NC}"; }
ok() { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; ISSUES=$((ISSUES + 1)); }
fail() { echo -e "  ${RED}✗${NC} $1"; ISSUES=$((ISSUES + 1)); }

if $JSON_OUTPUT; then
    results="{}"
fi

# --- Node Health ---
if ! $JSON_OUTPUT; then
    header "Nodes"
    NOT_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -cv " Ready " || true)
    TOTAL_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    if [[ "$NOT_READY" -gt 0 ]]; then
        fail "$NOT_READY/$TOTAL_NODES nodes not ready"
        kubectl get nodes --no-headers | grep -v " Ready "
    else
        ok "All $TOTAL_NODES nodes ready"
    fi
fi

# --- Pod Health ---
if ! $JSON_OUTPUT; then
    header "Pods"
fi

FAILED_PODS=$(kubectl get pods -A --no-headers --field-selector 'status.phase!=Running,status.phase!=Succeeded' 2>/dev/null || true)
FAILED_COUNT=$(echo "$FAILED_PODS" | grep -c . 2>/dev/null || echo 0)

if $JSON_OUTPUT; then
    results=$(echo "$results" | jq --argjson c "$FAILED_COUNT" '.pods_failing = $c')
else
    if [[ "$FAILED_COUNT" -gt 0 && -n "$FAILED_PODS" ]]; then
        fail "$FAILED_COUNT pods not running:"
        echo "$FAILED_PODS" | head -20 | sed 's/^/    /'
    else
        ok "All pods healthy"
    fi
fi

# --- High Restart Pods ---
if ! $JSON_OUTPUT; then
    RESTART_PODS=$(kubectl get pods -A -o json 2>/dev/null | jq -r '
        .items[] |
        select(.status.containerStatuses != null) |
        select(.status.containerStatuses[].restartCount > 5) |
        "\(.metadata.namespace)/\(.metadata.name) restarts=\(.status.containerStatuses[0].restartCount)"
    ' 2>/dev/null || true)

    if [[ -n "$RESTART_PODS" ]]; then
        warn "Pods with high restart counts:"
        echo "$RESTART_PODS" | sed 's/^/    /'
    else
        ok "No pods with excessive restarts"
    fi
fi

# --- Flux Kustomizations ---
if ! $JSON_OUTPUT; then
    header "Flux Kustomizations"
fi

if command -v flux &>/dev/null; then
    FAILED_KS=$(flux get ks -A 2>/dev/null | grep -i false || true)
    FAILED_KS_COUNT=$(echo "$FAILED_KS" | grep -c . 2>/dev/null || echo 0)

    if $JSON_OUTPUT; then
        results=$(echo "$results" | jq --argjson c "$FAILED_KS_COUNT" '.kustomizations_failing = $c')
    else
        TOTAL_KS=$(flux get ks -A 2>/dev/null | tail -n +2 | wc -l)
        if [[ -n "$FAILED_KS" && "$FAILED_KS_COUNT" -gt 0 ]]; then
            fail "$FAILED_KS_COUNT kustomizations not ready:"
            echo "$FAILED_KS" | sed 's/^/    /'
        else
            ok "All $TOTAL_KS kustomizations ready"
        fi
    fi
else
    if ! $JSON_OUTPUT; then
        warn "flux CLI not found — skipping Flux checks"
    fi
fi

# --- Flux HelmReleases ---
if ! $JSON_OUTPUT; then
    header "Flux HelmReleases"
fi

if command -v flux &>/dev/null; then
    FAILED_HR=$(flux get hr -A 2>/dev/null | grep -i false || true)
    FAILED_HR_COUNT=$(echo "$FAILED_HR" | grep -c . 2>/dev/null || echo 0)

    if $JSON_OUTPUT; then
        results=$(echo "$results" | jq --argjson c "$FAILED_HR_COUNT" '.helmreleases_failing = $c')
    else
        TOTAL_HR=$(flux get hr -A 2>/dev/null | tail -n +2 | wc -l)
        if [[ -n "$FAILED_HR" && "$FAILED_HR_COUNT" -gt 0 ]]; then
            fail "$FAILED_HR_COUNT HelmReleases not ready:"
            echo "$FAILED_HR" | sed 's/^/    /'
        else
            ok "All $TOTAL_HR HelmReleases ready"
        fi
    fi
fi

# --- Flux Sources ---
if ! $JSON_OUTPUT; then
    header "Flux Sources"
fi

if command -v flux &>/dev/null; then
    FAILED_SRC=$(flux get sources all -A 2>/dev/null | grep -i false || true)
    FAILED_SRC_COUNT=$(echo "$FAILED_SRC" | grep -c . 2>/dev/null || echo 0)

    if $JSON_OUTPUT; then
        results=$(echo "$results" | jq --argjson c "$FAILED_SRC_COUNT" '.sources_failing = $c')
    else
        if [[ -n "$FAILED_SRC" && "$FAILED_SRC_COUNT" -gt 0 ]]; then
            fail "$FAILED_SRC_COUNT sources not ready:"
            echo "$FAILED_SRC" | sed 's/^/    /'
        else
            ok "All sources healthy"
        fi
    fi
fi

# --- Summary ---
if $JSON_OUTPUT; then
    results=$(echo "$results" | jq --argjson i "$ISSUES" '.total_issues = $i')
    echo "$results" | jq .
else
    header "Summary"
    if [[ "$ISSUES" -gt 0 ]]; then
        echo -e "  ${RED}$ISSUES issue(s) found${NC}"
        exit 1
    else
        echo -e "  ${GREEN}All checks passed${NC}"
        exit 0
    fi
fi
