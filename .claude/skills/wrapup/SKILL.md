# Wrapup Skill

Finalize the session by updating the prompt log and committing all changes.

## Usage

```
/wrapup [commit message]
```

- If no commit message provided, auto-generate one based on changes
- If there are no changes to commit, just update the prompt log

## When Invoked

### Step 1: Run promptlog

First, execute the `/promptlog` skill to update PROMPTLOG.md with the current session's prompts.

### Step 2: Check for changes

Run `git status` to see if there are any uncommitted changes (including the newly updated PROMPTLOG.md).

### Step 3: Commit changes

If there are changes:

1. Stage all relevant files (be careful not to stage sensitive files like .env)
2. Create a commit with:
   - The provided commit message, OR
   - An auto-generated message summarizing the session's work
3. Include the prompt log update in the commit message if it was updated

### Step 4: Report summary

Tell the user:
- What files were committed
- The commit hash
- Whether they need to push (remind them to `git push` if on a branch)

## Example Output

```
Wrapped up session:
- Updated PROMPTLOG.md with 5 new prompts
- Committed 3 files: PROMPTLOG.md, TODO.md, src/config.ts
- Commit: abc1234 "Add user authentication and update docs"

Don't forget to push: git push origin main
```
