#!/usr/bin/env bash
set -euo pipefail

# save-note.sh — Write content to the Obsidian vault
# Usage: save-note.sh --path <relative-path> [--content <text> | --stdin] [--append] [--vault <dir>]

VAULT="${OBSIDIAN_VAULT:-/home/node/obsidian-vault}"
NOTE_PATH=""
CONTENT=""
USE_STDIN=false
APPEND=false

usage() {
    cat <<EOF
Usage: $(basename "$0") --path <relative-path> [OPTIONS]

Save a note to the Obsidian vault.

Options:
  --path <path>       Relative path within the vault (required)
  --content <text>    Content to write
  --stdin             Read content from stdin
  --append            Append to existing file instead of overwriting
  --vault <dir>       Vault root directory (default: \$OBSIDIAN_VAULT or /home/node/obsidian-vault)
  -h, --help          Show this help message

Examples:
  $(basename "$0") --path "Security/Daily/2026-02-08.md" --content "# Daily Report"
  echo "# Report" | $(basename "$0") --path "Reports/output.md" --stdin
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --path) NOTE_PATH="$2"; shift 2 ;;
        --content) CONTENT="$2"; shift 2 ;;
        --stdin) USE_STDIN=true; shift ;;
        --append) APPEND=true; shift ;;
        --vault) VAULT="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

if [[ -z "$NOTE_PATH" ]]; then
    echo "Error: --path is required" >&2
    exit 1
fi

if [[ "$USE_STDIN" == true ]]; then
    CONTENT=$(cat)
elif [[ -z "$CONTENT" ]]; then
    echo "Error: --content or --stdin is required" >&2
    exit 1
fi

FULL_PATH="${VAULT}/${NOTE_PATH}"
mkdir -p "$(dirname "$FULL_PATH")"

if [[ "$APPEND" == true ]]; then
    echo "$CONTENT" >> "$FULL_PATH"
else
    echo "$CONTENT" > "$FULL_PATH"
fi

echo "$FULL_PATH"
