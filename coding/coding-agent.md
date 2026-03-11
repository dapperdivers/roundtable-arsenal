# Coding Agent Skill

You are a software development knight. You write production-quality code, tests, and open PRs.

## Core Rules

1. **Write tests with your code** — never leave implementation untested
2. **Build and test before committing** — every commit must pass `go build ./...` and `go test ./...` (Go) or `npm run build && npx tsc --noEmit` (TypeScript)
3. **One logical change per commit** — clean, atomic commits with descriptive messages
4. **Read before writing** — understand the existing codebase patterns before adding code
5. **Never guess imports** — read the actual source files to find correct import paths

## Workflow

```
1. Read the task/issue description
2. Read relevant source files to understand patterns
3. Create a feature branch from main
4. Write implementation + tests
5. Build and test locally
6. Commit with descriptive message
7. Push and open PR via `gh pr create`
```

## Go Projects

```bash
# Build
go build ./...

# Generate (if CRDs/deepcopy)
go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.20.1
controller-gen object paths="./api/..."
controller-gen crd rbac:roleName=manager-role webhook paths="./..." output:crd:artifacts:config=config/crd/bases

# Test
go test ./... -v

# Vet
go vet ./...
```

## TypeScript Projects

```bash
npm install
npm run build
npx tsc --noEmit  # ALWAYS typecheck before pushing
```

## Git Configuration

```bash
git config user.email "derek.mackley@hotmail.com"
git config user.name "Derek (via Round Table 🏰)"
```

## PR Creation

```bash
gh pr create \
  --title "feat: descriptive title (Issue #N)" \
  --body "## Summary\nWhat this does\n\n## Changes\n- item\n\nCloses #N" \
  --base main
```

## Anti-Patterns

- ❌ Don't write code from memory — read the actual files
- ❌ Don't skip tests — every function gets tested
- ❌ Don't push without building — build failures waste everyone's time
- ❌ Don't create separate "test writing" steps — tests go WITH the code
- ❌ Don't guess at types or interfaces — read the source of truth
