# Handoff Skill

Prepare for context handoff when running low on context. Updates documentation so a fresh agent can seamlessly continue the work.

## Usage

```
/handoff
```

Run this when:
- Context is getting long/full
- You're about to start a new session
- Switching to a different task and want to preserve state

## When Invoked

### Step 1: Summarize current state

Reflect on what was accomplished in this session:
- What tasks were completed?
- What's currently in progress?
- What problems were encountered?
- What decisions were made and why?

### Step 2: Update SITREP.md

Update the situation report with:
- **Current State**: What's working, what's not
- **Recent Changes**: What was modified in this session
- **Blockers/Issues**: Any problems the next agent should know about
- **Key Decisions**: Important choices made and their rationale

### Step 3: Update TODO.md

Ensure TODO.md reflects:
- **Completed items**: Remove or mark done
- **In-progress work**: Clear description of where things stand
- **Next steps**: Specific, actionable items for the next agent
- **Context needed**: Any non-obvious information the next agent needs

### Step 4: Run /wrapup

Execute the `/wrapup` skill to:
- Update PROMPTLOG.md with session prompts
- Commit all documentation changes

### Step 5: Report handoff summary

Output a brief summary for the user:

```
Handoff prepared:
- SITREP.md: Updated with [summary]
- TODO.md: [N] items ready for next session
- PROMPTLOG.md: Updated with [N] prompts
- Committed: [hash]

Next agent should start with: "check @TODO.md and @SITREP.md and continue"
```

## Tips for Next Agent

The recommended prompt to continue work is:

```
check @TODO.md and @SITREP.md and continue
```

This loads both files into context and gives the agent clear direction.
