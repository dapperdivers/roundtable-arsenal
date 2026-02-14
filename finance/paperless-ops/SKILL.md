---
name: paperless-ops
description: Paperless-ngx document management — search, tag, organize, and retrieve documents
---

# Paperless-ngx Operations

Manage documents in Paperless-ngx via REST API.

## Connection

- **Base URL:** `http://paperless.selfhosted.svc.cluster.local:8000`
- **Auth:** `Authorization: Token $PAPERLESS_TOKEN`

```bash
PAPERLESS="http://paperless.selfhosted.svc.cluster.local:8000/api"
AUTH="Authorization: Token $PAPERLESS_TOKEN"
```

## Common Operations

### Search Documents
```bash
# Full-text search
curl -s -H "$AUTH" "$PAPERLESS/documents/?query=tax+2025" | jq '.results[] | {id, title, created}'

# Filter by tag
curl -s -H "$AUTH" "$PAPERLESS/documents/?tags__id__in=5" | jq '.results[] | {id, title}'

# Filter by correspondent
curl -s -H "$AUTH" "$PAPERLESS/documents/?correspondent__id=3" | jq '.results[] | {id, title}'

# Filter by document type
curl -s -H "$AUTH" "$PAPERLESS/documents/?document_type__id=2" | jq '.results[] | {id, title}'

# Filter by date range
curl -s -H "$AUTH" "$PAPERLESS/documents/?created__date__gte=2025-01-01&created__date__lte=2025-12-31"

# Combine filters
curl -s -H "$AUTH" "$PAPERLESS/documents/?query=invoice&tags__id__in=5&ordering=-created"
```

### List Tags
```bash
curl -s -H "$AUTH" "$PAPERLESS/tags/" | jq '.results[] | {id, name, document_count}'
```

### List Correspondents
```bash
curl -s -H "$AUTH" "$PAPERLESS/correspondents/" | jq '.results[] | {id, name, document_count}'
```

### List Document Types
```bash
curl -s -H "$AUTH" "$PAPERLESS/document_types/" | jq '.results[] | {id, name, document_count}'
```

### Get Document Details
```bash
curl -s -H "$AUTH" "$PAPERLESS/documents/42/" | jq '{id, title, content, tags, correspondent, document_type, created}'
```

### Download Document
```bash
# Original file
curl -s -H "$AUTH" "$PAPERLESS/documents/42/download/" -o document.pdf

# Thumbnail
curl -s -H "$AUTH" "$PAPERLESS/documents/42/thumb/" -o thumb.png
```

### Update Document
```bash
# Add tags (PATCH preserves other fields)
curl -s -X PATCH -H "$AUTH" -H "Content-Type: application/json" \
  "$PAPERLESS/documents/42/" \
  -d '{"tags": [5, 8, 12]}'

# Update title
curl -s -X PATCH -H "$AUTH" -H "Content-Type: application/json" \
  "$PAPERLESS/documents/42/" \
  -d '{"title": "2025 W2 - Employer Name"}'

# Set correspondent
curl -s -X PATCH -H "$AUTH" -H "Content-Type: application/json" \
  "$PAPERLESS/documents/42/" \
  -d '{"correspondent": 3}'
```

### Create Tag
```bash
curl -s -X POST -H "$AUTH" -H "Content-Type: application/json" \
  "$PAPERLESS/tags/" \
  -d '{"name": "tax-2025", "color": "#ff6600", "matching_algorithm": 3, "match": "2025 W2,2025 1099,tax 2025"}'
```

### Upload Document
```bash
curl -s -X POST -H "$AUTH" \
  "$PAPERLESS/documents/post_document/" \
  -F "document=@/path/to/file.pdf" \
  -F "title=Tax Return 2025" \
  -F "tags=5,8"
```

## Matching Algorithms
- `1` — Any word
- `2` — All words
- `3` — Exact match
- `4` — Regular expression
- `5` — Fuzzy match
- `6` — Auto (ML-based)

## Document Organization Workflow

### Tax Season
1. Search for all documents tagged "tax" in the target year
2. Verify W-2s, 1099s, receipts are all present
3. Cross-reference with transaction categorization (`finance/tax-prep`)
4. Tag missing documents, set reminders for outstanding items

### Monthly Filing
1. Check recent untagged documents: `?tags__id__isnull=true&ordering=-added`
2. Assign correspondent, document type, and tags
3. Verify OCR quality — re-upload if text is garbled

### Recommended Tag Structure
- **By Year:** `tax-2024`, `tax-2025`
- **By Type:** `receipt`, `invoice`, `statement`, `contract`, `medical`, `insurance`
- **By Status:** `needs-review`, `filed`, `archived`
- **By Owner:** `derek`, `shared`, `business`

## Pagination
API returns 25 results by default. Use `?page=2` or `?page_size=100` (max 100).

## Notes
- Paperless auto-OCRs uploaded PDFs and images
- Use `query=` for full-text search across OCR content
- `ordering=-created` for newest first, `ordering=created` for oldest
- The `content` field in document details contains the full OCR text
