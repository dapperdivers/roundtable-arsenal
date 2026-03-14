---
name: go-refactoring
description: Safe Go refactoring patterns using gopls, golangci-lint, and incremental compilation. Use when moving code between packages, renaming types/functions, or extracting modules.
---

# Go Refactoring with LSP Tools

## Available Tools

- `gopls` — Go Language Server (type-safe rename, find references, implementations)
- `golangci-lint` — Meta-linter (catches what `go vet` misses)
- `goimports` — Auto-fix imports after moving code (part of `gotools`)

## Golden Rule

**Never use `sed` for Go refactoring.** Use `gopls` for renames and the `edit` tool for surgical changes. Run `go build ./...` after EVERY change.

## Refactoring Patterns

### Moving Functions Between Packages

1. **Create the new file** in the target package
2. **Copy** the function (don't cut yet)
3. **Update the signature** — export if needed, adjust receiver types
4. **Run `go build ./...`** — fix import paths
5. **Update all callers** to use the new package
6. **Run `go build ./...`** again — verify callers compile
7. **Delete the old function**
8. **Run `go build ./... && go test ./...`** — final check

### Type-Safe Rename with gopls

```bash
# Rename a function/type/variable across the entire codebase
gopls rename -w path/to/file.go:#OFFSET NewName

# Find the byte offset of a symbol
grep -b 'oldFunctionName' path/to/file.go
# Use the byte offset in the rename command
```

### Find All References

```bash
# Find everywhere a symbol is used before modifying it
gopls references path/to/file.go:#OFFSET
```

### Extract Method to New Package — Step by Step

```bash
# 1. Create target package
mkdir -p internal/newpkg

# 2. Find all references to understand impact
gopls references internal/controller/old_file.go:#OFFSET

# 3. Copy function to new package, adjust types
# 4. Build to check
go build ./...

# 5. Fix imports automatically
goimports -w internal/controller/old_file.go
goimports -w internal/newpkg/new_file.go

# 6. Update callers one at a time, building after each
# 7. Delete old function
# 8. Final validation
go build ./... && go test ./...
```

### Lint After Refactoring

```bash
# Full lint check
golangci-lint run ./...

# Just the changed packages
golangci-lint run ./internal/newpkg/... ./internal/controller/...
```

## Anti-Patterns

❌ `sed -i 's/oldFunc/newFunc/g' *.go` — breaks string literals, comments, partial matches
❌ Making 10 changes then building — cascading errors become impossible to debug
❌ Moving code without checking references first — orphaned callers
❌ Skipping `goimports` after cross-package moves — import hell

## Incremental Refactoring Checklist

For each function/method being moved:
- [ ] `gopls references` — understand all callers
- [ ] Copy to new location, adjust signature
- [ ] `go build ./...` — fix compilation
- [ ] `goimports -w` — fix imports
- [ ] Update ONE caller at a time
- [ ] `go build ./...` after each caller
- [ ] Delete old function
- [ ] `go test ./...` — verify behavior
