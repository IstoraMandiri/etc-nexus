#!/bin/bash
# Hook script that runs on Stop event
# Reminds Claude to suggest /wrapup if significant work was done

# Read input from stdin (contains session info)
input=$(cat)

# Output a reminder that gets added to Claude's context
cat << 'EOF'
If this session involved significant work (code changes, file edits, or meaningful discussion), consider suggesting the user run `/wrapup` to update the prompt log and commit changes.
EOF

exit 0
