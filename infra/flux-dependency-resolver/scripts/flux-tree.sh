#!/bin/bash
# flux-tree.sh - Visualize Flux Kustomization dependency tree
# Part of flux-dependency-resolver skill v1.0.0

set -euo pipefail

# Configuration
NAMESPACE="${FLUX_NAMESPACE:-flux-system}"
ALL_NAMESPACES="${FLUX_ALL_NAMESPACES:-false}"
SHOW_STATUS="${FLUX_SHOW_STATUS:-true}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check dependencies
for cmd in kubectl jq; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd not found in PATH" >&2
        exit 1
    fi
done

# Get status symbol
get_status_symbol() {
    local status="$1"
    local reason="$2"
    
    case "$status" in
        "True")
            echo -e "${GREEN}✓${NC}"
            ;;
        "False")
            echo -e "${RED}✗${NC}"
            ;;
        "Unknown")
            echo -e "${YELLOW}○${NC}"
            ;;
        *)
            echo -e "${YELLOW}⧗${NC}"
            ;;
    esac
}

# Get status text
get_status_text() {
    local status="$1"
    local reason="$2"
    
    if [ "$status" = "True" ]; then
        echo "Ready"
    elif [ "$status" = "False" ]; then
        echo "$reason"
    elif [ -n "$reason" ]; then
        echo "$reason"
    else
        echo "Unknown"
    fi
}

# Build tree structure
build_tree() {
    local kust_data="$1"
    local name="$2"
    local namespace="$3"
    local prefix="$4"
    local is_last="$5"
    local visited="$6"
    local depth="${7:-0}"
    
    # Prevent infinite recursion
    if [ "$depth" -gt 20 ]; then
        return
    fi
    
    local key="${namespace}/${name}"
    
    # Check if already visited (circular dependency)
    if echo "$visited" | grep -q ",$key,"; then
        echo "${prefix}[CIRCULAR: $name]"
        return
    fi
    
    visited="$visited,$key,"
    
    # Get Kustomization data
    local kust=$(echo "$kust_data" | jq -r --arg n "$name" --arg ns "$namespace" \
        '.items[] | select(.metadata.name==$n and .metadata.namespace==$ns)')
    
    if [ -z "$kust" ] || [ "$kust" = "null" ]; then
        echo "${prefix}${name} (not found)"
        return
    fi
    
    local ready=$(echo "$kust" | jq -r '.status.conditions[]? | select(.type=="Ready") | .status // "Unknown"')
    local reason=$(echo "$kust" | jq -r '.status.conditions[]? | select(.type=="Ready") | .reason // ""')
    local dependencies=$(echo "$kust" | jq -r '.spec.dependsOn[]? | .name' 2>/dev/null || echo "")
    
    local status_symbol=$(get_status_symbol "$ready" "$reason")
    local status_text=$(get_status_text "$ready" "$reason")
    
    # Print this node
    if [ "$ready" != "True" ] && [ -n "$reason" ]; then
        echo -e "${prefix}${name} (${status_text}) ${status_symbol}"
    else
        echo -e "${prefix}${name} (${status_text}) ${status_symbol}"
    fi
    
    # Get dependents (children)
    local dependents=$(echo "$kust_data" | jq -r --arg n "$name" --arg ns "$namespace" \
        '[.items[] | select(.spec.dependsOn[]? | select(.name==$n) and select(.metadata.namespace==$ns)) | .metadata.name] | .[]' 2>/dev/null || echo "")
    
    if [ -z "$dependents" ]; then
        return
    fi
    
    # Convert to array
    local deps_array=()
    while IFS= read -r dep; do
        [ -z "$dep" ] && continue
        deps_array+=("$dep")
    done <<< "$dependents"
    
    # Print dependents
    local count=${#deps_array[@]}
    local i=0
    
    for dep in "${deps_array[@]}"; do
        i=$((i + 1))
        local is_last_child="false"
        [ $i -eq $count ] && is_last_child="true"
        
        local child_prefix
        if [ "$is_last_child" = "true" ]; then
            if [ "$is_last" = "true" ]; then
                child_prefix="${prefix}    "
            else
                child_prefix="${prefix}│   "
            fi
            build_tree "$kust_data" "$dep" "$namespace" "${prefix}└── " "true" "$visited" $((depth + 1))
        else
            if [ "$is_last" = "true" ]; then
                child_prefix="${prefix}    "
            else
                child_prefix="${prefix}│   "
            fi
            build_tree "$kust_data" "$dep" "$namespace" "${prefix}├── " "false" "$visited" $((depth + 1))
        fi
    done
}

# Find root Kustomizations (no dependencies)
find_roots() {
    local kust_data="$1"
    echo "$kust_data" | jq -r '.items[] | select(.spec.dependsOn == null or (.spec.dependsOn | length == 0)) | .metadata.name'
}

# Find blockers
find_blockers() {
    local kust_data="$1"
    echo "$kust_data" | jq -c '.items[] | 
        select(.status.conditions[]? | select(.type=="Ready" and .status!="True")) |
        {
            name: .metadata.name,
            namespace: .metadata.namespace,
            reason: (.status.conditions[] | select(.type=="Ready") | .reason),
            message: (.status.conditions[] | select(.type=="Ready") | .message)
        }'
}

# Count dependents
count_blocking() {
    local kust_data="$1"
    local blocker_name="$2"
    local namespace="$3"
    
    echo "$kust_data" | jq --arg n "$blocker_name" --arg ns "$namespace" \
        '[.. | select(.dependsOn[]? | select(.name==$n))] | length'
}

# Main execution
main() {
    # Get all Kustomizations
    local kust_data
    if [ "$ALL_NAMESPACES" = "true" ]; then
        kust_data=$(kubectl get kustomizations --all-namespaces -o json 2>/dev/null || echo '{"items":[]}')
    else
        kust_data=$(kubectl get kustomizations -n "$NAMESPACE" -o json 2>/dev/null || echo '{"items":[]}')
    fi
    
    local total=$(echo "$kust_data" | jq '.items | length')
    
    if [ "$total" -eq 0 ]; then
        echo "No Kustomizations found in namespace: $NAMESPACE"
        exit 1
    fi
    
    echo "Flux Kustomization Dependency Tree"
    echo "==================================="
    echo ""
    
    # Find and print root Kustomizations
    local roots
    roots=$(find_roots "$kust_data")
    
    if [ -z "$roots" ]; then
        echo "Warning: No root Kustomizations found (all have dependencies)"
        echo "This may indicate a circular dependency"
        echo ""
        # Print all as roots
        roots=$(echo "$kust_data" | jq -r '.items[].metadata.name')
    fi
    
    local first=true
    while IFS= read -r root; do
        [ -z "$root" ] && continue
        [ "$first" = "false" ] && echo ""
        build_tree "$kust_data" "$root" "$NAMESPACE" "" "true" "," 0
        first=false
    done <<< "$roots"
    
    echo ""
    echo "Legend:"
    echo -e "  ${GREEN}✓${NC} = Ready"
    echo -e "  ${RED}✗${NC} = Failed"
    echo -e "  ${YELLOW}⧗${NC} = Pending/Progressing"
    echo -e "  ${YELLOW}○${NC} = Unknown"
    echo ""
    
    # Find blockers
    local blockers
    blockers=$(find_blockers "$kust_data")
    
    if [ -n "$blockers" ] && [ "$blockers" != "null" ]; then
        echo -e "${RED}ROOT BLOCKERS DETECTED:${NC}"
        echo ""
        while IFS= read -r blocker; do
            [ -z "$blocker" ] && continue
            local name=$(echo "$blocker" | jq -r '.name')
            local reason=$(echo "$blocker" | jq -r '.reason')
            local message=$(echo "$blocker" | jq -r '.message')
            local blocking_count=$(count_blocking "$kust_data" "$name" "$NAMESPACE")
            
            if [ "$blocking_count" -gt 0 ]; then
                echo -e "${RED}ROOT BLOCKER:${NC} $name"
                echo "  Reason: $reason"
                echo "  Message: $message"
                echo "  Blocking: $blocking_count Kustomization(s)"
                echo ""
            fi
        done <<< "$blockers"
        
        echo -e "${YELLOW}ACTION REQUIRED: Fix root blockers to unblock dependents${NC}"
        echo ""
    fi
    
    # Summary
    local ready=$(echo "$kust_data" | jq '[.items[] | select(.status.conditions[]? | select(.type=="Ready" and .status=="True"))] | length')
    local failed=$(echo "$kust_data" | jq '[.items[] | select(.status.conditions[]? | select(.type=="Ready" and .status=="False"))] | length')
    local pending=$((total - ready - failed))
    
    echo "Summary:"
    echo "  Total: $total Kustomizations"
    echo -e "  Ready: ${GREEN}$ready${NC}"
    if [ "$failed" -gt 0 ]; then
        echo -e "  Failed: ${RED}$failed${NC}"
    else
        echo "  Failed: $failed"
    fi
    if [ "$pending" -gt 0 ]; then
        echo -e "  Pending: ${YELLOW}$pending${NC}"
    else
        echo "  Pending: $pending"
    fi
}

# Run main
main "$@"
