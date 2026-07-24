#!/bin/bash
# ==============================================================================
# Agentic Remediation Engine v2.0
# ==============================================================================
# Creates an isolated branch, injects Neural Memory context, runs the AI agent,
# validates the fix locally, records successful fixes back into memory,
# and maintains clean git state with robust error traps.
# ==============================================================================

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <file_path> <error_message> [memory_context]"
    exit 1
fi

FILE_PATH="$1"
ERROR_MSG="$2"
MEMORY_CONTEXT="${3:-}"
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MEMORY_ENGINE="$WORKSPACE_DIR/bin/memory-engine.sh"

# Generate a unique branch name
TIMESTAMP=$(date +%s)
BRANCH_NAME="auto-fix-${TIMESTAMP}"
ORIGINAL_BRANCH=$(git -C "$WORKSPACE_DIR" rev-parse --abbrev-ref HEAD)

echo "🔨 Remediation Engine v2.0 triggered"
echo "   File: $FILE_PATH"
echo "   Branch: $BRANCH_NAME"

cd "$WORKSPACE_DIR"

# Stash and branch
git stash || true
git checkout -b "$BRANCH_NAME"

# Robust cleanup trap
cleanup() {
    echo "🧹 Cleanup: returning to $ORIGINAL_BRANCH"
    git checkout "$ORIGINAL_BRANCH" 2>/dev/null || true
    git branch -D "$BRANCH_NAME" 2>/dev/null || true
    git stash pop 2>/dev/null || true
}
trap cleanup ERR

# Build the AI prompt with memory injection
PROMPT="Fix the error in $FILE_PATH.
ERROR: $ERROR_MSG

STRICT RULES:
- Enforce ClearCode: O(1) logic, zero deep nesting, single-responsibility functions.
- Do not break existing functionality.
- Do not commit. Only modify the file."

if [[ -n "$MEMORY_CONTEXT" ]]; then
    PROMPT="${PROMPT}

ATTENTION — NEURAL MEMORY CONTEXT:
You have seen similar errors before. Here are past fixes:
${MEMORY_CONTEXT}
Do NOT repeat failed approaches. Learn from the above."
fi

echo "🤖 Dispatching AI agent with $([ -n "$MEMORY_CONTEXT" ] && echo 'memory-augmented' || echo 'standard') prompt..."

# Try available agents in priority order
if command -v agy.exe &>/dev/null; then
    agy.exe --print "$PROMPT" --dangerously-skip-permissions
elif command -v agy &>/dev/null; then
    agy --print "$PROMPT" --dangerously-skip-permissions
elif command -v claude &>/dev/null; then
    echo "$PROMPT" | claude -p
else
    echo "❌ No AI agent found. Install agy, claude, or another supported agent."
    exit 1
fi

# Validate the fix before committing
echo "🔍 Validating the AI's fix locally..."
VALID=true
case "$FILE_PATH" in
    *.sh)   bash -n "$FILE_PATH" || VALID=false ;;
    *.py)   python3 -m py_compile "$FILE_PATH" || VALID=false ;;
    *.json) python3 -c "import json; json.load(open('$FILE_PATH'))" || VALID=false ;;
esac

if [[ "$VALID" == "false" ]]; then
    echo "❌ AI fix failed validation. Aborting."
    exit 1
fi

echo "✅ Fix validated!"

# Commit the fix
git add "$FILE_PATH"
git commit -m "🤖 Auto-fix: $(basename "$FILE_PATH") — remediation engine v2.0" || {
    echo "❌ Commit failed."
    exit 1
}

# Record successful fix into Neural Memory
if [[ -f "$MEMORY_ENGINE" ]]; then
    local_diff=$(git diff HEAD~1 --stat 2>/dev/null || echo "unknown")
    bash "$MEMORY_ENGINE" record "$ERROR_MSG" "$local_diff" "$FILE_PATH"
    echo "🧠 Fix recorded to Neural Memory."
fi

echo "✅ Remediation complete on branch: $BRANCH_NAME"
echo "   Push with: git push -u origin $BRANCH_NAME"

# Return to original branch
trap - ERR
git checkout "$ORIGINAL_BRANCH"
git stash pop 2>/dev/null || true
