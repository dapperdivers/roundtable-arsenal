#!/usr/bin/env bash
set -euo pipefail

# query-vault.sh — Query SQLite vault index with filters
# Version: 1.0.0
# Author: Patsy (vault curator)

# Configuration
DB_PATH="${VAULT_INDEX_DB:-/data/vault-index.db}"
OUTPUT_FORMAT="table"
TAGS=()
PATHS=()
SINCE=""
UNTIL=""
DAYS=""
TYPE=""
NO_TAGS=0
NO_FRONTMATTER=0
LIMIT=""
SORT="modified"
ORDER="DESC"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --tag)
            TAGS+=("$2")
            shift 2
            ;;
        --path)
            PATHS+=("$2")
            shift 2
            ;;
        --since)
            SINCE="$2"
            shift 2
            ;;
        --until)
            UNTIL="$2"
            shift 2
            ;;
        --days)
            DAYS="$2"
            shift 2
            ;;
        --type)
            TYPE="$2"
            shift 2
            ;;
        --no-tags)
            NO_TAGS=1
            shift
            ;;
        --no-frontmatter)
            NO_FRONTMATTER=1
            shift
            ;;
        --limit)
            LIMIT="$2"
            shift 2
            ;;
        --sort)
            SORT="$2"
            shift 2
            ;;
        --order)
            ORDER="$2"
            shift 2
            ;;
        --format|-f)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        --db)
            DB_PATH="$2"
            shift 2
            ;;
        --help|-h)
            cat <<EOF
Usage: query-vault.sh [OPTIONS]

Query vault index with filters and output in various formats.

OPTIONS:
    --tag TAG              Filter by tag (can specify multiple)
    --path PATH            Filter by path pattern (SQL LIKE)
    --since DATE           Notes created/modified >= DATE (YYYY-MM-DD)
    --until DATE           Notes created/modified <= DATE
    --days N               Notes from last N days
    --type TYPE            Filter by type (briefing, note, etc.)
    --no-tags              Show notes without any tags
    --no-frontmatter       Show notes without frontmatter
    --limit N              Limit results to N rows
    --sort FIELD           Sort by: created, modified, size, path (default: modified)
    --order ASC|DESC       Sort order (default: DESC)
    --format FMT, -f FMT   Output format: table, json, csv, paths (default: table)
    --db PATH              Database path (default: /data/vault-index.db)
    --help, -h             Show this help

EXAMPLES:
    # Find security briefings from last 7 days
    query-vault.sh --tag security --days 7 --type briefing

    # All notes in Daily briefings folder
    query-vault.sh --path "Briefings/Daily%"

    # Knight assessments from March
    query-vault.sh --path "Briefings/Knights%" --since 2026-03-01

    # Notes without tags (needs cleanup)
    query-vault.sh --no-tags

    # Recent large files
    query-vault.sh --sort size --limit 10

    # Export to JSON
    query-vault.sh --tag kubernetes --format json > k8s-notes.json

EXIT CODES:
    0  Success
    1  Error (database not found, query failed, etc.)
EOF
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option '$1'${NC}" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
    esac
done

# Check database exists
if [[ ! -f "$DB_PATH" ]]; then
    echo -e "${RED}Error: Database not found: $DB_PATH${NC}" >&2
    echo "Run index-vault.sh first to build the index" >&2
    exit 1
fi

# Build SQL query
build_query() {
    local query="SELECT DISTINCT n.path, n.filename, n.title, n.created, n.modified, n.type, n.size_bytes, n.word_count FROM notes n"
    local joins=""
    local where_clauses=()
    
    # Join tags if filtering by tag
    if [[ ${#TAGS[@]} -gt 0 ]]; then
        for i in "${!TAGS[@]}"; do
            joins="$joins LEFT JOIN tags t$i ON n.id = t$i.note_id"
            where_clauses+=("t$i.tag = '${TAGS[$i]}'")
        done
    fi
    
    # Path filters
    for path in "${PATHS[@]}"; do
        where_clauses+=("n.path LIKE '%$path%'")
    done
    
    # Date filters
    if [[ -n "$DAYS" ]]; then
        local cutoff_date
        cutoff_date=$(date -d "$DAYS days ago" +%Y-%m-%d 2>/dev/null || date -v-"$DAYS"d +%Y-%m-%d 2>/dev/null)
        where_clauses+=("(n.created >= '$cutoff_date' OR n.modified >= '$cutoff_date')")
    fi
    
    if [[ -n "$SINCE" ]]; then
        where_clauses+=("(n.created >= '$SINCE' OR n.modified >= '$SINCE')")
    fi
    
    if [[ -n "$UNTIL" ]]; then
        where_clauses+=("(n.created <= '$UNTIL' OR n.modified <= '$UNTIL')")
    fi
    
    # Type filter
    if [[ -n "$TYPE" ]]; then
        where_clauses+=("n.type = '$TYPE'")
    fi
    
    # No tags filter
    if [[ $NO_TAGS -eq 1 ]]; then
        joins="$joins LEFT JOIN tags t_check ON n.id = t_check.note_id"
        where_clauses+=("t_check.id IS NULL")
    fi
    
    # No frontmatter filter
    if [[ $NO_FRONTMATTER -eq 1 ]]; then
        where_clauses+=("n.has_frontmatter = 0")
    fi
    
    # Combine query parts
    query="$query$joins"
    
    if [[ ${#where_clauses[@]} -gt 0 ]]; then
        local where_str
        where_str=$(IFS=" AND "; echo "${where_clauses[*]}")
        query="$query WHERE $where_str"
    fi
    
    # Sorting
    local sort_field="n.$SORT"
    query="$query ORDER BY $sort_field $ORDER"
    
    # Limit
    if [[ -n "$LIMIT" ]]; then
        query="$query LIMIT $LIMIT"
    fi
    
    echo "$query"
}

# Format output as table
format_table() {
    local header="PATH|CREATED|TYPE|SIZE|TAGS"
    echo -e "${CYAN}$header${NC}"
    echo "----------------------------------------"
    
    while IFS='|' read -r path created type size_bytes note_id; do
        # Get tags for this note
        local tags
        tags=$(sqlite3 "$DB_PATH" "SELECT GROUP_CONCAT(tag, ', ') FROM tags WHERE note_id = $note_id" 2>/dev/null || echo "")
        
        # Format size
        local size_human
        if [[ $size_bytes -lt 1024 ]]; then
            size_human="${size_bytes}B"
        elif [[ $size_bytes -lt 1048576 ]]; then
            size_human="$((size_bytes / 1024))KB"
        else
            size_human="$((size_bytes / 1048576))MB"
        fi
        
        # Truncate path if too long
        local display_path="$path"
        if [[ ${#display_path} -gt 50 ]]; then
            display_path="${display_path:0:47}..."
        fi
        
        # Truncate tags if too long
        local display_tags="$tags"
        if [[ ${#display_tags} -gt 30 ]]; then
            display_tags="${display_tags:0:27}..."
        fi
        
        printf "%-50s %-10s %-10s %-6s %s\n" "$display_path" "$created" "$type" "$size_human" "$display_tags"
    done
}

# Format output as JSON
format_json() {
    echo "["
    local first=1
    
    while IFS='|' read -r path filename title created modified type size_bytes word_count note_id; do
        # Get tags for this note
        local tags_json
        tags_json=$(sqlite3 "$DB_PATH" "SELECT json_group_array(tag) FROM tags WHERE note_id = $note_id" 2>/dev/null || echo "[]")
        
        if [[ $first -eq 0 ]]; then
            echo ","
        fi
        first=0
        
        cat <<JSON
  {
    "path": "$path",
    "filename": "$filename",
    "title": "$title",
    "created": "$created",
    "modified": "$modified",
    "type": "$type",
    "size_bytes": $size_bytes,
    "word_count": $word_count,
    "tags": $tags_json
  }
JSON
    done
    
    echo ""
    echo "]"
}

# Format output as CSV
format_csv() {
    echo "path,filename,title,created,modified,type,size_bytes,word_count,tags"
    
    while IFS='|' read -r path filename title created modified type size_bytes word_count note_id; do
        # Get tags for this note
        local tags
        tags=$(sqlite3 "$DB_PATH" "SELECT GROUP_CONCAT(tag, ';') FROM tags WHERE note_id = $note_id" 2>/dev/null || echo "")
        
        # Escape quotes in fields
        path="${path//\"/\"\"}"
        filename="${filename//\"/\"\"}"
        title="${title//\"/\"\"}"
        tags="${tags//\"/\"\"}"
        
        echo "\"$path\",\"$filename\",\"$title\",\"$created\",\"$modified\",\"$type\",$size_bytes,$word_count,\"$tags\""
    done
}

# Format output as paths only
format_paths() {
    while IFS='|' read -r path _; do
        echo "$path"
    done
}

# Execute query and format output
execute_query() {
    local query
    query=$(build_query)
    
    # Add note_id to query for tag lookup
    query="${query/SELECT DISTINCT n.path/SELECT DISTINCT n.path, n.filename, n.title, n.created, n.modified, n.type, n.size_bytes, n.word_count, n.id}"
    
    local results
    results=$(sqlite3 -separator '|' "$DB_PATH" "$query" 2>/dev/null || echo "")
    
    if [[ -z "$results" ]]; then
        echo -e "${YELLOW}No results found${NC}" >&2
        return 0
    fi
    
    case "$OUTPUT_FORMAT" in
        table)
            echo "$results" | format_table
            ;;
        json)
            echo "$results" | format_json
            ;;
        csv)
            echo "$results" | format_csv
            ;;
        paths)
            echo "$results" | format_paths
            ;;
        *)
            echo -e "${RED}Error: Unknown format '$OUTPUT_FORMAT'${NC}" >&2
            exit 1
            ;;
    esac
}

# Main
execute_query
