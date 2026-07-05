---
name: briefing-scorecard
description: >
  Weekly audit of the Daily briefings: score every claim in the trailing
  week against the domain vault reports and open-items ledgers using the
  forensic taxonomy (verified / stale-echo / fabricated /
  unverifiable-personal), run the mechanical assertions, and write the
  scorecard to /vault/Briefings/Scorecards/. This is how prompt and model
  changes stay testable — the next week's real runs ARE the test.
---

# Briefing Scorecard — Weekly Claim Audit

You audit what was **published** against what was **true**. Sources of truth,
in order: the domain vault reports for that day (`/vault/Briefings/Security|
Intel|HomeLab|Home|Finance|Career|Wellness/`, matched **by mtime** — Intel
filenames are sometimes future-dated), the open-items ledgers
(`/vault/Briefings/Ledger/<domain>.json`), and the verifier reports where
they exist. You never rescore a claim as true because it sounds plausible —
only because a source confirms it.

## Scope

The 7 most recent `/vault/Briefings/Daily/YYYY-MM-DD.md` files by mtime
(skip `-home` variants and fallback files, but note their existence).

## Per-claim taxonomy

Extract every factual claim (a statement checkable in principle — statuses,
Day-N counters, incidents, resolutions, "missing report" assertions,
citations). Classify each:

- **verified** — a same-day source (vault report, ledger, verifier report)
  supports it.
- **stale-echo** — was true once, wasn't true that day (carried items,
  outdated statuses, counters incremented without confirmation).
- **fabricated** — no source supports it (invented citations, invented
  numbers, phantom incidents, wrong knight-liveness).
- **unverifiable-personal** — personal-domain claim with no checkable source;
  not an error, tracked separately.

Attribute every non-verified claim to the stage that introduced it:
**knight** (wrong in the vault report too), **summary-hop** (right in the
vault report, wrong/missing in what reached synthesis), **synthesis**
(right in the inputs, wrong in the briefing), **chain-spec** (prompt
told the knight something false).

## Mechanical assertions (pass/fail per briefing)

1. **No unconfirmed Day-N:** every "⏳ Day N" item has same-day confirmation
   (ledger `open` + `last_verified` = that day, or an explicit summary
   bullet). Day-N values equal `date - first_seen` where the ledger has one.
2. **No counter arithmetic drift:** no counter decreases, jumps by more than
   the elapsed days, or contradicts another instance in the same briefing.
3. **No pregnancy-era tokens:** no due-date/countdown/pregnancy-week/
   nursery-prep/hospital-bag language (Emma was born 2026-04-14).
4. **Liveness honesty:** no domain listed missing that has a same-day vault
   report (by mtime), and no domain presented as reporting that has none.
5. **Citations exist:** every cited report/file exists with a plausible
   mtime; the citation's content direction matches the claim.
6. **Numbers traceable:** spot-check ≥5 numbers per briefing back to a
   source; any untraceable number fails this assertion.
7. **Length discipline:** no padding; a quiet day reads short; over 150
   lines fails.
8. **Required sections present:** TOP 3, CROSS-DOMAIN, DOMAIN SNAPSHOTS,
   MISSING REPORTS.

If the ledgers or verifier reports don't exist yet for part of the week,
run what's runnable and mark the rest "not assessable — ledger absent";
never fail an assertion on missing infrastructure.

## Output — `/vault/Briefings/Scorecards/YYYY-Www.md`

ISO week of the Monday you run on. Create the directory if missing. Contents:

1. **Headline table** — per day: claims, verified, stale-echo, fabricated,
   unverifiable-personal, corrupt % (corrupt = stale-echo + fabricated).
2. **Stage attribution** — corrupt-claim counts per stage
   (knight / summary-hop / synthesis / chain-spec).
3. **Assertion matrix** — the 8 assertions × 7 days, pass/fail/n-a.
4. **Trend line** — vs the previous scorecard file if one exists; call out
   any error class that grew.
5. **Worst 5 claims** — quoted, with the evidence that disproves each.
6. **One-line verdict** — is the pipeline getting more honest or less?

Keep the whole file under ~120 lines. Numbers you print are subject to the
same rules you're enforcing: every one traceable to a check you ran.

## Baseline

The pipeline's pre-hardening baseline (2026-07-02/03/04) was **47% / 53% /
52% corrupt** — scored with this same taxonomy. That is the number to beat;
week-over-week comparisons are valid only if the taxonomy above is applied
unchanged.
