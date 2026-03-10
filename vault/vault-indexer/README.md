# Vault SQLite Metadata Indexer

A skill for **Patsy** (vault management AI knight) that indexes an Obsidian vault's markdown files into a SQLite database for fast metadata lookups.

## What It Does

- Scans all `.md` files in the vault (`/vault/`)
- Extracts: file path, title (first H1), YAML frontmatter tags, word count, last modified time, file size
- Stores everything in a SQLite database at `/data/vault-index.db`
- Supports **incremental updates** — only re-indexes files modified since last run
- Provides a search script for querying by title and path

## Scripts

### `index-vault.sh`

Indexes or re-indexes the vault.

```bash
./index-vault.sh          # Incremental update (default)
./index-vault.sh --full   # Full re-index
```

### `search-vault.sh`

Search the index by title or path.

```bash
./search-vault.sh "meeting notes"
```

Returns a JSON array:

```json
[
  {
    "path": "Projects/meeting-notes.md",
    "title": "Meeting Notes",
    "tags": "project,meetings",
    "word_count": 342
  }
]
```

## Requirements

- `sqlite3` CLI
- Bash 4+
- Standard Unix tools (`find`, `awk`, `sed`, `stat`, `date`)

## Database Schema

| Column | Type | Description |
|--------|------|-------------|
| file_path | TEXT | Relative path from vault root (primary key) |
| title | TEXT | First H1 heading in the file |
| tags | TEXT | Comma-separated tags from YAML frontmatter |
| word_count | INTEGER | Total word count |
| last_modified | INTEGER | Unix timestamp of last modification |
| size_bytes | INTEGER | File size in bytes |
| indexed_at | INTEGER | Unix timestamp when indexed |
