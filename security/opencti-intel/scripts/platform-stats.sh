#!/bin/bash
# OpenCTI Platform Stats

TOKEN="${OPENCTI_TOKEN:-}"
if [ -z "$TOKEN" ]; then
  echo "Error: OPENCTI_TOKEN not set"
  exit 1
fi

API="http://opencti-server.security.svc.cluster.local/graphql"

echo "=== OpenCTI Platform Health ==="
curl -s --max-time 10 -X POST "$API" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"query":"{about{version dependencies{name version}}}"}'
echo ""

echo "=== Object Counts ==="
curl -s --max-time 10 -X POST "$API" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"query":"{stixCoreObjectsNumber{total} indicatorsNumber{total} reportsNumber{total}}"}'
echo ""

echo "=== RSS Feed Status ==="
curl -s --max-time 10 -X POST "$API" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"query":"{ingestionRsss{edges{node{name ingestion_running current_state_date}}}}"}'
echo ""
