---
name: zettel-extraction
description: >
  Extract zettels (atomic notes: one claim plus the owner's own opinion, quoted verbatim)
  from a voice memo transcript, journal entry or long-form note, and return them as JSON for
  a pipeline to write. Use when asked to make zettels, atomic notes or a Zettelkasten layer,
  to capture someone's takes, opinions or decisions from text, or to mine notes or
  transcripts for ideas worth keeping.
metadata:
  author: dapperdivers
  runtime: kagent
---

# Zettel Extraction

A zettel is **one idea worth keeping**: a standalone claim plus the owner's own take on it,
in their own words. Its value is the opinion; facts are findable anywhere.

## Rules

1. **0–3 zettels per source. Fewer, stronger.** A few-sentence memo usually has 0 or 1.
   Returning none is a correct answer when nothing is worth keeping.
2. **Only what the owner actually states**: ideas, opinions, decisions, predictions,
   principles. Not reminders, to-dos, questions, logistics or rambling.
3. **The take is a verbatim quote** from the source: a full sentence or two (6+ words),
   copied exactly. Never paraphrase, tidy up or invent it. Callers check it against the
   source and drop zettels whose quote doesn't match.
4. **Each zettel is a different idea with a different quote.** Never split one sentence into
   two zettels.
5. **The claim stands alone**, stated as a claim, understandable without the source.
   Not "The speaker proposes…", not "The note says…".

## Fields

| Field | Rule |
|---|---|
| `title` | 3–8 words naming the idea, Title Case, no punctuation |
| `claim` | one sentence stating the idea on its own |
| `context` | 1–3 sentences of background from the source |
| `take` | verbatim quote of the owner's opinion or decision |
| `domain` | one lowercase word: homelab, security, finance, family, career, home, garden, health, learning, business, ai, ... |
| `confidence` | how firmly the owner holds it (scale below) |
| `tags` | 1–4 lowercase topic tags, single words or hyphenated |

**Confidence:** `high` = stated as a firm belief or decision ("we will", "always", "this is
how"); `medium` = a considered opinion; `low` = tentative ("maybe", "I think possibly");
`speculative` = brainstorming or "what if". Default to `medium`, not `high`.

## Output

Return only the JSON object the caller asks for. Without other instructions:

```json
{"zettels": [{"title": "", "claim": "", "context": "", "take": "", "domain": "", "confidence": "medium", "tags": []}]}
```

## Examples

Good:
- take: *"So what we're really trying to teach is cross-functional, cross-domain linking of
  ideas to generate new concepts."* → claim: "Education should teach cross-domain linking of
  ideas rather than memorization." (learning, high)

Bad (don't produce these):
- take *"Are we paying debts off optimally? Yes."*: a question the owner asked themselves.
- take *"Either that or almost something like a knowledge graph."*: a fragment; fold it into
  the zettel it belongs to, or skip it.
- claim *"The speaker proposes a visual message flow."*: not standalone; state the idea.
- Two zettels sharing one quote: keep the stronger one.
