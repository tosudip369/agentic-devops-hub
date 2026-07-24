#!/bin/bash
# ==============================================================================
# Neural Memory Engine — The Attention Layer
# ==============================================================================
# Stores error→fix pairs in a local JSONL ledger. Before any remediation,
# the system queries this ledger to inject historical context into the agent
# prompt, preventing repeated mistakes. This is the "attention mechanism."
# ==============================================================================

set -euo pipefail

MEMORY_DIR="${HOME}/.agentic/memory"
LEDGER="${MEMORY_DIR}/error_ledger.jsonl"
mkdir -p "$MEMORY_DIR"
touch "$LEDGER"

# ── RECORD: Store a solved error ──────────────────────────────────────────────
record() {
    local error_sig="$1"
    local fix_diff="$2"
    local file_path="${3:-unknown}"
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Escape quotes for JSON safety
    error_sig=$(echo "$error_sig" | tr '"' "'")
    fix_diff=$(echo "$fix_diff" | tr '"' "'" | tr '\n' ' ')

    local entry
    entry=$(printf '{"timestamp":"%s","file":"%s","error":"%s","fix":"%s"}' \
        "$timestamp" "$file_path" "$error_sig" "$fix_diff")

    echo "$entry" >> "$LEDGER"
    echo "🧠 Memory recorded: $(echo "$error_sig" | head -c 80)..."
}

# ── RECALL: Query past fixes for similar errors ──────────────────────────────
recall() {
    local current_error="$1"
    local max_results="${2:-3}"

    if [[ ! -s "$LEDGER" ]]; then
        echo ""
        return
    fi

    # Extract keywords from the current error (simple tf approach)
    local keywords
    keywords=$(echo "$current_error" | tr '[:upper:]' '[:lower:]' | \
        grep -oE '[a-z_]{4,}' | sort -u | head -10)

    local matches=""
    local count=0

    while IFS= read -r line; do
        for kw in $keywords; do
            if echo "$line" | grep -qi "$kw"; then
                matches="${matches}${line}\n"
                count=$((count + 1))
                break
            fi
        done
        [[ $count -ge $max_results ]] && break
    done < "$LEDGER"

    if [[ -n "$matches" ]]; then
        echo -e "$matches"
    fi
}

# ── STATS: Show memory health ────────────────────────────────────────────────
stats() {
    local total
    total=$(wc -l < "$LEDGER" 2>/dev/null || echo 0)
    echo "🧠 Neural Memory: $total recorded fixes in ledger"
    echo "   Location: $LEDGER"
    if [[ $total -gt 0 ]]; then
        echo "   Latest: $(tail -1 "$LEDGER" | head -c 120)..."
    fi
}

# ── CLI ──────────────────────────────────────────────────────────────────────
case "${1:-help}" in
    record)  record "${2:-}" "${3:-}" "${4:-}" ;;
    recall)  recall "${2:-}" "${3:-3}" ;;
    stats)   stats ;;
    *)       echo "Usage: memory-engine.sh {record|recall|stats}" ;;
esac
