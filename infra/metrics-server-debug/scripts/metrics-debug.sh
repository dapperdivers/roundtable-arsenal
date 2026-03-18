#!/bin/bash
# metrics-debug.sh - Debug metrics-server failures and connectivity issues
# Part of metrics-server-debug skill v1.0.0

set -euo pipefail

# Configuration
NAMESPACE="${METRICS_NAMESPACE:-kube-system}"
DEPLOYMENT="${METRICS_DEPLOYMENT:-metrics-server}"
LOG_LINES="${METRICS_LOG_LINES:-200}"
COMPONENT="${METRICS_DEBUG_COMPONENT:-all}"
OUTPUT_FORMAT="${METRICS_OUTPUT_FORMAT:-json}"

# Check dependencies
for cmd in kubectl jq; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "{\"error\": \"$cmd not found in PATH\"}" >&2
        exit 1
    fi
done

# Initialize results
OVERALL_STATUS="healthy"
CHECKS="{}"
ISSUES="[]"
RECOMMENDATIONS="[]"

# Function to add check result
add_check() {
    local component="$1"
    local result="$2"
    CHECKS=$(echo "$CHECKS" | jq --arg comp "$component" --argjson res "$result" '. + {($comp): $res}')
}

# Function to add issue
add_issue() {
    local severity="$1"
    local component="$2"
    local description="$3"
    local cause="$4"
    local remediation="$5"
    
    ISSUES=$(echo "$ISSUES" | jq --arg sev "$severity" --arg comp "$component" \
        --arg desc "$description" --arg cause "$cause" --arg rem "$remediation" \
        '. + [{severity: $sev, component: $comp, description: $desc, likely_cause: $cause, remediation: $rem}]')
    
    if [ "$severity" = "error" ] || [ "$severity" = "critical" ]; then
        OVERALL_STATUS="failed"
    elif [ "$severity" = "warning" ] && [ "$OVERALL_STATUS" = "healthy" ]; then
        OVERALL_STATUS="degraded"
    fi
}

# Function to add recommendation
add_recommendation() {
    local rec="$1"
    RECOMMENDATIONS=$(echo "$RECOMMENDATIONS" | jq --arg r "$rec" '. + [$r]')
}

# Check deployment
check_deployment() {
    local deploy_json
    if ! deploy_json=$(kubectl get deployment -n "$NAMESPACE" "$DEPLOYMENT" -o json 2>&1); then
        add_check "deployment" "$(jq -n --arg err "$deploy_json" '{status: "not_found", error: $err}')"
        add_issue "critical" "deployment" "Metrics-server deployment not found" \
            "Deployment not created or wrong namespace" \
            "Deploy metrics-server: kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
        return
    fi
    
    local replicas=$(echo "$deploy_json" | jq -r '.status.replicas // 0')
    local ready_replicas=$(echo "$deploy_json" | jq -r '.status.readyReplicas // 0')
    local image=$(echo "$deploy_json" | jq -r '.spec.template.spec.containers[0].image')
    local available=$(echo "$deploy_json" | jq -r '.status.conditions[] | select(.type=="Available") | .status')
    
    if [ "$ready_replicas" -lt "$replicas" ]; then
        add_check "deployment" "$(jq -n --arg r "$ready_replicas/$replicas" --arg img "$image" \
            '{status: "degraded", replicas: $r, image: $img}')"
        add_issue "warning" "deployment" "Not all replicas ready ($ready_replicas/$replicas)" \
            "Pod scheduling issues or startup problems" \
            "Check pod status and events"
    else
        add_check "deployment" "$(jq -n --arg r "$ready_replicas/$replicas" --arg img "$image" \
            '{status: "healthy", replicas: $r, image: $img}')"
    fi
}

# Check pods
check_pods() {
    local pod_json
    if ! pod_json=$(kubectl get pods -n "$NAMESPACE" -l k8s-app=metrics-server -o json 2>&1); then
        add_check "pods" "$(jq -n --arg err "$pod_json" '{status: "error", error: $err}')"
        return
    fi
    
    local pod_count=$(echo "$pod_json" | jq '.items | length')
    if [ "$pod_count" -eq 0 ]; then
        add_check "pods" '{"status": "not_found"}'
        add_issue "critical" "pods" "No metrics-server pods found" \
            "Deployment exists but no pods created" \
            "Check deployment events and resource availability"
        return
    fi
    
    local pod_name=$(echo "$pod_json" | jq -r '.items[0].metadata.name')
    local phase=$(echo "$pod_json" | jq -r '.items[0].status.phase')
    local ready=$(echo "$pod_json" | jq -r '[.items[0].status.containerStatuses[]? | select(.ready==true)] | length')
    local total=$(echo "$pod_json" | jq -r '.items[0].status.containerStatuses | length')
    local restarts=$(echo "$pod_json" | jq -r '.items[0].status.containerStatuses[0].restartCount // 0')
    
    local pod_issues="[]"
    
    if [ "$phase" != "Running" ]; then
        pod_issues=$(echo "$pod_issues" | jq '. + ["pod_not_running"]')
        add_issue "error" "pods" "Pod not running (phase: $phase)" \
            "Scheduling failure, image pull error, or startup crash" \
            "Check pod describe and events: kubectl describe pod -n $NAMESPACE $pod_name"
    fi
    
    if [ "$ready" -lt "$total" ]; then
        pod_issues=$(echo "$pod_issues" | jq '. + ["pod_not_ready"]')
        add_issue "warning" "pods" "Pod not ready ($ready/$total containers ready)" \
            "Readiness probe failing or container startup issue" \
            "Check pod logs and readiness probe configuration"
    fi
    
    if [ "$restarts" -gt 10 ]; then
        pod_issues=$(echo "$pod_issues" | jq '. + ["high_restart_count"]')
        add_issue "info" "pods" "High restart count ($restarts restarts)" \
            "Recurring crashes, OOM, or connectivity issues" \
            "Review pod logs for crash patterns: kubectl logs -n $NAMESPACE $pod_name --previous"
        add_recommendation "Review metrics-server logs for recurring errors"
    fi
    
    add_check "pods" "$(jq -n --arg phase "$phase" --arg ready "$ready/$total" --argjson restarts "$restarts" \
        --argjson issues "$pod_issues" \
        '{status: ($phase | ascii_downcase), ready: $ready, restarts: $restarts, issues: $issues}')"
}

# Check kubelet connectivity
check_kubelet_connectivity() {
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l k8s-app=metrics-server -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$pod_name" ]; then
        add_check "kubelet_connectivity" '{"status": "skipped", "reason": "no metrics-server pod found"}'
        return
    fi
    
    # Get nodes with unknown metrics
    local nodes_json
    nodes_json=$(kubectl get nodes -o json 2>/dev/null || echo '{"items":[]}')
    local total_nodes=$(echo "$nodes_json" | jq '.items | length')
    
    # Try to get node metrics to see which fail
    local failed_nodes="[]"
    local failed_count=0
    
    # Check recent logs for scraping errors
    local logs
    logs=$(kubectl logs -n "$NAMESPACE" "$pod_name" --tail=100 2>/dev/null || echo "")
    
    # Parse failed node scrapes from logs
    while IFS= read -r line; do
        if [[ "$line" =~ node=\"([^\"]+)\" ]]; then
            local node="${BASH_REMATCH[1]}"
            failed_nodes=$(echo "$failed_nodes" | jq --arg n "$node" '. + [$n] | unique')
            failed_count=$((failed_count + 1))
        fi
    done < <(echo "$logs" | grep -i "failed to scrape node" || true)
    
    local successful=$((total_nodes - $(echo "$failed_nodes" | jq 'length')))
    
    if [ "$(echo "$failed_nodes" | jq 'length')" -gt 0 ]; then
        local error_msg=$(echo "$logs" | grep -i "failed to scrape" | head -1 | sed 's/^.*err="\([^"]*\).*/\1/' || echo "unknown error")
        add_check "kubelet_connectivity" "$(jq -n --argjson total "$total_nodes" --argjson success "$successful" \
            --argjson failed "$(echo "$failed_nodes" | jq 'length')" --argjson nodes "$failed_nodes" --arg err "$error_msg" \
            '{status: "failed", tested_nodes: $total, successful: $success, failed: $failed, failed_nodes: $nodes, error: $err}')"
        
        add_issue "warning" "kubelet_connectivity" \
            "Cannot scrape metrics from $(echo "$failed_nodes" | jq 'length') node(s)" \
            "Network connectivity, kubelet certificate, or kubelet configuration issue" \
            "Check node network, verify kubelet is running, check kubelet certificates"
        
        add_recommendation "Investigate network connectivity to failed nodes: $(echo "$failed_nodes" | jq -r 'join(", ")')"
    else
        add_check "kubelet_connectivity" "$(jq -n --argjson total "$total_nodes" \
            '{status: "healthy", tested_nodes: $total, successful: $total, failed: 0}')"
    fi
}

# Check TLS certificates
check_tls_certificates() {
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l k8s-app=metrics-server -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$pod_name" ]; then
        add_check "tls_certificates" '{"status": "skipped", "reason": "no metrics-server pod found"}'
        return
    fi
    
    # Check for TLS-related errors in logs
    local logs
    logs=$(kubectl logs -n "$NAMESPACE" "$pod_name" --tail=100 2>/dev/null || echo "")
    
    if echo "$logs" | grep -q -i "x509\|certificate\|tls"; then
        local cert_error=$(echo "$logs" | grep -i "x509\|certificate\|tls" | head -1 || echo "")
        add_check "tls_certificates" "$(jq -n --arg err "$cert_error" \
            '{status: "issues_detected", error: $err}')"
        
        add_issue "warning" "tls_certificates" "TLS certificate validation errors detected" \
            "Kubelet certificates not trusted by metrics-server" \
            "Configure --kubelet-certificate-authority or use --kubelet-insecure-tls (not recommended)"
        
        add_recommendation "Review TLS configuration: kubectl get deployment -n $NAMESPACE $DEPLOYMENT -o yaml | grep -A5 args"
    else
        add_check "tls_certificates" '{"status": "valid", "note": "no TLS errors in recent logs"}'
    fi
}

# Check APIService
check_apiservice() {
    local apisvc_json
    if ! apisvc_json=$(kubectl get apiservice v1beta1.metrics.k8s.io -o json 2>&1); then
        add_check "api_service" "$(jq -n --arg err "$apisvc_json" '{status: "not_found", error: $err}')"
        add_issue "critical" "api_service" "APIService v1beta1.metrics.k8s.io not found" \
            "Metrics-server not properly installed" \
            "Reinstall metrics-server with proper manifests"
        return
    fi
    
    local available=$(echo "$apisvc_json" | jq -r '.status.conditions[] | select(.type=="Available") | .status')
    local service_ref=$(echo "$apisvc_json" | jq -r '.spec.service | "\(.name)/\(.namespace)"')
    local conditions=$(echo "$apisvc_json" | jq -c '[.status.conditions[] | {type, status, message}]')
    
    if [ "$available" != "True" ]; then
        add_check "api_service" "$(jq -n --arg svc "$service_ref" --argjson cond "$conditions" \
            '{status: "unavailable", service: $svc, conditions: $cond}')"
        
        local reason=$(echo "$apisvc_json" | jq -r '.status.conditions[] | select(.type=="Available") | .message')
        add_issue "error" "api_service" "APIService not available" \
            "$reason" \
            "Check service endpoints: kubectl get endpoints -n $NAMESPACE metrics-server"
    else
        add_check "api_service" "$(jq -n --arg svc "$service_ref" --argjson cond "$conditions" \
            '{status: "available", service: $svc, conditions: $cond}')"
    fi
}

# Check RBAC
check_rbac() {
    local sa_json
    if ! sa_json=$(kubectl get serviceaccount -n "$NAMESPACE" metrics-server -o json 2>&1); then
        add_check "rbac" "$(jq -n --arg err "$sa_json" '{status: "error", error: $err}')"
        return
    fi
    
    # Check for ClusterRoleBinding
    local crb_exists
    crb_exists=$(kubectl get clusterrolebinding | grep -c "metrics-server" || echo "0")
    
    if [ "$crb_exists" -eq 0 ]; then
        add_check "rbac" '{"status": "missing_binding", "service_account": "metrics-server"}'
        add_issue "error" "rbac" "No ClusterRoleBinding found for metrics-server" \
            "RBAC permissions not configured" \
            "Create ClusterRoleBinding for system:metrics-server ClusterRole"
    else
        add_check "rbac" '{"status": "healthy", "service_account": "metrics-server", "cluster_role": "system:metrics-server", "binding": "present"}'
    fi
}

# Analyze logs
analyze_logs() {
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l k8s-app=metrics-server -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$pod_name" ]; then
        add_check "logs" '{"status": "skipped", "reason": "no pod found"}'
        return
    fi
    
    local logs
    logs=$(kubectl logs -n "$NAMESPACE" "$pod_name" --tail="$LOG_LINES" 2>/dev/null || echo "")
    
    local error_count=$(echo "$logs" | grep -c "^E" || echo "0")
    local warning_count=$(echo "$logs" | grep -c "^W" || echo "0")
    
    # Extract unique error patterns
    local error_patterns="[]"
    while IFS= read -r pattern; do
        [ -z "$pattern" ] && continue
        error_patterns=$(echo "$error_patterns" | jq --arg p "$pattern" '. + [$p]')
    done < <(echo "$logs" | grep "^E" | sed 's/^E[0-9]* [0-9:.]* [0-9]* //' | sort | uniq -c | sort -rn | head -5 | sed 's/^[[:space:]]*[0-9]* //' || true)
    
    add_check "logs" "$(jq -n --argjson errors "$error_count" --argjson warnings "$warning_count" \
        --argjson patterns "$error_patterns" --argjson lines "$LOG_LINES" \
        '{status: "analyzed", error_count: $errors, warning_count: $warnings, top_errors: $patterns, lines_analyzed: $lines}')"
    
    if [ "$error_count" -gt 50 ]; then
        add_issue "warning" "logs" "High error rate in logs ($error_count errors in last $LOG_LINES lines)" \
            "Persistent connectivity or configuration issues" \
            "Review error patterns and address root causes"
        add_recommendation "High error rate - review top error patterns in logs"
    fi
}

# Main execution
main() {
    local cluster_name
    cluster_name=$(kubectl config current-context 2>/dev/null || echo "unknown")
    
    # Run checks based on component filter
    if [ "$COMPONENT" = "all" ] || [ "$COMPONENT" = "deployment" ]; then
        check_deployment
    fi
    
    if [ "$COMPONENT" = "all" ] || [ "$COMPONENT" = "pods" ]; then
        check_pods
    fi
    
    if [ "$COMPONENT" = "all" ] || [ "$COMPONENT" = "connectivity" ]; then
        check_kubelet_connectivity
    fi
    
    if [ "$COMPONENT" = "all" ] || [ "$COMPONENT" = "tls" ]; then
        check_tls_certificates
    fi
    
    if [ "$COMPONENT" = "all" ] || [ "$COMPONENT" = "apiservice" ]; then
        check_apiservice
    fi
    
    if [ "$COMPONENT" = "all" ] || [ "$COMPONENT" = "rbac" ]; then
        check_rbac
    fi
    
    if [ "$COMPONENT" = "all" ] || [ "$COMPONENT" = "logs" ]; then
        analyze_logs
    fi
    
    # Build final output
    if [ "$OUTPUT_FORMAT" = "json" ]; then
        jq -n --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" --arg cluster "$cluster_name" \
            --arg status "$OVERALL_STATUS" --argjson checks "$CHECKS" \
            --argjson issues "$ISSUES" --argjson recs "$RECOMMENDATIONS" \
            '{
                timestamp: $ts,
                cluster: $cluster,
                overall_status: $status,
                checks: $checks,
                issues: $issues,
                recommendations: $recs
            }'
    else
        # Text output
        echo "Metrics Server Debug Report"
        echo "=========================="
        echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        echo "Cluster: $cluster_name"
        echo "Overall Status: $OVERALL_STATUS"
        echo ""
        echo "Checks:"
        echo "$CHECKS" | jq -r 'to_entries[] | "  \(.key): \(.value.status // "unknown")"'
        echo ""
        if [ "$(echo "$ISSUES" | jq 'length')" -gt 0 ]; then
            echo "Issues:"
            echo "$ISSUES" | jq -r '.[] | "  [\(.severity | ascii_upcase)] \(.component): \(.description)"'
            echo ""
        fi
        if [ "$(echo "$RECOMMENDATIONS" | jq 'length')" -gt 0 ]; then
            echo "Recommendations:"
            echo "$RECOMMENDATIONS" | jq -r '.[] | "  - \(.)"'
        fi
    fi
}

# Run main
main "$@"
