#!/usr/bin/env bash
set -euo pipefail

# recent-notes.sh — Show recently modified notes from vault index
# Version: 1.0.0
# Author: Patsy (vault curator)

# Configuration
DB_PATH="${VAULT_INDEX_DB:-/data/vault-index.db}"
LIMIT=10
PATHS=()
TAGS=()
SINCE=""
OUTPUT_FORMAT="table"

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
        --limit|-n)
            LIMIT="$2"
            shift 2
            ;;
        --path)
            PATHS+=("$2")
            shift 2
            ;;
        --tag)
            TAGS+=("$2")
            shift 2
            ;;
        --since)
            SINCE="$2"
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
Usage: recent-notes.sh [OPTIONS]

Show recently modified notes from the vault index.

OPTIONS:
    --limit N, -n N        Show N most recent notes (default: 10)
    --path PATH            Filter by path pattern
    --tag TAG              Filter by tag (can specify multiple)
    --since DATE           Only show notes modified since DATE (YYYY-MM-DD)
    --format FMT, -f FMT   Output format: table, json, csv, paths (default: table)
    --db PATH              Database path (default: /data/vault-index.db)
    --help, -h             Show this help

EXAMPLES:
    # Last 10 modified notes
    recent-notes.sh

    # Last 20 daily briefings
    recent-notes.sh --limit 20 --path "Briefings/Daily"

    # Recent security notes
    recent-notes.sh --tag security --limit 5

    # Notes modified since yesterday
    recent-notes.sh --since \$(date -d yesterday +%Y-%m-%d)

    # Export to JSON
    recent-notes.sh --limit 50 --format json > recent.json

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
    local query="SELECT DISTINCT n.id, n.path, n.filename, n.title, n.modified, n.size_bytes, n.word_count FROM notes n"
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
    
    # Since filter
    if [[ -n "$SINCE" ]]; then
        where_clauses+=("n.modified >= '$SINCE'")
    fi
    
    # Combine query parts
    query="$query$joins"
    
    if [[ ${#where_clauses[@]} -gt 0 ]]; then
        local where_str
        where_str=$(IFS=" AND "; echo "${where_clauses[*]}")
        query="$query WHERE $where_str"
    fi
    
    # Sort by modified descending
    query="$query ORDER BY n.modified DESC LIMIT $LIMIT"
    
    echo "$query"
}

# Format size human-readable
format_size() {
    local bytes=$1
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$((bytes / 1024))KB"
    else
        echo "$((bytes / 1048576))MB"
    fi
}

# Format output as table
format_table() {
    echo -e "${CYAN}MODIFIED             PATH                                               SIZE    TITLE${NC}"
    echo "--------------------------------------------------------------------------------------------------------"
    
    while IFS='|' read -r note_id path filename title modified size_bytes word_count; do
        # Format modified datetime
        local mod_display
        mod_display=$(echo "$modified" | cut -d'T' -f1,2 | tr 'T' ' ' || echo "$modified")
        
        # Format size
        local size_human
        size_human=$(format_size "$size_bytes")
        
        # Truncate path if too long
        local display_path="$path"
        if [[ ${#display_path} -gt 50 ]]; then
            display_path="${display_path:0:47}..."
        fi
        
        # Truncate title if too long
        local display_title="$title"
        if [[ ${#display_title} -gt 30 ]]; then
            display_title="${display_title:0:27}..."
        fi
        
        printf "%-20s %-50s %-7s %s\n" "$mod_display" "$display_path" "$size_human" "$display_title"
    done
}

# Format output as JSON
format_json() {
    echo "["
    local first=1
    
    while IFS='|' read -r note_id path filename title modified size_bytes word_count; do
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
    "modified": "$modified",
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
    echo "modified,path,filename,title,size_bytes,word_count"
    
    while IFS='|' read -r note_id path filename title modified size_bytes word_count; do
        # Escape quotes in fields
        path="${path//\"/\"\"}"
        filename="${filename//\"/\"\"}"
        title="${title//\"/\"\"}"
        
        echo "\"$modified\",\"$path\",\"$filename\",\"$title\",$size_bytes,$word_count"
    done
}

# Format output as paths only
format_paths() {
    while IFS='|' read -r note_id path _; do
        echo "$path"
    done
}

# Execute query and format output
execute_query() {
    local query
    query=$(build_query)
    
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
