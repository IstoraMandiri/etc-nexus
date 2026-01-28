---
name: sync-docs
description: Synchronize documentation with current project state. Updates SITREP.md, TODO.md, and HIVE-TEST-ANALYSIS.md.
argument-hint: "[--commit]"
---

# Sync Documentation

Update project documentation to reflect the current state. This ensures docs are accurate before handoffs or at any checkpoint.

## Arguments

- `--commit`: Automatically commit changes after syncing (optional)
- (no args): Sync docs but ask before committing

## Files Updated

| File | Purpose | What to Check |
|------|---------|---------------|
| `SITREP.md` | Current situation | Running tests, recent changes, blockers |
| `TODO.md` | Task tracking | Progress, completed items, next steps |
| `HIVE-TEST-ANALYSIS.md` | Test analysis | Test progress, status updates |

## Workflow

### Step 1: Check for Running Tests

Look for active Hive test runs:

```bash
# Check if hive is running
ps aux | grep -E "hive.*--sim" | grep -v grep

# Find active test log
/bin/ls -lt /workspaces/etc-nexus/hive/workspace/logs/details/ | head -3
```

If tests are running, get current progress:

```bash
# Count completed tests
grep -c "^-- " /workspaces/etc-nexus/hive/workspace/logs/details/<latest-log>
```

### Step 2: Gather Current State

Collect information about:
- **Test progress**: If running, what % complete? What's the rate/ETA?
- **Git status**: Any uncommitted changes? What branch?
- **Recent commits**: What was done recently?

```bash
git status --short
git log --oneline -5
```

### Step 3: Update SITREP.md

Update the "Current Activity" section with:
- What's currently running (tests, builds, etc.)
- Progress metrics (X/Y tests, Z% complete)
- Rate and ETA if applicable
- Any blockers or issues

Update "What's Working" section if status has changed.

### Step 4: Update TODO.md

Update the "Currently Running" section with:
- Current progress numbers
- Updated time estimates
- Mark any completed items

Update "Test Status Summary" table with latest results.

### Step 5: Update HIVE-TEST-ANALYSIS.md

If test progress has changed significantly (>5%), update:
- "Current Status" section at the top
- Phase 2 progress table
- Any status changes in Quick Reference

### Step 6: Review Changes

Show a summary of what was updated:

```
Docs synced:
- SITREP.md: Updated test progress to X/Y (Z%)
- TODO.md: Updated progress, ETA now ~N hours
- HIVE-TEST-ANALYSIS.md: Updated current status

Changes ready to commit. Proceed? (or use --commit to auto-commit)
```

### Step 7: Commit (if requested)

If `--commit` flag or user confirms:

```bash
git add SITREP.md TODO.md HIVE-TEST-ANALYSIS.md
git commit -m "Sync docs with current state

- Test progress: X/Y (Z%)
- ETA: ~N hours remaining"
```

## Reference: Test Suite Totals

| Suite | Total Tests |
|-------|-------------|
| `legacy` | 32,615 |
| `legacy-cancun` | 111,983 |
| `consensus` | 1,148 |

## Tips

- Run this before `/handoff` to ensure docs are current
- Run periodically during long test runs to track progress
- The skill will detect if no tests are running and skip test-related updates
