#!/usr/bin/env bash
# Search the vault SQLite index
# Usage: search-vault.sh <query>
set -euo pipefail

DB_PATH="/data/vault-index.db"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <search-query>" >&2
    exit 1
fi

if [[ ! -f "$DB_PATH" ]]; then
    echo "Error: Index not found at $DB_PATH. Run index-vault.sh first." >&2
    exit 1
fi

QUERY="$1"
# Escape single quotes
ESC_QUERY=$(echo "$QUERY" | sed "s/'/''/g")

sqlite3 -json "$DB_PATH" \
    "SELECT file_path as path, title, tags, word_count FROM vault_files WHERE title LIKE '%${ESC_QUERY}%' OR file_path LIKE '%${ESC_QUERY}%' ORDER BY last_modified DESC LIMIT 50;"
