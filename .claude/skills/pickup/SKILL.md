# Pickup Skill

Resume work from a previous session. Loads context from documentation and gets up to speed quickly.

## Usage

```
/pickup
```

Run this at the start of a new session to continue work from where the previous agent left off.

## When Invoked

### Step 1: Load context files

Read the following files to understand current state:
- `SITREP.md` - Current situation, what's working/broken, recent decisions
- `TODO.md` - Outstanding tasks and next steps
- `CLAUDE.md` - Project instructions and available skills
- `PROMPTLOG.md` - Recent session history (skim for context)

### Step 2: Summarize understanding

Output a brief summary of what you understand:

```
Picking up from previous session:

**Current State:**
- [What's working]
- [What's in progress]
- [Any blockers]

**Next Steps:**
1. [First priority task]
2. [Second priority task]
...

Ready to continue. What would you like to focus on?
```

### Step 3: Verify understanding

If anything is unclear or seems outdated, ask clarifying questions before proceeding.

### Step 4: Check git status

Run `git status` to see if there are any uncommitted changes from a previous session that need attention.

## Alternative Start Commands

If the user prefers a more directed start:

```
check @TODO.md and @SITREP.md and continue
```

This is equivalent but more explicit about which files to read.
