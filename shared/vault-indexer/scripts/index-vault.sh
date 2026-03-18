#!/usr/bin/env bash
set -euo pipefail

# index-vault.sh — Build SQLite index of vault metadata
# Version: 1.0.0
# Author: Patsy (vault curator)

# Configuration
VAULT_PATH="${VAULT_PATH:-/vault}"
DB_PATH="${VAULT_INDEX_DB:-/data/vault-index.db}"
VERBOSE=${VERBOSE:-0}
INCREMENTAL=${INCREMENTAL:-0}
INDEXER_VERSION="1.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --vault)
            VAULT_PATH="$2"
            shift 2
            ;;
        --db)
            DB_PATH="$2"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE=1
            shift
            ;;
        --incremental|-i)
            INCREMENTAL=1
            shift
            ;;
        --quiet|-q)
            VERBOSE=0
            shift
            ;;
        --help|-h)
            cat <<EOF
Usage: index-vault.sh [OPTIONS]

Build SQLite index of vault metadata for fast queries.

OPTIONS:
    --vault PATH        Vault directory (default: /vault)
    --db PATH          Database path (default: /data/vault-index.db)
    --incremental, -i  Skip unchanged files (uses mtime)
    --verbose, -v      Show detailed progress
    --quiet, -q        Minimal output
    --help, -h         Show this help

EXAMPLES:
    # Full rebuild
    index-vault.sh

    # Incremental update
    index-vault.sh --incremental

    # Custom vault location
    index-vault.sh --vault /path/to/vault --db /tmp/vault.db

ENVIRONMENT:
    VAULT_PATH         Override vault directory
    VAULT_INDEX_DB     Override database path
    VERBOSE            Set to 1 for verbose output

EXIT CODES:
    0  Success
    1  Error (missing dependencies, vault not found, etc.)
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

# Logging functions
log_info() {
    if [[ $VERBOSE -eq 1 ]]; then
        echo -e "${BLUE}[INFO]${NC} $*" >&2
    fi
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Check dependencies
check_dependencies() {
    local missing=0
    
    # Check sqlite3
    if ! command -v sqlite3 &>/dev/null; then
        log_error "Missing dependency: sqlite3"
        missing=1
    fi
    
    # Check python3
    if ! command -v python3 &>/dev/null; then
        log_error "Missing dependency: python3"
        missing=1
    fi
    
    # Check yq - try multiple locations
    if command -v yq &>/dev/null; then
        YQ_CMD="yq"
    elif [[ -f /data/.mise/installs/github-mikefarah-yq/latest/yq_linux_amd64 ]]; then
        YQ_CMD="/data/.mise/installs/github-mikefarah-yq/latest/yq_linux_amd64"
    elif [[ -f ~/.local/share/mise/installs/github-mikefarah-yq/latest/bin/yq ]]; then
        YQ_CMD="$HOME/.local/share/mise/installs/github-mikefarah-yq/latest/bin/yq"
    else
        log_error "Missing dependency: yq (install via: mise use github:mikefarah/yq)"
        missing=1
    fi
    
    if [[ $missing -eq 1 ]]; then
        log_error "Install missing dependencies and try again"
        exit 1
    fi
    
    log_info "Dependencies OK: sqlite3, yq, python3"
    log_info "Using yq: $YQ_CMD"
}

# Verify vault exists
check_vault() {
    if [[ ! -d "$VAULT_PATH" ]]; then
        log_error "Vault not found: $VAULT_PATH"
        exit 1
    fi
    
    log_info "Vault found: $VAULT_PATH"
}

# Initialize database schema
init_database() {
    log_info "Initializing database: $DB_PATH"
    
    sqlite3 "$DB_PATH" <<'SQL'
-- Create notes table
CREATE TABLE IF NOT EXISTS notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    path TEXT UNIQUE NOT NULL,
    filename TEXT NOT NULL,
    title TEXT,
    created TEXT,
    modified TEXT,
    type TEXT,
    size_bytes INTEGER,
    word_count INTEGER,
    line_count INTEGER,
    has_frontmatter INTEGER DEFAULT 0,
    indexed_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_notes_created ON notes(created);
CREATE INDEX IF NOT EXISTS idx_notes_modified ON notes(modified);
CREATE INDEX IF NOT EXISTS idx_notes_type ON notes(type);
CREATE INDEX IF NOT EXISTS idx_notes_filename ON notes(filename);
CREATE INDEX IF NOT EXISTS idx_notes_path ON notes(path);

-- Create tags table
CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    note_id INTEGER NOT NULL,
    tag TEXT NOT NULL,
    FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
    UNIQUE(note_id, tag)
);

CREATE INDEX IF NOT EXISTS idx_tags_tag ON tags(tag);
CREATE INDEX IF NOT EXISTS idx_tags_note_id ON tags(note_id);

-- Create links table
CREATE TABLE IF NOT EXISTS links (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_id INTEGER NOT NULL,
    target_path TEXT NOT NULL,
    link_type TEXT DEFAULT 'wiki',
    FOREIGN KEY (source_id) REFERENCES notes(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_links_source ON links(source_id);
CREATE INDEX IF NOT EXISTS idx_links_target ON links(target_path);

-- Create metadata table
CREATE TABLE IF NOT EXISTS metadata (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
SQL

    log_success "Database schema initialized"
}

# Extract frontmatter and metadata from a markdown file
index_file() {
    local filepath="$1"
    local relpath="${filepath#$VAULT_PATH/}"
    local filename
    filename="$(basename "$filepath")"
    
    # Get file stats
    local size
    local mtime
    size=$(stat -c%s "$filepath" 2>/dev/null || stat -f%z "$filepath" 2>/dev/null || echo 0)
    mtime=$(stat -c%Y "$filepath" 2>/dev/null || stat -f%m "$filepath" 2>/dev/null || echo 0)
    local modified
    modified=$(date -d "@$mtime" -Iseconds 2>/dev/null || date -r "$mtime" -Iseconds 2>/dev/null || echo "")
    
    # Incremental mode: skip if file hasn't changed
    if [[ $INCREMENTAL -eq 1 ]]; then
        local last_indexed
        last_indexed=$(sqlite3 "$DB_PATH" "SELECT indexed_at FROM notes WHERE path = '$relpath'" 2>/dev/null || echo "")
        
        if [[ -n "$last_indexed" ]]; then
            local last_indexed_ts
            last_indexed_ts=$(date -d "$last_indexed" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S%z" "$last_indexed" +%s 2>/dev/null || echo 0)
            
            if [[ $mtime -le $last_indexed_ts ]]; then
                log_info "Skipping unchanged: $relpath"
                return 0
            fi
        fi
    fi
    
    log_info "Indexing: $relpath"
    
    # Count lines and words
    local line_count
    local word_count
    line_count=$(wc -l < "$filepath" || echo 0)
    word_count=$(wc -w < "$filepath" || echo 0)
    
    # Try to extract frontmatter with yq
    local has_frontmatter=0
    local created=""
    local type=""
    local title=""
    local tags_json="[]"
    
    # Check if file starts with ---
    if head -n1 "$filepath" | grep -q "^---$"; then
        has_frontmatter=1
        
        # Extract frontmatter fields with yq (it can handle YAML in markdown)
        created=$($YQ_CMD eval '.created // ""' "$filepath" 2>/dev/null | head -n1 || echo "")
        type=$($YQ_CMD eval '.type // ""' "$filepath" 2>/dev/null | head -n1 || echo "")
        
        # Extract tags as JSON array
        tags_json=$($YQ_CMD eval '.tags // [] | @json' "$filepath" 2>/dev/null | head -n1 || echo "[]")
    fi
    
    # If no title from frontmatter, try first H1
    if [[ -z "$title" ]]; then
        title=$(grep -m1 "^# " "$filepath" 2>/dev/null | sed 's/^# //' || echo "")
    fi
    
    # Extract wiki links [[...]]
    local links_array=()
    while IFS= read -r link; do
        links_array+=("$link")
    done < <(grep -oP '\[\[\K[^\]]+' "$filepath" 2>/dev/null || true)
    
    local indexed_at
    indexed_at=$(date -Iseconds)
    
    # Escape single quotes for SQL
    relpath="${relpath//\'/\'\'}"
    filename="${filename//\'/\'\'}"
    title="${title//\'/\'\'}"
    created="${created//\'/\'\'}"
    type="${type//\'/\'\'}"
    modified="${modified//\'/\'\'}"
    indexed_at="${indexed_at//\'/\'\'}"
    
    # Insert or replace note
    sqlite3 "$DB_PATH" <<SQL
INSERT OR REPLACE INTO notes (path, filename, title, created, modified, type, size_bytes, word_count, line_count, has_frontmatter, indexed_at)
VALUES ('$relpath', '$filename', '$title', '$created', '$modified', '$type', $size, $word_count, $line_count, $has_frontmatter, '$indexed_at');
SQL
    
    # Get note ID
    local note_id
    note_id=$(sqlite3 "$DB_PATH" "SELECT id FROM notes WHERE path = '$relpath'")
    
    # Delete old tags and links for this note
    sqlite3 "$DB_PATH" <<SQL
DELETE FROM tags WHERE note_id = $note_id;
DELETE FROM links WHERE source_id = $note_id;
SQL
    
    # Insert tags
    if [[ "$tags_json" != "[]" && "$tags_json" != "null" ]]; then
        echo "$tags_json" | python3 -c "
import json, sys
tags = json.load(sys.stdin)
if isinstance(tags, list):
    for tag in tags:
        tag_clean = tag.replace(\"'\", \"''\")
        print(f\"INSERT INTO tags (note_id, tag) VALUES ($note_id, '{tag_clean}');\")
" | sqlite3 "$DB_PATH" 2>/dev/null || true
    fi
    
    # Insert links
    for link in "${links_array[@]}"; do
        link="${link//\'/\'\'}"
        sqlite3 "$DB_PATH" "INSERT INTO links (source_id, target_path, link_type) VALUES ($note_id, '$link', 'wiki');" 2>/dev/null || true
    done
}

# Main indexing loop
index_vault() {
    log_info "Scanning vault for markdown files..."
    
    local file_count=0
    local start_time
    start_time=$(date +%s)
    
    # Find all .md files and index them
    while IFS= read -r filepath; do
        index_file "$filepath"
        ((file_count++))
        
        if [[ $VERBOSE -eq 1 ]] && [[ $((file_count % 100)) -eq 0 ]]; then
            log_info "Processed $file_count files..."
        fi
    done < <(find "$VAULT_PATH" -type f -name "*.md" 2>/dev/null)
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Update metadata
    local now
    now=$(date -Iseconds)
    
    sqlite3 "$DB_PATH" <<SQL
INSERT OR REPLACE INTO metadata (key, value) VALUES ('last_indexed', '$now');
INSERT OR REPLACE INTO metadata (key, value) VALUES ('total_notes', '$file_count');
INSERT OR REPLACE INTO metadata (key, value) VALUES ('vault_path', '$VAULT_PATH');
INSERT OR REPLACE INTO metadata (key, value) VALUES ('indexer_version', '$INDEXER_VERSION');
SQL
    
    log_success "Indexed $file_count files in ${duration}s"
}

# Show summary
show_summary() {
    local total_notes
    local total_tags
    local total_links
    local last_indexed
    
    total_notes=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM notes" 2>/dev/null || echo 0)
    total_tags=$(sqlite3 "$DB_PATH" "SELECT COUNT(DISTINCT tag) FROM tags" 2>/dev/null || echo 0)
    total_links=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM links" 2>/dev/null || echo 0)
    last_indexed=$(sqlite3 "$DB_PATH" "SELECT value FROM metadata WHERE key = 'last_indexed'" 2>/dev/null || echo "unknown")
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}   Vault Index Summary${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "  Database:      ${BLUE}$DB_PATH${NC}"
    echo -e "  Vault:         ${BLUE}$VAULT_PATH${NC}"
    echo -e "  Total Notes:   ${YELLOW}$total_notes${NC}"
    echo -e "  Unique Tags:   ${YELLOW}$total_tags${NC}"
    echo -e "  Total Links:   ${YELLOW}$total_links${NC}"
    echo -e "  Last Indexed:  ${YELLOW}$last_indexed${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
}

# Main execution
main() {
    log_info "Vault Indexer v$INDEXER_VERSION"
    log_info "Mode: $(if [[ $INCREMENTAL -eq 1 ]]; then echo 'INCREMENTAL'; else echo 'FULL'; fi)"
    
    check_dependencies
    check_vault
    init_database
    index_vault
    show_summary
}

main "$@"
