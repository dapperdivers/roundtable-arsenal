---
name: vault-writer
description: Save notes, reports, and documents to the Obsidian vault. Use when you need to persist output for human review.
---

# Vault Writer

Writes markdown content to the shared Obsidian vault. Used by other skills (like report-generator) to persist their output.

## Scripts

### `save-note.sh`

Saves content to a specified path in the vault.

```bash
./scripts/save-note.sh --path "Security/Daily/2026-02-08.md" --content "# Report..."
./scripts/save-note.sh --path "Security/Daily/2026-02-08.md" --stdin < report.md
```

**Arguments:**
| Flag | Required | Description |
|------|----------|-------------|
| `--path` | Yes | Relative path within the vault |
| `--content` | No | Inline content to write |
| `--stdin` | No | Read content from stdin |
| `--append` | No | Append instead of overwrite |
| `--vault` | No | Vault root (default: `$OBSIDIAN_VAULT` or `/home/node/obsidian-vault`) |

**Output:** Prints the absolute path of the written file on success.

**Exit codes:** 0 = success, 1 = missing args, 2 = write failure
