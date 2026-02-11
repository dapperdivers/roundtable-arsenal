#!/bin/bash
# OpenCTI Daily Intelligence Brief
# Pulls latest indicators, CVEs, malware, reports, and platform stats

TOKEN="${OPENCTI_TOKEN:-}"
if [ -z "$TOKEN" ]; then
  echo "Error: OPENCTI_TOKEN not set"
  exit 1
fi

API="http://opencti-server.security.svc.cluster.local/graphql"

echo "=== PLATFORM STATS ==="
curl -s --max-time 15 -X POST "$API" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"query":"{stixCoreObjectsNumber{total count}}"}'
echo ""

echo "=== LATEST REPORTS (20) ==="
curl -s --max-time 15 -X POST "$API" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"query":"{reports(first:20 orderBy:created_at orderMode:desc){edges{node{name created_at createdBy{name}}}}}"}'
echo ""

echo "=== LATEST INDICATORS (20) ==="
curl -s --max-time 15 -X POST "$API" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"query":"{indicators(first:20 orderBy:created_at orderMode:desc){edges{node{name pattern indicator_types created_at createdBy{name}}}}}"}'
echo ""

echo "=== LATEST VULNERABILITIES (10) ==="
curl -s --max-time 15 -X POST "$API" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"query":"{vulnerabilities(first:10 orderBy:created orderMode:desc){edges{node{name description x_opencti_cvss_base_score created}}}}"}'
echo ""

echo "=== LATEST MALWARE (10) ==="
curl -s --max-time 15 -X POST "$API" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"query":"{malwares(first:10 orderBy:created_at orderMode:desc){edges{node{name description is_family created_at}}}}"}'
echo ""
