---
name: obsidian-conventions
description: >
  How to read and cite an Obsidian vault through the MCPVault MCP tools (search_notes,
  read_note, list_directory, get_frontmatter, read_note_lines, wiki_link) and how to propose
  changes to it: vault-relative paths, frontmatter schema, wikilinks, dates, and
  ready-to-paste suggestions instead of edits. Use whenever a task involves the user's notes,
  vault, second brain or knowledge base, including looking things up, citing notes,
  suggesting additions, or writing text meant to be pasted into a note.
compatibility: >
  Written for MCPVault (@bitbonsai/mcpvault) running read-only. Tool names differ on other
  vault MCP servers; the conventions still apply.
metadata:
  author: dapperdivers
  runtime: kagent
---

# Obsidian Vault Conventions

The vault is the owner's long-term memory. Read it carefully, cite it precisely, and never
change it unless a tool for writing is explicitly provided.

## Finding things

- **Search before you browse.** `search_notes` (BM25) over content, and over frontmatter with
  `searchFrontmatter: true` (e.g. `status: inbox`, a tag, a `type`). 2–4 distinctive words
  work better than a sentence.
- **Read only what you need.** Start with `get_frontmatter` or `get_notes_info` to triage,
  `get_note_outline` + `read_note_lines` for long notes, `read_multiple_notes` for a batch.
- **Index notes** (`000 <Area> Index.md`, `README.md`, `INDEX.md`) are the map of an area.
- **Resolve links** with `wiki_link` when a `[[name]]` is ambiguous.

## Paths and links

- Paths are **relative to the vault root**, no leading slash: `Projects/Home/Garden Log.md`.
  The root is `""` (or `/`).
- Cite notes as wikilinks without `.md`: `[[Projects/Home/Garden Log]]`, or with a label
  `[[Projects/Home/Garden Log|Garden Log]]`. Never Markdown links to `.md` files.

## What to trust

- Prefer the owner's **curated notes**. Treat notes with `generated: true`, anything under
  `Agents/` (briefings, Night Watch, knight research, generated catalogs) or
  `Archive/Briefings/` as machine output: useful for context, not as the owner's view.
- **"Current" lives in frontmatter**: `status` and `updated`, not the newest-looking text.
  `Archive/` is history.
- Dates in notes are absolute (YYYY-MM-DD). Write absolute dates too, never "yesterday".

## Proposing changes (read-only)

You cannot edit notes. When asked to fill a gap or add something:

- Name the exact note (wikilink) and where in it the text belongs (heading or after which line).
- Give the text **ready to paste**, in the note's own style (headings, tables, bullet form).
- Cite sources for facts you add; mark anything unverified.

New notes, when a caller will write them, need frontmatter:

```yaml
---
created: YYYY-MM-DD
type: note            # note | project | reference | research | briefing | zettel | ...
status: active        # active | complete | archived | draft | stub
tags: [area/topic]
description: "One sentence: what this note is and why someone would open it."
generated: true       # machine-written notes only
author: <pipeline-or-agent-slug>
---
```

## Gotchas

- **Don't read the generated vault catalog whole** (`Agents/Generated/Vault Catalog.md`):
  it is tens of thousands of tokens. Search instead.
- **Write tools may be absent** (read-only mode). Don't call or promise `write_note`,
  `patch_note`, `move_note`; say "paste this into …" instead.
- **Never claim you changed a file.**
- Notes may be edited from phones and synced; don't assume a note is complete or final.
