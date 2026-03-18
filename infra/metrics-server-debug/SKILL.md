---
name: metrics-server-debug
description: >
  Debug metrics-server failures including kubelet connectivity, TLS certificate issues, and API availability problems. Use when kubectl top shows errors or HPA can't get metrics.
---

# Metrics Server Debug

**Version:** 1.0.0  
**Author:** Tristan (Infrastructure Knight)  
**Category:** Troubleshooting  
**Tags:** metrics-server, kubernetes, debugging, diagnostics, monitoring  
**Spec Version:** AgentSkills.io v1.0

## Overview

Debug metrics-server failures and connectivity issues in Kubernetes clusters. Provides automated diagnostics for common metrics-server problems including kubelet connectivity, TLS certificate validation, RBAC permissions, and API aggregation layer configuration.

## Capabilities

- **Metrics Server Health Check**: Verify metrics-server deployment and pod status
- **Kubelet Connectivity Test**: Check metrics-server to kubelet network connectivity
- **TLS Certificate Validation**: Validate certificates used for kubelet communication
- **RBAC Verification**: Check service account permissions and role bindings
- **API Aggregation Debug**: Verify APIService registration and status
- **Log Analysis**: Parse metrics-server logs for common error patterns

## Prerequisites

### RBAC Requirements

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: metrics-server-debug
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "nodes", "services"]
  verbs: ["get", "list"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list"]
- apiGroups: ["apiregistration.k8s.io"]
  resources: ["apiservices"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["serviceaccounts"]
  verbs: ["get"]
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["clusterroles", "clusterrolebindings"]
  verbs: ["get", "list"]
```

### Cluster Requirements

- kubectl access to the cluster
- metrics-server deployed (typically in kube-system namespace)
- jq for JSON processing

## Usage

### Full Diagnostic Run

```bash
./scripts/metrics-debug.sh
```

**Example Output:**
```json
{
  "timestamp": "2026-03-17T20:00:00Z",
  "cluster": "dapper-cluster",
  "overall_status": "degraded",
  "checks": {
    "deployment": {
      "status": "healthy",
      "replicas": "1/1",
      "image": "registry.k8s.io/metrics-server/metrics-server:v0.7.0"
    },
    "pods": {
      "status": "running",
      "ready": "1/1",
      "restarts": 22,
      "issues": ["high_restart_count"]
    },
    "kubelet_connectivity": {
      "status": "failed",
      "tested_nodes": 11,
      "successful": 10,
      "failed": 1,
      "failed_nodes": ["talos-node-large-2"],
      "error": "TLS handshake timeout"
    },
    "tls_certificates": {
      "status": "valid",
      "serving_cert": "valid until 2027-03-15",
      "ca_bundle": "present"
    },
    "api_service": {
      "status": "available",
      "service": "metrics-server/kube-system",
      "conditions": [
        {"type": "Available", "status": "True"}
      ]
    },
    "rbac": {
      "status": "healthy",
      "service_account": "metrics-server",
      "cluster_role": "system:metrics-server",
      "binding": "present"
    }
  },
  "issues": [
    {
      "severity": "warning",
      "component": "kubelet_connectivity",
      "description": "Cannot scrape metrics from talos-node-large-2",
      "likely_cause": "Network connectivity or kubelet certificate issue",
      "remediation": "Check node network, verify kubelet is running, check kubelet certificates"
    },
    {
      "severity": "info",
      "component": "pod_restarts",
      "description": "Pod has restarted 22 times",
      "likely_cause": "Intermittent connectivity issues or resource constraints",
      "remediation": "Review pod logs for crash patterns"
    }
  ],
  "recommendations": [
    "Investigate network connectivity to talos-node-large-2",
    "Check kubelet status on talos-node-large-2",
    "Review metrics-server logs for recurring errors",
    "Consider increasing resource limits if OOMKilled"
  ]
}
```

### Check Specific Component

```bash
# Check only deployment status
METRICS_DEBUG_COMPONENT=deployment ./scripts/metrics-debug.sh

# Check only kubelet connectivity
METRICS_DEBUG_COMPONENT=connectivity ./scripts/metrics-debug.sh

# Check only logs
METRICS_DEBUG_COMPONENT=logs ./scripts/metrics-debug.sh
```

## Troubleshooting Workflows

### Workflow 1: Metrics Server Not Running

**Symptoms:**
- `kubectl top nodes` returns "Metrics API not available"
- No metrics-server pods running

**Diagnostic Steps:**
```bash
./scripts/metrics-debug.sh
```

**Check:**
1. Deployment exists and has desired replicas
2. Pod status (Pending, CrashLoopBackOff, ImagePullBackOff)
3. Events for the deployment/pod
4. Resource availability on nodes

**Common Causes & Solutions:**

| Cause | Solution |
|-------|----------|
| Deployment not created | Apply metrics-server manifest |
| Image pull failure | Check image name and registry access |
| Insufficient resources | Check node capacity, adjust resource requests |
| Node selector mismatch | Verify node labels match pod requirements |

### Workflow 2: Metrics Server Running but Not Collecting Metrics

**Symptoms:**
- Metrics-server pod is Running
- `kubectl top nodes` returns error or `<unknown>`
- Node metrics show as unavailable

**Diagnostic Steps:**
```bash
./scripts/metrics-debug.sh
```

**Check:**
1. Kubelet connectivity from metrics-server pod
2. TLS certificate validation
3. Kubelet serving certificates
4. Network policies blocking traffic

**Common Causes & Solutions:**

| Cause | Solution |
|-------|----------|
| TLS verification failure | Add `--kubelet-insecure-tls` flag (not recommended for production) |
| Network policy blocking | Allow egress from metrics-server to kubelets (port 10250) |
| Kubelet not exposing metrics | Verify kubelet config has `--enable-server=true` |
| Certificate mismatch | Regenerate kubelet serving certificates |
| Node-specific issue | Check specific node kubelet status and logs |

### Workflow 3: Intermittent Metrics Failures

**Symptoms:**
- Metrics work sometimes but not always
- High restart count on metrics-server pod
- Some nodes show `<unknown>` metrics

**Diagnostic Steps:**
```bash
./scripts/metrics-debug.sh
```

**Check:**
1. Pod restart count and restart reasons
2. Resource usage (CPU/memory)
3. Timeout issues in logs
4. Node-specific failures

**Common Causes & Solutions:**

| Cause | Solution |
|-------|----------|
| Resource constraints | Increase CPU/memory limits |
| Slow kubelet responses | Increase timeout values |
| Network latency | Check network between metrics-server and kubelets |
| Specific node issues | Investigate failing nodes individually |

### Workflow 4: APIService Not Available

**Symptoms:**
- `kubectl get apiservice v1beta1.metrics.k8s.io` shows "False"
- Metrics API returns 503 Service Unavailable

**Diagnostic Steps:**
```bash
./scripts/metrics-debug.sh
```

**Check:**
1. APIService registration
2. Service endpoint availability
3. Metrics-server service selector
4. Pod label matching

**Common Causes & Solutions:**

| Cause | Solution |
|-------|----------|
| Service selector mismatch | Update service selector to match pod labels |
| No endpoints | Verify metrics-server pod is Ready |
| APIService misconfigured | Check APIService caBundle and service reference |
| Certificate issues | Verify serving certificates are valid |

## Common Error Patterns

### Error: "Unable to fetch metrics from node"

**Log Pattern:**
```
E0317 20:00:00.123456 1 scraper.go:140] "Failed to scrape node" err="Get \"https://10.100.0.55:10250/metrics/resource\": context deadline exceeded" node="talos-node-large-2"
```

**Diagnosis:**
- Network connectivity issue to specific node
- Kubelet not responding
- Firewall/network policy blocking

**Resolution:**
1. Check node status: `kubectl get node <node-name>`
2. Check kubelet: `kubectl get --raw /api/v1/nodes/<node-name>/proxy/metrics/resource`
3. Test connectivity from metrics-server pod to node kubelet
4. Verify kubelet is serving on port 10250

### Error: "x509: certificate signed by unknown authority"

**Log Pattern:**
```
E0317 20:00:00.123456 1 scraper.go:140] "Failed to scrape node" err="x509: certificate signed by unknown authority" node="talos-node-1"
```

**Diagnosis:**
- TLS certificate verification failure
- CA bundle not configured correctly
- Kubelet using self-signed certificates

**Resolution:**
1. Add `--kubelet-insecure-tls` flag (development only)
2. Configure `--kubelet-certificate-authority` with proper CA
3. Regenerate kubelet certificates signed by cluster CA
4. Use `--kubelet-preferred-address-types` to use correct endpoint

### Error: "no metrics known for node"

**Log Pattern:**
```
E0317 20:00:00.123456 1 manager.go:111] unable to fully scrape metrics: unable to fully scrape metrics from node talos-node-large-2: no metrics known for node
```

**Diagnosis:**
- Kubelet metrics endpoint returning empty/invalid data
- Kubelet cAdvisor disabled
- Node just joined cluster (metrics not yet available)

**Resolution:**
1. Check kubelet configuration for metrics exposure
2. Verify cAdvisor is enabled on kubelet
3. Wait 30-60 seconds for initial metrics collection
4. Restart kubelet if configuration changed

### Error: "Failed to list *v1.Node: Unauthorized"

**Log Pattern:**
```
E0317 20:00:00.123456 1 reflector.go:140] pkg/mod/k8s.io/client-go@v0.26.0/tools/cache/reflector.go:169: Failed to list *v1.Node: Unauthorized
```

**Diagnosis:**
- RBAC permissions missing
- Service account token expired/invalid
- ClusterRoleBinding missing

**Resolution:**
1. Verify ClusterRole has required permissions
2. Check ClusterRoleBinding exists and references correct service account
3. Recreate service account if token invalid
4. Apply proper RBAC from Prerequisites section

## Configuration Options

### Environment Variables

```bash
# Namespace where metrics-server is deployed
METRICS_NAMESPACE=kube-system

# Metrics-server deployment name
METRICS_DEPLOYMENT=metrics-server

# Number of recent log lines to analyze
METRICS_LOG_LINES=200

# Specific component to check (deployment, pods, connectivity, tls, rbac, apiservice, logs)
METRICS_DEBUG_COMPONENT=all

# Output format (json, text)
METRICS_OUTPUT_FORMAT=json
```

## Advanced Diagnostics

### Manual Kubelet Connectivity Test

```bash
# Get a node IP
NODE_IP=$(kubectl get node talos-node-large-2 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')

# Test from metrics-server pod
METRICS_POD=$(kubectl get pod -n kube-system -l k8s-app=metrics-server -o jsonpath='{.items[0].metadata.name}')

kubectl exec -n kube-system $METRICS_POD -- curl -k https://${NODE_IP}:10250/metrics/resource
```

### Check Kubelet Certificates

```bash
# Get kubelet serving certificate
kubectl get --raw /api/v1/nodes/talos-node-large-2/proxy/configz | jq -r '.kubeletconfig.tlsCertFile'

# Verify certificate details
echo | openssl s_client -connect ${NODE_IP}:10250 2>/dev/null | openssl x509 -noout -text
```

### Verify API Aggregation

```bash
# Check APIService status
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml

# Verify service endpoints
kubectl get endpoints metrics-server -n kube-system

# Test direct service access
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
```

## Integration Examples

### Automated Health Check

```bash
#!/bin/bash
# Run metrics-server diagnostics every 5 minutes

while true; do
  RESULT=$(./scripts/metrics-debug.sh)
  STATUS=$(echo "$RESULT" | jq -r '.overall_status')
  
  if [ "$STATUS" != "healthy" ]; then
    echo "⚠️ Metrics Server Issues Detected"
    echo "$RESULT" | jq '.issues'
    # Send alert
  fi
  
  sleep 300
done
```

### Pre-Flight Check

```bash
#!/bin/bash
# Check metrics-server health before running monitoring queries

if ! ./scripts/metrics-debug.sh | jq -e '.overall_status == "healthy"' > /dev/null; then
  echo "Metrics server not healthy - cannot collect metrics"
  exit 1
fi

# Proceed with metrics collection
kubectl top nodes
kubectl top pods --all-namespaces
```

## Troubleshooting the Troubleshooter

### Script fails with "metrics-server not found"

**Cause:** Metrics-server not deployed or in different namespace

**Solution:**
```bash
# Check all namespaces
kubectl get deployment --all-namespaces | grep metrics-server

# Set correct namespace
export METRICS_NAMESPACE=monitoring  # or wherever it's deployed
./scripts/metrics-debug.sh
```

### Script fails with "Permission denied"

**Cause:** Insufficient RBAC permissions

**Solution:** Apply RBAC from Prerequisites section and bind to your ServiceAccount

### Script times out

**Cause:** Large cluster or slow API responses

**Solution:**
```bash
# Increase kubectl timeout
export KUBECTL_TIMEOUT=60
./scripts/metrics-debug.sh
```

## Performance Considerations

- Script execution time: 5-30 seconds depending on cluster size
- Network overhead: Minimal (kubectl API calls only)
- Safe to run frequently (read-only operations)
- Can be run on production clusters without impact

## Related Skills

- `k8s-resource-monitor` - Cluster resource monitoring
- `pod-debug-toolkit` - General pod troubleshooting
- `network-policy-debug` - Network connectivity debugging
- `certificate-inspector` - TLS certificate validation

## Changelog

### v1.0.0 (2026-03-17)
- Initial release
- Full metrics-server diagnostic suite
- Kubelet connectivity testing
- TLS certificate validation
- RBAC verification
- Log analysis with error pattern matching
- JSON and text output formats

## License

MIT License - Part of Roundtable Knight Skills Collection

## Support

For issues or enhancements, contact the Infrastructure Knight (Tristan) or submit to the skills repository.
