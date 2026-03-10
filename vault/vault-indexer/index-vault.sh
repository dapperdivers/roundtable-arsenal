#!/usr/bin/env bash
# Vault SQLite Metadata Indexer
# Scans /vault/ markdown files and indexes metadata into SQLite
set -euo pipefail

VAULT_DIR="/vault"
DB_PATH="/data/vault-index.db"
FULL_REINDEX=false

[[ "${1:-}" == "--full" ]] && FULL_REINDEX=true

# Ensure data directory exists
mkdir -p "$(dirname "$DB_PATH")"

# Initialize database schema
sqlite3 "$DB_PATH" <<'SQL'
CREATE TABLE IF NOT EXISTS vault_files (
    file_path    TEXT PRIMARY KEY,
    title        TEXT,
    tags         TEXT,
    word_count   INTEGER,
    last_modified INTEGER,
    size_bytes   INTEGER,
    indexed_at   INTEGER
);
CREATE INDEX IF NOT EXISTS idx_title ON vault_files(title);
CREATE INDEX IF NOT EXISTS idx_tags ON vault_files(tags);
CREATE INDEX IF NOT EXISTS idx_path ON vault_files(file_path);
SQL

# Get last index time for incremental mode
LAST_RUN=0
if [[ "$FULL_REINDEX" == false ]]; then
    LAST_RUN=$(sqlite3 "$DB_PATH" "SELECT COALESCE(MAX(indexed_at), 0) FROM vault_files;" 2>/dev/null || echo 0)
fi

NOW=$(date +%s)
COUNT=0
SKIPPED=0

# Remove entries for files that no longer exist
sqlite3 "$DB_PATH" "SELECT file_path FROM vault_files;" | while IFS= read -r dbpath; do
    if [[ ! -f "$VAULT_DIR/$dbpath" ]]; then
        sqlite3 "$DB_PATH" "DELETE FROM vault_files WHERE file_path = '$(echo "$dbpath" | sed "s/'/''/g")';"
    fi
done

# Extract title (first H1) from a markdown file
extract_title() {
    local file="$1"
    grep -m1 '^# ' "$file" 2>/dev/null | sed 's/^# //' || echo ""
}

# Extract tags from YAML frontmatter
extract_tags() {
    local file="$1"
    # Check if file starts with ---
    if ! head -1 "$file" | grep -q '^---$'; then
        echo ""
        return
    fi
    # Extract frontmatter between first --- and next ---
    local fm
    fm=$(awk 'NR==1 && /^---$/{found=1; next} found && /^---$/{exit} found{print}' "$file")
    if [[ -z "$fm" ]]; then
        echo ""
        return
    fi
    # Parse tags - handles both list and inline formats
    # tags: [tag1, tag2] or tags:\n  - tag1\n  - tag2
    local tags=""
    tags=$(echo "$fm" | awk '
        /^tags:/ {
            # Inline array: tags: [a, b, c]
            if (match($0, /\[.*\]/)) {
                s = substr($0, RSTART+1, RLENGTH-2)
                gsub(/[ ]+/, "", s)
                gsub(/#/, "", s)
                print s
                next
            }
            # Inline single: tags: foo
            sub(/^tags:[ ]*/, "")
            if (length($0) > 0 && $0 !~ /^$/) {
                gsub(/#/, "", $0)
                gsub(/[ ]+/, "", $0)
                print
            }
            collecting = 1
            next
        }
        collecting && /^  - / {
            sub(/^  - /, "")
            gsub(/#/, "")
            gsub(/[ ]+/, "")
            gsub(/"/, "")
            gsub(/'\''/, "")
            items = items (items ? "," : "") $0
            next
        }
        collecting && !/^  - / && !/^$/ { collecting = 0 }
        END { if (items) print items }
    ')
    echo "$tags"
}

# Process each markdown file
while IFS= read -r -d '' filepath; do
    relpath="${filepath#$VAULT_DIR/}"
    mtime=$(stat -c %Y "$filepath" 2>/dev/null || stat -f %m "$filepath" 2>/dev/null)
    
    # Skip if not modified since last run (incremental mode)
    if [[ "$FULL_REINDEX" == false && "$mtime" -le "$LAST_RUN" ]]; then
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    title=$(extract_title "$filepath")
    tags=$(extract_tags "$filepath")
    word_count=$(wc -w < "$filepath" | tr -d ' ')
    size_bytes=$(stat -c %s "$filepath" 2>/dev/null || stat -f %z "$filepath" 2>/dev/null)

    # Escape single quotes for SQL
    esc_path=$(echo "$relpath" | sed "s/'/''/g")
    esc_title=$(echo "$title" | sed "s/'/''/g")
    esc_tags=$(echo "$tags" | sed "s/'/''/g")

    sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO vault_files (file_path, title, tags, word_count, last_modified, size_bytes, indexed_at) VALUES ('$esc_path', '$esc_title', '$esc_tags', $word_count, $mtime, $size_bytes, $NOW);"
    COUNT=$((COUNT + 1))
done < <(find "$VAULT_DIR" -name '*.md' -type f -print0)

echo "Indexing complete: $COUNT files indexed, $SKIPPED unchanged, $(date -Iseconds)"
