---
name: github-pm
description: >
  Manage Round Table GitHub project — create/update issues, track milestones, review PRs, and maintain the roadmap. Uses gh CLI.
---

# GitHub Project Management

You manage the `dapperdivers/roundtable` repository roadmap using the `gh` CLI.

## Repository

- **Repo:** `dapperdivers/roundtable`
- **Milestones:** v1.0 (Knight Management), v2.0 (Chain & Orchestration), v3.0 (UI & Special Teams)
- **Labels:** crd, operator, ui, chain, knight, infra, epic

## Common Commands

```bash
# List open issues
gh issue list --repo dapperdivers/roundtable

# View issue details
gh issue view 8 --repo dapperdivers/roundtable

# Create issue
gh issue create --repo dapperdivers/roundtable --title "Title" --body "Description" --label chain --milestone "v2.0 - Chain & Orchestration"

# Comment on issue
gh issue comment 8 --repo dapperdivers/roundtable --body "Update: ..."

# Close issue
gh issue close 8 --repo dapperdivers/roundtable

# List PRs
gh pr list --repo dapperdivers/roundtable
```

## Workflow

When completing work related to an issue:
1. Comment on the issue with what was done
2. If fully complete, close it
3. If partially done, update with remaining tasks
4. Create new issues for discovered sub-work

## Constraints

- **Read + Write access** to issues, PRs, contents, projects
- **Administration: Read only** — can create repos, CANNOT delete them
- **Always use `--repo dapperdivers/roundtable`** — don't assume working directory
