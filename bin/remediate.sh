#!/bin/bash
# ==============================================================================
# Agentic Remediation Script
# ==============================================================================
# Takes a failing file and an error message, creates a new isolated branch,
# uses the local Antigravity CLI (agy) to generate a fix, and commits it.
# ==============================================================================

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <file_path> <error_message>"
    exit 1
fi

FILE_PATH="$1"
ERROR_MSG="$2"
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Generate a unique branch name
TIMESTAMP=$(date +%s)
BRANCH_NAME="auto-fix-${TIMESTAMP}"

echo "🔨 Remediation triggered for $FILE_PATH"
echo "➡️ Creating isolated branch: $BRANCH_NAME"

cd "$WORKSPACE_DIR"

# Ensure working tree is clean before branching (stash any uncommitted changes)
git stash || true
git checkout -b "$BRANCH_NAME"

echo "🤖 Asking Antigravity CLI (agy) to fix the issue..."
# Use agy CLI to fix the file
# We instruct the model to replace the content of the file and save it
PROMPT="The file $FILE_PATH has a syntax error. The error is: $ERROR_MSG. Please fix the file and save the changes. Do NOT commit the changes, just modify the file."

# Note: We use --dangerously-skip-permissions to allow autonomous file writes
agy.exe --print "$PROMPT" --dangerously-skip-permissions

echo "💾 Committing the fix..."
git add "$FILE_PATH"
git commit -m "🤖 Auto-fix: Correct syntax error in $(basename "$FILE_PATH")" || {
    echo "❌ No changes made by the AI or commit failed."
    # Optionally revert back
    git checkout main
    git branch -D "$BRANCH_NAME"
    exit 1
}

echo "✅ Remediation complete. Fix committed to branch: $BRANCH_NAME"
echo "You can now push this branch and open a PR: git push -u origin $BRANCH_NAME"

# Switch back to main to keep the main environment clean
git checkout main
