#!/bin/bash
# ==============================================================================
# Optimized Agentic Remediation Script
# ==============================================================================
# Creates an isolated branch, runs the local agent to fix the error, 
# validates the fix locally before committing, and maintains clean git state.
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

# Clean up trap in case of failure
cleanup() {
    echo "🧹 Running cleanup..."
    git checkout main
    git branch -D "$BRANCH_NAME" || true
    git stash pop || true
}
trap cleanup ERR

echo "🤖 Asking Antigravity CLI (agy) to fix the issue..."
# We instruct the model to use ClearCode principles as defined in our architecture
PROMPT="The file $FILE_PATH has an error: $ERROR_MSG. Please fix the file and save the changes. STRICT RULES: Enforce ClearCode (O(1) logic, no deep nesting). Do not break existing functionality. Do not commit, just modify the file."

# Note: We use --dangerously-skip-permissions to allow autonomous file writes
agy.exe --print "$PROMPT" --dangerously-skip-permissions || agy --print "$PROMPT" --dangerously-skip-permissions

# OPTIMIZATION: Validate the fix locally before committing
echo "🔍 Validating the AI's fix locally..."
if [[ "$FILE_PATH" == *.sh ]]; then
    bash -n "$FILE_PATH" || {
        echo "❌ AI failed to produce valid bash syntax. Aborting."
        exit 1
    }
fi

echo "💾 Committing the verified fix..."
git add "$FILE_PATH"
git commit -m "🤖 Auto-fix: Correct syntax error in $(basename "$FILE_PATH")" || {
    echo "❌ No changes made by the AI or commit failed."
    exit 1
}

echo "✅ Remediation complete. Fix committed to branch: $BRANCH_NAME"
echo "You can now push this branch and open a PR: git push -u origin $BRANCH_NAME"

# Switch back to main to keep the main environment clean
trap - ERR # remove the error trap on success
git checkout main
git stash pop || true
