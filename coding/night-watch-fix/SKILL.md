---
name: night-watch-fix
description: Execute a Night Watch fix Mission - reproduce, fix, test, and open a PR for an incident dispatched by the watchman. Use when a mission briefing references a Night-Watch fingerprint.
---

# Night Watch Fix Procedure

You received a Mission briefing with a fingerprint, evidence, and a target repo.
The deliverable is a **PR**, or an explicit, well-argued "not a bug" verdict.
Follow coding-agent rules (branch, tests, PR); this skill adds the Night Watch
specifics.

Read your repo's codebase skill first: `coding/roundtable-operator`,
`coding/pi-knight-runtime`, `coding/roundtable-ui`, or `coding/roundtable-arsenal`.

## Per-repo procedure

| Repo | Verify before push |
|---|---|
| dapperdivers/pi-knight | `npm ci && npx tsc --noEmit && npm test && npm run build` |
| dapperdivers/roundtable-ui | `cd api && go build ./... && go vet ./... && go test ./...`; UI changes: `cd ui && npm install && npm run build` |
| dapperdivers/roundtable | `go build ./... && go vet ./...`; run `make test` (envtest) — if the sandbox can't, say so in the PR body |
| dapperdivers/roundtable-arsenal | skills are markdown: valid YAML frontmatter (`name`, `description`), check referenced paths/commands actually exist |
| dapperdivers/nats-bridge | check package.json/Makefile for the test command; at minimum build clean |
| dapperdivers/dapper-cluster | **`kubernetes/apps/roundtable/**` paths ONLY** — never touch anything else. Update the matching `kustomization.yaml` for new files. |

## Rules

1. **Reproduce first when feasible.** A failing test that demonstrates the bug is
   worth more than the fix itself — it becomes the regression guard. If you
   cannot reproduce, say so in the PR body and explain your confidence anyway.
2. **Branch**: `night-watch/<fingerprint>`. Commits: conventional
   (`fix: <what> (night-watch <fp>)`). Never push to main. No Co-Authored-By lines.
3. **Smallest correct fix.** No drive-by refactors; the human reviewing at 7 AM
   must be able to grasp the diff in one read.
4. **PR body template** (the trailer line is machine-read — keep it exact):

   ```
   ## Night Watch fix

   **Incident:** <one-line summary>
   **Evidence:** <key log lines / metrics from the briefing>
   **Root cause:** <what was actually wrong>
   **Fix:** <what you changed and why this addresses the root cause>
   **Reproduced:** yes — <how> | no — <why not>
   **Tests:** <suites run + results>

   Night-Watch-Fingerprint: <fp>
   ```

## AUTOMERGE POLICY — current phase: 2 (human merges)

Do NOT run `gh pr merge` in any form. Open the PR and stop.
(Tier rules will be enabled here in Phase 3 — tier 1: arsenal + roundtable
manifests may auto-merge on green; tier 3: operator Go code, workflows, RBAC,
renovate config NEVER auto-merge.)

## Protected paths — never modify, any repo, any tier

- `.github/workflows/**`
- `kubernetes/apps/roundtable/infrastructure/app/*rbac*.yaml`, `*secret*.yaml`
- `.renovate/**`, `renovate.json*`

If the fix genuinely requires one of these, stop and say so in your result —
that escalation is a human decision.

## Afterwards

End your result with: PR URL, fingerprint, repos touched, test results.
The watchman reads Mission results to update the ledger — make them parseable
at a glance.
