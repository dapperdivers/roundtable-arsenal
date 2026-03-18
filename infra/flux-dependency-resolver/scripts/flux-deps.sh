#!/bin/bash
# flux-deps.sh - Trace Flux Kustomization dependencies and identify root blockers
# Part of flux-dependency-resolver skill v1.0.0

set -euo pipefail

# Configuration
NAMESPACE="${FLUX_NAMESPACE:-flux-system}"
ALL_NAMESPACES="${FLUX_ALL_NAMESPACES:-false}"
SPECIFIC_KUSTOMIZATION="${FLUX_KUSTOMIZATION:-}"
BLOCKERS_ONLY="${FLUX_BLOCKERS_ONLY:-false}"
OUTPUT_FORMAT="${FLUX_OUTPUT_FORMAT:-json}"
MAX_DEPTH="${FLUX_MAX_DEPTH:-10}"

# Check dependencies
for cmd in kubectl jq; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "{\"error\": \"$cmd not found in PATH\"}" >&2
        exit 1
    fi
done

# Get all Kustomizations
get_kustomizations() {
    if [ "$ALL_NAMESPACES" = "true" ]; then
        kubectl get kustomizations --all-namespaces -o json 2>/dev/null || echo '{"items":[]}'
    else
        kubectl get kustomizations -n "$NAMESPACE" -o json 2>/dev/null || echo '{"items":[]}'
    fi
}

# Parse Kustomization data
parse_kustomization() {
    local kust_json="$1"
    
    echo "$kust_json" | jq -c '{
        name: .metadata.name,
        namespace: .metadata.namespace,
        suspended: (.spec.suspend // false),
        dependencies: ([.spec.dependsOn[]? | .name] // []),
        ready: (.status.conditions[]? | select(.type=="Ready") | .status) // "Unknown",
        reason: (.status.conditions[]? | select(.type=="Ready") | .reason) // "",
        message: (.status.conditions[]? | select(.type=="Ready") | .message) // "",
        last_applied: .status.lastAppliedRevision // "",
        observed_generation: .status.observedGeneration // 0
    }'
}

# Build dependency map
build_dependency_map() {
    local kust_list="$1"
    local dep_map="{}"
    
    while IFS= read -r kust; do
        local name=$(echo "$kust" | jq -r '.name')
        local namespace=$(echo "$kust" | jq -r '.namespace')
        local key="${namespace}/${name}"
        
        dep_map=$(echo "$dep_map" | jq --arg key "$key" --argjson kust "$kust" \
            '. + {($key): $kust}')
    done < <(echo "$kust_list" | jq -c '.items[]')
    
    echo "$dep_map"
}

# Find dependents (reverse lookup)
find_dependents() {
    local dep_map="$1"
    local target_name="$2"
    local target_namespace="$3"
    
    echo "$dep_map" | jq -c --arg name "$target_name" --arg ns "$target_namespace" \
        '[to_entries[] | select(.value.dependencies[] == $name and .value.namespace == $ns) | .value.name]'
}

# Calculate depth (distance from roots)
calculate_depth() {
    local dep_map="$1"
    local name="$2"
    local namespace="$3"
    local visited="$4"
    local current_depth="${5:-0}"
    
    # Prevent infinite recursion
    if [ "$current_depth" -gt "$MAX_DEPTH" ]; then
        echo "$MAX_DEPTH"
        return
    fi
    
    local key="${namespace}/${name}"
    
    # Check if already visited (circular dependency)
    if echo "$visited" | jq -e --arg k "$key" '. | contains([$k])' > /dev/null 2>&1; then
        echo "-1"  # Circular dependency marker
        return
    fi
    
    visited=$(echo "$visited" | jq --arg k "$key" '. + [$k]')
    
    local kust=$(echo "$dep_map" | jq -r --arg k "$key" '.[$k]')
    if [ "$kust" = "null" ]; then
        echo "0"
        return
    fi
    
    local dependencies=$(echo "$kust" | jq -r '.dependencies[]? // empty')
    
    if [ -z "$dependencies" ]; then
        echo "$current_depth"
        return
    fi
    
    local max_dep_depth=0
    while IFS= read -r dep; do
        [ -z "$dep" ] && continue
        local dep_depth=$(calculate_depth "$dep_map" "$dep" "$namespace" "$visited" $((current_depth + 1)))
        if [ "$dep_depth" -gt "$max_dep_depth" ]; then
            max_dep_depth=$dep_depth
        fi
    done <<< "$dependencies"
    
    echo "$max_dep_depth"
}

# Find root blockers
find_root_blockers() {
    local dep_map="$1"
    local blockers="[]"
    
    while IFS= read -r entry; do
        local key=$(echo "$entry" | jq -r '.key')
        local kust=$(echo "$entry" | jq -r '.value')
        
        local name=$(echo "$kust" | jq -r '.name')
        local namespace=$(echo "$kust" | jq -r '.namespace')
        local ready=$(echo "$kust" | jq -r '.ready')
        local reason=$(echo "$kust" | jq -r '.reason')
        local message=$(echo "$kust" | jq -r '.message')
        
        # Only interested in non-ready Kustomizations
        if [ "$ready" != "True" ] && [ "$ready" != "Unknown" ]; then
            # Find what this blocks
            local dependents=$(find_dependents "$dep_map" "$name" "$namespace")
            local blocks_count=$(echo "$dependents" | jq 'length')
            
            if [ "$blocks_count" -gt 0 ]; then
                blockers=$(echo "$blockers" | jq --arg n "$name" --arg ns "$namespace" \
                    --arg r "$reason" --arg m "$message" --argjson bc "$blocks_count" \
                    --argjson deps "$dependents" \
                    '. + [{
                        name: $n,
                        namespace: $ns,
                        status: "False",
                        reason: $r,
                        message: $m,
                        blocks_count: $bc,
                        blocked_kustomizations: $deps
                    }]')
            fi
        fi
    done < <(echo "$dep_map" | jq -c 'to_entries[]')
    
    echo "$blockers"
}

# Detect circular dependencies
detect_circular_dependencies() {
    local dep_map="$1"
    local circular="[]"
    
    while IFS= read -r entry; do
        local key=$(echo "$entry" | jq -r '.key')
        local kust=$(echo "$entry" | jq -r '.value')
        local name=$(echo "$kust" | jq -r '.name')
        local namespace=$(echo "$kust" | jq -r '.namespace')
        
        local depth=$(calculate_depth "$dep_map" "$name" "$namespace" "[]" 0)
        
        if [ "$depth" = "-1" ]; then
            circular=$(echo "$circular" | jq --arg n "$name" --arg ns "$namespace" \
                '. + [{name: $n, namespace: $ns}]')
        fi
    done < <(echo "$dep_map" | jq -c 'to_entries[]')
    
    echo "$circular"
}

# Build dependency chains
build_dependency_chains() {
    local dep_map="$1"
    local chains="[]"
    
    while IFS= read -r entry; do
        local key=$(echo "$entry" | jq -r '.key')
        local kust=$(echo "$entry" | jq -r '.value')
        
        local name=$(echo "$kust" | jq -r '.name')
        local namespace=$(echo "$kust" | jq -r '.namespace')
        local ready=$(echo "$kust" | jq -r '.ready')
        local reason=$(echo "$kust" | jq -r '.reason')
        local dependencies=$(echo "$kust" | jq -c '.dependencies')
        local dependents=$(find_dependents "$dep_map" "$name" "$namespace")
        local depth=$(calculate_depth "$dep_map" "$name" "$namespace" "[]" 0)
        local is_root=$([ $(echo "$dependencies" | jq 'length') -eq 0 ] && echo "true" || echo "false")
        local blocks_count=$(echo "$dependents" | jq 'length')
        
        local chain=$(jq -n --arg n "$name" --arg ns "$namespace" --arg s "$ready" \
            --arg r "$reason" --argjson deps "$dependencies" --argjson depts "$dependents" \
            --arg root "$is_root" --argjson d "$depth" --argjson bc "$blocks_count" \
            '{
                name: $n,
                namespace: $ns,
                status: $s,
                reason: $r,
                dependencies: $deps,
                dependents: $depts,
                is_root: ($root | test("true")),
                depth: $d,
                blocks: $bc
            }')
        
        if [ "$ready" != "True" ] && [ "$blocks_count" -gt 0 ]; then
            local blocked=$(echo "$dependents" | jq -c .)
            chain=$(echo "$chain" | jq --argjson bl "$blocked" '. + {blocked_resources: $bl}')
        fi
        
        chains=$(echo "$chains" | jq --argjson c "$chain" '. + [$c]')
    done < <(echo "$dep_map" | jq -c 'to_entries[]')
    
    echo "$chains"
}

# Generate issues
generate_issues() {
    local root_blockers="$1"
    local circular="$2"
    local issues="[]"
    
    # Add root blocker issues
    while IFS= read -r blocker; do
        local name=$(echo "$blocker" | jq -r '.name')
        local message=$(echo "$blocker" | jq -r '.message')
        local blocks=$(echo "$blocker" | jq -r '.blocked_kustomizations | join(", ")')
        local blocks_count=$(echo "$blocker" | jq -r '.blocks_count')
        
        issues=$(echo "$issues" | jq --arg n "$name" --arg m "$message" --arg b "$blocks" \
            --argjson bc "$blocks_count" \
            '. + [{
                severity: "critical",
                kustomization: $n,
                description: ("Root blocker preventing " + ($bc | tostring) + " dependent Kustomizations from reconciling"),
                cause: $m,
                impact: ("Blocks: " + $b),
                remediation: "Fix \($n) deployment, then Flux will automatically reconcile dependents"
            }]')
    done < <(echo "$root_blockers" | jq -c '.[]')
    
    # Add circular dependency issues
    if [ "$(echo "$circular" | jq 'length')" -gt 0 ]; then
        local cycle=$(echo "$circular" | jq -r '[.[] | .name] | join(" → ")')
        issues=$(echo "$issues" | jq --arg c "$cycle" \
            '. + [{
                severity: "error",
                type: "circular_dependency",
                description: "Circular dependency detected",
                cycle: $c,
                remediation: "Remove one of the dependsOn references to break the cycle"
            }]')
    fi
    
    echo "$issues"
}

# Generate recommendations
generate_recommendations() {
    local root_blockers="$1"
    local healthy_count="$2"
    local total_count="$3"
    local recommendations="[]"
    
    if [ "$(echo "$root_blockers" | jq 'length')" -eq 0 ]; then
        if [ "$healthy_count" -eq "$total_count" ]; then
            recommendations=$(echo "$recommendations" | jq '. + ["All Kustomizations healthy - no action required"]')
        else
            recommendations=$(echo "$recommendations" | jq '. + ["Some Kustomizations not ready but no root blockers detected - check individual status"]')
        fi
    else
        while IFS= read -r blocker; do
            local name=$(echo "$blocker" | jq -r '.name')
            recommendations=$(echo "$recommendations" | jq --arg n "$name" \
                '. + ["Priority: Fix \($n) to unblock downstream Kustomizations"]')
        done < <(echo "$root_blockers" | jq -c '.[]')
    fi
    
    echo "$recommendations"
}

# Main execution
main() {
    local cluster_name
    cluster_name=$(kubectl config current-context 2>/dev/null || echo "unknown")
    
    # Get all Kustomizations
    local kust_list
    kust_list=$(get_kustomizations)
    
    local total=$(echo "$kust_list" | jq '.items | length')
    
    if [ "$total" -eq 0 ]; then
        echo "{\"error\": \"No Kustomizations found\", \"namespace\": \"$NAMESPACE\"}" >&2
        exit 1
    fi
    
    # Build dependency map
    local dep_map
    dep_map=$(build_dependency_map "$kust_list")
    
    # Calculate statistics
    local healthy=$(echo "$kust_list" | jq '[.items[] | select(.status.conditions[]? | select(.type=="Ready" and .status=="True"))] | length')
    local unhealthy=$(echo "$kust_list" | jq '[.items[] | select(.status.conditions[]? | select(.type=="Ready" and .status!="True"))] | length')
    
    # Find root blockers
    local root_blockers
    root_blockers=$(find_root_blockers "$dep_map")
    
    # Detect circular dependencies
    local circular
    circular=$(detect_circular_dependencies "$dep_map")
    
    # Build dependency chains
    local chains
    chains=$(build_dependency_chains "$dep_map")
    
    # Generate issues and recommendations
    local issues
    issues=$(generate_issues "$root_blockers" "$circular")
    
    local recommendations
    recommendations=$(generate_recommendations "$root_blockers" "$healthy" "$total")
    
    # Filter if specific Kustomization requested
    if [ -n "$SPECIFIC_KUSTOMIZATION" ]; then
        chains=$(echo "$chains" | jq --arg n "$SPECIFIC_KUSTOMIZATION" '[.[] | select(.name==$n)]')
        root_blockers=$(echo "$root_blockers" | jq --arg n "$SPECIFIC_KUSTOMIZATION" '[.[] | select(.name==$n)]')
    fi
    
    # Filter if blockers only
    if [ "$BLOCKERS_ONLY" = "true" ]; then
        chains=$(echo "$chains" | jq '[.[] | select(.status!="True" and .blocks > 0)]')
    fi
    
    # Build output
    jq -n --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" --arg cluster "$cluster_name" \
        --arg ns "$NAMESPACE" --argjson total "$total" --argjson healthy "$healthy" \
        --argjson unhealthy "$unhealthy" --argjson blockers "$root_blockers" \
        --argjson chains "$chains" --argjson issues "$issues" --argjson recs "$recommendations" \
        '{
            timestamp: $ts,
            cluster: $cluster,
            namespace: $ns,
            total_kustomizations: $total,
            healthy: $healthy,
            unhealthy: $unhealthy,
            pending: ($total - $healthy),
            root_blockers: $blockers,
            dependency_chains: $chains,
            issues: $issues,
            recommendations: $recs
        }'
}

# Run main
main "$@"
